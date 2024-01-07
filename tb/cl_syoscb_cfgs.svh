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
/// Wrapper class, for forwarding cfg object array from test to env.
class cl_syoscb_cfgs extends uvm_object;
  cl_syoscb_cfg syoscb_cfg[];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_cfgs)
    `uvm_field_array_object(syoscb_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_cfgs");
    super.new(name);
  endfunction : new

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function void init(int unsigned no);
endclass: cl_syoscb_cfgs

// Instantiates syoscb_cfg to contain no elements inside
function void cl_syoscb_cfgs::init(int unsigned no);
  this.syoscb_cfg = new[no];
endfunction: init
