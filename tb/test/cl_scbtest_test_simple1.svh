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

class cl_scbtest_test_simple1 extends cl_scbtest_test_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbtest_test_simple1)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbtest_test_simple1", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scbtest_test_simple1

function cl_scbtest_test_simple1::new(string name = "cl_scbtest_test_simple1", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scbtest_test_simple1::run_phase(uvm_phase phase);
  super.run_phase(phase);
  begin
    cl_scbtest_seq_item item1;
    item1 = cl_scbtest_seq_item::type_id::create("item1");
    item1.int_a = 'h3a;
    scbtest_env.syoscb.add_item("Q1", "P1", item1);
  end
  begin
    cl_scbtest_seq_item item1;
    item1 = cl_scbtest_seq_item::type_id::create("item1");
    item1.int_a = 'h3a;
    scbtest_env.syoscb.add_item("Q2", "P1", item1);
  end
endtask: run_phase
