//----------------------------------------------------------------------
//   Copyright 2014-2015 SyoSil ApS
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
/// Queue iterator base class defining the iterator API used for iterating queues.
class cl_syoscb_queue_iterator_base extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// The owner of this iterator
  protected cl_syoscb_queue owner;

  /// Current position in the queue
  protected int unsigned position = 0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_queue_iterator_base)
    `uvm_field_object(owner, UVM_DEFAULT)
    `uvm_field_int(position, UVM_DEFAULT)
  `uvm_object_utils_end

    function new(string name = "cl_syoscb_queue_iterator_base");
      super.new(name);
    endfunction: new

  //-------------------------------------
  // Iterator API
  //-------------------------------------
  extern virtual function bit next();                           // Base 'next' function. Moves iterator to next item in queue
  extern virtual function bit previous();                       // Base 'previous' function. Moves iterator to previous item in queue
  extern virtual function bit first();                          // Base 'first' function. Moves iterator to first item in queue
  extern virtual function bit last();                           // Base 'last' function. Moves iterator to last item in queue
  extern virtual function int unsigned get_idx();               // Base 'get_idx' function. Returns current iterator position
  extern virtual function cl_syoscb_item get_item();            // Base 'get_item' function. Returns item at current iterator position
  extern virtual function bit is_done();                        // Base 'is_done' function. Returns 1 if iterator is at the end of the queue, otherwise 0
  extern protected function cl_syoscb_queue get_queue();        // Returns the queue that this iterator is associated with
  extern virtual function bit set_queue(cl_syoscb_queue owner); // Sets the queue that this iterator is associated with
endclass: cl_syoscb_queue_iterator_base

/// <b>Iterator API:</b> Moves the iterator to the next item in the queue.
/// It shall return 1'b0 if there is no next item, e.g. when it is either empty or
/// the iterator has reached the end of the queue. 
function bit cl_syoscb_queue_iterator_base::next();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::next() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Iterator API:</b>  Moves the iterator to the previous item in the queue.
/// It shall return 1'b0 if there is no previous item, e.g. when it is either empty or
/// the iterator has reached the very beginning of the queue. 
function bit cl_syoscb_queue_iterator_base::previous();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::previous() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Iterator API:</b>  Moves the iterator to the first item in the queue.
/// It shall return 1'b0 if there is no first item (Queue is empty). 
function bit cl_syoscb_queue_iterator_base::first();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::first() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Iterator API:</b>  Moves the iterator to the last item in the queue.
/// It shall return 1'b0 if there is no last item (Queue is empty). 
function bit cl_syoscb_queue_iterator_base::last();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::last() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Iterator API:</b>  Returns the current index
function int unsigned cl_syoscb_queue_iterator_base::get_idx();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::get_idx() *MUST* be overwritten"));
  return(0);
endfunction

/// <b>Iterator API:</b>  Returns the current cl_syoscb_item object at the current index
function cl_syoscb_item cl_syoscb_queue_iterator_base::get_item();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::get_item() *MUST* be overwritten"));
  return(null);
endfunction

/// <b>Iterator API:</b>  Returns 1'b0 as long as the iterator has not reached the end.
/// When the iterator has reached the end then it returns 1'b1.
function bit cl_syoscb_queue_iterator_base::is_done();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::is_done() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Iterator API:</b>  Returns releated queue
function cl_syoscb_queue cl_syoscb_queue_iterator_base::get_queue();
  if(this.owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("QUEUE_ERROR", $sformatf("Unable to find queue associated with iterator %s", this.get_name()));
    return null;
  end else begin
    return this.owner;
  end
endfunction: get_queue

/// <b>Iterator API:</b>  Sets releated queue
function bit cl_syoscb_queue_iterator_base::set_queue(cl_syoscb_queue owner);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::set_queue() *MUST* be overwritten"));
  return(1'b0);
endfunction
