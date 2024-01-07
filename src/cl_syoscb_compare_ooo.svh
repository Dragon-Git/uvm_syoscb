//----------------------------------------------------------------------
//   Copyright 2014 SyoSil ApS
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
class cl_syoscb_compare_ooo extends cl_syoscb_compare_base;
  `uvm_object_utils(cl_syoscb_compare_ooo)

  // TBD: max_search_window for OOO compare?

  extern function new(string name = "cl_syoscb_compare_ooo");
  extern virtual function bit compare();
  extern function bit compare_do();

endclass: cl_syoscb_compare_ooo

function cl_syoscb_compare_ooo::new(string name = "cl_syoscb_compare_ooo");
  super.new(name);
endfunction: new

function bit cl_syoscb_compare_ooo::compare();
  // Here any state variables should be queried
  // to compute if the compare should be done or not
  return(this.compare_do());
endfunction: compare

function bit cl_syoscb_compare_ooo::compare_do();
  string primary_queue_name;
  cl_syoscb_queue primary_queue;
  cl_syoscb_queue_iterator_base primary_queue_iter;
  string queue_names[];
  int unsigned secondary_item_found[string];
  bit compare_continue = 1'b1;
  bit compare_result = 1'b0;
  uvm_sequence_item primary_item;

  primary_queue_name = this.get_primary_queue_name();
  this.get_cfg.get_queues(queue_names);

  `uvm_info("DEBUG", $sformatf("cmp-ooo: primary queue: %s", primary_queue_name), UVM_FULL);
  `uvm_info("DEBUG", $sformatf("cmp-ooo: number of queues: %0d", queue_names.size()), UVM_FULL);

  if(!$cast(primary_queue, this.get_cfg().queues[primary_queue_name])) begin
    `uvm_fatal("TYPE_ERROR", $sformatf("Unable to cast type %0s to type %0s",
                                       this.get_cfg().queues[primary_queue_name].get_type_name(),
                                       primary_queue.get_type_name()));
  end

  primary_queue_iter = primary_queue.create_iterator();

  // Outer loop loops through all
  while (!primary_queue_iter.is_done()) begin
    primary_item = primary_queue_iter.get_item();

    // Inner loop through all queues
    foreach(queue_names[i]) begin
      `uvm_info("DEBUG", $sformatf("Looking at queue: %s", queue_names[i]), UVM_FULL);

      if(queue_names[i] != primary_queue_name) begin
        cl_syoscb_queue secondary_queue;
        cl_syoscb_queue_iterator_base secondary_queue_iter;

        `uvm_info("DEBUG", $sformatf("%s is a secondary queue - now comparing", queue_names[i]), UVM_FULL);

        if(!$cast(secondary_queue, this.get_cfg().queues[queue_names[i]])) begin
          `uvm_fatal("TYPE_ERROR", $sformatf("Unable to cast type %0s to type %0s",
                                             this.get_cfg().queues[primary_queue_name].get_type_name(),
                                             primary_queue.get_type_name()));
        end
        secondary_queue_iter = secondary_queue.create_iterator();

        // Only the first match is removed
        while(!secondary_queue_iter.is_done()) begin
          if(secondary_queue_iter.get_item().compare(primary_item) == 1'b1) begin
            secondary_item_found[queue_names[i]] = secondary_queue_iter.get_idx();
            `uvm_info("DEBUG", $sformatf("Secondary item found at index: %0d", secondary_queue_iter.get_idx()),
                      UVM_FULL);
            break;
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

    if(secondary_item_found.size() != 0) begin
      string queue_name;
      `uvm_info("DEBUG", $sformatf("Found match for primary queue item : %s",
                                   primary_queue_iter.get_item().sprint()), UVM_FULL);

      // Remove from primary
      if(!primary_queue.delete_item(primary_queue_iter.get_idx())) begin
        `uvm_error("QUEUE_ERROR", $sformatf("Unable to delete item idx %0d from queue %s",
                                            primary_queue_iter.get_idx(), primary_queue.get_name()));
      end

      // Remove from all secondaries
      while(secondary_item_found.next(queue_name)) begin
        cl_syoscb_queue secondary_queue;

        if(!$cast(secondary_queue, this.get_cfg().queues[queue_name])) begin
          `uvm_fatal("TYPE_ERROR", $sformatf("Unable to cast type %0s to type %0s",
                                             this.get_cfg().queues[primary_queue_name].get_type_name(),
                                             primary_queue.get_type_name()));
        end
        if(!secondary_queue.delete_item(secondary_item_found[queue_name])) begin
          `uvm_error("QUEUE_ERROR", $sformatf("Unable to delete item idx %0d from queue %s",
                                              secondary_item_found[queue_name], secondary_queue.get_name()));
        end
      end
    end

    if(!primary_queue_iter.next()) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to get next element from iterator on parimary queue: %s", primary_queue_name));
    end
  end

  if(!primary_queue.delete_iterator(primary_queue_iter)) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to delete iterator from primary queue: %s", primary_queue_name));
  end

  // TBD: See note in cl_scbsyo_compare_base.svh
  return(1'b1);
endfunction : compare_do