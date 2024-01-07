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
// Simple IOP compare with STD queue test. Testing the cl_syoscbs class
// using TLM hook up to monitors

class cl_scbs_test_iop_std_base extends cl_scbs_test_base;
  localparam int unsigned l_no_scbds = 16;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_iop_std_base)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbs_test_iop_std_base", uvm_component parent = null);
  extern virtual function void pre_build();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
endclass : cl_scbs_test_iop_std_base

function cl_scbs_test_iop_std_base::new(string name = "cl_scbs_test_iop_std_base", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbs_test_iop_std_base::pre_build();
  t_scb_compare_type l_compare_array[];
  t_scb_queue_type   l_queue_array[];

  super.pre_build();

  // Create 16 cfg objects inside scbs_cfg.cfgs dyn array.
  this.scbs_cfg.set_no_scbs(this.l_no_scbds);

  l_compare_array = new[this.l_no_scbds];
  foreach(l_compare_array[i]) begin
    l_compare_array[i] = pk_syoscb::SYOSCB_COMPARE_IOP;
    l_queue_array[i] = pk_syoscb::SYOSCB_QUEUE_STD;
  end
  this.scbs_cfg.set_compare_type(l_compare_array);
  this.scbs_cfg.set_queue_type(l_queue_array);
endfunction : pre_build

function void cl_scbs_test_iop_std_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.scbs_env.no_scbs = this.l_no_scbds;
  this.scbs_env.producers = {"P1", "P2"};
endfunction: build_phase
