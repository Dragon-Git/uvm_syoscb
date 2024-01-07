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
/// Queue iterator base class defining the iterator API used for iterating over queues.
/// The iterator API is modelled after the Java ListIterator interface https://docs.oracle.com/javase/8/docs/api/java/util/ListIterator.html.
/// To iterate over all elements of a queue, use a while loop of the type
/// <pre>
/// void'(iter.first());
/// while(iter.has_next()) begin
///   cl_syoscb_proxy_item_base pib = iter.next();
///   //do something
/// end
/// </pre>
/// Internally, the iterator's position is always between elements. Calling #next or #previous will advance
/// or reverse the iterator, returning the item that was moved past
/// <pre>
/// items:              queue[0]   queue[1]   queue[2]   ...   queue[n-1]
/// cursor positions: ^          ^          ^          ^     ^            ^
/// </pre>
class cl_syoscb_queue_iterator_base extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// The owner of this iterator
  protected cl_syoscb_queue_base owner;

  /// Current position in the queue
  protected int unsigned position = 0;

  /// Local handle to the SCB cfg
  protected cl_syoscb_cfg cfg;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_queue_iterator_base)
    `uvm_field_object(owner, UVM_DEFAULT)
    `uvm_field_int(position, UVM_DEFAULT | UVM_DEC)
    `uvm_field_object(cfg,   UVM_DEFAULT | UVM_REFERENCE)
  `uvm_object_utils_end

  function new(string name = "cl_syoscb_queue_iterator_base");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Iterator API
  //-------------------------------------
  extern           virtual function cl_syoscb_proxy_item_base next();
  extern           virtual function bit                       has_next();
  extern           virtual function int                       next_index();
  extern           virtual function cl_syoscb_proxy_item_base previous();
  extern           virtual function bit                       has_previous();
  extern           virtual function int                       previous_index();
  extern           virtual function bit                       first();
  extern           virtual function bit                       last();
  extern protected virtual function cl_syoscb_queue_base      get_queue();
  extern           virtual function bit                       set_queue(cl_syoscb_queue_base owner);
  extern protected virtual function cl_syoscb_proxy_item_base get_item_proxy();

endclass: cl_syoscb_queue_iterator_base

/// <b>Iterator API:</b> Moves the iterator one step forward, returning the next item in the queue.
/// \return The next item if successful, raises a uvm_error if there is no next item
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_base::next();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::next() *MUST* be overwritten"));
  return null;
endfunction: next

/// <b>Iterator API:</b> Checks if there are more items in the queue in the forward direction
/// \return 1 if there are more items in the forward direction, 0 otherwise (either empty queue or past last item)
function bit cl_syoscb_queue_iterator_base::has_next();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::has_next() *MUST* be overwritten"));
  return 1'b0;
endfunction: has_next

/// <b>Iterator API:</b> Returns the index of the item which would be returned if #next() was called
/// \return The index of the next item, or queue.size() if the iterator has reached the end.
function int cl_syoscb_queue_iterator_base::next_index();
  return this.position;
endfunction: next_index

/// <b>Iterator API:</b> Moves the iterator one step backward, returning the previous item in the queue.
/// \return The previous item if successful, raises a uvm_error if there is no previous item
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_base::previous();
  `uvm_fatal("IMPL_ERROR",
             $sformatf("cl_syoscb_queue_iterator_base::previous() *MUST* be overwritten"));
  return null;
endfunction: previous

/// <b>Iterator API:</b> Checks if there are more items in the queue in the backward direction
/// \return 1 if there are more items in the backward direction, 0 otherwise (either empty queue or at first item)
function bit cl_syoscb_queue_iterator_base::has_previous();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::has_previous() *MUST* be overwritten"));
  return 1'b0;
endfunction: has_previous

/// <b>Iterator API:</b> Returns the index of the item which would be returned if #previous() was called
/// \return The index of the previous item, or -1 if the iterator is pointing to the first item of the queue
function int cl_syoscb_queue_iterator_base::previous_index();
  return this.position - 1;
endfunction: previous_index

/// <b>Iterator API:</b> Moves the iterator to the first item in the queue.
/// Calling #has_previous at this point will always return 1'b0
/// \return 1 if successful, 0 if the queue is empty
function bit cl_syoscb_queue_iterator_base::first();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::first() *MUST* be overwritten"));
  return 1'b0;
endfunction: first

/// <b>Iterator API:</b> Moves the iterator to the last item in the queue.
/// Calling #has_next at this point will always return 1'b0.
/// \return 1 if succesful, 0 if there is no first item (queue is empty)
function bit cl_syoscb_queue_iterator_base::last();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::last() *MUST* be overwritten"));
  return 1'b0;
endfunction: last

/// <b>Iterator API:</b> Internal API: Returns the queue over which this iterator is iterating.
/// \return A handle to the queue. Raises a UVM_FATAL if no queue is associated with the iterator.
function cl_syoscb_queue_base cl_syoscb_queue_iterator_base::get_queue();
  if(this.owner == null) begin
    // An iterator should always have an associated queue
    `uvm_fatal("QUEUE_ERROR",
               $sformatf("Unable to find queue associated with iterator %s", this.get_name()));
    return null;
  end else begin
    return this.owner;
  end
endfunction: get_queue

/// <b>Iterator API:</b> Sets the queue over which this iterator is iterating.
/// If a queue has already been associated with this iterator, or the queue type does not
/// match the iterator type, generates a UVM_ERROR message with id ITER_ERROR.
/// \return 1 if successful, raises a UVM_ERROR otherwise (a queue is already associated with this iterator, or wrong queue type)
function bit cl_syoscb_queue_iterator_base::set_queue(cl_syoscb_queue_base owner);
  `uvm_fatal("IMPL_ERROR",
             $sformatf("cl_syoscb_queue_iterator_base::set_queue() *MUST* be overwritten"));
  return 1'b0;
endfunction: set_queue

/// <b>Iterator API:</b> Internal API: Returns a proxy item that can be used to access the element
/// that was just moved past by calling #next or #previous.
/// \return A proxy item for the element that was moved past.
function cl_syoscb_proxy_item_base cl_syoscb_queue_iterator_base::get_item_proxy();
  `uvm_fatal("IMPL_ERROR",
             $sformatf("cl_syoscb_queue_iterator_base::get_item_proxy() *MUST* be overwritten"));
  return null;
endfunction: get_item_proxy
