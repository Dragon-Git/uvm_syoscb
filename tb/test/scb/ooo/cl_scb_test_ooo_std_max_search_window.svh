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
/// Simple OOO compare test using the function based API and the max_search_window knob to control
/// OOO compare searches
class cl_scb_test_ooo_std_max_search_window extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_std_max_search_window)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_std_max_search_window", uvm_component parent = null);
  extern virtual function void pre_build();
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task     run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
endclass : cl_scb_test_ooo_std_max_search_window

function cl_scb_test_ooo_std_max_search_window::new(string name = "cl_scb_test_ooo_std_max_search_window",
                                         uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_ooo_std_max_search_window::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  this.syoscb_cfgs.syoscb_cfg[0].set_max_search_window(5, {});
  this.syoscb_cfgs.syoscb_cfg[0].set_max_print_orphans(0);
  this.syoscb_cfgs.syoscb_cfg[0].set_trigger_greediness(pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY);
  this.syoscb_cfgs.syoscb_cfg[0].print();

endfunction : pre_build

task cl_scb_test_ooo_std_max_search_window::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.run_phase(phase);

  //Push in a number of transactions that we wish to match on
  for(int unsigned i=0; i<10; i++) begin
    cl_tb_seq_item item1;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item1.int_a = i;
    scb_env.syoscb[0].add_item("Q1", "P1", item1);
  end

  //Push in transactions to Q2 which should not match in Q1
  //Since we're pushing them in reverse order, no matches should be found
  //Q1: 0 1 2 3 4 5 6 7 8 9
  //Q2: 9 8 7 6 5 4 3 2 1 0
  //msw: -------^
  for(int i=9; i>=0; i--) begin
    cl_tb_seq_item item2;
    item2 = cl_tb_seq_item::type_id::create("item2");
    item2.int_a = i;
    scb_env.syoscb[0].add_item("Q2", "P1", item2);
  end

  //At this point, we expect there to have been 0 matches, 20 insertions
  `uvm_info("TEST", $sformatf("Total items inserted: %0d. Total items remaining in SCB: %0d",
                               scb_env.syoscb[0].get_total_cnt_add_items(),
                               scb_env.syoscb[0].get_total_queue_size()),
                               UVM_LOW)

  if(scb_env.syoscb[0].get_total_queue_size() != 20) begin
    `uvm_error("TEST", $sformatf("Items have been removed from the SCB. Expected 20 items remaining, found %0d", scb_env.syoscb[0].get_total_queue_size()))
  end

  this.syoscb_cfgs.syoscb_cfg[0].set_max_search_window(0, {});
  //By setting max_search_window == 0, the remaining transactions will be removed in cl_syoscb_compare::extract_phase

  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_ooo_std_max_search_window::check_phase(uvm_phase phase);
  if(scb_env.syoscb[0].get_total_queue_size() != 0) begin
    `uvm_error("TEST", $sformatf("All queue items have not been drained, %0d items remaining, expected 0", scb_env.syoscb[0].get_total_queue_size()));
  end
endfunction: check_phase