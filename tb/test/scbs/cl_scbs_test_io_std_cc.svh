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
/// Simple IO compare with STD queue test. Testing the cl_syoscbs class
// using TLM hook up to monitors

class cl_scbs_test_io_std_cc extends cl_scbs_test_io_std_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_io_std_cc)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbs_test_io_std_cc",
                      uvm_component parent = null);

  extern task run_phase(uvm_phase phase);
  extern function void extract_phase(uvm_phase phase);
endclass : cl_scbs_test_io_std_cc

function cl_scbs_test_io_std_cc::new(string name = "cl_scbs_test_io_std_cc",
                                     uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scbs_test_io_std_cc::run_phase(uvm_phase phase);
  t_scb_compare_greed global_greed[];
  int unsigned   ws;

  phase.raise_objection(this);
  super.run_phase(phase);

  // Generate random wait
  ws = $urandom_range(1000, 90);

  `uvm_info("TEST", $sformatf("Waiting %0d time units", ws), UVM_NONE);

  // Do the wait
  #(ws);

  `uvm_info("TEST", $sformatf("Wait done"), UVM_NONE);

  this.scbs_env.syoscbs.compare_control_all(1'b0);

  // Inserting a random error will return a miscompare if the end greedy is enabled
  this.rnd_scb_insert();

  // Keeping the injection of the random insert, but disabling the drain in the extract phase.
  global_greed[0] = pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY;
  this.scbs_env.syoscbs_cfg.set_scb_end_greediness(.idxs({}), .eg(global_greed));

  phase.drop_objection(this);
endtask: run_phase

function void cl_scbs_test_io_std_cc::extract_phase(uvm_phase phase);
  super.extract_phase(phase);

  this.scbs_env.syoscbs.flush_queues_all();
endfunction: extract_phase
