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
class random_index;

  randc int int_a;

  function new ();
  endfunction: new

endclass: random_index

/// Heavy OOO compare test using the function based API
class cl_scb_test_ooo_heavy_base extends cl_scb_test_single_scb;

  typedef enum {Q1FULL,Q1COMPLEX} t_scenario;
  typedef enum {SMALL,LARGE} t_size;

  int N;
  t_scenario scenario;
  t_size item_size;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_heavy_base)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_heavy_base", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void pre_build();
  extern         function void build_phase(uvm_phase phase);
  extern         task          run_phase(uvm_phase phase);

  extern         function void do_q1full();

endclass : cl_scb_test_ooo_heavy_base

function cl_scb_test_ooo_heavy_base::new(string name = "cl_scb_test_ooo_heavy_base",
                                         uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_ooo_heavy_base::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
endfunction: pre_build

function void cl_scb_test_ooo_heavy_base::build_phase(uvm_phase phase);
  int size;
  int sc;

  this.pre_build();
  super.build_phase(phase);
  void'(uvm_config_db#(uvm_bitstream_t)::get(this,"","events",this.N));
  void'(uvm_config_db#(uvm_bitstream_t)::get(this,"","size",size));
  void'(uvm_config_db#(uvm_bitstream_t)::get(this,"","sc",sc));
  this.item_size = t_size'(size);
  this.scenario = t_scenario'(sc);
endfunction: build_phase

task cl_scb_test_ooo_heavy_base::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  case (this.scenario)
    Q1FULL: begin
      this.do_q1full();
    end
    default: begin
      `uvm_fatal("SCENARIO_ERROR", $sformatf("Unknown scenario:%s",this.scenario.name()));
    end
  endcase

  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_ooo_heavy_base::do_q1full();
  cl_tb_seq_item items[];
  int                 idxs[];
  cl_tb_seq_item cur_item;
  random_index        idx_q2;

  idxs  = new[this.N];
  items = new[this.N];

  cur_item = cl_tb_seq_item::type_id::create("cur_item");

  if (item_size == SMALL) begin
    cur_item.use_data = 0;
  end else begin
    cur_item.use_data = 1;
  end

  for(int i=0; i<this.N; i++) begin
    cl_tb_seq_item item_clone;

    if(!cur_item.randomize()) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("Randomization fail for item %d",i));
    end

    if (i%1000==0) begin
      `uvm_info("Inserts", $sformatf("%d: ", i), UVM_NONE);
    end

    if(!$cast(item_clone, cur_item.clone())) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%d]: Unable to cast cloned item to uvm_sequence_item",i));
    end

    scb_env.syoscb[0].add_item("Q1", "P1", cur_item);
    items[i]=item_clone;

  end

  idx_q2 = new();

  for(int i=0; i<this.N ; i++) begin

    if(!idx_q2.randomize() with {int_a>=0;
                                 int_a<local::this.N;}) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("Randomization fail for index of item %d",i));
    end

    scb_env.syoscb[0].add_item("Q2", "P1", items[idx_q2.int_a]);

    if (i%1000==0) begin
      `uvm_info("Compares",$sformatf("%d: ", i), UVM_NONE);
    end
  end

endfunction : do_q1full
