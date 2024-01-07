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
class cl_tb_env_scb extends cl_tb_env_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_syoscb           syoscb[];
  cl_syoscb_cfgs     syoscb_cfgs;

  cl_tb_cov_collector scb_collector;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_tb_env_scb)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);


  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
endclass: cl_tb_env_scb

function cl_tb_env_scb::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

function void cl_tb_env_scb::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.syoscb      = new[NO_OF_SCB];

  if(!uvm_config_db #(cl_syoscb_cfgs)::get(this, "", "cfg", this.syoscb_cfgs)) begin
    `uvm_fatal("SCB_ENV", "Array of scb configuration not passed")
  end

  foreach (this.syoscb_cfgs.syoscb_cfg[i])begin
    uvm_config_db #(cl_syoscb_cfg)::set(this, $sformatf("syoscb%0d", i),
                                        "cfg", this.syoscb_cfgs.syoscb_cfg[i]);
    uvm_config_db #(cl_syoscb_cfg)::set(this, "scb_collector",
                                        $sformatf("scbcfg%0d", i), this.syoscb_cfgs.syoscb_cfg[i]);

   this.syoscb[i] = cl_syoscb::type_id::create($sformatf("syoscb%0d", i), this);
   this.syoscb_cfgs.syoscb_cfg[i].set_scb_name($sformatf("syoscb%0d", i));
  end

  this.scb_collector = cl_tb_cov_collector::type_id::create("scb_collector", this);
endfunction: build_phase

function void cl_tb_env_scb::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction: connect_phase
