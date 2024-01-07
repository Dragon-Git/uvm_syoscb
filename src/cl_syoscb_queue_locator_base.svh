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
/// Locator base class defining the locator API used for searching in queues.
/// Locators are primarily used with the OOO compare and hash queues, as this allows us
/// to efficiently find an item with a matching digest
class cl_syoscb_queue_locator_base extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// The queue owning this locator
  protected cl_syoscb_queue_base owner;

  /// Local handle to the SCB cfg
  protected cl_syoscb_cfg cfg;

  `uvm_object_utils_begin(cl_syoscb_queue_locator_base)
    `uvm_field_object(owner, UVM_DEFAULT)
    `uvm_field_object(cfg,   UVM_DEFAULT | UVM_REFERENCE)
  `uvm_object_utils_end

  function new(string name = "cl_syoscb_queue_locator_base");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Locator  API
  //-------------------------------------
  extern virtual function cl_syoscb_proxy_item_base search(cl_syoscb_proxy_item_base proxy_item);
  extern virtual function bit                       set_queue(cl_syoscb_queue_base owner);
  extern virtual function cl_syoscb_queue_base      get_queue();
endclass: cl_syoscb_queue_locator_base

/// <b>Locator API:</b> Returns the item of the underlying queue which matches the given proxy item
/// \param proxy_item A proxy item indicating what to search for in this queue
/// \return A proxy item pointing to the matching item in this queue, or null if no match is found
function cl_syoscb_proxy_item_base cl_syoscb_queue_locator_base::search(cl_syoscb_proxy_item_base proxy_item);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue_locator_base::search() *MUST* be overwritten"))
  return null;
endfunction: search

/// <b>Locator API:</b> Returns the queue that this locator is associated with
function cl_syoscb_queue_base cl_syoscb_queue_locator_base::get_queue();
  if(this.owner == null) begin
    // A locator should always have an associated queue
    `uvm_fatal("QUEUE_ERROR",
               $sformatf("Unable to find queue associated with iterator %s", this.get_name()))
    return null;
  end else begin
    return this.owner;
  end
endfunction: get_queue

/// <b>Locator API:</b> Sets the queue that this locator is associated with
function bit cl_syoscb_queue_locator_base::set_queue(cl_syoscb_queue_base owner);
  if(owner == null) begin
    // An iterator should always have an associated queue
    `uvm_error("QUEUE_ERROR", $sformatf("Unable to associate queue with locator "));
    return 0;
  end else begin
    this.owner = owner;
    this.cfg = owner.get_cfg();
    return 1;
  end
endfunction: set_queue
