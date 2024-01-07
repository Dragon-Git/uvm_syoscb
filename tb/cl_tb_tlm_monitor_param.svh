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
/// A version of cl_tb_tlm_monitor which creates a sequence item of the parameter type,
/// instead of always creating an item of type cl_tb_seq_item.
// This class is made because we cannot override functionality in cl_tb_tlm_monitor,
// as that breaks the test in cl_scb_test_ooo_std_tlm
class cl_tb_tlm_monitor_param#(type T = cl_tb_seq_item) extends uvm_monitor;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  uvm_analysis_port #(T) anls_port;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_param_utils(cl_tb_tlm_monitor_param#(T))

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_tb_tlm_monitor_param", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task          run_phase(uvm_phase phase);
  extern function void build_phase(uvm_phase phase);
endclass: cl_tb_tlm_monitor_param

function cl_tb_tlm_monitor_param::new(string name = "cl_tb_tlm_monitor_param", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

function void cl_tb_tlm_monitor_param::build_phase(uvm_phase phase);
  super.build_phase(phase);
  this.anls_port = new("anls_port", this);
endfunction: build_phase

task cl_tb_tlm_monitor_param::run_phase(uvm_phase phase);
  T a;

  // Raise objection
  phase.raise_objection(this);

  super.run_phase(phase);

  // Create UVM sequence item
  a = T::type_id::create("a");

  // Produce 100 writes
  for(int i=0; i<100; i++) begin
    int unsigned ws;

    // Generate random wait
    ws = $urandom_range(100, 10);

    `uvm_info("TB_TLM_MON", $sformatf("[%0d]: Waiting %0d time units", i, ws), UVM_HIGH);

    // Do the wait
    #(ws);

    `uvm_info("TB_TLM_MON", $sformatf("[%0d]: Wait done", i), UVM_HIGH);

    // Use increasing values. This will work for OOO/IOP compares
    a.int_a = i;

    // Write to the analysis port. This will mimic e.g. a monitor instantiated inside a UVM agent
    // which samples transactions and writres them to its subscribers
    anls_port.write(a);
  end

  // Drop objection
  phase.drop_objection(this);
endtask: run_phase