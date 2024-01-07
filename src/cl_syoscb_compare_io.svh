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
/// Implementation of the in-order comparison algorithm for N queues.
class cl_syoscb_compare_io extends cl_syoscb_compare_base;

  ///Scoreboard wrapper item from the primary queue
  cl_syoscb_item primary_item;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_compare_io)
    `uvm_field_object(primary_item, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_io");

  //-------------------------------------
  // Compare Strategy API
  //-------------------------------------
  extern protected virtual function void primary_loop_do();
  extern protected virtual function void count_producers(string producer = "");
  extern protected virtual function void secondary_loop_do();

endclass: cl_syoscb_compare_io

function cl_syoscb_compare_io::new(string name = "cl_syoscb_compare_io");
  super.new(name);
endfunction: new

/// <b>Compare Strategy API</b>: Implementation of the in-order comparison algorithm.
///
/// In the primary loop, the algorithm extracts the oldest inserted element
/// from the primary queue, and then starts looping over all secondary queues
/// to find a matching item in #secondary_loop_do.
/// If matching items are found, these are removed from all of the queues
/// If no matching items are found, a miscompare is generated and a UVM_ERROR is issued.
function void cl_syoscb_compare_io::primary_loop_do();
  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: number of queues: %0d", this.cfg.get_scb_name(), this.secondary_queues.size()+1), UVM_FULL);
  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: primary queue: %s", this.cfg.get_scb_name(), this.primary_queue_name), UVM_FULL);

  // Get first item in primary queue
  // *NOTE*: No need to check if there is any item since compare_do is only invoked
  //         if there is at least a single element in all queues
  //Iterator has already been reset in create_primary_iterator, so we can get the item right now
  this.primary_item_proxy = this.primary_queue_iter.next();
  this.primary_item       = this.primary_queue.get_item(this.primary_item_proxy);

  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Now comparing primary transaction:\n%s",
                     this.cfg.get_scb_name(),
                     cl_syoscb_string_library::sprint_item(primary_item, this.cfg)),
             UVM_FULL);

  // Clear secondary match item counter before starting new secondary queue loop
  this.secondary_item_found.delete();

  this.secondary_loop_do();

  void'(this.delete());
endfunction: primary_loop_do

function void cl_syoscb_compare_io::count_producers(string producer = "");
  // For io compare, this function is kept empty. This because
  // for io, the count_producers does not make sense because
  // Item are ever matched starting from the first element in each queue
  // Idependently by the producer. If the inserted item belongs to a different producer,
  // a simply miscompare error will be generated
endfunction: count_producers

/// <b>Compare Strategy API:</b> Loop through all the secondary queues, checking if the first item in that
/// secondary queues matches the first in the primary queue.
/// If a match is found, this is recorded in cl_syoscb_compare_base#secondary_items_found
function void cl_syoscb_compare_io::secondary_loop_do();
  foreach(this.secondary_queues[i]) begin
    `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Looking at secondary queue: %s", this.cfg.get_scb_name(), this.secondary_queue_names[i]), UVM_FULL);

    `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: %0d items in queue: %s", this.cfg.get_scb_name(),secondary_queues[i].get_size(), this.secondary_queue_names[i]), UVM_FULL);

    // Do the compare
    begin
      cl_syoscb_item                secondary_item;
      string                        sec_queue_name;
      cl_syoscb_proxy_item_base     sec_proxy;
      uvm_comparer                  comparer;
      cl_syoscb_queue_iterator_base iter;

      sec_queue_name = this.secondary_queue_names[i];

      //Get first item of sec. queue using an iterator
      //Cannot use proxy item to get it, as this will allow hash-queues to find items that are not in order
      iter = this.secondary_queues[i].get_iterator("default");
      if(iter == null) begin
        iter = this.secondary_queues[i].create_iterator("default");
      end
      void'(iter.first());
      sec_proxy = iter.next();

      secondary_item = this.secondary_queues[i].get_item(sec_proxy);
      comparer = this.cfg.get_comparer(this.primary_queue_name, this.primary_item.get_producer());
      if(comparer == null) begin
        comparer = this.cfg.get_default_comparer();
      end

      if(secondary_item.compare(this.primary_item, comparer) == 1'b1) begin
        `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Secondary item found:\n%s",
                                     this.cfg.get_scb_name(),
                                     cl_syoscb_string_library::sprint_item(secondary_item, this.cfg)),
                  UVM_FULL);

        this.secondary_item_found[sec_queue_name] = sec_proxy;
      end else begin
        string miscmp_table;

        miscmp_table = this.generate_miscmp_table(this.primary_item, secondary_item, sec_queue_name, comparer, "cmp-io");
        `uvm_error("COMPARE_ERROR", $sformatf("\n%0s", miscmp_table))

        break; //Exit foreach loop on error
      end
    end
  end
endfunction: secondary_loop_do
