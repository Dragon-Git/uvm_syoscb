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
class cl_scbtest_env extends uvm_env;

   cl_syoscb     syoscb;   
   cl_syoscb_cfg syoscb_cfg;

  `uvm_component_utils_begin(cl_scbtest_env)
    `uvm_field_object(syoscb,     UVM_ALL_ON)
    `uvm_field_object(syoscb_cfg, UVM_ALL_ON)
  `uvm_component_utils_end
  
  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass: cl_scbtest_env

function cl_scbtest_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

function void cl_scbtest_env::build_phase(uvm_phase phase);
  super.build_phase(phase);

   cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
                                              cl_syoscb_queue_std::get_type(),
                                              "*");

   factory.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
                                     cl_syoscb_compare_ooo::get_type(),
                                     "*");

  this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");

  this.syoscb_cfg.set_queues({"Q1", "Q2"});
  void'(this.syoscb_cfg.set_primary_queue("Q1")); 
  void'(this.syoscb_cfg.set_producer("P1", {"Q1", "Q2"})); 

  uvm_config_db #(cl_syoscb_cfg)::set(this, "syoscb", "cfg", this.syoscb_cfg); 
  this.syoscb = cl_syoscb::type_id::create("syoscb", this);
            
endfunction: build_phase


function void cl_scbtest_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction: connect_phase



