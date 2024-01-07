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
// Simple OOO compare test using the function based API

class cl_scbtest_test_ooo_simple extends cl_scbtest_test_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbtest_test_ooo_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbtest_test_ooo_simple", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scbtest_test_ooo_simple

function cl_scbtest_test_ooo_simple::new(string name = "cl_scbtest_test_ooo_simple", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbtest_test_ooo_simple::build_phase(uvm_phase phase);
  cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
                                             cl_syoscb_queue_std::get_type(),
                                             "*");

  this.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
                                 cl_syoscb_compare_ooo::get_type(),
                                 "*");
  super.build_phase(phase);
endfunction: build_phase
  
task cl_scbtest_test_ooo_simple::run_phase(uvm_phase phase);
  super.run_phase(phase);

  fork
	for(int unsigned i=0; i<10; i++) begin
      cl_scbtest_seq_item item1;
      item1 = cl_scbtest_seq_item::type_id::create("item1");
      item1.int_a = i;
      scbtest_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int i=9; i>=0; i--) begin
      cl_scbtest_seq_item item1;
      item1 = cl_scbtest_seq_item::type_id::create("item1");
      item1.int_a = i;
      scbtest_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join
endtask: run_phase
