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
/// Class which represents the base concept of a hash queue.
/// All hash queues must extend this class and implement the queue API.
class cl_syoscb_queue_hash #(int unsigned HASH_DIGEST_WIDTH = 1) extends cl_syoscb_queue_base;

  ///Typedef for hash algorithm digests
  typedef cl_syoscb_hash_base#(HASH_DIGEST_WIDTH)::tp_hash_digest tp_digest;

  /// Typedef for struct used to track items and their digests in the key queue.
  /// Only used when cl_syoscb_cfg.ordered_next=1
  typedef struct {
    cl_syoscb_item item;
    tp_digest digest;
  } tp_item_digest;

  /// Typedef for queue of digests and items
  typedef tp_item_digest                                tp_queue_of_keys[$];

  /// Typedef for parameterized AA wrapper
  typedef cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) tp_aa_hash;

  /// Typedef for struct representing whether an option with an iterator was valid
  typedef struct packed{
    bit       valid;
    tp_digest digest;
  } tp_return_digest;


  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the implemented hash algorithm
  protected cl_syoscb_hash_base#(HASH_DIGEST_WIDTH) hash_algo;

  /// Queue implementation with an assosiative array. Wrapped in a class for performance reasons
  protected cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  /// List of hash values of the items in the queue.
  /// Only used if cl_syoscb_cfg#ordered_next is 1.
  protected tp_item_digest key_queue[$];

  /// Size of queue, stored here to optimize for speed
  protected int unsigned size;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_param_utils_begin(cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH))
    `uvm_field_object(hash, UVM_DEFAULT)
    `uvm_field_object(hash_algo,UVM_DEFAULT)
    `uvm_field_int(size, UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);

  //-------------------------------------
  // Queue API
  //-------------------------------------
  // Basic queue functions
  extern           virtual function bit            add_item(string producer, uvm_sequence_item item);
  extern           virtual function bit            delete_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function cl_syoscb_item get_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function int unsigned   get_size();
  extern           virtual function bit            empty();
  extern           virtual function bit            insert_item(string producer,
                                                               uvm_sequence_item item,
                                                               int unsigned idx);

  // Iterator support functions
  extern virtual function bit delete_iterator(cl_syoscb_queue_iterator_base iterator);

  // Hash queue functions
  extern virtual function tp_queue_of_keys get_key_queue();
  extern virtual function tp_aa_hash       get_hash();

  // Misc support functions
  extern protected virtual function void do_flush_queue();
  // The UVM function do_copy() *MUST* be implemented inside every derived class, since this one
  // is only implementing the API for a generic hash queue and it cannot be directlty instantiated.
endclass: cl_syoscb_queue_hash

function cl_syoscb_queue_hash::new(string name, uvm_component parent);
  super.new(name, parent);
  this.hash = new;
endfunction: new

/// <b>Queue API:</b> See cl_syoscb_queue_base#add_item for more details
function bit cl_syoscb_queue_hash::add_item(string producer, uvm_sequence_item item);
  cl_syoscb_item      new_item;
  tp_digest           digest;

  new_item = this.pre_add_item(producer, item);

  // Insert the item in the queue
  // Generate hash, check for collision. If collision, add to queue on that hash item
  // otherwise, generate new hash itme with only this element
  digest=this.hash_algo.hash(new_item);
  this.hash.insert(digest, new_item);

  if(this.cfg.get_ordered_next() == 1) begin
    this.key_queue.push_back('{new_item, digest});
  end

  this.post_add_item(new_item);
  this.size++;

  // Signal that it worked
  return 1'b1;
endfunction: add_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#insert_item for more details
function bit cl_syoscb_queue_hash::insert_item(string producer, uvm_sequence_item item, int unsigned idx);
  cl_syoscb_item new_item;
  tp_digest digest;

  if(!this.cfg.get_ordered_next()) begin
    `uvm_fatal("CFG_ERROR", "Cannot use insert_item() on hash queues when cfg.ordered_next is disabled")
    return 1'b0;
  end else if(idx > this.get_size()) begin //Check immediatedly if index is too large
    `uvm_info("OUT_OF_BOUNDS", $sformatf("[%s] Idx %0d too large for insertion into queue %0s", this.cfg.get_scb_name(), idx, this.get_name()), UVM_DEBUG)
    return 1'b0;
  end

  new_item = this.pre_add_item(producer, item);
  digest = this.hash_algo.hash(new_item);

  //Update order of key queue
  if(idx < this.get_size()) begin
    cl_syoscb_queue_iterator_base iters[$];

    //Get exclusive acces to all iterators
    while(!this.iter_sem.try_get());
    this.hash.insert(digest, new_item);

    //Insert into key queue and update iterators
    this.key_queue.insert(idx, '{new_item, digest});
    iters = this.iterators.find(x) with (x.next_index() > idx);
    for(int i=0; i<iters.size(); i++) begin
      //We can blindly call iter.next
      //See cl_syoscb_queue_std::insert_item for more description as to why
      void'(iters[i].next());
    end
    this.iter_sem.put();

  end else begin //We already checked if idx > this.size, so here idx must == this.size
    this.hash.insert(digest, new_item);
    this.key_queue.push_back('{new_item, digest});
  end

  this.post_add_item(new_item);
  this.size++;
  return 1'b1;
endfunction: insert_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#delete_item for more details
function bit cl_syoscb_queue_hash::delete_item(cl_syoscb_proxy_item_base proxy_item);
  tp_digest                                     digest;
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) proxy_item_hash;
  int unsigned                                  item_position_idx = 0;
  cl_syoscb_queue_iterator_base                 iter[$];
  string                                        producer;

  if(!$cast(proxy_item_hash,proxy_item))begin
    `uvm_fatal("Incorrect item type", $sformatf("[%s]:Proxy_item ", this.cfg.get_scb_name()));
    return 0;
  end

  digest = proxy_item_hash.digest;

  // Check if the aa contains the current digest value
  if(!this.hash.exists(digest)) begin
    return 0;
  end

  // Wait to get exclusive access to the queue
  // if there are multiple iterators
  while(!this.iter_sem.try_get());

  // Get the item producer name. The name needs to be cached before the item is being deleted.
  // This value is used after the item deletion for decreasing the item producer count.
  begin
    cl_syoscb_item tmp_item = this.hash.get_item(digest, proxy_item_hash.idx);
    producer = tmp_item.get_producer();
  end

  // Update all iterators on this queue
  // Before deleting the item, we need the iterator position of the current item to correctly perform
  // iter.previous() on all iterators that are pointing to or past the current item
  if(this.cfg.get_ordered_next() == 1) begin
    int q_idx[$];

    q_idx = this.key_queue.find_index with (item.digest==digest);

    //If AA[digest].size == 1, we can simply delete the matching item from our key queue
    if(this.hash.get_size(digest) <= 1) begin
      if(q_idx.size() == 0) begin
        return 0; //Did not find a match
      end
      this.key_queue.delete(q_idx[0]);
      item_position_idx = q_idx[0];
    end else begin
      //This branch is only executed if a hash collision occured
      //Must take special care to ensure correct item is removed from key queue
      cl_syoscb_item item1, item2;

      item1 = proxy_item_hash.get_item();
      //For each index, check if that item matches our expected item. If yes, remove
      foreach(q_idx[i]) begin
        item2 = this.key_queue[q_idx[i]].item;
        if(item1.compare(item2)) begin
          item_position_idx = q_idx[i];
          break;
        end
      end
    end
  end
  // If ordered_next is 0, key_queue can't be used to determine which is the current item position
  // inside the queue.
  // Instead, we go over all iterators associated with the queue, as one of them should
  // be pointing to our current item, allowing us to get idx from the iterator.
  // If no iterators are pointing to the item, we manually search over the AA to find the item
  else begin
    //Go over all iterators, find the one pointing to this proxy item and retrieve idx from that one
    foreach(this.iterators[i]) begin
      cl_syoscb_proxy_item_base other_proxy;

      //iterator.next() was called to get the proxy item, so we first rewind the iterator, then re-get the item
      void'(this.iterators[i].previous());
      other_proxy = this.iterators[i].next();
      //Can compare references directly, since they should both be pointing to the same object.
      //No need to compare hash digest or contents
      if(other_proxy.get_item() == proxy_item_hash.get_item()) begin
        item_position_idx = this.iterators[i].previous_index();
        break;
      end
    end

    // Only need to search if we didn't previously find the item by checking iterators
    // AND if there are actually any iterators to test out
    if(this.iterators.size() > 0 && item_position_idx == 0) begin
      int unsigned v_idx = 0;
      tp_digest loop_digest;

      if(this.hash.first(loop_digest)) begin
        while(loop_digest != digest) begin
          void'(this.hash.next(loop_digest));
          //If multiple items have this digest, we must also account for those in our final position idx
          v_idx += this.hash.get_size(loop_digest);
        end
        v_idx += proxy_item_hash.idx;
      end
      item_position_idx = v_idx;
    end
  end

  // Iterators update process can be shared independently by the value of ordered_next
  // Find all the iter which need to be updated (all of those which have a next idx > item_position_idx)
  iter = this.iterators.find(x) with (x.next_index() > item_position_idx);

  // Update them
  foreach(iter[i]) begin
    void'(iter[i].previous());
  end

  //Delete item, decrease producer count and size, return semaphore
  this.hash.delete(digest, proxy_item_hash.idx);
  this.decr_cnt_producer(producer);
  this.size--;
  this.iter_sem.put();

  return 1;
endfunction: delete_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#get_item for more details
function cl_syoscb_item cl_syoscb_queue_hash::get_item(cl_syoscb_proxy_item_base proxy_item);
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) proxy_item_hash;

  if(!$cast(proxy_item_hash, proxy_item)) begin
    `uvm_fatal("Incorrect item type", $sformatf("[%s]:Proxy_item was of type %0s", this.cfg.get_scb_name(), proxy_item.get_type_name()));
    return null;
  end

  return this.hash.get_item(proxy_item_hash.digest, proxy_item_hash.idx);
endfunction: get_item

/// <b>Queue API:</b> See cl_syoscb_queue_base#get_size for more details.
function int unsigned cl_syoscb_queue_hash::get_size();
  return this.size;
endfunction: get_size

/// <b>Queue API:</b> See cl_syoscb_queue_base#empty for more details
function bit cl_syoscb_queue_hash::empty();
  return this.get_size()==0;
endfunction

/// <b>Queue API:</b> See cl_syoscb_queue_base#delete_iterator for more details
function bit cl_syoscb_queue_hash::delete_iterator(cl_syoscb_queue_iterator_base iterator);
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

/// See cl_syoscb_queue_base#do_flush_queue for more details
function void cl_syoscb_queue_hash::do_flush_queue();
  this.hash.delete_all();
  this.key_queue = {};
  this.size = 0;
endfunction: do_flush_queue

/// Get the list of hash values of items in the queue.
/// \note If cl_syoscb_cfg#ordered_next is 0, the key queue has no inherent meaning.
///       An empty queue is returned in this case
function cl_syoscb_queue_hash::tp_queue_of_keys cl_syoscb_queue_hash::get_key_queue();
  return this.key_queue;
endfunction: get_key_queue

/// Gets the hash AA wrapper used for this queue
function cl_syoscb_queue_hash::tp_aa_hash cl_syoscb_queue_hash::get_hash();
  return this.hash;
endfunction: get_hash