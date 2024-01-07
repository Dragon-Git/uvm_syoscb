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
/// Test containing a series of unit tests to ensure that all iterators conform to spec.
class cl_scb_test_iterator_unit_tests extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_iterator_unit_tests)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_iterator_unit_tests", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------

  extern task                    main_phase(uvm_phase phase);
  extern function cl_tb_seq_item get_next(cl_syoscb_queue_iterator_base iter);
  extern function cl_tb_seq_item get_previous(cl_syoscb_queue_iterator_base iter);

  extern task                    check_next();
  extern task                    check_prev();
  extern task                    check_first();
  extern task                    check_last();
  extern task                    check_set_queue();
  extern task                    check_names();
  extern task                    check_flush();

endclass: cl_scb_test_iterator_unit_tests

//Gets the cl_tb_seq_item that the given iterator is currently pointing to
function cl_tb_seq_item cl_scb_test_iterator_unit_tests::get_next(cl_syoscb_queue_iterator_base iter);
  cl_tb_seq_item ctsi;
  $cast(ctsi, iter.next().get_item().get_item()); //proxy -> syoscb item -> seq item -> cast to ctsi
  return ctsi;
endfunction: get_next

function cl_tb_seq_item cl_scb_test_iterator_unit_tests::get_previous(cl_syoscb_queue_iterator_base iter);
  cl_tb_seq_item ctsi;
  $cast(ctsi, iter.previous().get_item().get_item()); //proxy -> syoscb item -> seq item -> cast to ctsi
  return ctsi;
endfunction: get_previous

/// Checks whether the cl_syoscb_queue_iterator_base#next method correctly moves through the queue
/// When called, the idx should increment and it should return 1'b1. It should then also point to the next item in the queue.
/// When called while already pointing to the last element of the queue, it should generate an out-of-bounds message and return 1'b0
task cl_scb_test_iterator_unit_tests::check_next();
  cl_tb_seq_item ctsi;

  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  cl_syoscb_queue_iterator_base iter = q.create_iterator();

  //Check that we can iterate over items in the queue
  for(int i=0; i<10; i++) begin
    ctsi = this.get_next(iter);
    if(ctsi.int_a != i || iter.previous_index() != i) begin
      `uvm_error("ITER_NEXT", $sformatf("iterator.next() did not correctly advance the iterator. i=%0d, int_a=%0d, prev_idx=%0x", i, ctsi.int_a, iter.previous_index()))
    end
  end

  if(iter.next_index() != q.get_size()) begin
    `uvm_error("ITER_NEXT", "iterator.next() did not advance to the end of the queue")
  end

  //Check that calling has_next() when iter.next_idx() == queue.size returns 1'b0
  if(iter.has_next()) begin
    `uvm_error("ITER_NEXT", "iterator.has_next() returned 1'b1 while at the end of the queue")
  end

  //Check that calling has_next() on an empty queue returns 1'b0
  begin
    cl_syoscb_queue_iterator_base iter2 = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").create_iterator();
    if(iter2.has_next()) begin
      `uvm_error("ITER_NEXT", "iterator.has_next() returned 1'b1 on an empty queue")
    end
    void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").delete_iterator(iter2));
  end

  void'(q.delete_iterator(iter));
  `uvm_info("ITER_NEXT", "iterator.next() and iterator.has_next() passed tests", UVM_LOW)

endtask: check_next

/// Checks whether the cl_syoscb_queue_iterator_base#previous method correctly moves through the queue.
/// When called, the idx should decrement and it should return 1'b1. It should then also point to the previous item in the queue.
/// When called while already pointing to the first element of the queue, it should generate an out-of-bounds message and return 1'b0.
/// When called on an empty queue, it should return 1'b0.
task cl_scb_test_iterator_unit_tests::check_prev();
  cl_tb_seq_item ctsi;

  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  cl_syoscb_queue_iterator_base iter = q.create_iterator();

  //We now know that next() works. Start by iterating forward to final item
  while(iter.has_next()) begin
    void'(iter.next());
  end

  //Iterate backwards
  for(int i=9; i>0; i--) begin
    ctsi = this.get_previous(iter);
    if(ctsi.int_a != i || iter.next_index() != i) begin
      `uvm_error("ITER_PREV", "iterator.previous() did not correctly move iterator back")
    end
  end

  //Check that we have arrived at first element of queue
  ctsi = this.get_previous(iter);
  if(ctsi.int_a != 0 || iter.previous_index() != -1) begin
    `uvm_error("ITER_PREV", "iterator.previous() did not move to index 0")
  end

  //Check that calling has_previous() returns 1'b0
  if(iter.has_previous()) begin
    `uvm_error("ITER_PREV", "iterator.has_previous() returned 1'b1 while at the start of the queue")
  end

  //Check that calling has_previous() on an empty queue returns 1'b0
  begin
    cl_syoscb_queue_iterator_base iter2 = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").create_iterator();
    if(iter2.has_previous()) begin
      `uvm_error("ITER_PREV", "iterator.has_previous() returned 1'b1 on an empty queue")
    end
    void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").delete_iterator(iter2));
  end

  void'(q.delete_iterator(iter));
  `uvm_info("ITER_PREV", "iterator.previous() and iterator.has_previous() passed tests", UVM_LOW)
endtask: check_prev

/// Checks whether the cl_syoscb_queue_iterator_base#first method correctly moves through the queue.
/// When called, the idx should become 0 and it should return 1'b1. It should then also point to the first item in the queue.
/// When called while already pointing to the first element of the queue, behavior should be the same.
/// When called on an empty queue, should return 1'b0.
task cl_scb_test_iterator_unit_tests::check_first();
  cl_tb_seq_item ctsi;

  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  cl_syoscb_queue_iterator_base iter = q.create_iterator();

  //We now know that next() works. Start by iterating 6 times forwards
  for(int i=0; i<6; i++) begin
    void'(iter.next());
  end

  //Check twice that calling first works
  //Initial call resets the iterator, next call should not modify state of iterator
  for(int i=0; i<2; i++) begin
    //Go back to first
    if(!iter.first()) begin
      `uvm_error("ITER_FIRST", "iterator.first() did not return 1'b1 while moving to first element")
    end

    //Check that we are at the start
    if(iter.previous_index() != -1) begin
      `uvm_error("ITER_FIRST", "iterator.first() did not set idx to 0")
    end

    ctsi = this.get_next(iter);
    if(ctsi.int_a != 0) begin
      `uvm_error("ITER_FIRST", "iterator.first() did not move to first element in queue")
    end
  end

  //Check that calling first on an empty queue fails
  begin
    cl_syoscb_queue_iterator_base iter2 = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").create_iterator();
    if(iter2.first()) begin
      `uvm_error("ITER_FIRST", "iterator.first() did not return 1'b0 when called on an empty queue")
    end
    void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").delete_iterator(iter2));
  end

  void'(q.delete_iterator(iter));
  `uvm_info("ITER_FIRST", "iterator.first() passed tests", UVM_LOW)
endtask: check_first

/// Checks whether the cl_syoscb_queue_iterator_base#last method correctly moves through the queue.
/// When called, the idx should become queue.size()-1 and it should return 1'b1. It should then also point to the final item in the queue.
/// When called while already pointing to the final element of the queue, behavior should be the same.
/// When called on an empty queue, should return 1'b0.
task cl_scb_test_iterator_unit_tests::check_last();
  cl_tb_seq_item ctsi;
  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  cl_syoscb_queue_iterator_base iter = q.create_iterator();

  //Calling last on a queue with items should move to final element
  //Initial call moves iterator to final element, next call should not modify state of iterator
  for(int i=0; i<2; i++) begin
    if(!iter.last()) begin
      `uvm_error("ITER_LAST", "iterator.last() did not return 1'b1 when moving to last element")
    end
    ctsi = this.get_previous(iter);
    if(ctsi.int_a != q.get_size()-1 || iter.next_index() != q.get_size()-1) begin
      $display("int_a=%0d, next_index=%0d, get_size=%0d", ctsi.int_a, iter.next_index(), q.get_size());
      `uvm_error("ITER_LAST", "iterator.last() did not move to the last element of the queue")
    end
  end

  //Check that calling last on an empty queue fails
  begin
    cl_syoscb_queue_iterator_base iter2 = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").create_iterator();
    if(iter2.last()) begin
      `uvm_error("ITER_LAST", "iterator.last() did not return 1'b0 when called on an empty queue")
    end
    void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").delete_iterator(iter2));
  end

  void'(q.delete_iterator(iter));
  `uvm_info("ITER_LAST", "iterator.last() passed tests", UVM_LOW)
endtask: check_last

/// Checks whether the cl_syoscb_queue_iterator_base#set_queue method correctly sets the queue associated with an iterator.
/// When called with null as argument, should return 1'b0.
/// When called and the iterator already has an owner associated, should raise a UVM_ERROR
/// When called and the new owner is not of the right queue type, should raise a UVM_ERROR
/// When called and the iterator does not have an owner associated, should return 1'b1 and set the queue as owner.
task cl_scb_test_iterator_unit_tests::check_set_queue();
  cl_tb_seq_item ctsi;
  cl_syoscb_queue_iterator_std iter2_std;
  cl_syoscb_queue_iterator_hash#(pk_syoscb::MD5_HASH_DIGEST_WIDTH) iter2_hash;

  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  cl_syoscb_queue_base q2 = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2");
  cl_syoscb_queue_iterator_base iter = q.create_iterator();

  //Demote ITER_ERROR for the duration of this test
  uvm_root::get().set_report_severity_id_override(UVM_ERROR, "ITER_ERROR", UVM_INFO);

  //Check that we cannot reassign the queue that an iterator is assigned to
  if(iter.set_queue(q2)) begin
    `uvm_error("ITER_SET_QUEUE", "iter.set_queue() allowed us to reassign the owner of an iterator")
  end

  iter2_std = new;
  iter2_hash = new;
  //Check that we cannot assign the owner of an iterator to null
  if(iter2_std.set_queue(null)) begin
    `uvm_error("ITER_SET_QUEUE", "iter.set_queue() allowed us to set owner of a std queue to null")
  end
  if(iter2_hash.set_queue(null)) begin
    `uvm_error("ITER_SET_QUEUE", "iter.set_queue() allowed us to set owner of a hash queue to null")
  end

  //Check that we can assign queue to an iterator, but only if the iterator type matches the queue type
  if(this.syoscb_cfgs.syoscb_cfg[0].get_queue_type() == SYOSCB_QUEUE_STD) begin
    //Attempt to set a queue of the wrong type as the owner
    if(iter2_hash.set_queue(q2)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() allowed us to assign a hash iterator to a standard queue")
    end
    //Check that we can assign a queue to an iterator that doesn't have an owner
    if(!iter2_std.set_queue(q2)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() did not allow us to set owner of an un-owned iterator")
    end
    //Check that it was set by trying to reassign the owner
    if(iter2_std.set_queue(q)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() did not correctly set owner of an un-owned iterator")
    end
  end else begin //queue type is HASH_MD5
    //Attempt to set a queue of the wrong type as the owner
    if(iter2_std.set_queue(q2)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() allowed us to assign a std iterator to a hash queue");
    end
    //Check that we can assign a queue to an iterator that doesn't have an owner
    if(!iter2_hash.set_queue(q2)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() did not allow us to set owner of an un-owned iterator")
    end
    //Check that it was set by trying to reassign the owner
    if(iter2_hash.set_queue(q)) begin
      `uvm_error("ITER_SET_QUEUE", "iter.set_queue() did not correctly set owner of an un-owned iterator")
    end
  end

  void'(q.delete_iterator(iter));
  uvm_root::get().set_report_severity_id_override(UVM_INFO, "ITER_ERROR", UVM_ERROR);
  `uvm_info("ITER_SET_QUEUE", "iterator.set_queue() passed tests", UVM_LOW)

endtask: check_set_queue

/// Checks whether cl_syoscb_queue_base::get_iterator and cl_syoscb_queue_base::create_iterator correctly
/// create and retrieve named iterators.
/// It should not be possible to create two iterators with the same name, and it should not be possible
/// to retrieve an iterator if the name does not match any iterators.
task cl_scb_test_iterator_unit_tests::check_names();
  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2");
  cl_syoscb_queue_iterator_base iter = q.create_iterator("custom_name");

  //Check that we cannot create an iterator with the same name as an existing iterator
  if(q.create_iterator("custom_name") != null) begin
    `uvm_error("ITER_NAMES", "queue.create_iterator() allowed us to create two iterators with the same name")
  end

  //Check that new iterators get assigned progressively larger indices
  begin
    cl_syoscb_queue_iterator_base iter2, iter3, iter4;
    int iter2_idx, iter4_idx;
    string iter2_name, iter4_name;
    iter2 = q.create_iterator();
    iter3 = q.create_iterator("iter3");
    iter4 = q.create_iterator();

    iter2_name = iter2.get_name();
    iter4_name = iter4.get_name();
    //Must find the last 'r' to extract number
    for(int i=iter2_name.len(); i>=0; i--) begin
      if(iter2_name[i] == "r") begin
        string sub = iter2_name.substr(i+1, iter2_name.len()-1);
        iter2_idx = sub.atoi();
      end
    end
    for(int i=iter4_name.len(); i>=0; i--) begin
      if(iter4_name[i] == "r") begin
        string sub = iter4_name.substr(i+1, iter4_name.len()-1);
        iter4_idx = sub.atoi();
      end
    end
    if(iter4_idx != iter2_idx+2) begin
      `uvm_error("ITER_NAMES", $sformatf({"queue.create_iterator() did not use progessively larger indices for iterators\n",
      "iterators were named %0s and %0s, indices were %0d and %0d"}, iter2_name, iter4_name, iter2_idx, iter4_idx))
    end

    void'(q.delete_iterator(iter2));
    void'(q.delete_iterator(iter3));
    void'(q.delete_iterator(iter4));
  end

  //Check that attempting to get an iterator with undefined name returns null
  if(q.get_iterator("not_set") != null) begin
    `uvm_error("ITER_NAMES", "queue.get_iterator() returned an iterator for a name that was not set")
  end

  //Check that getting an iterator with the same name returns the same handle
  if(q.get_iterator("custom_name") != iter) begin
    `uvm_error("ITER_NAMES", "queue.get_iterator() did not return the same handle for the same name")
  end

  //Check that deleting an iterator and then creating a new one with the same name is OK
  void'(q.delete_iterator(iter));
  //First, verify that it really is deleted
  if(q.get_iterator("custom_name") != null) begin
    `uvm_error("ITER_NAMES", "queue.get_iterator() returned an iterator after deleting it")
  end else if(q.create_iterator("custom_name") == null) begin
    `uvm_error("ITER_NAMES", "queue.create_iterator() was not able to create an iterator after the last iterator with same name was deleted")
  end

  `uvm_info("ITER_NAMES", "queue.get_iterator() and queue.create_iterator() name functionality passed tests", UVM_LOW)
endtask: check_names

/// When a queue is flushed, all associated iterators should be reset such that has_next/has_previous both return 0
task cl_scb_test_iterator_unit_tests::check_flush();
  cl_syoscb_queue_base q;
  cl_syoscb_queue_iterator_base iter;
  cl_syoscb_proxy_item_base pib;
  cl_tb_seq_item first;

  q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  iter = q.create_iterator();

  //Move the iterator into the middle of the queue
  void'(iter.first());
  first = this.get_next(iter); //Storing a copy of the first item so we can check hash queues with ordered_next=0 behavior
  void'(iter.next());
  void'(iter.next());

  //And now, flush the SCB
  this.scb_env.syoscb[0].flush_queues_all();

  //Attempts to move forward/backward should raise an error
  if(iter.has_next()) begin
    `uvm_error("ITER_FLUSH", "iter.has_next() returns 1 after flushing queue.");
  end
  if(iter.has_previous()) begin
    `uvm_error("ITER_FLUSH", "iter.has_previous() returns 1 after flushing queue.");
  end
  if(iter.first()) begin
    `uvm_error("ITER_FLUSH", "iter.first() returns 1 after flushing queue.");
  end
  if(iter.last()) begin
    `uvm_error("ITER_FLUSH", "iter.last() returns 1 after flushing queue.");
  end
  if(iter.next_index() != 0) begin
    `uvm_error("ITER_FLUSH", $sformatf("iter.next_index() did not return 0 after flushing queue, returned %0d", iter.next_index()))
  end
  if(iter.previous_index() != -1) begin
    `uvm_error("ITER_FLUSH", $sformatf("iter.previous_index() did not return -1 after flushing queue, returned %0d", iter.next_index()))
  end

  //Re-add items to Q1 to make other tests pass
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
    item.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", item);
  end

  //Should now be able to move forward again
  if(!iter.has_next()) begin
    `uvm_error("ITER_FLUSH", "iter.has_next() returns 0 after reinserting items.");
  end else begin
    cl_tb_seq_item ctsi = this.get_next(iter);
    //By comparing first to ctsi, we also validate correctness for hash queues
    if(ctsi.int_a != first.int_a) begin
      `uvm_error("ITER_FLUSH", $sformatf("iter.next() did not return item with int_a=%0d after reinserting, got int_a=%0d", first.int_a, ctsi.int_a))
    end
  end

  void'(q.delete_iterator(iter));
  `uvm_info("ITER_FLUSH", "Queue behavior after flushing queues passed tests", UVM_LOW)

endtask: check_flush

task cl_scb_test_iterator_unit_tests::main_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.main_phase(phase);

  //Add items to Q1 that we can iterate through
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
    item.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", item);
  end

  this.check_flush();
  this.check_next();
  this.check_prev();
  this.check_first();
  this.check_last();
  this.check_set_queue();
  this.check_names();
  `uvm_info("ITER_TESTS", "ALL TESTS PASSED", UVM_LOW)

  //Add items to Q2 to match and avoid errors
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
    item.int_a = i;
    this.scb_env.syoscb[0].add_item("Q2", "P1", item);
  end

  phase.drop_objection(this);
endtask: main_phase