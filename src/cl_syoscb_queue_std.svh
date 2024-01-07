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
/// Standard implementation of a queue. Uses a normal SystemVerilog queue as
/// implementation. The class implements the queue API as defined by the queue
/// base class.
class cl_syoscb_queue_std extends cl_syoscb_queue_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Simple queue implementation with a SV queue
  local cl_syoscb_item items[$];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_queue_std)
    `uvm_field_queue_object(items, UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Queue API
  //-------------------------------------
  // Basic queue functions
  extern           virtual function bit            add_item(string producer, uvm_sequence_item item);
  extern           virtual function bit            delete_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function cl_syoscb_item get_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function int unsigned   get_size();
  extern           virtual function bit            empty();
  extern           virtual function bit            insert_item(string producer, uvm_sequence_item item, int unsigned idx);

  // Iterator support functions
  extern virtual function cl_syoscb_queue_iterator_base create_iterator(string name = "");
  extern virtual function bit                           delete_iterator(cl_syoscb_queue_iterator_base iterator);

  // Locator support function
  extern virtual function cl_syoscb_queue_locator_base get_locator();

  //-------------------------------------
  // Internal support functions
  //-------------------------------------
  extern protected virtual function void do_flush_queue();
  extern virtual function void           get_native_queue(ref cl_syoscb_item q[$]);
endclass: cl_syoscb_queue_std

/// <b>Queue API:</b> See cl_syoscb_queue_base#add_item for more details
function bit cl_syoscb_queue_std::add_item(string producer, uvm_sequence_item item);
  cl_syoscb_item new_item;

  //Generate scoreboard item, assign metadata
  new_item = this.pre_add_item(producer, item);

  // Insert the item in the queue
  this.items.push_back(new_item);

  //Perform bookkeeping on counters and shadow queue
  this.post_add_item(new_item);

  // Signal that it worked
  return 1;
endfunction: add_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#delete_item for more details
function bit cl_syoscb_queue_std::delete_item(cl_syoscb_proxy_item_base proxy_item);
  cl_syoscb_proxy_item_std proxy_item_std;
  int unsigned             idx;

  if(!$cast(proxy_item_std,proxy_item)) begin
    `uvm_fatal("Incorrect item type", $sformatf("[%s]:Proxy_item ", this.cfg.get_scb_name()));
    return 0;
  end else if(proxy_item == null) begin
    `uvm_info("NULL", $sformatf("[%s] Passed null item to queue %s for deletion. Ignoring it", this.cfg.get_scb_name(), this.get_name()), UVM_DEBUG)
    return 1'b0;
  end

  idx = proxy_item_std.idx;

  if(idx < this.items.size()) begin
    string producer;
    cl_syoscb_queue_iterator_base iter[$];

    // Wait to get exclusive access to the queue
    // if there are multiple iterators
    while(!this.iter_sem.try_get());
    producer = this.items[idx].get_producer();
    this.items.delete(idx);

    // Update iterators
    iter = this.iterators.find(x) with (x.next_index() > idx);
    foreach(iter[i]) begin
      void'(iter[i].previous());
    end

    this.decr_cnt_producer(producer);

    this.iter_sem.put();
    return 1;
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("[%s]: Idx: %0d is not present in queue: %0s", this.cfg.get_scb_name(), idx, this.get_name()), UVM_DEBUG);
    return 0;
  end
endfunction: delete_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#get_item for more details
function cl_syoscb_item cl_syoscb_queue_std::get_item(cl_syoscb_proxy_item_base proxy_item);
  cl_syoscb_proxy_item_std proxy_item_std;
  int unsigned             idx;

  if(!$cast(proxy_item_std, proxy_item)) begin
    `uvm_fatal("Incorrect item type", $sformatf("[%s]:Proxy_item was of type %0s", this.cfg.get_scb_name(), proxy_item.get_type_name()));
    return null;
  end
  idx = proxy_item_std.idx;


  if(idx < this.items.size()) begin
    return items[idx];
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("[%s]: Idx: %0d is not present in queue: %0s", this.cfg.get_scb_name(), idx, this.get_name()), UVM_DEBUG);
    return null;
  end
endfunction: get_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#get_size for more details
function int unsigned cl_syoscb_queue_std::get_size();
  return this.items.size();
endfunction: get_size

/// <b>Queue API:</b> See cl_syoscb_queue_base#empty for more details
function bit cl_syoscb_queue_std::empty();
  return this.get_size()==0;
endfunction

/// <b>Queue API:</b> See cl_syoscb_queue_base#insert_item for more details
function bit cl_syoscb_queue_std::insert_item(string producer, uvm_sequence_item item, int unsigned idx);
  cl_syoscb_item new_item;

  new_item = this.pre_add_item(producer, item);

  if(idx < this.items.size()) begin
    cl_syoscb_queue_iterator_base iters[$];

    // Wait to get exclusive access to the queue
    // if there are multiple iterators
    while(!this.iter_sem.try_get());
    this.items.insert(idx, new_item);

    // Update iterators
    iters = this.iterators.find(x) with (x.next_index() >= idx);
    for(int i = 0; i < iters.size(); i++) begin
      // Call .next() blindly. This can never fail by design, since
      // if it was pointing at the last element then it points to the second last
      // element prior to the .next(). The .next() call will then just
      // set the iterator to the correct index again after the insertion
      void'(iters[i].next());
    end
    this.iter_sem.put();
  end else if(idx == this.items.size()) begin
    this.items.push_back(new_item);
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("[%s]: Idx: %0d too large for queue %0s", this.cfg.get_scb_name(), idx, this.get_name()), UVM_DEBUG);
    return 1'b0;
  end

  this.post_add_item(new_item);
  return 1'b1;
endfunction: insert_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#create_iterator for more details
function cl_syoscb_queue_iterator_base cl_syoscb_queue_std::create_iterator(string name = "");
  cl_syoscb_queue_iterator_std result;
  string iter_name;
  cl_syoscb_queue_iterator_base f[$];

  // Wait to get exclusive access to the queue
  // if there are multiple iterators
  while(this.iter_sem.try_get() == 0);

  if(name == "") begin
    iter_name = $sformatf("%0s_iter%0d", this.get_name(), this.num_iters_created);
  end else begin
    iter_name = name;
  end

  //Check if an iterator with that name already exists
  f = this.iterators.find_index() with (item.get_name() == name);
  if(f.size() != 0) begin
    `uvm_info("ITERATOR", $sformatf("[%0s] An iterator with the name %0s already exists", this.cfg.get_scb_name(), name), UVM_DEBUG)
    this.iter_sem.put();
    return null;
  end
  result = cl_syoscb_queue_iterator_std::type_id::create(iter_name);

  // No need to check return value since set_queue will issue
  // an `uvm_error of something goes wrong
  void'(result.set_queue(this));

  this.iterators[result] = result;
  this.num_iters_created++;
  this.iter_sem.put();

  return result;
endfunction: create_iterator

/// <b>Queue API:</b> See cl_syoscb_queue_base#delete_iterator for more details
function bit cl_syoscb_queue_std::delete_iterator(cl_syoscb_queue_iterator_base iterator);
  if(iterator == null) begin
    `uvm_info("NULL", $sformatf("[%s]: Asked to delete null iterator from list of iterators in %s",
                                this.cfg.get_scb_name(), this.get_name()), UVM_DEBUG);
    return 0;
  end else begin
    // Wait to get exclusive access to the queue
    // if there are multiple iterators
    while(!this.iter_sem.try_get());

    this.iterators.delete(iterator);
    this.iter_sem.put();
    return 1;
  end
endfunction: delete_iterator

/// <b>Queue API:</b> See cl_syoscb_queue_base#get_locator for more details
function cl_syoscb_queue_locator_base cl_syoscb_queue_std::get_locator();
  cl_syoscb_queue_locator_std locator;

  locator = cl_syoscb_queue_locator_std::type_id::create($sformatf("%s_loc", this.get_name()));
  void'(locator.set_queue(this));
  return locator;
endfunction: get_locator

/// See cl_syoscb_queue_base#do_flush_queue for more details
function void cl_syoscb_queue_std::do_flush_queue();
  this.items = {};
endfunction: do_flush_queue

// Returns a handle to this queue's underlying SV queue to allow locators to search through it.
// The returned queue should not be modified by the caller.
// DO NOT CALL FROM USER CODE
// \param q Handle to a queue where the results will be returned
function void cl_syoscb_queue_std::get_native_queue(ref cl_syoscb_item q[$]);
  q = this.items;
endfunction: get_native_queue