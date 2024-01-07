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
/// Proxy item implementation for standard queues.
/// Contains the index in the queue at which the item is located.
class cl_syoscb_proxy_item_std extends cl_syoscb_proxy_item_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Position in the queue
  int unsigned idx;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_proxy_item_std)
    `uvm_field_int(idx, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_proxy_item_std");

endclass: cl_syoscb_proxy_item_std

function cl_syoscb_proxy_item_std::new(string name = "cl_syoscb_proxy_item_std");
  super.new(name);
endfunction : new
