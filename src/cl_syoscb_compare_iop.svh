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
// Class which implements the in order by producer compare algorithm
class cl_syoscb_compare_iop extends cl_syoscb_compare_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_compare_iop)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_iop");

  //-------------------------------------
  // Compare API
  //-------------------------------------
  extern virtual function void compare();
  extern function void compare_do();
endclass: cl_syoscb_compare_iop

function cl_syoscb_compare_iop::new(string name = "cl_syoscb_compare_iop");
  super.new(name);
endfunction: new

/// <b>Compare API</b>: Mandatory overwriting of the base class' compare method.
/// Currently, this just calls do_copy() blindly 
function void cl_syoscb_compare_iop::compare();
  // Here any state variables should be queried
  // to compute if the compare should be done or not
  this.compare_do();
endfunction: compare

/// <b>Compare API</b>: Mandatory overwriting of the base class' do_compare method.
/// Here the actual out of order compare is implemented.
///
/// The algorithm gets the primary queue and then loops over all other queues to see if
/// it can find the primary item as the first item of the same producer in all of the other queues.
/// If so then the items are removed from all queues. If not then nothing is done. Thus, if some items are not
/// matched then the result is that the queue will be non-empty at the end of simulation.
/// This will then be caught by the check_phase.
function void cl_syoscb_compare_iop::compare_do();
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
    `uvm_fatal("QUEUE_ERROR", "Unable to retrieve primary queue handle");
  end

  primary_queue_iter = primary_queue.create_iterator();

  `uvm_info("DEBUG", $sformatf("cmp-iop: primary queue: %s", primary_queue_name), UVM_FULL);
  `uvm_info("DEBUG", $sformatf("cmp-iop: number of queues: %0d", queue_names.size()), UVM_FULL);

  // Outer loop loops through all
  while (!primary_queue_iter.is_done()) begin
    primary_item = primary_queue_iter.get_item();

    `uvm_info("DEBUG", $sformatf("Now comparing primary transaction:\n%s", primary_item.sprint()), UVM_FULL); 

    // Clear list of found slave items before starting new inner loop
    secondary_item_found.delete();

    // Inner loop through all queues
    foreach(queue_names[i]) begin
      `uvm_info("DEBUG", $sformatf("Looking at queue: %s", queue_names[i]), UVM_FULL);

      if(queue_names[i] != primary_queue_name) begin
        cl_syoscb_queue secondary_queue;
        cl_syoscb_queue_iterator_base secondary_queue_iter;

        `uvm_info("DEBUG", $sformatf("%s is a secondary queue - now comparing", queue_names[i]), UVM_FULL);

        // Get the secondary queue
        secondary_queue = this.cfg.get_queue(queue_names[i]);

        if(secondary_queue == null) begin
          `uvm_fatal("QUEUE_ERROR", "Unable to retrieve secondary queue handle");
        end

        `uvm_info("DEBUG", $sformatf("%0d items in queue: %s", secondary_queue.get_size(), queue_names[i]), UVM_FULL);

        // Get an iterator for the secondary queue
        secondary_queue_iter = secondary_queue.create_iterator();

        // Only the first match is removed
        while(!secondary_queue_iter.is_done()) begin
          // Get the item from the secondary queue
          cl_syoscb_item sih = secondary_queue_iter.get_item();

          // Only do the compare if the producers match
          if(primary_item.get_producer == sih.get_producer()) begin
            if(sih.compare(primary_item) == 1'b1) begin
              secondary_item_found[queue_names[i]] = secondary_queue_iter.get_idx();
              `uvm_info("DEBUG", $sformatf("Secondary item found at index: %0d:\n%s", secondary_queue_iter.get_idx(), sih.sprint()), UVM_FULL);
              break;
            end else begin
              `uvm_error("COMPARE_ERROR", $sformatf("Item:\n%s\nfrom primary queue: %s not found in secondary queue: %s. Found this item in %s instead:\n%s", primary_item.sprint(), primary_queue_name, queue_names[i], queue_names[i], sih.sprint()))
            end
          end

          if(!secondary_queue_iter.next()) begin
            `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to get next element from iterator on secondary queue: %s", queue_names[i]));
          end	  
        end
        if(!secondary_queue.delete_iterator(secondary_queue_iter)) begin
          `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to delete iterator from secondaery queue: %s", queue_names[i]));
        end
      end else begin
        `uvm_info("DEBUG", $sformatf("%s is the primary queue - skipping", queue_names[i]), UVM_FULL);
      end
    end

    // Only start to remove items if all slave items are found (One from each slave queue)
    if(secondary_item_found.size() == queue_names.size()-1) begin
      string queue_name;
      cl_syoscb_item pih;

      // Get the item from the primary queue
      pih = primary_queue_iter.get_item();

      `uvm_info("DEBUG", $sformatf("Found match for primary queue item :\n%s",
                                   pih.sprint()), UVM_FULL);

      // Remove from primary
      if(!primary_queue.delete_item(primary_queue_iter.get_idx())) begin
        `uvm_error("QUEUE_ERROR", $sformatf("Unable to delete item idx %0d from queue %s",
                                            primary_queue_iter.get_idx(), primary_queue.get_name()));
      end

      // Remove from all secondaries
      while(secondary_item_found.next(queue_name)) begin
        cl_syoscb_queue secondary_queue;

        // Get the secondary queue
        secondary_queue = this.cfg.get_queue(queue_name);

        if(secondary_queue == null) begin
          `uvm_fatal("QUEUE_ERROR", "Unable to retrieve secondary queue handle");
        end

        if(!secondary_queue.delete_item(secondary_item_found[queue_name])) begin
          `uvm_error("QUEUE_ERROR", $sformatf("Unable to delete item idx %0d from queue %s",
                                              secondary_item_found[queue_name], secondary_queue.get_name()));
        end
      end
    end

    // Call .next() blindly since we do not care about the
    // return value, since we might be at the end of the queue.
    // Thus, .next() will return 1'b0 at the end of the queue
    void'(primary_queue_iter.next());
  end

  if(!primary_queue.delete_iterator(primary_queue_iter)) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to delete iterator from primary queue: %s", primary_queue_name));
  end
endfunction: compare_do
