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
/// Class which implements the in order by producer compare algorithm
class cl_syoscb_compare_iop extends cl_syoscb_compare_base;

  /// Scoreboard wrapper item from the primary queue
  protected cl_syoscb_item primary_item;
  /// Scoreboard wrapper item from the secondary queue currently being inspected
  protected cl_syoscb_item secondary_item;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_compare_iop)
    `uvm_field_object(primary_item,   UVM_DEFAULT)
    `uvm_field_object(secondary_item, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_iop");

  //-------------------------------------
  // Compare Strategy API
  //-------------------------------------
  extern protected virtual function void   compare_init();
  extern protected virtual function void   primary_loop_do();
  extern protected virtual function void   secondary_loop_do();
  extern protected virtual function string get_count_producer();
endclass: cl_syoscb_compare_iop

function cl_syoscb_compare_iop::new(string name = "cl_syoscb_compare_iop");
  super.new(name);
endfunction: new

/// <b>Compare Strategy API</b>: Verifies if the conditions for starting a compare are met.
/// For IOP comparison, we only check whether all queues have at least one item in them, but do not check
/// if primary queue's oldest item's producer exists in all queues.
/// Checking if all queues have an item from the same producer is moved to primary_loop_do
function void cl_syoscb_compare_iop::compare_init();
  this.check_queues();
endfunction: compare_init


/// <b>Compare Strategy API</b>: Implementation of the in-order by producer comparison.
///
/// The algorithm gets the primary queue, extracting the oldest element.
/// It then checks if all other queues also contain an element from this element's producer.
/// If true, it attempts to find a match for the primary item in all secondary queues.
/// If false, extracts the second-oldest element from primary, checking if this item's producer
/// has at least one item in all other queues.
/// Continues performing this loop over items in primary queue until one of three things happen:
/// -# A match is found for the item from the primary queue, the item and matches are removed from their queues.
/// -# An item from a secondary queue has the same producer but does not match primary item.
///    This generates a miscompare and raises a UVM_ERROR.
/// -# No matches are found. Will search over at most cl_syoscb_cfg#max_search_window elements in the primary
///    and secondary queues. Does not raise a UVM_ERROR
/// Note that this may leave the queues non_empty at the end of simulation without triggering any errors.
/// These orphaned items in queues are caught in the check_phase.
function void cl_syoscb_compare_iop::primary_loop_do();
  cl_syoscb_item primary_item;
  int unsigned msw = this.cfg.get_max_search_window(this.primary_queue_name);

  if(this.primary_queue_iter.first()) begin //Reset iterator, start while-loop
    //Iterator not finished and not exceeding max search window
    while(this.primary_queue_iter.has_next() && (msw > 0 ? this.primary_queue_iter.next_index() < msw : 1)) begin
      this.primary_item_proxy = this.primary_queue_iter.next();
      this.primary_item = this.primary_queue.get_item(this.primary_item_proxy);

      //Set go=1 to indicate that we wish to start a comparison
      //If still 1 after calling count_producers, we have matching producers in all queues
      this.go = 1'b1;
      this.count_producers(this.primary_item.get_producer());
      if(this.go) begin
        `uvm_info("DEBUG", $sformatf("[%s]: cmp-iop: Now comparing primary transaction:\n%s",
          this.cfg.get_scb_name(),
          cl_syoscb_string_library::sprint_item(this.primary_item, this.cfg)),
          UVM_FULL);
        this.secondary_item_found.delete();
        this.secondary_loop_do();

        if(this.delete()) begin
          //If delete return 1'b1, we found matching items in all queues.
          //If it return 1'b0, the primary item's producer exists in all queues,
          //but items were not found (due to max search window limiting the
          //number of seq. items searched).
          break;
        end
        return;
      end else begin
        `uvm_info("DEBUG", $sformatf({"[%s]: cmp-iop: Not comparing primary transaction since not all queues",
        " have items from producer '%s'"}, this.primary_item.get_producer()), UVM_DEBUG)
      end
    end
  end
endfunction: primary_loop_do

/// <b>Compare Strategy API:</b> Loop through all secondary queues, attempting to find an item
/// which matches the primary item.
function void cl_syoscb_compare_iop::secondary_loop_do();
  foreach(this.secondary_queue_names[i]) begin
    cl_syoscb_queue_iterator_base secondary_queue_iter;
    string                        sec_queue_name;
    int unsigned                  msw;

    sec_queue_name = this.secondary_queue_names[i];

    `uvm_info("DEBUG", $sformatf("[%s]: cmp-iop: Looking at queue: %s", this.cfg.get_scb_name(), sec_queue_name), UVM_FULL);
    `uvm_info("DEBUG", $sformatf("[%s]: cmp-iop: %s is a secondary queue - now comparing", this.cfg.get_scb_name(), sec_queue_name), UVM_FULL);

    `uvm_info("DEBUG", $sformatf("[%s]: cmp-iop: %0d items in queue: %s", this.cfg.get_scb_name(), this.secondary_queues[i].get_size(), sec_queue_name), UVM_FULL);

    // *NOTE*: No need to check if there is any item since compare_do is only invoked
    //         if there is at least a single element in all queues

    secondary_queue_iter = this.secondary_queues[i].get_iterator("default");
    if(secondary_queue_iter == null) begin
      secondary_queue_iter = this.secondary_queues[i].create_iterator("default");
    end
    void'(secondary_queue_iter.first());
    msw = this.cfg.get_max_search_window(sec_queue_name);

    // Only the first match is removed
    while(secondary_queue_iter.has_next() && (msw > 0 ? secondary_queue_iter.next_index() < msw : 1)) begin
      // Get the item from the secondary queue
      cl_syoscb_proxy_item_base secondary_item_proxy = secondary_queue_iter.next();
      this.secondary_item = this.secondary_queues[i].get_item(secondary_item_proxy);

      // Only do the compare if the producers match
      if(this.primary_item.get_producer() == secondary_item.get_producer()) begin
        uvm_comparer comparer;

        comparer = this.cfg.get_comparer(this.primary_queue_name, this.primary_item.get_producer());
        if(comparer == null) begin
          comparer = this.cfg.get_default_comparer();
        end

        if(this.secondary_item.compare(this.primary_item, comparer) == 1'b1) begin
          this.secondary_item_found[sec_queue_name] = secondary_item_proxy;

          `uvm_info("DEBUG", $sformatf("[%s]: cmp-iop: Secondary item found at index: %0d:\n%s",
                                       this.cfg.get_scb_name(),
                                       secondary_queue_iter.previous_index(),
                                       cl_syoscb_string_library::sprint_item(this.secondary_item, this.cfg)),
                    UVM_FULL);

          break;
        end else begin
          string miscmp_table;

          miscmp_table = this.generate_miscmp_table(this.primary_item, this.secondary_item, sec_queue_name, comparer, "cmp-iop");
          `uvm_error("COMPARE_ERROR", $sformatf("\n%0s", miscmp_table))

          // The first element was not a match => break since this is an in order compare
          // w.r.t. the producer name.
          break;
        end
      end
    end
  end
endfunction: secondary_loop_do


/// <b>Compare Strategy API</b>: For IOP comparisons, this function returns the producer
/// of the first element (the oldest) inside the primary queue, and not the most recently inserted item.
function string cl_syoscb_compare_iop::get_count_producer();
  cl_syoscb_proxy_item_base l_item_proxy;
  cl_syoscb_item l_item;
  cl_syoscb_queue_iterator_base l_iter;

  if(this.primary_queue_iter == null) begin
    this.primary_queue_iter = this.primary_queue.create_iterator("default");
  end

  void'(this.primary_queue_iter.first());

  l_item_proxy = this.primary_queue_iter.next();
  l_item = this.primary_queue.get_item(l_item_proxy);
  void'(this.primary_queue_iter.first()); //Must reset after peeking first item

  return l_item.get_producer();
endfunction: get_count_producer
