//----------------------------------------------------------------------
//   Copyright 2014 SyoSil ApS
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
virtual class cl_syoscb_queue extends uvm_component;
   `uvm_component_utils(cl_syoscb_queue);

   // List of iterators registered with queue
   cl_syoscb_queue_iterator_base iterators[cl_syoscb_queue_iterator_base];
   int  unsigned iter_idx;

   semaphore iter_sem;

   // Basic queue functions
   pure virtual function bit add_item(string producer, uvm_sequence_item item);
   pure virtual function bit delete_item(int unsigned idx);
   pure virtual function uvm_sequence_item get_item(int unsigned idx);
   pure virtual function int unsigned get_size();
   pure virtual function bit insert_item(string producer, uvm_sequence_item item, int unsigned idx);

   // Iterator support functions
   pure virtual function cl_syoscb_queue_iterator_base create_iterator();
   pure virtual function bit delete_iterator(cl_syoscb_queue_iterator_base iterator);

   // TBD: Locator not implemented yet

   // TBD: Hmmm... a constructor in a pure virtual class??
   extern function new(string name, uvm_component parent);
endclass : cl_syoscb_queue

function cl_syoscb_queue::new(string name, uvm_component parent);
   super.new(name, parent);

   this.iter_sem = new(1);
   this.iter_idx = 0;
endfunction : new
