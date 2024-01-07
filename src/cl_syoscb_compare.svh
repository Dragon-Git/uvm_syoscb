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
/// Class which act as the root of the compare algorithm. It instantiates the chosen compare
/// algorithm.
class cl_syoscb_compare extends uvm_component;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration
  local cl_syoscb_cfg cfg;

  /// Handle to the actual compare algorithm to be used
  local cl_syoscb_compare_base compare_algo;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_compare)
    `uvm_field_object(cfg,          UVM_DEFAULT)
    `uvm_field_object(compare_algo, UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);

  //-------------------------------------
  // Class methods
  //-------------------------------------
 extern function void compare();
endclass : cl_syoscb_compare

function cl_syoscb_compare::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

/// Gets the global scoreboard configuration and creates the compare algorithm, e.g. out-of-order.
function void cl_syoscb_compare::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", "Configuration object not passed.")
  end

  this.compare_algo = cl_syoscb_compare_base::type_id::create("compare_algo");
  this.compare_algo.set_cfg(this.cfg);
endfunction

/// Invokes the compare algorithms compare method. 
function void cl_syoscb_compare::compare();
  this.compare_algo.compare();
endfunction : compare
