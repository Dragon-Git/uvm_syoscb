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
/// Simple IO test using the TLM ssetup and mutexed add_item
class cl_scb_test_io_std_tlm_mutexed extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_tb_tlm_monitor#() monQ1P1;
  cl_tb_tlm_monitor#() monQ2P1;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_tlm_mutexed)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_tlm_mutexed", uvm_component parent = null);
  extern virtual function void pre_build();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_tlm_mutexed

function cl_scb_test_io_std_tlm_mutexed::new(string name = "cl_scb_test_io_std_tlm_mutexed",
                                      uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_io_std_tlm_mutexed::pre_build();
  super.pre_build();
  this.syoscb_cfgs.syoscb_cfg[0].set_mutexed_add_item_enable(1'b1);
endfunction : pre_build

function void cl_scb_test_io_std_tlm_mutexed::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.monQ1P1 = new("monQ1P1", this);
  this.monQ2P1 = new("monQ2P1", this);
endfunction: build_phase

function void cl_scb_test_io_std_tlm_mutexed::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  // *NOTE*: This will hook up the TLM monitors with the TLM API of the
  //         scoreboard. Normally, this would not be done here but in the
  //         testbench environment which would have access to all of the
  //         montors and the scoreboard. However, these monitors only
  //         exists for this specific test. Thus, it is done here locally.
  begin
    cl_syoscb_subscriber subscriber;

    // Get the subscriber for Producer: P1 for queue: Q1 and connect it
    // to the UVM monitor producing transactions for this queue
    subscriber = this.scb_env.syoscb[0].get_subscriber("Q1", "P1");
    this.monQ1P1.anls_port.connect(subscriber.analysis_export);

    // Get the subscriber for Producer: P1 for queue: Q2 and connect it
    // to the UVM monitor producing transactions for this queue
    subscriber = this.scb_env.syoscb[0].get_subscriber("Q2", "P1");
    this.monQ2P1.anls_port.connect(subscriber.analysis_export);
  end
endfunction: connect_phase

task cl_scb_test_io_std_tlm_mutexed::run_phase(uvm_phase phase);
  // Raise objection
  phase.raise_objection(this);

  super.run_phase(phase);

  // *NOTE*: This test is intentionally empty since
  //         All of the stimulti is coming from the TLM monitors

  // Drop objection
  phase.drop_objection(this);
endtask: run_phase
