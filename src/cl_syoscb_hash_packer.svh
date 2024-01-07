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
/// A base class for packers which should be used with hash algorithms
/// in the scoreboard.
/// The packers should implement \c get_bits or \c get_packed_bits (depending on
/// UVM version), returning a bitstream which conforms to the given hash
/// algorithm's requirements
class cl_syoscb_hash_packer extends uvm_packer;
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
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void clean();

endclass: cl_syoscb_hash_packer

/// Clean and reset the underlying packer data structure
/// This method correctly calls packer.flush on UVM-IEEE and
/// packer.reset on previous versions of UVM, removing the need for
/// version-specific code in the caller
function void cl_syoscb_hash_packer::clean();
  `ifdef UVM_VERSION
    this.flush();
  `else
    this.reset();
  `endif
endfunction: clean