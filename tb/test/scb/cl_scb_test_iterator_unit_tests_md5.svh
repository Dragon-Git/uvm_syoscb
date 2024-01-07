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
/// Test that md5-iterators using cl_syoscb_cfg#ordered_next conform to spec.
class cl_scb_test_iterator_unit_tests_md5 extends cl_scb_test_iterator_unit_tests;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_iterator_unit_tests_md5)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_iterator_unit_tests_md5", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task          main_phase(uvm_phase phase);
  extern function void check_hash_collision_iteration();
  extern function void check_hash_collision_iteration_no_ordered_next();


endclass: cl_scb_test_iterator_unit_tests_md5

function void cl_scb_test_iterator_unit_tests_md5::pre_build();
  super.pre_build();
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b1);
endfunction: pre_build

//If two items have the same hash, and ordered_next=0, do we correctly iterate over the queue?
function void cl_scb_test_iterator_unit_tests_md5::check_hash_collision_iteration_no_ordered_next();
  //Test is very similar to test where ordered_next=1, but since we don't know which items show up first,
  //we must modify the test a little bit
  cl_tb_seq_item items[4];
  cl_syoscb_queue_iterator_base iter;

  //Disable cloning to we can modify items after insertion
  this.syoscb_cfgs.syoscb_cfg[0].set_disable_clone(1'b1);
  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b0);

  //We generate items with same contents to make sure they have same hash
  foreach(items[i]) begin
    items[i] = cl_tb_seq_item::type_id::create("item");
  end
  items[0].int_a = 0;
  items[1].int_a = 0;
  items[2].int_a = 2;
  items[3].int_a = 2;
  foreach(items[i]) begin
    this.scb_env.syoscb[0].add_item("Q1", "P1", items[i]);
  end


  //After inserting items, we modify items[1] and items[3] to simulate a hash collision.
  items[1].int_a=1;
  items[3].int_a=3;

  //Now, we use an iterator to check that we can find all of the values in there
  iter = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").create_iterator();
  void'(iter.first());
  //Check if first two items are consecutive
  begin
    cl_tb_seq_item found_item1, found_item2;
    found_item1 = this.get_next(iter);
    found_item2 = this.get_next(iter);
    if(found_item2.int_a != found_item1.int_a+1) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("ordered_next=0, first two items did not match. first.int_a=%0d, second.int_a=%0d", found_item1.int_a, found_item2.int_a))
    end
  end

  begin
    cl_tb_seq_item found_item1, found_item2;
    found_item1 = this.get_next(iter);
    found_item2 = this.get_next(iter);

    if(found_item2.int_a != found_item1.int_a+1) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("ordered_next=0, last two items did not match. first.int_a=%0d, second.int_a=%0d", found_item1.int_a, found_item2.int_a))
    end
  end

  //Reset iterator to first
  void'(iter.first());
  //Reset back to last
  void'(iter.last());
  //Traverse queue in reverse order.
  begin
    cl_tb_seq_item found_item1, found_item2;
    found_item1 = this.get_previous(iter);
    found_item2 = this.get_previous(iter);

    if(found_item1.int_a != found_item2.int_a+1) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("ordered_next=0, last two items did not match. first.int_a=%0d, second.int_a=%0d", found_item1.int_a, found_item2.int_a))
    end
  end
  begin
    cl_tb_seq_item found_item1, found_item2;
    found_item1 = this.get_previous(iter);
    found_item2 = this.get_previous(iter);

    if(found_item1.int_a != found_item2.int_a+1) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("ordered_next=0, last two items did not match. first.int_a=%0d, second.int_a=%0d", found_item1.int_a, found_item2.int_a))
    end
  end

  //Tests passed, flush queues
  void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").delete_iterator(iter));
  `uvm_info("ITER_HASH_NEXT", "Iterator traversal with hash collisions and ordered_next=0 passed tests", UVM_LOW)
  this.scb_env.syoscb[0].flush_queues_all();

  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b1);

endfunction: check_hash_collision_iteration_no_ordered_next

//If two items have the hash hash, and ordered next=1, do we correctly iterate over the queue?
function void cl_scb_test_iterator_unit_tests_md5::check_hash_collision_iteration();
  cl_tb_seq_item items[4];
  cl_syoscb_queue_iterator_base iter;

  this.syoscb_cfgs.syoscb_cfg[0].set_disable_clone(1'b1);

  //We generate items with same contents to make sure they have same hash
  foreach(items[i]) begin
    items[i] = cl_tb_seq_item::type_id::create("item");
  end
  items[0].int_a = 0;
  items[1].int_a = 0;
  items[2].int_a = 2;
  items[3].int_a = 2;
  foreach(items[i]) begin
    this.scb_env.syoscb[0].add_item("Q1", "P1", items[i]);
  end


  //After inserting items, we modify items[1] and items[3] to simulate a hash collision.
  items[1].int_a=1;
  items[3].int_a=3;

  //Now, we use an iterator to check that we can find all of the values in there
  iter = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").create_iterator();
  //Reset iterator to first, check if it maches
  void'(iter.first());

  //Traverse forward over all items
  while(iter.has_next()) begin
    cl_tb_seq_item found_item;

    found_item = this.get_next(iter);
    if(found_item.int_a != iter.previous_index()) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("Item at index %0d did not have expected int_a value, got %0d", iter.previous_index(), found_item.int_a))
    end
    void'(iter.next());
  end

  //Reset iterator to first
  void'(iter.first());
  //Reset back to last
  void'(iter.last());
  //Traverse queue in reverse order. First, we check item at last index for correctness
  begin
    cl_tb_seq_item found_item;

    found_item = this.get_previous(iter);
    if(found_item.int_a != 3) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("Item at index %0d did not have expected int_a value, got %0d", iter.next_index(), found_item.int_a))
    end
  end

  //Perform traversal in reverse order
  while(iter.has_previous()) begin
    cl_tb_seq_item found_item;

    found_item = this.get_previous(iter);
    if(found_item.int_a != iter.next_index()) begin
      `uvm_error("ITER_HASH_NEXT", $sformatf("Item at index %0d did not have expected int_a value, got %0d", iter.next_index(), found_item.int_a))
    end
  end

  //Tests passed, flush queues
  void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").delete_iterator(iter));
  `uvm_info("ITER_HASH_NEXT", "Iterator traversal with hash collisions and ordered_next=1 passed tests", UVM_LOW)
  this.scb_env.syoscb[0].flush_queues_all();

endfunction: check_hash_collision_iteration

task cl_scb_test_iterator_unit_tests_md5::main_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.main_phase(phase);

  this.check_hash_collision_iteration();
  this.check_hash_collision_iteration_no_ordered_next();

  //Verify that flushing and iterating works correctly when ordered_next = 0
  this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b0);
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
    item.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", item);
  end
  this.check_flush();
  this.scb_env.syoscb[0].flush_queues_all();

  phase.drop_objection(this);
endtask: main_phase