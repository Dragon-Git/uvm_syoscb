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
class cl_tb_env_base extends uvm_env;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_tb_env_base)
  `uvm_component_utils_end
  
  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);
endclass: cl_tb_env_base

function cl_tb_env_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new
