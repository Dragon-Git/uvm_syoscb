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
class cl_scbtest_seq_item extends uvm_sequence_item;
  //-------------------------------------
  // Randomizable variables
  //-------------------------------------
  rand int unsigned int_a;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_scbtest_seq_item)
    `uvm_field_int(int_a, UVM_ALL_ON)
  `uvm_object_utils_end

  extern function new (string name = "cl_scbtest_seq_item");
endclass: cl_scbtest_seq_item

function cl_scbtest_seq_item::new (string name = "cl_scbtest_seq_item");
   super.new(name);
endfunction
