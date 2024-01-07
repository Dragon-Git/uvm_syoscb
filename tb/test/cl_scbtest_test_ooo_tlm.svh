//----------------------------------------------------------------------
//   Copyright 2014-2015 SyoSil ApS
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
// *NOTES*:
// Simple OOO compare test using the TLM based API

// This class implements a monitor which does a sequence of
// writes on it's analysis port with random waits in between
class cl_ooo_tlm_monitor extends uvm_monitor; 
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  uvm_analysis_port #(uvm_sequence_item) anls_port; 

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_ooo_tlm_monitor)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component p = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass: cl_ooo_tlm_monitor

function cl_ooo_tlm_monitor::new(string name, uvm_component p = null); 
  super.new(name,p); 
endfunction 

function void cl_ooo_tlm_monitor::build_phase(uvm_phase phase);
  cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
                                             cl_syoscb_queue_std::get_type(),
                                             "*");

  this.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
                                 cl_syoscb_compare_iop::get_type(),
                                 "*");
  
  super.build_phase(phase);
  this.anls_port = new("anls_port", this); 
endfunction: build_phase

task cl_ooo_tlm_monitor::run_phase(uvm_phase phase);
  cl_scbtest_seq_item a;

  // Raise objection
  phase.raise_objection(this);

  super.run_phase(phase);

  // Create UVM sequence item
  a = new(); 

  // Produce 100 writes
  for(int i=0; i<100; i++) begin
    int unsigned ws;

    // Generate random wait
    ws = $urandom_range(100, 10);

    `uvm_info("OOO_TLM_MON", $sformatf("[%0d]: Waiting %0d time units", i, ws), UVM_NONE);

    // Do the wait
    #(ws); 

    `uvm_info("OOO_TLM_MON", $sformatf("[%0d]: Wait done", i), UVM_NONE);

    // Use increasing values. This will work since we have an OOO compare
    a.int_a = i;

    // Write to the analysis port. This will mimic e.g. a monitor instantiated inside a UVM agent
    // which samples transactions and writres them to its subscribers
    anls_port.write(a); 
  end

  // Drop objection
  phase.drop_objection(this);
endtask: run_phase

class cl_scbtest_test_ooo_tlm extends cl_scbtest_test_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_ooo_tlm_monitor monQ1P1;
  cl_ooo_tlm_monitor monQ2P1;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbtest_test_ooo_tlm)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbtest_test_ooo_tlm", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scbtest_test_ooo_tlm

function cl_scbtest_test_ooo_tlm::new(string name = "cl_scbtest_test_ooo_tlm", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbtest_test_ooo_tlm::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.monQ1P1 = new("monQ1P1", this);
  this.monQ2P1 = new("monQ2P1", this);
endfunction: build_phase

function void cl_scbtest_test_ooo_tlm::connect_phase(uvm_phase phase);
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
    subscriber = this.scbtest_env.syoscb.get_subscriber("Q1", "P1");
    this.monQ1P1.anls_port.connect(subscriber.analysis_export);

    // Get the subscriber for Producer: P1 for queue: Q2 and connect it
    // to the UVM monitor producing transactions for this queue
    subscriber = this.scbtest_env.syoscb.get_subscriber("Q2", "P1");
    this.monQ2P1.anls_port.connect(subscriber.analysis_export);
  end
endfunction: connect_phase

task cl_scbtest_test_ooo_tlm::run_phase(uvm_phase phase);
  // Raise objection
  phase.raise_objection(this);

  super.run_phase(phase);

  // *NOTE*: This test is intentionally empty since
  //         All of the stimulti is coming from the TLM monitors

  // Drop objection
  phase.drop_objection(this);
endtask: run_phase
