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
/// A "b" type item which used a field macros instead of manually implementing do_compare
class cl_tb_cmp_b_f_seq_item#(type TIOBJ = cl_tb_seq_item) extends cl_tb_cmp_seq_item_base#(TIOBJ);
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_tb_cmp_b_f_seq_item#(TIOBJ))
    `uvm_field_int(ival, UVM_ALL_ON)
    `uvm_field_object(iobj, UVM_ALL_ON)
    `uvm_field_array_int(ivals, UVM_ALL_ON)
    `uvm_field_array_object(iobjs, UVM_ALL_ON)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_cmp_b_f_seq_item");
    super.new(name);
  endfunction: new
endclass: cl_tb_cmp_b_f_seq_item