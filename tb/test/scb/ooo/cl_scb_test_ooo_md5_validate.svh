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
/// Test to ensure that config knob cl_syoscb_cfg::hash_compare_check correctly controls MD5
/// validation behavior. Validation will verify whether items with the same hash match, or whether
/// no match found really is a no-match
class cl_scb_test_ooo_md5_validate extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_ooo_md5_validate)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_ooo_md5_validate", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();
  extern task run_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

endclass: cl_scb_test_ooo_md5_validate

function void cl_scb_test_ooo_md5_validate::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_hash_compare_check(pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_ALL);
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  this.syoscb_cfgs.syoscb_cfg[0].set_trigger_greediness(pk_syoscb::SYOSCB_COMPARE_GREEDY); //Greedy compare to get all proper comparisons
endfunction: pre_build

task cl_scb_test_ooo_md5_validate::run_phase(uvm_phase phase);
  uvm_root uvm_top;
  phase.raise_objection(this);

  super.run_phase(phase);

  uvm_top = uvm_root::get();

  //Validate matches that are performed correctly
  fork
    for(int i=0; i<10; i++) begin
      cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
      item.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item);
    end

    for(int i=9; i>=0; i--) begin
      cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
      item.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item);
    end
  join

  //Should raise error if digest is the same but contents are not the same
  //We disable clone and insert matching items such that they get the same hash
  //After insertion, change the data in one of the items
  //The digest value should not change, but the contents should, promoting an error
  //We demote that error since it is wanted
  uvm_top.set_report_severity_id_override(UVM_ERROR, "MISCMP_HASH", UVM_INFO); //Demote the error that is triggered
  this.syoscb_cfgs.syoscb_cfg[0].set_disable_clone(1'b1);
  begin
    cl_tb_seq_item item1, item2;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item2 = cl_tb_seq_item::type_id::create("item2");

    item1.int_a = 42;
    item2.int_a = 42;

    scb_env.syoscb[0].add_item("Q1", "P1", item1);
    item1.int_a = 43;

    //Triggers comparison which should fail
    scb_env.syoscb[0].add_item("Q2", "P1", item2);
  end
  //Flush queues to avoid orphan errors
  this.scb_env.syoscb[0].flush_queues_all();

  //It should raise an error if a match is not found by digest, but contents are a match
  //First, add 20 randomized items to secondary queue. This is to ensure that we correctly search the entire queue
  fork
    for(int i=0; i<20; i++) begin
      cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
      if(!item.randomize()) begin
        `uvm_fatal("RAND", "Unable to randomize seq item")
      end
      scb_env.syoscb[0].add_item("Q2", "P1", item);
    end
  join

  //Now, add items with different hashes that actually match
  //Again, we do this by disabling clone and modifying an item after insertion
  begin
    cl_tb_seq_item item1, item2;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item2 = cl_tb_seq_item::type_id::create("item2");

    item1.int_a = 42;
    item2.int_a = 43;

    scb_env.syoscb[0].add_item("Q1", "P2", item1);
    item1.int_a = 43;

    scb_env.syoscb[0].add_item("Q2", "P2", item2);
  end

  //Flush queues to avoid orphans
  this.scb_env.syoscb[0].flush_queues_all();

  uvm_top.set_report_severity_id_override(UVM_ERROR, "MISCMP_HASH", UVM_ERROR); //Reset to error level, no longer accepted
  //Finally, insert two items which are entirely different, should not match
  begin
    cl_tb_seq_item item1, item2;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item2 = cl_tb_seq_item::type_id::create("item2");

    if(!item1.randomize()) begin
      `uvm_fatal("RAND", "Unable to randomize item1")
    end

    if(!item2.randomize()) begin
      `uvm_fatal("RAND", "Unable to randomize item1")
    end

    scb_env.syoscb[0].add_item("Q1", "P2", item1);
    scb_env.syoscb[0].add_item("Q2", "P2", item2);
  end

  //Flush queues to avoid orphans
  this.scb_env.syoscb[0].flush_queues_all();

  //Ensure that we received exactly two MISCMP_HASH reports
  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_ooo_md5_validate::report_phase(uvm_phase phase);
  uvm_report_server rs;
  int cnt;

  super.report_phase(phase);

  //Verify that we actually got the two MISCMP_HASH that we wanted
  rs = uvm_report_server::get_server();
  cnt = rs.get_id_count("MISCMP_HASH");
  if(rs.get_id_count("MISCMP_HASH") != 2) begin
    `uvm_error("TEST", $sformatf("Did not get exactly two MISCMP_HASH messages as expected, got %0d", cnt));
  end
endfunction: report_phase