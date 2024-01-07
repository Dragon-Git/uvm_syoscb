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
/// Simple IO-2HP compare test using the function based API
class cl_scb_test_io_2hp_std_simple extends cl_scb_test_io_std_simple;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_2hp_std_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_2hp_std_simple", uvm_component parent = null);
  extern virtual function void pre_build();
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------

endclass : cl_scb_test_io_2hp_std_simple

function cl_scb_test_io_2hp_std_simple::new(string name = "cl_scb_test_io_2hp_std_simple",
                                            uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_io_2hp_std_simple::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IO2HP);
endfunction : pre_build