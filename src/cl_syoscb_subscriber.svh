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
/// Generic subscriber for the scoreboard. It provides the write method
/// for UVM monitors and utilizes the function based API of the scoreboard to insert
/// the items received through the write method.
class cl_syoscb_subscriber extends uvm_subscriber#(uvm_sequence_item);
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// The name of the queue this subscriber writes data to
  local string queue_name;
  /// The name of the producer that this is subscribed to
  local string producer;
  /// Whether to use mutexed add_item calls (1) or non-mutexed (0)
  local bit mutexed_add_item_enable = 1'b0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_subscriber)
    `uvm_field_string(queue_name, UVM_DEFAULT);
    `uvm_field_string(producer,   UVM_DEFAULT);
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_subscriber", uvm_component parent = null);

  //-------------------------------------
  // UVM overwrites/extensions
  //-------------------------------------
  extern function void write(uvm_sequence_item t);

  //-------------------------------------
  // Subscriber API
  //-------------------------------------
  extern virtual function string get_queue_name();
  extern virtual function void   set_queue_name(string qn);
  extern virtual function string get_producer();
  extern virtual function void   set_producer(string p);
  extern virtual function void   set_mutexed_add_item_enable(bit maie);
endclass: cl_syoscb_subscriber

function cl_syoscb_subscriber::new(string name = "cl_syoscb_subscriber", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

/// Implementation of the write method which must be implemented when extending uvm_subscriber.
function void cl_syoscb_subscriber::write(uvm_sequence_item t);
  cl_syoscb parent;

  // Get the parent which is the SCB top
  // This is needed for access to the function based API
  begin
    uvm_component tmp_parent;

    tmp_parent = this.get_parent();

    if(!$cast(parent, tmp_parent)) begin
      // *NOTE*: Here the parent cannot be cast. Thus, the print cannot contain the SCB name
      `uvm_fatal("IMPL_ERROR", "Unable to cast parent of subscriber");
    end
  end

  `uvm_info("DEBUG", $sformatf("Trigger add_item by subscriber: %s (Queue: %s, Producer: %s)", this.get_name(), this.queue_name, this.producer), UVM_FULL);

  // Add the item to the queue
  if(this.mutexed_add_item_enable) begin
    fork
      parent.add_item_mutexed(this.queue_name, this.producer, t);
    join_none
  end else begin
    parent.add_item(this.queue_name, this.producer, t);
  end
endfunction

/// <b>Subscriber API</b>: Returns the name of the queue which this subscriber is connected to.
function string cl_syoscb_subscriber::get_queue_name();
  return(this.queue_name);
endfunction: get_queue_name

/// <b>Subscriber API</b>: Sets the name of the queue which this subscriber is connected to.
function void cl_syoscb_subscriber::set_queue_name(string qn);
  this.queue_name = qn;
endfunction: set_queue_name

/// <b>Subscriber API</b>: Returns the name of the produer which this subscriber is connected to.
function string cl_syoscb_subscriber::get_producer();
  return(this.producer);
endfunction: get_producer

/// <b>Subscriber API</b>: Sets the name of the producer which this subscriber is connected to.
function void cl_syoscb_subscriber::set_producer(string p);
  this.producer = p;
endfunction: set_producer

/// <b>Subscriber API</b>: Controls whether items should be added in a mutexed fashion or not.
/// Must be called during cl_syoscb#build_phase
function void cl_syoscb_subscriber::set_mutexed_add_item_enable(bit maie);
  this.mutexed_add_item_enable = maie;
endfunction: set_mutexed_add_item_enable