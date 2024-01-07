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
/// Base class for all SCB tests usings two scoreboards

class cl_scb_test_double_scb extends cl_scb_test_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_double_scb)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_double_scb",
                      uvm_component parent = null);

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function void pre_build();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
endclass : cl_scb_test_double_scb

function cl_scb_test_double_scb::new(string name = "cl_scb_test_double_scb",
                                     uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_double_scb::build_phase(uvm_phase phase);
  this.pre_build();

  super.build_phase(phase);

  uvm_config_db #(cl_syoscb_cfgs)::set(this, "scb_env",
                                        "cfg", this.syoscb_cfgs);

  this.scb_env = cl_tb_env_scb::type_id::create("scb_env", this);
endfunction: build_phase

// Creates and sets up cfg objects for each scoreboard
function void cl_scb_test_double_scb::pre_build();
  cl_tb_cfg_rnd cfg_rnd[pk_tb::NO_OF_SCB];

  this.syoscb_cfgs = cl_syoscb_cfgs::type_id::create("syoscb_cfgs");
  this.syoscb_cfgs.init(pk_tb::NO_OF_SCB);

  foreach(this.syoscb_cfgs.syoscb_cfg[i]) begin
    cfg_rnd[i] = this.config_create_and_randomize();
    this.syoscb_cfgs.syoscb_cfg[i] = cl_syoscb_cfg::type_id::create($sformatf("syoscb_cfg%0d", i));

    //Init queues: Sets up queue name and producer links,
    this.syoscb_cfgs.syoscb_cfg[i].init($sformatf("syoscb%0d", i), '{"Q1", "Q2"}, '{"P1", "P2", "P3"});

    // Set the maximum queue size for Q1 to 100 elements
    this.syoscb_cfgs.syoscb_cfg[i].set_max_queue_size("Q1", 100);

    //Set queue type and compare type defaults for all of the included tests
    this.syoscb_cfgs.syoscb_cfg[i].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IO);
    this.syoscb_cfgs.syoscb_cfg[i].set_queue_type(pk_syoscb::SYOSCB_QUEUE_STD);

    // Set the primary queue
    if (cfg_rnd[i].dynamic_primary_queue == 1'b0) begin
      if(!this.syoscb_cfgs.syoscb_cfg[i].set_primary_queue("Q1")) begin
        `uvm_fatal("CFG_ERROR", "syoscb_cfg.set_primary_queue call failed!")
      end
    end
  end
endfunction: pre_build
