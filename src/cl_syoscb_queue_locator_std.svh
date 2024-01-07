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
/// Locator class for searching over std queues
class cl_syoscb_queue_locator_std extends cl_syoscb_queue_locator_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_queue_locator_std)

  function new(string name = "cl_syoscb_queue_locator_std");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Locator API
  //-------------------------------------
  extern virtual function cl_syoscb_proxy_item_base search(cl_syoscb_proxy_item_base proxy_item);

  //-------------------------------------
  // Internal support functions
  //-------------------------------------
  extern virtual function bit                       compare_items(cl_syoscb_item primary_item,
                                                                  cl_syoscb_item sec_item,
                                                                  uvm_comparer comparer);

endclass: cl_syoscb_queue_locator_std

/// <b>Locator API:</b> See cl_syoscb_queue_locator_base#search for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_locator_std::search(cl_syoscb_proxy_item_base proxy_item);
  uvm_comparer        comparer;
  int unsigned        msw;
  cl_syoscb_item      primary_item;
  cl_syoscb_queue_std owner_std;
  cl_syoscb_item      queue[$];
  int                 found[$];

  //Get variables and handle to owner as std queue
  msw = this.cfg.get_max_search_window(this.owner.get_name());
  primary_item = proxy_item.get_item();
  comparer = this.cfg.get_comparer(this.owner.get_name(), primary_item.get_producer());
  if(comparer == null) begin
    comparer = this.cfg.get_default_comparer();
  end
  if(!$cast(owner_std, this.owner)) begin
    `uvm_error("LOCATOR_ERROR", $sformatf("Unable to typecast owner from queue_base to queue_std. Type of owner is %0s", this.owner.get_type_name()))
  end

  //Get underlying queue, trim representation if msw requires it
  owner_std.get_native_queue(queue);
  if(msw > 0) begin
    queue = queue[0:msw-1];
  end

  //Search for item, return it if found
  found = queue.find_first_index(x) with (this.compare_items(primary_item, x, comparer));
  if(found.size() == 1) begin
    cl_syoscb_proxy_item_std return_proxy;
    `uvm_info("DEBUG", $sformatf("[%0s]: cmp-ooo: Secondary item found at index %0d\n%0s",
      this.cfg.get_scb_name(),
      found[0],
      queue[found[0]].sprint),
      UVM_DEBUG)
    return_proxy = cl_syoscb_proxy_item_std::type_id::create("return_proxy");
    return_proxy.idx = found[0];
    return_proxy.set_queue(this.owner);
    return return_proxy;
  end else if(found.size() > 1) begin //This shouldn't happen
    `uvm_fatal("LOCATOR_ERROR", $sformatf("queue.find_first_index returned %0d indexes, that shouldn't happen", found.size()))
    return null;
  end else begin //size is 0
    return null;
  end
endfunction: search

/// Compare two scoreboard items and check if they're equal.
/// Used as parameter to queue.find_first_index when searching std-queues
/// \param primary_item The item from the primary queue
/// \param sec_item     The item from the secondary queue
/// \param comparer     The comparer to use when comparing the two items
/// \return             1 if the two items are equal, 0 otherwise
function bit cl_syoscb_queue_locator_std::compare_items(cl_syoscb_item primary_item,
                                                        cl_syoscb_item sec_item,
                                                        uvm_comparer comparer);
  if(primary_item.compare(sec_item, comparer)) begin
    `uvm_info("DEBUG", "Secondary item found", UVM_DEBUG)
    return 1'b1;
  end else begin
    return 1'b0;
  end
endfunction: compare_items