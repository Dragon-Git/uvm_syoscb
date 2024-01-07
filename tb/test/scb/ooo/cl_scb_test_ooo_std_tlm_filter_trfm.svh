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
/// Simple OOO compare test using the TLM based API and filter transforms
class cl_scb_test_ooo_std_tlm_filter_trfm extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_tb_tlm_monitor#(cl_tb_seq_item) monQ1P1;
  cl_tb_tlm_monitor#(cl_tb_seq_item) monQ2P1;

  pk_utils_uvm::filter_trfm#(cl_tb_seq_item) filterQ1P1;
  pk_utils_uvm::filter_trfm#(cl_tb_seq_item) filterQ2P1;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_std_tlm_filter_trfm)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_std_tlm_filter_trfm",
                      uvm_component parent = null);
  extern virtual function void pre_build();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_ooo_std_tlm_filter_trfm

function cl_scb_test_ooo_std_tlm_filter_trfm::new(string name = "cl_scb_test_ooo_std_tlm_filter_trfm",
                                                  uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_ooo_std_tlm_filter_trfm::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
endfunction : pre_build

function void cl_scb_test_ooo_std_tlm_filter_trfm::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.monQ1P1 = new("monQ1P1", this);
  this.monQ2P1 = new("monQ2P1", this);
  this.filterQ1P1 = new("filterQ1P1", this);
  this.filterQ2P1 = new("filterQ2P1", this);
endfunction: build_phase

function void cl_scb_test_ooo_std_tlm_filter_trfm::connect_phase(uvm_phase phase);
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
    this.filterQ1P1.ap.connect(subscriber.analysis_export);
    this.monQ1P1.anls_port.connect(this.filterQ1P1.analysis_export);

    // Get the subscriber for Producer: P1 for queue: Q2 and connect it
    // to the UVM monitor producing transactions for this queue
    subscriber = this.scb_env.syoscb[0].get_subscriber("Q2", "P1");
    this.filterQ2P1.ap.connect(subscriber.analysis_export);
    this.monQ2P1.anls_port.connect(this.filterQ2P1.analysis_export);
  end
endfunction: connect_phase

task cl_scb_test_ooo_std_tlm_filter_trfm::run_phase(uvm_phase phase);
  // Raise objection
  phase.raise_objection(this);

  super.run_phase(phase);

  // *NOTE*: This test is intentionally empty since
  //         All of the stimulti is coming from the TLM monitors

  // Drop objection
  phase.drop_objection(this);
endtask: run_phase
