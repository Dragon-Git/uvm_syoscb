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
class cl_syoscb_queue extends uvm_component;
   `uvm_component_utils(cl_syoscb_queue)

   // List of iterators registered with queue
   cl_syoscb_queue_iterator_base iterators[cl_syoscb_queue_iterator_base];
   int  unsigned iter_idx;

   semaphore iter_sem;

   // Basic queue functions
   virtual function bit add_item(string producer, uvm_sequence_item item);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::add_item() *MUST* be overwritten"));
     return(1'b0);
   endfunction

   virtual function bit delete_item(int unsigned idx);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::delete_item() *MUST* be overwritten"));
     return(1'b0);
   endfunction

   virtual function uvm_sequence_item get_item(int unsigned idx);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::get_item() *MUST* be overwritten"));
     return(null);
   endfunction

   virtual function int unsigned get_size();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::get_size() *MUST* be overwritten"));
    return(0);
   endfunction

   virtual function bit insert_item(string producer, uvm_sequence_item item, int unsigned idx);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::insert_item() *MUST* be overwritten"));
     return(1'b0);
   endfunction

   // Iterator support functions
   virtual function cl_syoscb_queue_iterator_base create_iterator();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::create_iterator() *MUST* be overwritten"));
    return(null);
   endfunction

   virtual function bit delete_iterator(cl_syoscb_queue_iterator_base iterator);
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::delete_item() *MUST* be overwritten"));
     return(1'b0);
   endfunction

   // TBD: Locator not implemented yet

   // Constructor
   extern function new(string name, uvm_component parent);
endclass : cl_syoscb_queue

function cl_syoscb_queue::new(string name, uvm_component parent);
   super.new(name, parent);

   this.iter_sem = new(1);
   this.iter_idx = 0;
endfunction : new
