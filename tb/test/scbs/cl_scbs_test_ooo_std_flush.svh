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

/// Simple OOO compare with STD queue test which inserts additional random items,
/// requiring a flush at the end to pass the test.
// Uses TLM based API
class cl_scbs_test_ooo_std_flush extends cl_scbs_test_ooo_std_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_ooo_std_flush)

  extern function new(string name = "cl_scbs_test_ooo_std_flush",
                      uvm_component parent = null);

  extern task run_phase(uvm_phase phase);
  extern function void extract_phase(uvm_phase phase);
endclass : cl_scbs_test_ooo_std_flush

function cl_scbs_test_ooo_std_flush::new(string name = "cl_scbs_test_ooo_std_flush",
                                         uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scbs_test_ooo_std_flush::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  this.rnd_scb_insert();

  phase.drop_objection(this);
endtask: run_phase

function void cl_scbs_test_ooo_std_flush::extract_phase(uvm_phase phase);
  super.extract_phase(phase);

  this.scbs_env.syoscbs.flush_queues_by_index();
endfunction: extract_phase
