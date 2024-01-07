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
/// Tests the ability to flush queues and disable compare during runtime for std queues.

class cl_scb_test_io_std_disable_compare extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_disable_compare)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_disable_compare",
                      uvm_component parent = null);
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_disable_compare

function cl_scb_test_io_std_disable_compare::new(string name = "cl_scb_test_io_std_disable_compare",
                                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scb_test_io_std_disable_compare::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  fork
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  if(!scb_env.syoscb[0].empty_queues()) begin
    `uvm_error("TEST_ERROR", "All queues not empty 1st time around!");
  end

  scb_env.syoscb[0].compare_control(1'b0);

  fork
    for(int unsigned i=0; i<8; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<7; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i+1000;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  scb_env.syoscb[0].flush_queues();

  if(!scb_env.syoscb[0].empty_queues()) begin
    `uvm_error("TEST_ERROR", "All queues not empty 2nd time around!");
  end

  scb_env.syoscb[0].compare_control(1'b1);

  fork
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  phase.drop_objection(this);
endtask: run_phase
