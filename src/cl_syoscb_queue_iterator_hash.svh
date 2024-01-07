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
/// Queue iterator class defining the iterator API used for iterating hash queues.
/// \param HASH_DIGEST_WIDTH Number of bits used in the hash digest for the chosen hash algorithm
class cl_syoscb_queue_iterator_hash#(int unsigned HASH_DIGEST_WIDTH = 1) extends cl_syoscb_queue_iterator_base;

  /// Holds the value of the most recently accessed hash digest
  local cl_syoscb_hash_base#(HASH_DIGEST_WIDTH)::tp_hash_digest digest;

  /// Field indicating which cl_syoscb_hash_item index we're currently looking at
  protected int unsigned hash_index = 0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_syoscb_queue_iterator_hash#(HASH_DIGEST_WIDTH))
    `uvm_field_int(digest,     UVM_DEFAULT)
    `uvm_field_int(hash_index, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "cl_syoscb_queue_iterator_hash");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Iterator API
  //-------------------------------------
  extern           virtual function cl_syoscb_proxy_item_base next();
  extern           virtual function bit                       has_next();
  extern           virtual function cl_syoscb_proxy_item_base previous();
  extern           virtual function bit                       has_previous();
  extern           virtual function bit                       first();
  extern           virtual function bit                       last();
  extern           virtual function bit                       set_queue(cl_syoscb_queue_base owner);
  extern protected virtual function cl_syoscb_proxy_item_base get_item_proxy();
endclass: cl_syoscb_queue_iterator_hash


/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#next for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_hash::next();
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)      qh;
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) proxy_item_hash;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  void'($cast(qh,this.get_queue()));

  //1: Get item
  //2: Move pointer

  if(this.has_next()) begin
    void'($cast(proxy_item_hash, this.get_item_proxy()));
    hash = qh.get_hash();

    //Increment position, update this.digest and this.hash_index to reflect current item
    this.position++;
    if(this.cfg.get_ordered_next() == 1) begin
      cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)::tp_queue_of_keys key_queue;

      //Firstly, get handle to item currently pointed to
      key_queue = qh.get_key_queue();

      this.digest = key_queue[this.position].digest;
      if(hash.get_size(this.digest) == 1) begin
        //If only one item has that hash, set idx=0
        this.hash_index = 0;
      end else begin
        //In case of hash collision, go through items and manually compare
        cl_syoscb_item item1, item2;
        item1 = key_queue[this.position].item;
        for(int i=0; i<hash.get_size(this.digest); i++) begin
          item2 = hash.get_item(this.digest, i);
          if(item1.compare(item2)) begin
            this.hash_index = i;
            break;
          end
        end
      end
    end else begin //ordered_next == 0
      //To avoid hash collisions, we must increment hash index if there are multiple items with given digest
      //The check for position != qh.get_size() is required to correctly iterate past the final element in the queue
      //If pos == qh.get_size(), we increase hash_index, ensuring it is non-zero
      //When previous() is called, it only decrements hash_index, returning a valid index
      if(hash.get_size(this.digest)-1 == this.hash_index && this.position != qh.get_size()) begin
        this.hash_index = 0;
        void'(hash.next(this.digest));
      end else begin
        this.hash_index++;
      end
    end

    return proxy_item_hash;
  end else begin
    `uvm_error("ITER_ERROR", $sformatf("Cannot get next item for hash-queue %0s with %0d elements. Already pointing to last element", qh.get_name(), qh.get_size()))
    return null;
  end
endfunction: next

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#has_next for details
function bit cl_syoscb_queue_iterator_hash::has_next();
  cl_syoscb_queue_base qh = this.get_queue();
  return this.position < qh.get_size();
endfunction: has_next

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#previous for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_hash::previous();
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) qh;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  void'($cast(qh,this.get_queue()));

  if(!this.has_previous()) begin
    `uvm_error("ITER_ERROR", $sformatf("Cannot get previous item for hash-queue %0s with %0d elements. Already pointing to first element", qh.get_name(), qh.get_size()))
    return null;
  end

  hash = qh.get_hash();

  //Decrement position, update this.digest and this.hash_index to reflect current item
  this.position--;
  if(this.cfg.get_ordered_next() == 1) begin
    cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)::tp_queue_of_keys key_queue;
    cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)::tp_digest digest;

    //Firstly, get handle to item currently pointed to
    key_queue = qh.get_key_queue();

    this.digest = key_queue[this.position].digest;
    if(hash.get_size(this.digest) == 1) begin
      //If only one item has that hash, set idx=0
      this.hash_index = 0;
    end else begin
      //In case of hash collision, go through items and manually compare
      cl_syoscb_item item1, item2;
      item1 = key_queue[this.position].item;
      for(int i=0; i<hash.get_size(this.digest); i++) begin
        item2 = hash.get_item(this.digest, i);
        if(item1.compare(item2)) begin
          this.hash_index = i;
          break;
        end
      end
    end
  end else begin //ordered_next == 0
    if(this.hash_index == 0) begin
      void'(hash.prev(this.digest));
      this.hash_index = hash.get_size(this.digest)-1;
    end else begin
      this.hash_index--;
    end
  end

  return this.get_item_proxy();
endfunction: previous

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#has_previous for details
function bit cl_syoscb_queue_iterator_hash::has_previous();
  cl_syoscb_queue_base qh = this.get_queue();
  return (this.position > 0);
endfunction: has_previous

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#first for details
function bit cl_syoscb_queue_iterator_hash::first();
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) qh;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  void'($cast(qh,this.owner));

  if(qh.get_size() == 0) begin
    return 1'b0;
  end

  this.position = 0;
  this.hash_index = 0;
  //when ordered_next == 0, we must also update the value of this.digest, as it is required for next/previous
  //if ordered_next == 1, this is not necessary as it only depends on this.position when calling next/previous
  if(!this.cfg.get_ordered_next()) begin
    hash = qh.get_hash();
    void'(hash.first(this.digest));
  end
  return 1'b1;
endfunction: first

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#last for details
function bit cl_syoscb_queue_iterator_hash::last();
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) qh;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  void'($cast(qh,this.owner));
  if(qh.get_size() == 0) begin
    return 1'b0;
  end

  this.position = qh.get_size();
  //Same reasons for only updating digest/hash_index when ordered_next == 0 as stated above in first()
  if (!this.cfg.get_ordered_next()) begin
    hash = qh.get_hash();
    void'(hash.last(this.digest));
    //By setting hash_index = hash.get_size(), it is one larger than the number of items with that hash value
    //When iter.previous() is called, hash_index is decremented, pointing us to the actually final element
    this.hash_index = hash.get_size(this.digest);
  end
  return 1'b1;
endfunction: last

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#set_queue for details
function bit cl_syoscb_queue_iterator_hash::set_queue(cl_syoscb_queue_base owner);
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) qh;

  if(owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("ITER_ERROR", "Unable to associate queue with iterator as argument was null")
    return 1'b0;
  end else if(this.owner != null) begin
    //An iterator's owner should not be re-assignable
    `uvm_error("ITER_ERROR", $sformatf("Cannot reassign queue owner. Use create_iterator() to create an iterator for queue %s", owner.get_name()))
    return 1'b0;
  end else if(!$cast(qh, owner)) begin
    `uvm_error("ITER_ERROR", $sformatf({"Cannot assign queue %0s to iterator %0s, as the types do not match.\n",
                                        "Expected a queue of type cl_syoscb_queue_hash#(%0d), got %0s"}, owner.get_name(), this.get_name(), HASH_DIGEST_WIDTH, owner.get_type_name()))
    return 1'b0;
  end else begin
    this.owner = owner;
    this.cfg = owner.get_cfg();
    return 1'b1;
  end
endfunction: set_queue

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#get_item_proxy for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_hash::get_item_proxy();
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) proxy_item_hash;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;

  proxy_item_hash = cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH)::type_id::create("proxy_item_hash");

  //When calling next() the first time, this line will get executed, initializing this.digest and this.hash_index
  if(this.position == 0) begin
    cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) qh;
    void'($cast(qh, this.get_queue()));
    this.hash_index = 0;

    if(this.cfg.get_ordered_next()) begin
      cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)::tp_queue_of_keys key_queue = qh.get_key_queue();
      this.digest = key_queue[this.position].digest;
    end else begin
      cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash = qh.get_hash();
      void'(hash.first(this.digest));
    end
  end

  proxy_item_hash.digest = this.digest;
  proxy_item_hash.idx = this.hash_index;
  proxy_item_hash.set_queue(this.owner);

  return proxy_item_hash;
endfunction: get_item_proxy