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
class cl_syoscb_item extends uvm_object;

   // TBD: MD5 Checksum
   string producer;
   uvm_sequence_item item;

   `uvm_object_utils_begin(cl_syoscb_item)
     `uvm_field_string(producer, UVM_DEFAULT)
     `uvm_field_object(item, UVM_DEFAULT)
   `uvm_object_utils_end

   extern function new(string name = "cl_syoscb_item");
   extern function string get_producer();
   extern function void set_producer(string producer);
   extern function uvm_sequence_item get_item();
   extern function void set_item(uvm_sequence_item item);

endclass : cl_syoscb_item

function cl_syoscb_item::new(string name = "cl_syoscb_item");
   super.new(name);
endfunction : new 	 

function string cl_syoscb_item::get_producer();
   return(this.producer);
endfunction: get_producer

function void cl_syoscb_item::set_producer(string producer);
      // TBD: Check that it is a valid producer
   this.producer = producer;
endfunction: set_producer

function uvm_sequence_item cl_syoscb_item::get_item();
   return(this.item);
endfunction: get_item

function void cl_syoscb_item::set_item(uvm_sequence_item item);
   this.item = item;
endfunction: set_item

