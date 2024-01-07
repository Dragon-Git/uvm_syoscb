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
/// Tests uvm_comparer and uvm_printer related features.
class cl_scb_test_io_std_comparer_printer extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_comparer_printer)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_comparer_printer",
                      uvm_component parent = null);
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_comparer_printer

function cl_scb_test_io_std_comparer_printer::new(string name = "cl_scb_test_io_std_comparer_printer",
                                                  uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scb_test_io_std_comparer_printer::run_phase(uvm_phase phase);
  cl_tb_seq_item item1;
  cl_tb_seq_item item2;
  uvm_comparer comparer;
  uvm_root uvm_top;

  phase.raise_objection(this);

  // Demote errors as this test is used for testing compare errors
  uvm_top = uvm_root::get();
  uvm_top.set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);

  super.run_phase(phase);

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_printer_verbosity(1'b1); //Print all array items
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_enable_comparer_report(1'b1);
  comparer = this.scb_env.syoscb_cfgs.syoscb_cfg[0].get_default_comparer();
  cl_syoscb_comparer_config::set_show_max(comparer, 5);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_comparer(comparer);

  //Create two random seq. items
  item1 = cl_tb_seq_item::type_id::create("item1");
  item1.use_data = 1'b1;
  item1.min_data_size = 10;
  item1.max_data_size = 10;

  if(!item1.randomize()) begin
     `uvm_fatal("TEST_ERROR", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q1", "P1", item1);

  item2 = cl_tb_seq_item::type_id::create("item2");
  item2.use_data = 1'b1;
  item2.min_data_size = 10;
  item2.max_data_size = 10;

  if(!item2.randomize()) begin
     `uvm_fatal("TEST_ERROR", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q2", "P1", item2);

  this.scb_env.syoscb[0].flush_queues();

  //Create two items where only dynamic array entries are different
  if(!item1.randomize() with {int_a == 2;}) begin
     `uvm_fatal("TEST_ERROR", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q1", "P1", item1);

  if(!item2.randomize() with {int_a == 2;}) begin
     `uvm_fatal("TEST_ERROR", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q2", "P1", item2);

  this.scb_env.syoscb[0].flush_queues();

  //Create two items where only dynamic_array[50] differs
  item1.min_data_size = 100;
  item1.max_data_size = 100;

  if(!item1.randomize() with {int_a == 2;}) begin
     `uvm_fatal("TEST_ERROR", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q1", "P1", item1);

  $cast(item2, item1.clone());
  item2.data[50] = item1.data[50]+1;

  this.scb_env.syoscb[0].add_item("Q2", "P1", item2);

  this.scb_env.syoscb[0].flush_queues();

  phase.drop_objection(this);
endtask: run_phase
