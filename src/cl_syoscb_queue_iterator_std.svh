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
/// Queue iterator class for iterating over std queues
class cl_syoscb_queue_iterator_std extends cl_syoscb_queue_iterator_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_queue_iterator_std)

  function new(string name = "cl_syoscb_queue_iterator_std");
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
endclass: cl_syoscb_queue_iterator_std

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#next for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_std::next();
  cl_syoscb_proxy_item_base proxy_item;
  cl_syoscb_queue_base qh = this.get_queue();
  if(!this.has_next()) begin
    `uvm_error("ITER_ERROR", $sformatf("Cannot get next item for std-queue %0s with %0d elements. Already pointing to last element", qh.get_name(), qh.get_size()))
    return null;
  end
  proxy_item = this.get_item_proxy();
  this.position++;
  return proxy_item;
endfunction: next

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#has_next for details
function bit cl_syoscb_queue_iterator_std::has_next();
  cl_syoscb_queue_base qh = this.get_queue();
  return this.position < qh.get_size();
endfunction: has_next

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#previous for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_std::previous();
  cl_syoscb_queue_base qh = this.get_queue();
  if(!this.has_previous()) begin
    `uvm_error("ITER_ERROR", $sformatf("Cannot get previous item for std-queue %0s with %0d elements. Already pointing to first element", qh.get_name(), qh.get_size()))
    return null;
  end

  this.position--;
  return this.get_item_proxy();
endfunction: previous

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#has_previous for details
function bit cl_syoscb_queue_iterator_std::has_previous();
  return (this.position > 0);
endfunction: has_previous

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#first for details
function bit cl_syoscb_queue_iterator_std::first();
  // If the call is done on a empty queue, the method call should fail
  if(this.owner.get_size() == 0) begin
    return 1'b0;
  end else begin
    this.position = 0;
    return 1'b1;
  end
endfunction: first

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#last for details
function bit cl_syoscb_queue_iterator_std::last();
  if(this.owner.get_size() == 0) begin
    return 1'b0;
  end else begin
    this.position = this.owner.get_size();
    return 1'b1;
  end
endfunction: last

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#set_queue for details
function bit cl_syoscb_queue_iterator_std::set_queue(cl_syoscb_queue_base owner);
  cl_syoscb_queue_std qs;

  if(owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("ITER_ERROR", "Unable to associate queue with iterator as argument was null")
    return 1'b0;
  end else if(this.owner != null) begin
    //An iterator's owner should not be re-assignable
    `uvm_error("ITER_ERROR", $sformatf("Cannot reassign queue owner. Use create_iterator() to create an iterator for queue %s", owner.get_name()))
    return 1'b0;
  end else if(!$cast(qs, owner)) begin
    `uvm_error("ITER_ERROR", $sformatf({"Cannot assign queue %0s to iterator %0s, as the types do not match.\n",
                                        "Expected a queue of type cl_syoscb_queue_std, got %0s"}, owner.get_name(), this.get_name(), owner.get_type_name()))
    return 1'b0;
  end else begin
    this.owner = owner;
    this.cfg = owner.get_cfg();
    return 1'b1;
  end
endfunction: set_queue

/// <b>Iterator API:</b> See cl_syoscb_queue_iterator_base#get_item_proxy for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_std::get_item_proxy();
  cl_syoscb_proxy_item_std proxy_item_std;

  proxy_item_std = cl_syoscb_proxy_item_std::type_id::create("proxy_item_std");
  proxy_item_std.idx = this.position;
  proxy_item_std.set_queue(this.owner);
  return proxy_item_std;
endfunction: get_item_proxy
