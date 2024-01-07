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
/// Tests the intermediate queue stat printout, see cl_syoscb_cfg#queue_stat_interval

class cl_scb_test_io_std_intermediate_dump extends cl_scb_test_io_std_simple;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_intermediate_dump)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_intermediate_dump", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_intermediate_dump

function void cl_scb_test_io_std_intermediate_dump::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  this.syoscb_cfgs.syoscb_cfg[0].set_scb_stat_interval(7);
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_stat_interval("Q1", 3); //Every third tx
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_stat_interval("Q2", 5); //Every 5th tx
  this.syoscb_cfgs.syoscb_cfg[0].set_enable_queue_stats("Q2", 1'b1); //Also print producer information for Q2
endfunction: end_of_elaboration_phase