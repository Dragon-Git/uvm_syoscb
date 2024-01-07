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
/// Base class for all SCB tests
class cl_scb_test_base extends uvm_test;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_tb_env_scb   scb_env;

  cl_syoscb_cfgs syoscb_cfgs;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_base)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_base",
                      uvm_component parent = null);

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function void          pre_build();
  extern virtual function cl_tb_cfg_rnd config_create_and_randomize();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
endclass : cl_scb_test_base

function cl_scb_test_base::new(string name = "cl_scb_test_base",
                               uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_base::pre_build();
  `uvm_fatal("IMPL_ERROR",
             $sformatf("[%p]: cl_scb_test_base::pre_build() *MUST* be overwritten",
             this.scb_env.syoscb));
endfunction: pre_build

// Utility function. Creates and returns a set
// of randomized fields for randomizing a configuration
function cl_tb_cfg_rnd cl_scb_test_base::config_create_and_randomize();
  cl_tb_cfg_rnd l_cfg_rnd;
  l_cfg_rnd = cl_tb_cfg_rnd::type_id::create("l_cfg_rnd");

  if (!l_cfg_rnd.randomize()) begin
    `uvm_fatal("ENV_SCB", "randomization of cfg_rnd failed")
  end
  else begin
    return l_cfg_rnd;
  end
endfunction: config_create_and_randomize
