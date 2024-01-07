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
///Base class for wrapping an array of some type.
class cl_tb_arr_wrapper#(type T = cl_tb_seq_item) extends uvm_object;
  //-------------------------------------
  // Parameters
  //-------------------------------------
  localparam max_size = 50;
  //-------------------------------------
  // Member variables
  //-------------------------------------
  rand T items[];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_tb_arr_wrapper#(T))
    `uvm_field_array_object(items, UVM_ALL_ON)
  `uvm_object_utils_end

  //-------------------------------------
  // Constraints
  //-------------------------------------
  constraint co_array_size {
    this.items.size() >= 1;
    this.items.size() <= max_size;
  }

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_arr_wrapper");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern function void pre_randomize();

endclass: cl_tb_arr_wrapper

function void cl_tb_arr_wrapper::pre_randomize();
  items = new[max_size];
  foreach(this.items[i]) begin
    this.items[i] = T::type_id::create($sformatf("items_%0d", i));
  end
endfunction: pre_randomize