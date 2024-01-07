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
/// Utility class for capturing the queue names associated with a producer
class cl_syoscb_cfg_pl extends uvm_object;
  //-------------------------------------
  // Non randomizable member variables
  //-------------------------------------
  /// The list of queue names connected to the producer that this _pl represents
  string list[];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_cfg_pl)
    `uvm_field_array_string(list, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_cfg_pl");

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function void set_list(string list[]);
  extern virtual function bit  exists(string queue);
endclass: cl_syoscb_cfg_pl

function cl_syoscb_cfg_pl::new(string name = "cl_syoscb_cfg_pl");
   super.new(name);
endfunction : new

/// Sets the list of queue names associated with a producer
function void cl_syoscb_cfg_pl::set_list(string list[]);
   this.list = list;
endfunction: set_list

/// Checks whether a given queue is connected to the producer that this object represents
/// \param queue The name of the queue to check
function bit cl_syoscb_cfg_pl::exists(string queue);
  string exists_queue[$];

  exists_queue = this.list.find(x) with (x == queue);

  return exists_queue.size() == 1 ? 1 : 0;
endfunction: exists
