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
/// Base class for all proxy items. A proxy item is used to decouple the act of
/// iterating over a queue from the queue's implementation. Proxy items encode information
/// that specify where in a given queue a specific cl_syoscb_item can be found.
class cl_syoscb_proxy_item_base extends uvm_object;
  protected cl_syoscb_queue_base queue;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_proxy_item_base)
    `uvm_field_object(queue, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_proxy_item_base");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Item API
  //-------------------------------------
  extern virtual function cl_syoscb_item       get_item();
  extern virtual function void                 set_queue(cl_syoscb_queue_base queue);
  extern virtual function cl_syoscb_queue_base get_queue();

endclass: cl_syoscb_proxy_item_base

/// <b>Item API:</b> Get the scoreboard item that this proxy item represents
/// \return That item
function cl_syoscb_item cl_syoscb_proxy_item_base::get_item();
  return this.queue.get_item(this);
endfunction: get_item

/// <b>Item API:</b> Sets the queue that the referenced item belongs to
/// \param A handle to the queue
function void cl_syoscb_proxy_item_base::set_queue(cl_syoscb_queue_base queue);
  this.queue = queue;
endfunction: set_queue

/// <b>Item API:</b> Gets the queue that this proxy item depends on
/// \return A handle to that queue
function cl_syoscb_queue_base cl_syoscb_proxy_item_base::get_queue();
  return this.queue;
endfunction: get_queue
