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
/// OOO Compare test for validating that OOO compares respect the current greed level
class cl_scb_test_ooo_std_trigger_greed extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_ooo_std_trigger_greed)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_ooo_std_trigger_greed", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern function void add_19();
  extern task          main_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);


endclass: cl_scb_test_ooo_std_trigger_greed

function void cl_scb_test_ooo_std_trigger_greed::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  //Set end greed off to ensure that remaining items are handled as errors
  this.syoscb_cfgs.syoscb_cfg[0].set_end_greediness(pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY);
  this.syoscb_cfgs.syoscb_cfg[0].set_max_print_orphans(-1);

endfunction: pre_build

//Disables comparisons, adds 19 items to the SCB, re-enables comparisons prepping it for us to add the final item
function void cl_scb_test_ooo_std_trigger_greed::add_19();
  //Disable comparison to allow us to have multiple matches in queues
  this.scb_env.syoscb[0].compare_control(1'b0);
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
  end

  //Add 9 items that also match
  for(int i=8; i>=0; i--) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = i;
    this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi);
  end

  if(this.scb_env.syoscb[0].get_total_queue_size() != 19) begin
    `uvm_fatal("TEST", $sformatf("Did not have 19 items total in queues, have %0d", this.scb_env.syoscb[0].get_total_queue_size()))
  end

  //Re-enable comparison, add the final item
  this.scb_env.syoscb[0].compare_control(1'b1);
endfunction: add_19

task cl_scb_test_ooo_std_trigger_greed::main_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.main_phase(phase);

  //Demote QUEUE_ERROR message to make the test pass
  this.scb_env.syoscb[0].set_report_severity_id_override(UVM_ERROR, "QUEUE_ERROR", UVM_INFO);

  //First: Check that trigger greed = GREEDY correctly drains all matches
  this.syoscb_cfgs.syoscb_cfg[0].set_trigger_greediness(pk_syoscb::SYOSCB_COMPARE_GREEDY);
  this.add_19();

  //Add final item
  begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = 9;
    this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi);
  end

  //Should have 0 items due to greed levels
  if(this.scb_env.syoscb[0].get_total_queue_size() != 0) begin
    `uvm_error("TEST", $sformatf("After GREEDY, SCB now has %0d items", this.scb_env.syoscb[0].get_total_queue_size()))
  end


  //Second, that that trigger greed = NOT GREEDY does not drain all matches
  this.syoscb_cfgs.syoscb_cfg[0].set_trigger_greediness(pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY);
  this.add_19();

  //Add final item
  begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = 9;
    this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi);
  end
  //Should have 18 items now
  if(this.scb_env.syoscb[0].get_total_queue_size() != 18) begin
    `uvm_warning("TEST", $sformatf("After NOT_GREEDY, SCB now has %0d items", this.scb_env.syoscb[0].get_total_queue_size()))
  end

  phase.drop_objection(this);
endtask: main_phase

function void cl_scb_test_ooo_std_trigger_greed::report_phase(uvm_phase phase);
  int queue_size, id_count;
  super.report_phase(phase);

  queue_size = this.scb_env.syoscb[0].get_total_queue_size();
  id_count   = uvm_report_server::get_server().get_id_count("QUEUE_ERROR");

  //Ensure that a total of 18 orphans still exists, and that a QUEUE_ERROR message was generated
  if(queue_size != 18) begin
    `uvm_error("TEST", $sformatf("There were not 18 orphans total as expected, have %0d", queue_size))
  end else if(id_count != 1) begin
    `uvm_error("TEST", $sformatf("Did not generate a QUEUE_ERROR message. count=%0d", id_count))
  end else begin
    `uvm_info("TEST", "All good", UVM_LOW)
  end
endfunction: report_phase