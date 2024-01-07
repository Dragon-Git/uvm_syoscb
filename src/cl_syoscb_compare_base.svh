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
class cl_syoscb_compare_base extends uvm_object;
  `uvm_object_utils(cl_syoscb_compare_base)
  
  // TBD: Field macros?
  cl_syoscb_cfg cfg;
  
  extern function new(string name = "cl_syoscb_compare_base");

  // TBD: Here the abstract compare API must be enforced
  // TBD: The definition of the return bit for both compare and compare_do
  //      must be defined, e.g. status or progress. Currently it is undefined
  virtual function bit compare();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_compare_base::compare() *MUST* be overwritten"));
     return(1'b0);
  endfunction

  virtual function bit compare_do();
    `uvm_fatal("IMPL_ERROR", $sformatf("cl_syoscb_compare_base::compare_do() *MUST* be overwritten"));
     return(1'b0);
  endfunction
  
  extern function void set_cfg(cl_syoscb_cfg cfg);
  extern function cl_syoscb_cfg get_cfg();
  extern function string get_primary_queue_name();   
endclass: cl_syoscb_compare_base

function cl_syoscb_compare_base::new(string name = "cl_syoscb_compare_base");
   super.new(name);
endfunction : new

// TBD: Replace by UVM cfg DB lookup?
function void cl_syoscb_compare_base::set_cfg(cl_syoscb_cfg cfg);
  this.cfg = cfg;
endfunction : set_cfg

function cl_syoscb_cfg cl_syoscb_compare_base::get_cfg();
  return(this.cfg);
endfunction : get_cfg

function string cl_syoscb_compare_base::get_primary_queue_name();
  cl_syoscb_cfg ch = this.get_cfg();

  return(ch.primary_queue);
endfunction: get_primary_queue_name
