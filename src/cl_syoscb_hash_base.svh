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
/// Class which defines the base concept of a hash algorithm.
/// All hash functions must extend this class and implement the hash API.
/// \param HASH_DIGEST_WIDTH The number of bits in the hash digest for that hashing algorithm
class cl_syoscb_hash_base #(int unsigned HASH_DIGEST_WIDTH = 1) extends uvm_object;

  /// Typedef for a bitstream of HASH_DIGEST_WIDTH bits
  typedef bit [HASH_DIGEST_WIDTH-1:0] tp_hash_digest;

  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration object
  protected cl_syoscb_cfg cfg;
  /// Handle to a packer suited for this hash algorithm
  /// The packer should be set in the implementing class' constructor
  protected cl_syoscb_hash_packer packer;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_syoscb_hash_base#(HASH_DIGEST_WIDTH))
    `uvm_field_object(cfg, UVM_DEFAULT | UVM_REFERENCE)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_hash_base");
     super.new(name);
  endfunction: new

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------

  //-------------------------------------
  // Hash API
  //-------------------------------------
  // User-facing functions
  extern virtual function tp_hash_digest hash(cl_syoscb_item item);
  extern virtual function tp_hash_digest hash_str(string str);

  // Internal hash functions
  extern protected virtual function tp_hash_digest do_hash(bit ser []);



endclass: cl_syoscb_hash_base

/// <b>Hash API:</b> Returns the hash value of the given bitstream. The bitstream must comply with the
/// chosen hash algorithm's requirements.
/// \param ser The bitstream to generate the hash for
/// \return The hash of the input bitstream
function cl_syoscb_hash_base::tp_hash_digest cl_syoscb_hash_base::do_hash(bit ser []);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_hash_base::do_hash() *MUST* be overwritten", this.cfg.get_scb_name()))
  return 'bx;
endfunction: do_hash

/// <b> Hash API:</b> Hashes a string, returning its hash value
/// \param str The string to hash
/// \return The hash value of that string
function cl_syoscb_hash_base::tp_hash_digest cl_syoscb_hash_base::hash_str(string str);
  bit ser [];
  tp_hash_digest out;

  this.packer.pack_string(str);

  `ifdef UVM_VERSION //Use UVM-IEEE API
    packer.get_packed_bits(ser);
  `else
    packer.get_bits(ser);
  `endif

  out=this.do_hash(ser);
  this.packer.clean();

  return out;
endfunction: hash_str

/// <b> Hash API:</b> Hashes a cl_syoscb_item, returning its hash value
/// \param item The item to hash
/// \return The hash value of that string
function cl_syoscb_hash_base::tp_hash_digest cl_syoscb_hash_base::hash(cl_syoscb_item item);
  bit ser [];
  tp_hash_digest  out;

  void'(item.pack(ser, this.packer));
  out=this.do_hash(ser);
  this.packer.clean();

  return out;
endfunction: hash
