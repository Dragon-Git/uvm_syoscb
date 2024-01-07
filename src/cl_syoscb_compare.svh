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
/// Component which instantiates the chosen comparison algorithm.
/// Serves to wrap the compare algorithm in a UVM component, as well as triggering
/// additional comparisons at the end of the run phase if the greed level prescribes this.
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
    `uvm_field_object(cfg,          UVM_DEFAULT | UVM_REFERENCE)
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
  extern function void extract_phase(uvm_phase phase);

  //-------------------------------------
  // Compare API
  //-------------------------------------
 extern virtual function void compare_trigger(string queue_name = "", cl_syoscb_item item = null);
 extern virtual function void compare_control(bit cc);
endclass : cl_syoscb_compare

function cl_syoscb_compare::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

/// UVM build phase: Gets the scoreboard's configuration and creates the comparison algorithm
function void cl_syoscb_compare::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Configuration object not passed.", this.cfg.get_scb_name()))
  end

  this.compare_algo = cl_syoscb_compare_base::type_id::create("compare_algo", this);
  this.compare_algo.set_cfg(this.cfg);
endfunction: build_phase

/// UVM extract phase: Check if cl_syoscb_cfg#end_greediness is greedy. If yes, we want to drain all
/// the remaining matches from the scb before moving to check_phase
function void cl_syoscb_compare::extract_phase(uvm_phase phase);
  if(this.cfg.get_end_greediness() == pk_syoscb::SYOSCB_COMPARE_GREEDY) begin
    this.compare_algo.compare_main(this.cfg.get_end_greediness());
  end
endfunction: extract_phase

/// <b>Compare API</b>: Starts a comparison by invoking the chosen compare strategy if comparisons are not disabled
/// \param queue_name Name of the queue which had an item inserted into it
/// \param item       The scoreboard wrapper item that was inserted into the SCB
function void cl_syoscb_compare::compare_trigger(string queue_name = "", cl_syoscb_item item = null);
  this.compare_algo.compare_trigger(queue_name, item);
endfunction : compare_trigger

/// <b>Compare API</b>: Toggle comparisons on or off
/// \param cc compare control bit. If 1, comparisons are enabled, if 0, comparisons are disabled
function void cl_syoscb_compare::compare_control(bit cc);
  this.compare_algo.compare_control(cc);
endfunction: compare_control
