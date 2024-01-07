//----------------------------------------------------------------------
//   Copyright 2005-2022 SyoSil ApS
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------
/// An implementation of a uvm_packer which returns bitstreams that are ready for md5 packing.
/// Generates bitstreams which follow the format below, as specified in RFC 1321
///  <table>
///  <tr>
///    <th>Bits</th>
///    <th>Information</th>
///  </tr>
///  <tr>
///    <td> 0 - length of the serialized item-1</td>
///    <td> Serialized item</td>
///  </tr>
///  <tr>
///    <td> length of the serialized item - lentgh of the serialized item+6</td>
///    <td> Zeros</td>
///  </tr>
///  <tr>
///    <td>length of the serialized item+7</td>
///    <td> One </td>
///  </tr>
///  <tr>
///    <td>length of the serialized item+8 - (512*x-64)</td>
///    <td> Zeros</td>
///  </tr>
///  <tr>
///    <td> last 64 bits</td>
///    <td> length of the item modulo 2^64</td>
///  </tr>
///  </table>
///
/// <b>NOTICE</b>: The current implementation of the md5_packer only manipulates the
/// bitstream returned when #get_bits or #get_packed_bits is called, and does not modify
/// the underlying bitstream.
/// After calling \c get_packed_bits or \c get_bits, call #clean to clean
/// the underlying bitstream, allowing the packer to be reused
class cl_syoscb_md5_packer extends cl_syoscb_hash_packer;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new();
    super.new();
    `ifndef UVM_VERSION
      this.big_endian = 0; //Must use this value to correctly pack strings
    `endif
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  `ifdef UVM_VERSION //UVM-IEEE implementation
    extern virtual function void get_packed_bits(ref bit unsigned stream[]);
  `else
    extern virtual function void get_bits(ref bit unsigned bits[]);
  `endif

endclass: cl_syoscb_md5_packer

`ifdef UVM_VERSION //UVM-IEEE implementation
/// Gets the packer's bitstream, modifying the contents such that it conforms to RFC 1321
function void cl_syoscb_md5_packer::get_packed_bits(ref bit unsigned stream[]);
  //See implementation of get_bits of non-IEEE implementations for a more thoroughly commented implementation

  //uvm-IEEE packers use the first 64 bits to store metadata - we don't want to include that
  //Also point to first available character, meaning that we have another 8 bits of junk to discard
  //m_pack_iter points to
  int data_size = m_pack_iter - 64 - 8;
  int stream_size = data_size + 512 - (data_size % 512);
  bit [63:0] length = data_size;

  if(512 - (data_size % 512) < 72) begin
    stream_size += 512;
  end

  //get_packed_bits also copies the iterator values
  //instead, we just copy the bits 64 and upward
  stream = new[stream_size];
  for(int i=0; i<data_size; i++) begin
    stream[i] = m_bits[i+64];
  end

  stream[data_size+7] = 1'b1;

  for(int i=0; i<64; i++) begin
    stream[stream_size-64+i] = length[i];
  end
endfunction: get_packed_bits

`else

/// Gets the packer's bitstream, modifying the contents such that it conforms to RFC 1321
function void cl_syoscb_md5_packer::get_bits(ref bit unsigned bits[]);
  int size, m_packed_size_old;
  bit [63:0] length;
  this.set_packed_size(); //Must call before manipulating bitstream

  //Size of bits-array should be next multiple of 512 which is larger than m_packed_size
  size = m_packed_size + 512 - (m_packed_size % 512);
  m_packed_size_old = m_packed_size;
  length = m_packed_size_old;

  //If difference between new size and m_packed_size is less than 72, we require another 512 bits due to MD5 spec
  if(512 - (m_packed_size % 512) < 72) begin //Less than 72, so we need the next multiple of 512
    size += 512;
  end

  this.m_packed_size = size;

  super.get_bits(bits); //Get bits from super implementation, uses new value of m_packed_size to allocate bits-array

  //Bits 0:6 after item should be 0's, but that is default behaviour
  //Bits 7 after item should be 1
  bits[m_packed_size_old+7] = 1'b1;

  //All bits between that 1'b1 and m_packed_size-64 need to be 0's
  //Bits default to zero, so nothing is set

  //Final length of item: The UVM implementation of get_bits uses an int
  //to traverse the bits-array. Therefore, size of bits-array is expressed with at most
  //32 bits => we can simply set the size of item without taking the modulo with 2^64
  for(int i=0; i<64; i++) begin
    bits[size-64+i] = length[i];
  end

  this.m_packed_size = m_packed_size_old;
endfunction: get_bits

`endif