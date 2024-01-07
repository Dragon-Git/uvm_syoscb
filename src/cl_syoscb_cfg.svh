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
/// Configuration class for the SyoSil UVM scoreboard
class cl_syoscb_cfg extends uvm_object;
  //---------------------------------
  // Non randomizable member variables
  //---------------------------------
  /// Associative array holding handles to each queue. Indexed by queue name
  local cl_syoscb_queue  queues[string];

  /// Associative array indexed by producer name. Returns the list of queues which
  /// this producer is related to.
  local cl_syoscb_cfg_pl producers[string];
  local string           primary_queue;

  /// 1'b0 => Calls to cl_syoscb::add_item will clone the uvm_sequence_item
  /// 1'b1 => Calls to cl_syoscb::add_item will not clone the uvm_sequence_item
  local bit disable_clone = 1'b0;

  /// Maximum number of elements in each queue before an error is signalled. 0 means no limit (default)
  local int unsigned     max_queue_size[string];

// TBD::JSA   local bit              full_scb_dump;
// TBD::JSA   local int unsigned     full_max_queue_size[string];
// TBD::JSA   local string           full_scb_type[];
// TBD::JSA   local int unsigned     item_time_out_queue[string];
// TBD::JSA   local int unsigned     item_time_out_producer[string];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_cfg)
    `uvm_field_aa_object_string(queues,      UVM_DEFAULT)
    `uvm_field_aa_object_string(producers,   UVM_DEFAULT)
    `uvm_field_string(primary_queue,         UVM_DEFAULT) 
    `uvm_field_int(disable_clone,            UVM_DEFAULT)
    `uvm_field_aa_int_string(max_queue_size, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_cfg");

  //-------------------------------------
  // Configuration API
  //-------------------------------------
  extern function cl_syoscb_queue get_queue(string queue_name);
  extern function void set_queue(string queue_name, cl_syoscb_queue queue);
  extern function void get_queues(output string queue_names[]);
  extern function void set_queues(string queue_names[]);
  extern function bit exist_queue(string queue_name);
  extern function int unsigned size_queues();
  extern function cl_syoscb_cfg_pl get_producer(string producer);
  extern function bit set_producer(string producer, queue_names[]);
  extern function bit exist_producer(string producer);
  extern function void get_producers(output string producers[]);
  extern function string get_primary_queue();
  extern function bit set_primary_queue(string primary_queue_name);
  extern function void set_disable_clone(bit dc);
  extern function bit get_disable_clone();
  extern function void set_max_queue_size(string queue_name, int unsigned mqs);
  extern function int unsigned get_max_queue_size(string queue_name);
endclass : cl_syoscb_cfg

function cl_syoscb_cfg::new(string name = "cl_syoscb_cfg");
  super.new(name);
endfunction: new

/// <b>Configuration API:</b> Returns a queue handle for the specificed queue
function cl_syoscb_queue cl_syoscb_cfg::get_queue(string queue_name);
  // If queue does not exist then return NULL
  if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("Queue: %0s is not found", queue_name), UVM_DEBUG);
    return(null);
  end

  return(this.queues[queue_name]);
endfunction: get_queue

/// <b>Configuration API:</b> Sets the queue object for a given queue
function void cl_syoscb_cfg::set_queue(string queue_name, cl_syoscb_queue queue);
  this.queues[queue_name] = queue;
endfunction: set_queue

/// <b>Configuration API:</b> Returns all queue names a string list
function void cl_syoscb_cfg::get_queues(output string queue_names[]);
  string queue_name;
  int    unsigned idx = 0;

  queue_names = new[this.queues.size()];

  while(this.queues.next(queue_name)) begin
    queue_names[idx++] = queue_name;
  end
endfunction: get_queues

/// <b>Configuration API:</b> Will set the legal queues when provides with a list of queue names.
/// An example could be: set_queues({"Q1", "Q2"})
/// Will set the max_queue_size for each queue to 0 (no limit) as default
function void cl_syoscb_cfg::set_queues(string queue_names[]);
  foreach(queue_names[i]) begin
    this.queues[queue_names[i]] = null;

    // Set default max queue size to no limit
    this.max_queue_size[queue_names[i]] = 0;
  end
endfunction: set_queues

/// <b>Configuration API:</b> Returns 1'b0 if the queue does not exist and 1'b1 if it exists
function bit cl_syoscb_cfg::exist_queue(string queue_name);
  return(this.queues.exists(queue_name)==0 ? 1'b0 : 1'b1);
endfunction

/// <b>Configuration API:</b> Returns the number of queues
function int unsigned cl_syoscb_cfg::size_queues();
  return(this.queues.size());
endfunction

/// <b>Configuration API:</b> Gets the given producer object for a specified producer
function cl_syoscb_cfg_pl cl_syoscb_cfg::get_producer(string producer);
  if(this.exist_producer(producer)) begin
    return(this.producers[producer]);
  end else begin
    `uvm_info("CFG_ERROR", $sformatf("Unable to get producer: %s", producer), UVM_DEBUG);
    return(null);
  end
endfunction: get_producer

/// <b>Configuration API:</b> Sets the given producer for the listed queues
function bit cl_syoscb_cfg::set_producer(string producer, queue_names[]);
  cl_syoscb_cfg_pl prod_list;

  // Check that all queues exists
  begin
    bit unique_queue_name[string];

    foreach (queue_names[i]) begin
      if(!unique_queue_name.exists(queue_names[i])) begin
        unique_queue_name[queue_names[i]] = 1'b1;
      end else begin
        `uvm_info("CFG_ERROR", $sformatf("Unable to set producer: %s. List of queue names contains dublicates", producer), UVM_DEBUG);
        return(1'b0);
      end

      // If queue does not exist then return 1'b0
      if(!this.exist_queue(queue_names[i])) begin
        `uvm_info("CFG_ERROR", $sformatf("Queue: %0s is not found", queue_names[i]), UVM_DEBUG);
        return(1'b0);
      end
    end
  end

  // All queues exist -> set the producer
  prod_list = new();                    // Create producer list
  prod_list.set_list(queue_names);      // Set queue names in producer list
  this.producers[producer] = prod_list; // Set producer list for producer

  // Return 1'b1 since all is good
  return(1'b1);
endfunction: set_producer

/// <b>Configuration API:</b> Checks if a given producer exists
function bit cl_syoscb_cfg::exist_producer(string producer);
  return(this.producers.exists(producer)==0 ? 1'b0 : 1'b1);
endfunction

/// <b>Configuration API:</b> Returns all producers as string list
function void cl_syoscb_cfg::get_producers(output string producers[]);
  string producer;
  int    unsigned idx = 0;

  producers = new[this.producers.size()];

  while(this.producers.next(producer)) begin
    producers[idx++] = producer;
  end
endfunction: get_producers

/// <b>Configuration API:</b> Gets the primary queue.
/// The primary queue is used by the compare algorithms to select which queue to use as the primary one.
function string cl_syoscb_cfg::get_primary_queue();
  return(this.primary_queue);
endfunction: get_primary_queue

/// <b>Configuration API:</b> Sets the primary queue.
/// The primary queue is used by the compare algorithms to select which queue to use as the primary one.
function bit cl_syoscb_cfg::set_primary_queue(string primary_queue_name);
  // If queue does not exist then return 1'b0
  if(!this.exist_queue(primary_queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("Queue: %0s is not found", primary_queue_name), UVM_DEBUG);
    return(1'b0);
  end

  // Set the primary queue
  this.primary_queue = primary_queue_name;

  // Return 1'b1 since all is good
  return(1'b1);
endfunction: set_primary_queue

/// <b>Configuration API:</b> Set the value of the disable_clone member variable
function void cl_syoscb_cfg::set_disable_clone(bit dc);
  this.disable_clone = dc;
endfunction

/// <b>Configuration API:</b> Get the value of the disable_clone member variable
function bit cl_syoscb_cfg::get_disable_clone();
  return(this.disable_clone);
endfunction

/// <b>Configuration API:</b> Set the maximum number of items allowed for a given queue.
/// 0 (no limit) is default
function void cl_syoscb_cfg::set_max_queue_size(string queue_name, int unsigned mqs);
  if(this.exist_queue(queue_name)) begin
    this.max_queue_size[queue_name] = mqs;
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("Queue: %s not found when trying to set max_queue_size", queue_name))  
  end
endfunction

/// <b>Configuration API:</b> Returns the maximum number of allowed items for a given queue.
/// 0 (no limit) is default
function int unsigned cl_syoscb_cfg::get_max_queue_size(string queue_name);
  if(this.exist_queue(queue_name)) begin
    return(this.max_queue_size[queue_name]);
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("Queue: %s not found when trying to get max_queue_size", queue_name))
    return(0);
  end
endfunction
