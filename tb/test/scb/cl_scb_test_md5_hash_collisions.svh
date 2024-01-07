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
/// Test to verify that comparisons still work correctly on hash items with multiple entries
/// where hash collisions may have occured
class cl_scb_test_md5_hash_collisions extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_md5_hash_collisions)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_md5_hash_collisions", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task          main_phase(uvm_phase phase);
  extern function void hash_collision_test();


endclass: cl_scb_test_md5_hash_collisions

function void cl_scb_test_md5_hash_collisions::pre_build();
  super.pre_build();

  //We must test md5-comparisons and
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  this.syoscb_cfgs.syoscb_cfg[0].set_disable_clone(1'b1);
endfunction: pre_build

function void cl_scb_test_md5_hash_collisions::hash_collision_test();
  cl_tb_seq_item                items[3];
  cl_tb_seq_item                remaining_item;
  cl_syoscb_queue_iterator_base iter;
  cl_syoscb_queue_base          q;

  //We generate 3 items of same contents to make sure they have same hash
  foreach(items[i]) begin
    items[i] = cl_tb_seq_item::type_id::create("item");
    items[i].int_a = 5;
  end

  this.scb_env.syoscb[0].add_item("Q1", "P1", items[0]);
  this.scb_env.syoscb[0].add_item("Q1", "P1", items[1]);

  //After inserting those items, we modify items[0] to simulate a hash collision. items[0] should not match
  //with items[2], but items[1] should. The only orphan should thus be the item with int_a = 6
  items[0].int_a=6;
  this.scb_env.syoscb[0].add_item("Q2", "P1", items[2]);

  q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  iter = q.create_iterator();
  void'(iter.first());
  //Get item proxy, cast down wrapped item
  if(!$cast(remaining_item, iter.next().get_item().get_item())) begin
    `uvm_fatal("CAST", "Unable to typecast seq item back to cl_tb_seq_item");
  end
  if(remaining_item.int_a != 6) begin
    `uvm_error("MD5_HASH_COLL", $sformatf("int_a of remaining item was %0d, expected 6", remaining_item.int_a))
  end else begin
    this.scb_env.syoscb[0].flush_queues_all();
    void'(q.delete_iterator(iter));
  end
endfunction: hash_collision_test

task cl_scb_test_md5_hash_collisions::main_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.main_phase(phase);

  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b0);
  this.hash_collision_test();
  `uvm_info("MD5_HASH_COLL", "Hash collision comparisons passed for ordered_next=0", UVM_NONE)
  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b1);
  this.hash_collision_test();
  `uvm_info("MD5_HASH_COLL", "Hash collision comparisons passed for ordered_next=1", UVM_NONE)

  phase.drop_objection(this);
endtask: main_phase