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
/// Class which contains the syoscb coverage collector
class cl_tb_cov_collector extends uvm_component;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration
  local cl_syoscb_cfg syoscb_cfg [NO_OF_SCB];

  /// Handle to coverage object. One for each scb.
  local cl_tb_cov     syoscb_cov [NO_OF_SCB];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_tb_cov_collector)
    `uvm_field_sarray_object(syoscb_cfg, UVM_DEFAULT)
    `uvm_field_sarray_object(syoscb_cov, UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern function void sample();
endclass: cl_tb_cov_collector

/// Gets scoreboard configuration, and create syoscb_cov object. One for each scb instance.
function void cl_tb_cov_collector::build_phase(uvm_phase phase);
  super.build_phase(phase);

  for (int i = 0; i < NO_OF_SCB; i++) begin
    if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", $sformatf("scbcfg%0d", i), this.syoscb_cfg[i])) begin
      `uvm_fatal("COV_COLLECTOR", $sformatf("syoscb%0d configuration object not passed.", i))
    end

    this.syoscb_cov[i] = cl_tb_cov::type_id::create($sformatf("syoscb_cov%0d", i));
  end
endfunction: build_phase

function void cl_tb_cov_collector::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);

  this.sample();
endfunction: start_of_simulation_phase

function void cl_tb_cov_collector::check_phase(uvm_phase phase);
  super.check_phase(phase);

  this.sample();
endfunction: check_phase

/// Coverage sample function
function void cl_tb_cov_collector::sample();
  foreach (syoscb_cfg[i]) begin
    this.syoscb_cov[i].sample(this.syoscb_cfg[i]);
  end
endfunction
