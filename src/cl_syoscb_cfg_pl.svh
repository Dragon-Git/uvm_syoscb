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
class cl_syoscb_cfg_pl extends uvm_object;
   string list[];

   `uvm_object_utils_begin(cl_syoscb_cfg_pl)
     `uvm_field_array_string(list, UVM_DEFAULT)
   `uvm_object_utils_end

   extern function new(string name = "cl_syoscb_cfg_pl");
   extern function void set_list(string list[]);

endclass : cl_syoscb_cfg_pl

function cl_syoscb_cfg_pl::new(string name = "cl_syoscb_cfg_pl");
   super.new(name);
endfunction : new

function void cl_syoscb_cfg_pl::set_list(string list[]);
   this.list = list;
endfunction: set_list
