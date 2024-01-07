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
/// Top level class implementing the root of the SyoSil UVM scoreboard
class cl_syoscb extends uvm_scoreboard;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the global UVM scoreboard configuration
  local cl_syoscb_cfg cfg;

  /// Array holding handles to all queues
  local cl_syoscb_queue queues[];

  // Handle to the compare startegy
  local cl_syoscb_compare compare_strategy;

  // Assoc array holding each uvm_subscriber
  local cl_syoscb_subscriber subscribers[string];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb)
    `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_field_array_object(queues, UVM_ALL_ON)
    `uvm_field_object(compare_strategy, UVM_ALL_ON)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);

  //-------------------------------------
  // Function based API
  //-------------------------------------
  extern function void add_item(string queue_name, string producer, uvm_sequence_item item);
  extern function void compare();

  //-------------------------------------
  // Transaction based API
  //-------------------------------------
  extern function cl_syoscb_subscriber get_subscriber(string queue_name, string producer);
endclass: cl_syoscb

function cl_syoscb::new(string name = "cl_syoscb", uvm_component parent = null);
   super.new(name, parent);
endfunction : new

/// The build_phase gets the scoreboard configuration and forwards it to the child components (cl_syoscb_queue
/// and cl_syoscb_compare). Additionally, it creates all of the queues defined in the configuration object. Finally,
/// it also creates the compare strategy via a factory create call.
function void cl_syoscb::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", "Configuration object not passed.")
  end

  // Create list of queues
  this.queues = new[this.cfg.size_queues()];

  // Create the queues as defined in the configuration
  begin
    string queue_names[];

    // Get teh list of queue names
    this.cfg.get_queues(queue_names);

    foreach(queue_names[i]) begin
      this.queues[i] = cl_syoscb_queue::type_id::create(queue_names[i], this);
      this.cfg.set_queue(queue_names[i], this.queues[i]);

      // Forward the configuration to the queue
      uvm_config_db #(cl_syoscb_cfg)::set(this, queue_names[i], "cfg", this.cfg); 
    end
  end

  // Forward the configuration to the compare_strategy
  uvm_config_db #(cl_syoscb_cfg)::set(this, "compare_strategy", "cfg", this.cfg); 

  // Create the compare strategy
  this.compare_strategy = cl_syoscb_compare::type_id::create(.name("compare_strategy"), .parent(this));

  begin
    cl_syoscb_report_catcher catcher = new();
    uvm_report_cb::add(null, catcher);
  end

  begin
    string producers[];

    this.cfg.get_producers(producers);

    foreach(producers[i]) begin
      cl_syoscb_cfg_pl pl = this.cfg.get_producer(producers[i]);

      foreach(pl.list[j]) begin
        cl_syoscb_subscriber subscriber;

        subscriber = new({producers[i], "_", pl.list[j], "_subscr"}, this);
        subscriber.set_queue_name(pl.list[j]);
        subscriber.set_producer(producers[i]);
        this.subscribers[{pl.list[j], producers[i]}] = subscriber;
      end
    end
  end
endfunction: build_phase

/// Method for adding a uvm_sequence_item to a given queue for a given producer.
/// The method will check if the queue and producer exists before adding it to the queue.
/// 
/// The uvm_sequence_item will be wrapped by a cl_syoscb_item along with some META data
/// Thus, it is the cl_syoscb_item which will be added to the queue and not the uvm_sequence_item
/// directly.
///
/// This ensures that the scoreboard can easily be added to an existing testbench with already defined
/// sequence items etc.
function void cl_syoscb::add_item(string queue_name, string producer, uvm_sequence_item item);
  uvm_sequence_item item_clone;

  // Check queue
  if(!this.cfg.exist_queue(queue_name)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("Queue: %0s is not found", queue_name));
  end

  // Check producer
  if(!this.cfg.exist_producer(producer)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("Producer: %0s is not found", producer));
  end

  // Clone the item if not disabled
  // Clone the item in order to isolate the UVM scb from the rest of the TB
  if(this.cfg.get_disable_clone() == 1'b0) begin
    if(!$cast(item_clone, item.clone())) begin
      `uvm_fatal("QUEUE_ERROR", "Unable to cast cloned item to uvm_sequence_item");
    end
  end else begin
    item_clone = item;
  end

  // Add the uvm_sequence_item to the queue for the given producer
  begin
    cl_syoscb_queue queue;

    queue = this.cfg.get_queue(queue_name);
   
    if(queue == null) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("Queue: %s not found by add_item method", queue_name));
    end

    if(!queue.add_item(producer, item_clone)) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to add item to queue: %s", queue_name));
    end
  end

  // Invoke the compare algorithm
  void'(this.compare());
endfunction: add_item

/// Invokes the compare strategy
function void cl_syoscb::compare();
  this.compare_strategy.compare();
endfunction: compare

/// Returns a UVM subscriber for a given combination of queue and producer
/// The retrurned UVM subscriber can then be connected to a UVM monitor or similar
/// which produces transactions which should be scoreboarded.
function cl_syoscb_subscriber cl_syoscb::get_subscriber(string queue_name, string producer);
    return(this.subscribers[{queue_name, producer}]);
endfunction: get_subscriber
