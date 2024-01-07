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
// Base test class which uses a single scoreboard only

class cl_scb_test_single_scb extends cl_scb_test_double_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_single_scb)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_single_scb", uvm_component parent = null);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
endclass : cl_scb_test_single_scb

function cl_scb_test_single_scb::new(string name = "cl_scb_test_single_scb",
                                     uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_single_scb::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  // Disabling insert check as the tests derived from this will use syoscb[0] only.
  // This prevents to generate sim errors because nothing no items are inserted into syoscb[1] queues.
  this.syoscb_cfgs.syoscb_cfg[1].set_enable_no_insert_check(0);
endfunction: end_of_elaboration_phase
