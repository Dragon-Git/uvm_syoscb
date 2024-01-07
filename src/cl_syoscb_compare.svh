//----------------------------------------------------------------------
//   Copyright 2014 SyoSil ApS
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
class cl_syoscb_compare extends uvm_component;

   // Handle to the actual compare algorithm to be used
   cl_syoscb_compare_base compare_algo;

   `uvm_component_utils_begin(cl_syoscb_compare)
     `uvm_field_object(compare_algo, UVM_DEFAULT)
   `uvm_component_utils_end

   extern function new(string name, uvm_component parent);
   extern function bit compare();
endclass : cl_syoscb_compare


function cl_syoscb_compare::new(string name, uvm_component parent);
   super.new(name, parent);
   this.compare_algo = cl_syoscb_compare_base::type_id::create("compare_algo");
endfunction : new

function bit cl_syoscb_compare::compare();
   return(this.compare_algo.compare());
endfunction : compare
