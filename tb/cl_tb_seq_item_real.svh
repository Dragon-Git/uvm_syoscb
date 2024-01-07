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
class cl_tb_seq_item_real extends cl_tb_seq_item;
    real b;

    `uvm_object_utils_begin(cl_tb_seq_item_real)
        `uvm_field_real(b, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cl_tb_seq_item_real");
        super.new(name);
    endfunction
endclass: cl_tb_seq_item_real