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
// *NOTES*:
// Base class for all SCB tests

class cl_scbtest_test_base extends uvm_test;
   `uvm_component_utils(cl_scbtest_test_base)
   cl_scbtest_env scbtest_env;
   extern function new(string name = "cl_scbtest_test_base", uvm_component parent = null);
   extern virtual function void pre_build();
   extern virtual function void build_phase(uvm_phase phase);
endclass : cl_scbtest_test_base

function cl_scbtest_test_base::new(string name = "cl_scbtest_test_base", uvm_component parent = null);
   super.new(name, parent);
endfunction : new

function void cl_scbtest_test_base::pre_build();   // overload in extended classes to add config changes
endfunction : pre_build

function void cl_scbtest_test_base::build_phase(uvm_phase phase);
   pre_build();
   super.build_phase(phase);
   scbtest_env = cl_scbtest_env::type_id::create("scbtest_env", this);
endfunction : build_phase
