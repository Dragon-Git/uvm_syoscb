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
/// Class which base concet of a queue. All queues must extend this class
/// and implement the queue API.
class cl_syoscb_queue extends uvm_component;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration
  protected cl_syoscb_cfg cfg;

  /// List of iterators registered with queue
  protected cl_syoscb_queue_iterator_base iterators[cl_syoscb_queue_iterator_base];

  /// Current number of iterators
  protected int unsigned iter_idx;

  /// Semaphore guarding exclusive access to the queue when
  /// multiple iterators are in play
  protected semaphore iter_sem;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_queue)
    `uvm_field_object(cfg,           UVM_DEFAULT)
    // TBD::JSA: Lacks a user defined implementation of field macro
    //           for completeness since: `uvm_field_aa_object-object does not exist
    `uvm_field_int(iter_idx,         UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void check_phase(uvm_phase phase);

  //-------------------------------------
  // Queue API
  //-------------------------------------
  // Basic queue functions
  extern virtual function bit add_item(string producer, uvm_sequence_item item);
  extern virtual function bit delete_item(int unsigned idx);
  extern virtual function cl_syoscb_item get_item(int unsigned idx);
  extern virtual function int unsigned get_size();
  extern virtual function bit empty();
  extern virtual function bit insert_item(string producer, uvm_sequence_item item, int unsigned idx);

  // Iterator support functions
  extern virtual function cl_syoscb_queue_iterator_base create_iterator();
  extern virtual function bit delete_iterator(cl_syoscb_queue_iterator_base iterator);

  // Locator support functions
  // TBD::JSA: Locator not implemented yet
endclass: cl_syoscb_queue

function cl_syoscb_queue::new(string name, uvm_component parent);
  super.new(name, parent);

  this.iter_sem = new(1);
  this.iter_idx = 0;
endfunction: new

/// Gets the global scoreboard configuration
function void cl_syoscb_queue::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", "Configuration object not passed.")
  end
endfunction

/// Checks if the queue is empty. If not then a UVM error is issued.
function void cl_syoscb_queue::check_phase(uvm_phase phase);
  // Check that this queue is empty. If not then issue an error
  if(!this.empty()) begin
    `uvm_error("QUEUE_ERROR", $psprintf("Queue %s not empty, entries: %0d", this.get_name(), this.get_size()));
  end
endfunction

/// <b>Queue API:</b> Adds an uvm_sequence_item. The implementation must wrap this in a
/// cl_syoscb_item object before the item is inserted
function bit cl_syoscb_queue::add_item(string producer, uvm_sequence_item item);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::add_item() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Queue API:</b> Deletes the item at index idx from the queue
function bit cl_syoscb_queue::delete_item(int unsigned idx);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::delete_item() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Queue API:</b> Gets the item at index idx from the queue
function cl_syoscb_item cl_syoscb_queue::get_item(int unsigned idx);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::get_item() *MUST* be overwritten"));
  return(null);
endfunction

/// <b>Queue API:</b> Returns the current size of the queue
function int unsigned cl_syoscb_queue::get_size();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::get_size() *MUST* be overwritten"));
  return(0);
endfunction

/// <b>Queue API:</b> Returns whether or not the queue is empty. 1'b0 means thet te queue
/// is not empty. 1'b1 means that the queue is empty
function bit cl_syoscb_queue::empty();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::empty() *MUST* be overwritten"));
  return(0);
endfunction

/// <b>Queue API:</b> Inserts a uvm_sequence_item at index idx. The implementation must wrap
/// the uvm_sequence_item in a cl_syoscb_item before it is inserted.
function bit cl_syoscb_queue::insert_item(string producer, uvm_sequence_item item, int unsigned idx);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::insert_item() *MUST* be overwritten"));
  return(1'b0);
endfunction

/// <b>Queue API:</b> Creates an iterator for this queue.
function cl_syoscb_queue_iterator_base cl_syoscb_queue::create_iterator();
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::create_iterator() *MUST* be overwritten"));
  return(null);
endfunction

/// <b>Queue API:</b> Deletes a given iterator for this queue.
function bit cl_syoscb_queue::delete_iterator(cl_syoscb_queue_iterator_base iterator);
  `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_queue::delete_item() *MUST* be overwritten"));
  return(1'b0);
endfunction
