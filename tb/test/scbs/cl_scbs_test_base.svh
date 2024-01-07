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
/// Base class for all SCBs tests
//FIN: The type of sequence items generated, which are then transformed to uvm_sequence_item in the filter transfrom
//MON: The type of monitors to be used. Must be parameterized to accept items of type FIN
//FT:  The type of filter transform to be used. Must be parameterized w.r.t the type of FIN
class cl_scbs_test_base#(type FIN = cl_tb_seq_item,
                         type MON = cl_tb_tlm_monitor#(cl_tb_seq_item),
                         type FT  = pk_utils_uvm::filter_trfm#(FIN, uvm_sequence_item)) extends uvm_test;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  cl_tb_env_scbs#(FIN, MON, FT) scbs_env;

  cl_syoscbs_cfg scbs_cfg;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_param_utils(cl_scbs_test_base#(FIN, MON, FT))

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern         function      new(string name = "cl_scbs_test_base", uvm_component parent = null);
  extern virtual function void pre_build();
  extern virtual task          rnd_scb_insert();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);

endclass : cl_scbs_test_base

function cl_scbs_test_base::new(string name = "cl_scbs_test_base", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scbs_test_base::build_phase(uvm_phase phase);
  this.pre_build();

  super.build_phase(phase);

  this.scbs_env = cl_tb_env_scbs#(FIN, MON, FT)::type_id::create("scbs_env", this);
endfunction: build_phase

function void cl_scbs_test_base::pre_build();
  this.scbs_cfg = cl_syoscbs_cfg::type_id::create("scbs_cfg");

  // Create NO_OF_SCBS cfg objects inside scbs_cfg.cfgs dyn array.
  // Other arguments are kept empty: Here we are interested to create cfgs only, and
  // the complete init will be called inside scbs_env with the fields defined in it.
  //
  // -scbs_name  : The specific name of the scbs wrapper.
  //               If not provided, the wrapper will have the name given while calling the create method.
  // -no_scbs    : The number of cfg objects contained inside the wrapper.
  //               In this case the number is set with NO_OF_SCBS to be equal 10.
  // -scb_names[]: Provide a different name for each scb. If no arguments are passed,
  //               each scb inside the wrapper will be assigned a default name.
  // -queues[]   : Sets the queues contained in the passed argument, and sets it for each
  //               cfg contained in the wrapper. Now we are passing an empty argument since the
  //               queue name list will be defined inside the env.
  // -producers[]: specifies the group of producers for the wrapper. Here we are giving an empty
  //               argument because we will define the list of producers inside the env.
  this.scbs_cfg.init("myscbs", NO_OF_SCBS, {}, {}, {});
  for(int i=0; i<NO_OF_SCBS; i++) begin
    cl_syoscb_cfg cfg = this.scbs_cfg.get_cfg(i);
    cfg.set_compare_type(pk_syoscb::SYOSCB_COMPARE_IO);
    cfg.set_queue_type(pk_syoscb::SYOSCB_QUEUE_STD);
    this.scbs_cfg.set_cfg(cfg, i);
  end

  // Forward created cfg to scbs_env
  uvm_config_db #(cl_syoscbs_cfg)::set(this , "scbs_env",
                                       "cfg", this.scbs_cfg);


  //We factory override from cl_syoscbs_base to cl_syoscbs#(FIN) in most cases
  cl_syoscbs_base::type_id::set_type_override(cl_syoscbs#(FIN)::get_type());
endfunction: pre_build

task cl_scbs_test_base::rnd_scb_insert();
  int unsigned item_cnt;

  // Inject random errors
  repeat ($urandom_range(100, 1)) begin
    int unsigned   ws;
    int unsigned   scb_idx;
    cl_syoscb      scb;
    cl_tb_seq_item item;

    // Generate random wait
    ws = $urandom_range(100, 10);

    `uvm_info("TEST", $sformatf("[%0d]: Waiting %0d time units",
                                item_cnt, ws), UVM_NONE);

    // Do the wait
    #(ws);

    `uvm_info("TEST", $sformatf("[%0d]: Wait done", item_cnt), UVM_NONE);

    // Pick random scb
    scb_idx = $urandom_range(this.scbs_env.syoscbs_cfg.get_no_scbs()-1, 0);

    // Get scb
    scb = this.scbs_env.syoscbs.get_scb(scb_idx);

    item = cl_tb_seq_item::type_id::create($sformatf("scb[%0d]-item[%0d]", scb_idx, item_cnt));

    if(!item.randomize()) begin
      `uvm_fatal("TEST_ERROR", "Unable to randomize")
    end

    scb.add_item(((item_cnt % 2) == 0) ? "Q1" : "Q2", "P1", item);
  end
endtask: rnd_scb_insert