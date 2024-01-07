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
/// A utility class used to wrap cl_syoscb_item objects when when using hash queues.
/// In case of a hash collision, this class contains a queue of all items with the same hash
class cl_syoscb_hash_item extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Queue of cl_syoscb_item with the same hash
  local cl_syoscb_item items[$];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_hash_item)
    `uvm_field_queue_object(items, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_hash_item");
    super.new(name);
  endfunction : new

  //-------------------------------------
  // Item API
  //-------------------------------------
  extern virtual function cl_syoscb_item get_item(int unsigned idx = 0);
  extern virtual function void           add_item(cl_syoscb_item item);
  extern virtual function int unsigned   get_size();
  extern virtual function void           delete_item(int unsigned idx = 0);
endclass: cl_syoscb_hash_item

/// <b>Item API:</b> Returns an item from this hash item's queue
/// If called without parameters, returns the first item from the queue
/// If idx is not a valid index in the queue, raises a UVM_WARNING and returns null
///
/// \param idx The index to access. Defaults to 0
/// \return    The item at that index, or null if no items exist / the index is invalid
function cl_syoscb_item cl_syoscb_hash_item::get_item(int unsigned idx = 0);
  if(idx >= this.items.size()) begin
    `uvm_warning("HASH_ERROR", $sformatf("No item at index %0d in hash item, size of hash item queue is %0d", idx, this.items.size()))
    return null;
  end else if (this.items.size() == 0) begin
    return null;
  end else begin
    return this.items[idx];
  end
endfunction: get_item

/// <b>Item API:</b> Adds an item to this hash item
/// \param item The item to add
function void cl_syoscb_hash_item::add_item(cl_syoscb_item item);
  this.items.push_back(item);
endfunction: add_item

/// <b>Item API:</b> Returns the number of items stored in this hash item
function int unsigned cl_syoscb_hash_item::get_size();
  return this.items.size();
endfunction: get_size

/// <b>Item API:</b> Deletes an item from this hash item
///
/// \param idx The index of the item to delete. If index is out range,
///            generates a UVM_ERROR
function void cl_syoscb_hash_item::delete_item(int unsigned idx = 0);
  if(idx >= this.items.size()) begin
    `uvm_error("HASH_ERROR", $sformatf("Cannot delete item at index %0d, out of range (only %0d items in hash item)", idx, this.items.size()))
  end else begin
    this.items.delete(idx);
  end
endfunction: delete_item
