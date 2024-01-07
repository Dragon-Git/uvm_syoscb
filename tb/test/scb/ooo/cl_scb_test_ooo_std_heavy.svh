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
/// Heavy OOO compare test using the function based API and a standard queue
class cl_scb_test_ooo_std_heavy extends cl_scb_test_ooo_heavy_base;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_std_heavy)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_std_heavy", uvm_component parent = null);
endclass: cl_scb_test_ooo_std_heavy

function cl_scb_test_ooo_std_heavy::new(string name = "cl_scb_test_ooo_std_heavy",
                                        uvm_component parent = null);
  super.new(name, parent);
endfunction : new
