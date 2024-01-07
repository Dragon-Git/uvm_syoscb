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
class cl_syoscb_queue_iterator_base extends uvm_object;
  `uvm_object_utils(cl_syoscb_queue_iterator_base)

  // The owner of this iterator
  cl_syoscb_queue owner;

  int unsigned position = 0;

  // Base 'next' function. Moves iterator to next item in queue
  virtual function bit next();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::next() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  // Base 'previous' function. Moves iterator to previous item in queue
  virtual function bit previous();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::previous() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  // Base 'first' function. Moves iterator to first item in queue
  virtual function bit first();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::first() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  // Base 'last' function. Moves iterator to last item in queue
  virtual function bit last();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::last() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  // Base 'get_idx' function. Returns current iterator position
  virtual function int unsigned get_idx();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::get_idx() *MUST* be overwritten"));
     return(0);
  endfunction

  // Base 'get_item' function. Returns item at current iterator position
  virtual function uvm_sequence_item get_item();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::get_item() *MUST* be overwritten"));
    return(null);
  endfunction

  // Base 'is_done' function. Returns 1 if iterator is at the end of the queue,
  // otherwise 0
  virtual function bit is_done();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::is_done() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  // Returns the queue that this iterator is associated with
  extern protected function cl_syoscb_queue get_queue();

  // Sets  the queue that this iterator is associated with
  virtual function bit set_queue(cl_syoscb_queue owner);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_iterator_base::set_queue() *MUST* be overwritten"));
     return(1'b0);
  endfunction
endclass : cl_syoscb_queue_iterator_base

function cl_syoscb_queue cl_syoscb_queue_iterator_base::get_queue();
  if(this.owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("QUEUE_ERROR", $sformatf("Unable to find queue associated with iterator %s", this.get_name()));
    return null;
  end else begin
    return this.owner;
  end
endfunction : get_queue
