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
/// Class which implements the in order compare algorithm
class cl_syoscb_compare_io extends cl_syoscb_compare_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_compare_io)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_io");

  //-------------------------------------
  // Compare API
  //-------------------------------------
  extern virtual function void compare();
  extern function void compare_do();
endclass: cl_syoscb_compare_io

function cl_syoscb_compare_io::new(string name = "cl_syoscb_compare_io");
  super.new(name);
endfunction: new

/// <b>Compare API</b>: Mandatory overwriting of the base class' compare method.
/// Currently, this just calls do_compare() blindly 
function void cl_syoscb_compare_io::compare();
  // Here any state variables should be queried
  // to compute if the compare should be done or not
  this.compare_do();
endfunction: compare

/// <b>Compare API</b>: Mandatory overwriting of the base class' do_compare method.
/// Here the actual in order compare is implemented.
///
/// The algorithm gets the primary queue and then loops over all other queues to see if
/// it can find primary item as the first item in all of the other queues. If so then the items
/// are removed from all queues. If not then a UVM error is issued.
function void cl_syoscb_compare_io::compare_do();
  string primary_queue_name;
  cl_syoscb_queue primary_queue;
  cl_syoscb_queue_iterator_base primary_queue_iter;
  string queue_names[];
  int unsigned secondary_item_found[string];
  bit compare_continue = 1'b1;
  bit compare_result = 1'b0;
  cl_syoscb_item primary_item;

  // Initialize state variables
  primary_queue_name = this.get_primary_queue_name();
  this.cfg.get_queues(queue_names);

  primary_queue = this.cfg.get_queue(primary_queue_name);
  if(primary_queue == null) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to retrieve primary queue handle", this.cfg.get_scb_name()));
  end

  primary_queue_iter = primary_queue.create_iterator();

  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: primary queue: %s", this.cfg.get_scb_name(), primary_queue_name), UVM_FULL);
  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: number of queues: %0d", this.cfg.get_scb_name(), queue_names.size()), UVM_FULL);

  // Outer loop loops through all
  while(!primary_queue_iter.is_done()) begin
    primary_item = primary_queue_iter.get_item();

    `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Now comparing primary transaction:\n%s", this.cfg.get_scb_name(), primary_item.sprint()), UVM_FULL); 

    // Clear list of found slave items before starting new inner loop
    secondary_item_found.delete();

    // Inner loop through all queues
    foreach(queue_names[i]) begin
      `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Looking at queue: %s", this.cfg.get_scb_name(), queue_names[i]), UVM_FULL);

      if(queue_names[i] != primary_queue_name) begin
        cl_syoscb_queue secondary_queue;
        cl_syoscb_queue_iterator_base secondary_queue_iter;
        cl_syoscb_item sih;

        `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: %s is a secondary queue - now comparing", this.cfg.get_scb_name(), queue_names[i]), UVM_FULL);

        // Get the secondary queue
        secondary_queue = this.cfg.get_queue(queue_names[i]);

        if(secondary_queue == null) begin
          `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to retrieve secondary queue handle", this.cfg.get_scb_name()));
        end

        `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: %0d items in queue: %s", this.cfg.get_scb_name(), secondary_queue.get_size(), queue_names[i]), UVM_FULL);

        // Get an iterator for the secondary queue
        secondary_queue_iter = secondary_queue.create_iterator();

        // Only do the compare if there are actually an item in the secondary queue
        if(!secondary_queue_iter.is_done()) begin         
          // Get the first item from the secondary queue       
          sih = secondary_queue_iter.get_item();

          if(sih.compare(primary_item) == 1'b1) begin
            secondary_item_found[queue_names[i]] = secondary_queue_iter.get_idx();
            `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Secondary item found at index: %0d:\n%s", this.cfg.get_scb_name(), secondary_queue_iter.get_idx(), sih.sprint()), UVM_FULL);
          end else begin
            `uvm_error("COMPARE_ERROR", $sformatf("[%s]: cmp-io: Item:\n%s\nfrom primary queue: %s not found in secondary queue: %s. Found this item in %s instead:\n%s", this.cfg.get_scb_name(), primary_item.sprint(), primary_queue_name, queue_names[i], queue_names[i], sih.sprint()))

            // The first element was not a match => break since this is an in order compare  
            break; 
          end
        end else begin
          `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: %s is empty - skipping", this.cfg.get_scb_name(), queue_names[i]), UVM_FULL);
        end

        if(!secondary_queue.delete_iterator(secondary_queue_iter)) begin
          `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to delete iterator from secondaery queue: %s", this.cfg.get_scb_name(), queue_names[i]));
        end
      end else begin
        `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: %s is the primary queue - skipping", this.cfg.get_scb_name(), queue_names[i]), UVM_FULL);
      end
    end

    // Only start to remove items if all slave items are found (One from each slave queue)
    if(secondary_item_found.size() == queue_names.size()-1) begin
      string queue_name;
      cl_syoscb_item pih;

      // Get the item from the primary queue
      pih = primary_queue_iter.get_item();

      `uvm_info("DEBUG", $sformatf("[%s]: cmp-io: Found match for primary queue item :\n%s", this.cfg.get_scb_name(), pih.sprint()), UVM_FULL);

      // Remove from primary
      if(!primary_queue.delete_item(primary_queue_iter.get_idx())) begin
        `uvm_error("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to delete item idx %0d from queue %s",
                                            this.cfg.get_scb_name(), primary_queue_iter.get_idx(), primary_queue.get_name()));
      end

      // Remove from all secondaries
      while(secondary_item_found.next(queue_name)) begin
        cl_syoscb_queue secondary_queue;

	// Get the secondary queue
        secondary_queue = this.cfg.get_queue(queue_name);

        if(secondary_queue == null) begin
          `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to retrieve secondary queue handle", this.cfg.get_scb_name()));
        end

        if(!secondary_queue.delete_item(secondary_item_found[queue_name])) begin
          `uvm_error("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to delete item idx %0d from queue %s",
                                              this.cfg.get_scb_name(), secondary_item_found[queue_name], secondary_queue.get_name()));
        end
      end
    end

    // Call .next() blindly since we do not care about the
    // return value, since we might be at the end of the queue.
    // Thus, .next() will return 1'b0 at the end of the queue
    void'(primary_queue_iter.next());
  end

  if(!primary_queue.delete_iterator(primary_queue_iter)) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io: Unable to delete iterator from primary queue: %s", this.cfg.get_scb_name(), primary_queue_name));
  end
endfunction: compare_do
