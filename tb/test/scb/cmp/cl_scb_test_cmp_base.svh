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
/// Base class for field macro/manual do_compare comparison tests.
/// These tests serve to make sure that a mix of field macros and manual do_compare implementations evaluate correctly.
/// Does this by using objects of type 'a', which has a handle to a type 'b' object, which has a handle to an endpoint object.
/// This allows us to chain field macros/do_compare/mixed implementations
/// \param ATYPE Type of the top-level objects to instantiate
/// \param suffix A suffix to add to the test name. The final testname will be "cl_scb_test_cmp_<io/ooo>_<suffix>"
class cl_scb_test_cmp_base#(type ATYPE = cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                            string suffix = "") extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils(cl_scb_test_cmp_base#(ATYPE))

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_cmp_base", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern function void check_phase(uvm_phase phase);

  //-------------------------------------
  // Typedefs
  //-------------------------------------
  typedef cl_tb_arr_wrapper#(ATYPE) stim_wrapper;

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function void drive_stimuli(string queue, string producer, stim_wrapper stim);
endclass: cl_scb_test_cmp_base

function cl_scb_test_cmp_base::new(string name = "cl_scb_test_cmp_base", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

function void cl_scb_test_cmp_base::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  //Will print where comparisons go wrong if a miscompare happens
  this.syoscb_cfgs.syoscb_cfg[0].set_default_enable_comparer_report(1'b1);
endfunction: end_of_elaboration_phase

task cl_scb_test_cmp_base::run_phase(uvm_phase phase);
  stim_wrapper stim1, stim2;
  int sz;

  phase.raise_objection(this);
  super.run_phase(phase);
  //Demote COMPARE_ERROR as we expect to have exactly one of these
  uvm_root::get().set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);

  //Generate randomized stim - we will copy the data from these into the actual transactions (see drive_stimuli)
  stim1 = stim_wrapper::type_id::create("stim1");
  stim2 = stim_wrapper::type_id::create("stim2");
  if(!stim1.randomize() with {stim1.items.size() > 10;}) begin
    `uvm_fatal("RND", "Unable to randomize stimulus wrapper")
  end

  //We want to ensure that errors are detected, so we make the last items in each stim packet a no-match
  //Will be an error for IO-compare, will just be a no-match for OOO compare
  stim2.copy(stim1);
  sz = stim2.items.size();
  stim2.items[sz-1].ival += 1;
  stim2.items[sz-2].iobj.ival += 1;
  stim2.items[sz-3].iobj.iobj.int_a += 1;
  stim2.items[sz-4].iobj.iobjs[0].int_a += 1;
  stim2.items[sz-5].iobjs[0].ival += 1;
  stim2.items[sz-6].iobjs[0].iobj.int_a += 1;
  stim2.items[sz-7].iobjs[0].iobjs[0].int_a += 1;

  fork
    this.drive_stimuli("Q1", "P1", stim1);
    this.drive_stimuli("Q2", "P1", stim2);
  join

  this.scb_env.syoscb[0].flush_queues();

  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_cmp_base::check_phase(uvm_phase phase);
  int num_flush;
  super.check_phase(phase);

  num_flush = this.scb_env.syoscb[0].get_total_cnt_flushed_items();

  //We expect to have flushed a total of 14 items
  if(num_flush != 14) begin
    `uvm_error("TEST", $sformatf("Number of flushed items was not 14 as expected, flushed %0d items instead", num_flush))
  end
endfunction: check_phase

function void cl_scb_test_cmp_base::drive_stimuli(string queue, string producer, stim_wrapper stim);
  foreach(stim.items[i]) begin
    scb_env.syoscb[0].add_item(queue, producer, stim.items[i]);
  end
endfunction