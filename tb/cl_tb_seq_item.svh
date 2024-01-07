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
class cl_tb_seq_item extends uvm_sequence_item;
  randc int unsigned int_a;
  rand byte          data[];

  bit                use_data;
  int unsigned       min_data_size = 0;
  int unsigned       max_data_size = 3072;

  constraint co_data_range {
    this.use_data == 0 -> this.data.size() == 0;
    this.use_data == 1 -> (this.data.size()>=this.min_data_size &&
                           this.data.size()<=this.max_data_size);
  }

  `uvm_object_utils_begin(cl_tb_seq_item)
    `uvm_field_int(int_a,         UVM_ALL_ON)
    `uvm_field_array_int(data,    UVM_ALL_ON)
    `uvm_field_int(use_data,      UVM_ALL_ON)
    `uvm_field_int(min_data_size, UVM_ALL_ON)
    `uvm_field_int(max_data_size, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "cl_tb_seq_item");
    super.new(name);
  endfunction: new

  extern virtual function string convert2string();
endclass: cl_tb_seq_item

function string cl_tb_seq_item::convert2string();
  return $sformatf("int_a: %0d, data.size: %0d, use_data: %0d", this.int_a, this.data.size(), this.use_data);
endfunction: convert2string
