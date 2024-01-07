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
/// Class which implements the out of order compare algorithm
class cl_syoscb_compare_ooo extends cl_syoscb_compare_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_compare_ooo)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_ooo");

  //-------------------------------------
  // Compare Strategy API
  //-------------------------------------
  // *NOTE*: init() hook s not used by the out-of-order compare
  extern protected virtual function void   primary_loop_do();
  extern protected virtual function void   secondary_loop_do();
  extern protected virtual function string get_count_producer();
endclass: cl_syoscb_compare_ooo

function cl_syoscb_compare_ooo::new(string name = "cl_syoscb_compare_ooo");
  super.new(name);
endfunction: new

/// <b>Compare Strategy API</b>: Implementation of the out-of-order comparison is here.
///
/// The algorithm iterates over the primary queue, starting from the oldest inserted item.
/// For each item in the primary queue, it then loops over all secondary queues,
/// attempting to find a matching item in the secondary queue.
/// If a match for an item in the primary queue is found in all secondary queues,
/// all of those items are removed from their respective queues.
/// If a match is not found in all queues, nothing is deleted.
/// Note that this means that if some items are not matched, the queues will be non-empty
/// at the end of simulation. This is caught in the cl_syoscb#check_phase.
///
/// The number of items that are inspected in each queue is controlled by the value of
/// cl_syoscb_cfg#max_search_window for that specific queue.
function void cl_syoscb_compare_ooo::primary_loop_do();
  int unsigned msw = this.cfg.get_max_search_window(this.primary_queue_name);

  //Reset primary iterator to first element, loop through at most max_search_window primary elements, comparing to secondary elements
  if(this.primary_queue_iter.first()) begin
    while(this.primary_queue_iter.has_next() && (msw > 0 ? this.primary_queue_iter.next_index() < msw : 1)) begin
      this.primary_item_proxy = this.primary_queue_iter.next();
      `uvm_info("DEBUG", $sformatf("[%s]: cmp-ooo: Now comparing primary transaction:\n%s", this.cfg.get_scb_name(), cl_syoscb_string_library::sprint_item(this.primary_queue.get_item(this.primary_item_proxy), this.cfg)), UVM_FULL);

      // Clear secondary match item counter before starting new secondary queue loop
      this.secondary_item_found.delete();
      this.secondary_loop_do();
      //break out if matches were found
      if(this.delete()) begin
        break;
      end
    end
  end
endfunction: primary_loop_do

/// <b>Compare Strategy API</b>: Loop through all secondary queues, attempting to find an item
/// which matches the item from the primary queue (as specified by #primary_item_proxy).
/// Searches at most cl_syoscb_cfg#max_search_window in each secondary queue if std. queues are used.
/// If MD5 queues are used, the max search window is not applied.
function void cl_syoscb_compare_ooo::secondary_loop_do();
  // Inner loop through all queues
  foreach(this.secondary_queue_names[i]) begin
    cl_syoscb_queue_locator_base secondary_queue_loc;
    cl_syoscb_proxy_item_base    secondary_proxy_item;

    if(this.secondary_queues[i] == null) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-ooo: Unable to retrieve secondary queue handle", this.cfg.get_scb_name()));
    end

    `uvm_info("DEBUG", $sformatf("[%s]: cmp-ooo: %0d items in queue: %s", this.cfg.get_scb_name(), secondary_queues[i].get_size(), this.secondary_queue_names[i]), UVM_FULL);

    // Get a locator for the secondary queue
    secondary_queue_loc = secondary_queues[i].get_locator();
    secondary_proxy_item = secondary_queue_loc.search(this.primary_item_proxy);

    if(secondary_proxy_item == null) begin
      break;
    end else begin
      this.secondary_item_found[this.secondary_queue_names[i]] = secondary_proxy_item;
    end
  end
endfunction: secondary_loop_do


/// <b>Compare Strategy API</b>: For OOO comparisons, the overrided function returns the producer
/// of the first element (the oldest) inside the primary queue.
function string cl_syoscb_compare_ooo::get_count_producer();
  cl_syoscb_proxy_item_base l_item_proxy;
  cl_syoscb_item l_item;

  if(this.primary_queue_iter == null) begin
    this.primary_queue_iter = this.primary_queue.create_iterator("default");
  end

  void'(this.primary_queue_iter.first());

  l_item_proxy = this.primary_queue_iter.next();
  l_item = this.primary_queue.get_item(l_item_proxy);
  void'(this.primary_queue_iter.first());

  return l_item.get_producer();
endfunction: get_count_producer
