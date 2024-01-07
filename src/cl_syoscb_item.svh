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
/// The UVM scoreboard item. This item wraps the uvm_sequence_items. This ensures that future
/// extensions to the UVM scoreboard will always be able to use all uvm_sqeuence_items from
/// already existing testbenches etc. even though more META data is added to the wrapping item.
class cl_syoscb_item extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Hold the name of the producer
  string producer;

  /// Handle to the wrapped uvm_sequence_item
  uvm_sequence_item item;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_item)
`ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
    // Use NOCOMPARE when do_compare is implemented. Otherwise the compare is done twice since
    // the super of uvm field automation is called before do_compare. This will invoke the compare
    // since the functions are virtual
    `uvm_field_string(producer, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_object(item,     UVM_DEFAULT | UVM_NOCOMPARE)
`else
    `uvm_field_string(producer, UVM_DEFAULT)
    `uvm_field_object(item,     UVM_DEFAULT)
`endif
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_item");

  //-------------------------------------
  // Item API
  //-------------------------------------
  extern function string get_producer();
  extern function void set_producer(string producer);
  extern function uvm_sequence_item get_item();
  extern function void set_item(uvm_sequence_item item);

`ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
  //-------------------------------------
  // UVM TLM2 Generic Payload compare
  // workaround
  //-------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    bit status = 1'b1;
    cl_syoscb_item that;
   
    // Code it properly using the comparer policy
    if(!$cast(that, rhs)) begin
      status = 1'b0;
    end else begin
      // "producer" compare using the comparer object
      status &= comparer.compare_string("producer", this.producer, that.producer);

      // Apply WORKAROUND:
      //   Ensure that the comparer object is properly updated at this level
      //   and propagate the compare result bit correctly
      status &= comparer.compare_object("item", this.item, that.item);
    end
    return(status);
  endfunction: do_compare
`endif
endclass: cl_syoscb_item

function cl_syoscb_item::new(string name = "cl_syoscb_item");
  super.new(name);
endfunction : new 	 

/// <b>Item API:</b> Returns the producer
function string cl_syoscb_item::get_producer();
  return(this.producer);
endfunction: get_producer

/// <b>Item API:</b> Sets the producer
function void cl_syoscb_item::set_producer(string producer);
  // The producer has been checked by the parent prior
  // to the insertion
  this.producer = producer;
endfunction: set_producer

/// <b>Item API:</b> Returns the wrapped uvm_sequence_item
function uvm_sequence_item cl_syoscb_item::get_item();
  return(this.item);
endfunction: get_item

/// <b>Item API:</b> Sets the to be wrapped uvm_sequence_item
function void cl_syoscb_item::set_item(uvm_sequence_item item);
  this.item = item;
endfunction: set_item
