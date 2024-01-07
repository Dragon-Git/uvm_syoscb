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
// Simple IOP compare test using the function based API

class cl_scb_test_iop_std_simple extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_iop_std_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_iop_std_simple", uvm_component parent = null);
  extern virtual function void pre_build();
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
  extern function void extract_phase(uvm_phase phase);

endclass : cl_scb_test_iop_std_simple

function cl_scb_test_iop_std_simple::new(string name = "cl_scb_test_iop_std_simple",
                                         uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_iop_std_simple::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IOP);
  this.syoscb_cfgs.syoscb_cfg[0].set_print_cfg(1'b1);
endfunction : pre_build

task cl_scb_test_iop_std_simple::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);
  //First comparisons: Ensure that comparisons are in-order by producer
  fork
    //Insert 20 items into Q1
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
      scb_env.syoscb[0].add_item("Q1", "P2", item1);
    end

    //Insert same 20 items into Q2 in opposite producer order
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P2", item1);
    end

    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  //At this point, those items should have matched no matter which queue is primary queue
  begin
    int cnt = this.scb_env.syoscb[0].get_total_queue_size();
    if(cnt != 0) begin
      `uvm_error("ERR", $sformatf("Did not have 0 items remaining after initial matches, had %0d", cnt))
    end
  end

  //Ensure that we really are comparing items in-order
  //Demote errors of type COMPARE_ERROR, as this should fail
  uvm_root::get().set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);
  //Add items with int_a=0, int_a=1 to Q1 (in that order)
  for(int i=0; i<2; i++) begin
    cl_tb_seq_item item1;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item1.int_a = i;
    scb_env.syoscb[0].add_item("Q1", "P1", item1);
  end


  //Add items with int_a=1, int_a=0 to Q2 (in that order)
  for(int i=1; i>=0; i--) begin
    cl_tb_seq_item item1;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item1.int_a = i;
    scb_env.syoscb[0].add_item("Q2", "P1", item1);
  end

  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_iop_std_simple::extract_phase(uvm_phase phase);
  int cnt;
  super.extract_phase(phase);

  //After inserting 40 items that match, the 4 items inserted at the end
  //should provoke 2 miscompares in run_phase (on both insertions into Q2),
  //as well as a third miscompare in extract_phase
  if(uvm_report_server::get_server().get_id_count("COMPARE_ERROR") != 3) begin
    `uvm_error("ERR", $sformatf("Did not provoke 3x compare error, iop comparisons are broken. Got %0d errors", cnt))
  end else begin
    //If the errors did show up, we can happily flush queues
    this.scb_env.syoscb[0].flush_queues_all();
  end

endfunction: extract_phase