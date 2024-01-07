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
// Simple test with two SCBs with different compares.

class cl_scbtest_test_ooo_io_simple extends cl_scbtest_test_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbtest_test_ooo_io_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbtest_test_ooo_io_simple", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scbtest_test_ooo_io_simple

function cl_scbtest_test_ooo_io_simple::new(string name = "cl_scbtest_test_ooo_io_simple", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbtest_test_ooo_io_simple::build_phase(uvm_phase phase);
  cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
                                             cl_syoscb_queue_std::get_type(),
                                             "*");


  cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_ooo::get_type(),
                                                     "uvm_test_top.scbtest_env.syoscb0.*");
  
  cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_io::get_type(),
                                                     "uvm_test_top.scbtest_env.syoscb1.*");

/* TBD::JSA: This doesn't work? 
  cl_syoscb_compare::set_inst_override_by_type("uvm_test_top.scbtest_env.syoscb0.compare_strategy",
                                               cl_syoscb_compare_base::get_type(),
                                               cl_syoscb_compare_ooo::get_type());

  cl_syoscb_compare::set_inst_override_by_type("uvm_test_top.scbtest_env.syoscb1.compare_strategy",
                                               cl_syoscb_compare_base::get_type(),
                                               cl_syoscb_compare_ooo::get_type());
*/
/* TBD::JSA: This doesn't work?
  this.set_inst_override_by_type("uvm_test_top.scbtest_env.syoscb0.compare_strategy",
                                 cl_syoscb_compare_base::get_type(),
                                 cl_syoscb_compare_ooo::get_type());

  this.set_inst_override_by_type("uvm_test_top.scbtest_env.syoscb1.compare_strategy",
                                 cl_syoscb_compare_base::get_type(),
                                 cl_syoscb_compare_io::get_type());
*/
/* Old general type overwrite
  this.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
                                 cl_syoscb_compare_ooo::get_type(),
                                 "*");
*/

  super.build_phase(phase);
endfunction: build_phase
  
task cl_scbtest_test_ooo_io_simple::run_phase(uvm_phase phase);
  super.run_phase(phase);

  fork
    // Insert items in Q1 as P1 with int_a from 0 to 9
    // in both syoscb[0] and syoscb[1]
    for(int unsigned i=0; i<10; i++) begin
      cl_scbtest_seq_item item1;
      item1 = cl_scbtest_seq_item::type_id::create("item1");
      item1.int_a = i;
      scbtest_env.syoscb[0].add_item("Q1", "P1", item1);
      scbtest_env.syoscb[1].add_item("Q1", "P1", item1);
    end

    // Insert items in Q2 as P1 with int_a from 9 to 0
    // but only in syoscb[0] as it runs with an OOO compare
    for(int i=9; i>=0; i--) begin
      cl_scbtest_seq_item item1;
      item1 = cl_scbtest_seq_item::type_id::create("item1");
      item1.int_a = i;
      scbtest_env.syoscb[0].add_item("Q2", "P1", item1);
    end

    // Insert items in Q2 as P1 with int_a from 0 to 9
    // but only in syoscb[1] as it runs with an IO compare
    for(int i=0; i<10; i++) begin
      cl_scbtest_seq_item item1;
      item1 = cl_scbtest_seq_item::type_id::create("item1");
      item1.int_a = i;
      scbtest_env.syoscb[1].add_item("Q2", "P1", item1);
    end
  join
endtask: run_phase
