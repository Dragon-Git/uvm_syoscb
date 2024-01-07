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
class cl_syoscb_cfg extends uvm_object;
   //---------------------------------
   // non randomizable member variables
   //---------------------------------
   cl_syoscb_queue     queues[string];
   cl_syoscb_cfg_pl producers[string];
   string               primary_queue;
// TBD   bit              full_scb_dump;
// TBD  int unsigned     max_queue_size[string];
// TBD  int unsigned     full_max_queue_size[string];
// TBD  string           full_scb_type[];
// TBD  int unsigned     item_time_out_queue[string];
// TBD  int unsigned     item_time_out_producer[string];

   `uvm_object_utils_begin(cl_syoscb_cfg)
     `uvm_field_aa_object_string(queues, UVM_DEFAULT)
     `uvm_field_aa_object_string(producers, UVM_DEFAULT)
     `uvm_field_string(primary_queue, UVM_DEFAULT)
   `uvm_object_utils_end

  extern function new(string name = "cl_syoscb_cfg");
  extern function void set_queues(string queue_names[]);
  extern function void get_queues(output string queue_names[]);
  extern function bit set_producer(string producer, queue_names[]);
  extern function bit set_primary_queue(string primary_queue_name);

endclass : cl_syoscb_cfg


function cl_syoscb_cfg::new(string name = "cl_syoscb_cfg");
   super.new(name);
endfunction : new

function void cl_syoscb_cfg::set_queues(string queue_names[]);
   foreach(queue_names[i]) begin
     this.queues[queue_names[i]] = null;
   end
endfunction : set_queues

// TBD: Can be fixed as a return type by using a typedef
// TBD: The implementation is a bit clumsy...
function void cl_syoscb_cfg::get_queues(output string queue_names[]);
   string queue_name;
   int    unsigned idx = 0;
   queue_names = new[this.queues.size()];
   while(this.queues.next(queue_name)) begin
      //$display("get_queues: %s", queue_name);
      queue_names[idx++] = queue_name;
   end
endfunction : get_queues

function bit cl_syoscb_cfg::set_producer(string producer, queue_names[]);
   cl_syoscb_cfg_pl prod_list = new();
   // TBD: Here there should be a check on the queue names
   prod_list.set_list(queue_names);
   this.producers[producer] = prod_list;
   // TBD: Shall be changed
   return(1'b1);
endfunction: set_producer

function bit cl_syoscb_cfg::set_primary_queue(string primary_queue_name);
   // TBD: Here the should be an existence check on the queue
   this.primary_queue = primary_queue_name;
   // TBD: Shall be changed
   return(1'b1);
endfunction: set_primary_queue
