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
/// The UVM scoreboard item which wraps uvm_sequence_item . This ensures that future
/// extensions to the UVM scoreboard will always be able to use all uvm_sequence_items from
/// already existing testbenches etc. even though more META data is added to the wrapping item.
class cl_syoscb_item extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Name of the producer that generated this seq. item
  local string producer;

  /// Handle to the wrapped uvm_sequence_item
  local uvm_sequence_item item;

  /// Insertion index N means that this is the N'th item inserted in that queue
  local longint unsigned insertion_index;

  /// This item's position in the queue.
  /// This field is only valid when the queue is dumped, as a queue index may change
  /// throughout simulation as items ahead of this item are removed from the queue.
  local longint queue_index;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_item)
  `uvm_field_int(insertion_index, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK | UVM_DEC)
  `uvm_field_int(queue_index, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK | UVM_DEC)
    `ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
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
  function new(string name = "cl_syoscb_item");
    super.new(name);
  endfunction : new

  //-------------------------------------
  // Item API
  //-------------------------------------
  extern virtual function string            get_producer();
  extern virtual function void              set_producer(string producer);
  extern virtual function uvm_sequence_item get_item();
  extern virtual function void              set_item(uvm_sequence_item item);

  extern virtual function void              set_insertion_index(longint unsigned ii);
  extern virtual function longint unsigned  get_insertion_index();
  extern virtual function void              set_queue_index(longint qi);
  extern virtual function longint           get_queue_index();

  extern virtual function string            convert2string();

`ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
  //-------------------------------------
  // UVM TLM2 Generic Payload compare
  // workaround
  //-------------------------------------
  //If a miscompare happens when comparing two GP items, the miscompare is printed as a UVM_INFO
  //message by default and the comparison returns 1'b1, where it should return 1'b0;
  //To fix this, we manually compare the GP items as ordinary objects using comparer::compare_object.
  //This ensures that we properly raise a UVM_ERROR if the GP items are not the same.
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

/// <b>Item API:</b> Returns the producer of the wrapped sequence item
function string cl_syoscb_item::get_producer();
  return this.producer;
endfunction: get_producer

/// <b>Item API:</b> Sets the producer of the wrapped sequence item.
/// The validity of the producer name must be checked by the caller before setting it in this item.
/// \param producer The name of the producer of the wrapped seq. item.
function void cl_syoscb_item::set_producer(string producer);
  // The producer has been checked by the parent prior
  // to the insertion
  this.producer = producer;
endfunction: set_producer

/// <b>Item API:</b> Returns the wrapped uvm_sequence_item
function uvm_sequence_item cl_syoscb_item::get_item();
  return this.item;
endfunction: get_item

/// <b>Item API:</b> Sets the uvm_sequence_item wrapped by this wrapper item
function void cl_syoscb_item::set_item(uvm_sequence_item item);
  this.item = item;
endfunction: set_item

/// <b>Item API:</b> Gets the insertion index of the wrapped sequence item
function void cl_syoscb_item::set_insertion_index(longint unsigned ii);
  this.insertion_index = ii;
endfunction: set_insertion_index

/// <b>Item API:</b> Sets the insertion index of the wrapped sequence item
function longint unsigned cl_syoscb_item::get_insertion_index();
  return this.insertion_index;
endfunction: get_insertion_index

/// <b>Item API:</b> Sets the queue index of the wrapped sequence item
function void cl_syoscb_item::set_queue_index(longint qi);
  this.queue_index = qi;
endfunction: set_queue_index

/// <b>Item API:</b> Gets the queue index of the wrapped sequence item
function longint cl_syoscb_item::get_queue_index();
  return this.queue_index;
endfunction: get_queue_index

/// Converts a cl_syoscb_item to a compact string representation.
/// Does this by simply returning the convert2string-implementation of the wrapped sequence item.
/// \note Raises a warning if newlines are contained in the output, as this may make the output uglier
function string cl_syoscb_item::convert2string();
  string c2s;
  c2s = this.item.convert2string();

  //Check if newlines exist and a warning should be generated
  for(int i=0; i<c2s.len(); i++) begin
    if(c2s[i] == "\n") begin
      `uvm_warning("C2S_WARNING", $sformatf(
        {"The convert2string()-implementation of type %s contains newlines.\n",
         "Consider removing these for prettier scb dumps when cfg.enable_c2s_full_scb_dump is set."},
        this.item.get_type_name()))
      break;
    end
  end

  return c2s;
endfunction: convert2string