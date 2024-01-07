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
/// Tests side-by-side error prints when using io-2hp comparison.
// This test is a functional copy of the test seen in cl_scb_test_io_std_sbs_print
// and is used to show that side-by-side prints also work when using io-2hp compare
class cl_scb_test_io_2hp_std_sbs_print extends cl_scb_test_io_std_sbs_print;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_2hp_std_sbs_print)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_2hp_std_sbs_print", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();

endclass: cl_scb_test_io_2hp_std_sbs_print

function void cl_scb_test_io_2hp_std_sbs_print::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IO2HP);
endfunction: pre_build