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
/// Simple IO compare with standard queues using TLM based API.
class cl_scbs_test_io_std_base extends cl_scbs_test_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_io_std_base)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbs_test_io_std_base",
                      uvm_component parent = null);
  extern virtual function void pre_build();

endclass : cl_scbs_test_io_std_base

function cl_scbs_test_io_std_base::new(string name = "cl_scbs_test_io_std_base",
                                       uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbs_test_io_std_base::pre_build();
  super.pre_build();
endfunction : pre_build
