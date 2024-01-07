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
typedef class small_seq_item;
typedef class large_seq_item;

/// Shows a number of different ways that the side-by-side miscompare table can be used
class cl_scb_test_io_std_sbs_print extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_std_sbs_print)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_sbs_print", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task run_phase(uvm_phase phase);

endclass: cl_scb_test_io_std_sbs_print

class small_seq_item extends uvm_sequence_item;
  rand int int_a;
  rand int int_b;

  `uvm_object_utils_begin(small_seq_item)
    `uvm_field_int(int_a, UVM_DEFAULT)
    `uvm_field_int(int_b, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "small_seq_item");
    super.new(name);
  endfunction: new

endclass: small_seq_item

class large_seq_item extends uvm_sequence_item;
  rand int int_a;
  int int_b;
  rand int int_arr[];

  constraint co_int_arr_size {int_arr.size() inside {[6:10]};}

  `uvm_object_utils_begin(large_seq_item)
    `uvm_field_int(int_a, UVM_DEFAULT)
    `uvm_field_int(int_b, UVM_DEFAULT)
    `uvm_field_array_int(int_arr, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "large_seq_item");
    super.new(name);
  endfunction: new

endclass: large_seq_item

task cl_scb_test_io_std_sbs_print::run_phase(uvm_phase phase);
  small_seq_item small1, small2, small3;
  large_seq_item large1, large2;

  uvm_root uvm_top;
  uvm_comparer comparer;

  phase.raise_objection(this);

  // Demote errors as this test is used for testing compare error prints
  // and thus will trigger compare errors
  uvm_top = uvm_root::get();
  uvm_top.set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);

  super.run_phase(phase);

  small1 = small_seq_item::type_id::create("small1");
  small2 = small_seq_item::type_id::create("small2");
  large1 = large_seq_item::type_id::create("large1");
  large2 = large_seq_item::type_id::create("large2");

  comparer = this.scb_env.syoscb_cfgs.syoscb_cfg[0].get_default_comparer();
  cl_syoscb_comparer_config::set_show_max(comparer, 5);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_comparer(comparer);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_enable_comparer_report(1'b1);

  if(!small1.randomize()) begin
    `uvm_fatal("RND", "Unable to randomize small1");
  end

  if(!small2.randomize()) begin
    `uvm_fatal("RND", "Unable to randomize small2");
  end

  if(!large1.randomize()) begin
    `uvm_fatal("RND", "Unable to randomize large1");
  end

  if(!large2.randomize() with {large2.int_arr.size() != large1.int_arr.size();}) begin
    `uvm_fatal("RND", "Unable to randomize large2");
  end

  $display("\n>>>Two items of the same type with different contents<<<");
  fork
    scb_env.syoscb[0].add_item("Q1", "P1", small1);
    scb_env.syoscb[0].add_item("Q2", "P1", small2);
  join
  scb_env.syoscb[0].flush_queues_all();

  $display("\n>>>Two items of different types<<<");
  fork
    scb_env.syoscb[0].add_item("Q1", "P1", large1);
    scb_env.syoscb[0].add_item("Q2", "P1", small1);
  join
  scb_env.syoscb[0].flush_queues_all();

  $display("\n>>>Two items of the same type, varying darray lengths<<<");
  fork
    scb_env.syoscb[0].add_item("Q1", "P1", large1);
    scb_env.syoscb[0].add_item("Q2", "P1", large2);
  join
  scb_env.syoscb[0].flush_queues_all();

  $display("\n>>>Two items of the same type, same darray lengths<<<");
  if(!large1.randomize()) begin
    `uvm_fatal("RND", "Unable to randomize large1")
  end

  if(!large2.randomize() with {large2.int_arr.size() == large1.int_arr.size();}) begin
    `uvm_fatal("RND", "Unable to randomize large2")
  end
  fork
    scb_env.syoscb[0].add_item("Q1", "P1", large1);
    scb_env.syoscb[0].add_item("Q2", "P1", large2);
  join
  scb_env.syoscb[0].flush_queues_all();




  phase.drop_objection(this);
endtask: run_phase