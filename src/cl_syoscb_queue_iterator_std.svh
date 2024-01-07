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
class cl_syoscb_queue_iterator_std extends cl_syoscb_queue_iterator_base;

  `uvm_object_utils(cl_syoscb_queue_iterator_std)

  extern virtual function bit next();
  extern virtual function bit previous();
  extern virtual function bit first();
  extern virtual function bit last();
  extern virtual function int unsigned get_idx();
  extern virtual function uvm_sequence_item get_item();
  extern virtual function bit is_done();
  extern virtual function bit set_queue(cl_syoscb_queue owner);

endclass : cl_syoscb_queue_iterator_std


function bit cl_syoscb_queue_iterator_std::next();
  cl_syoscb_queue qh = this.get_queue();

  if(this.position < qh.get_size()) begin
    this.position++;
    return 1;
  end else begin
    // Debug print when unable to advance to the next element (When at the end of the queue)
    `uvm_info("OUT_OF_BOUNDS", $sformatf("Not possible to increment position of queue %s: at end of queue",
                                         qh.get_name()), UVM_DEBUG);
    return 0;
  end
endfunction : next


function bit cl_syoscb_queue_iterator_std::previous();
  if(this.position != 0) begin
    this.position--;
    return 1;
  end else begin
    cl_syoscb_queue qh = this.get_queue();

    // Debug print when unable to advance to the previous element (When at the beginning of the queue)
    `uvm_info("OUT_OF_BOUNDS", $sformatf("Not possible to decrement position of queue %s: at end of queue",
                                         qh.get_name()), UVM_DEBUG);
    return 0;
  end
endfunction : previous


function bit cl_syoscb_queue_iterator_std::first();
  // Std queue uses an SV queue for its items, first item is always 0
  this.position = 0;
  return 1;
endfunction : first


function bit cl_syoscb_queue_iterator_std::last();
  cl_syoscb_queue qh = this.get_queue();

  this.position = qh.get_size()-1;
  return 1;
endfunction : last


function int unsigned cl_syoscb_queue_iterator_std::get_idx();
  return this.position;
endfunction : get_idx


function uvm_sequence_item cl_syoscb_queue_iterator_std::get_item();
  cl_syoscb_queue qh = this.get_queue();

  return qh.get_item(this.position);
endfunction : get_item


function bit cl_syoscb_queue_iterator_std::is_done();
  cl_syoscb_queue qh = this.get_queue();

  if(this.position == qh.get_size()) begin
    return 1;
  end else begin
    return 0;
  end
endfunction : is_done

function bit cl_syoscb_queue_iterator_std::set_queue(cl_syoscb_queue owner);
  if(owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("QUEUE_ERROR", $sformatf("Unable to associate queue with iterator "));
    return 0;
  end else begin
    this.owner = owner;
    return 1;
  end
endfunction : set_queue
