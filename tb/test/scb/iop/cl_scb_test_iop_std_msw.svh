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
/// This test ensures that IOP compares correctly search through the primary queue,
/// comparing not only the first item but also subsequent items for matches.
class cl_scb_test_iop_std_msw extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_iop_std_msw)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_iop_std_msw", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task          run_phase(uvm_phase phase);


endclass: cl_scb_test_iop_std_msw

function void cl_scb_test_iop_std_msw::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IOP);
  if(!this.syoscb_cfgs.syoscb_cfg[0].set_primary_queue("Q2")) begin
    `uvm_fatal("cl_scb_test_iop_std_msw", "Unable to set primary queue")
  end
endfunction: pre_build

task cl_scb_test_iop_std_msw::run_phase(uvm_phase phase);
  uvm_report_server rs;

  cl_tb_seq_item ctsi1, ctsi2, ctsi3;
  phase.raise_objection(this);
  super.run_phase(phase);

  ctsi1 = cl_tb_seq_item::type_id::create("ctsi1");
  ctsi2 = cl_tb_seq_item::type_id::create("ctsi2");
  ctsi3 = cl_tb_seq_item::type_id::create("ctsi3");

  if(!ctsi1.randomize()) begin
    `uvm_fatal("RAND", "Unable to randomize ctsi1")
  end

  if(!ctsi2.randomize()) begin
    `uvm_fatal("RAND", "Unable to randomize ctsi2")
  end

  if(!ctsi3.randomize()) begin
    `uvm_fatal("RAND", "Unable to randomize ctsi3")
  end

  ctsi1.int_a = 1;
  ctsi2.int_a = 2;
  ctsi3.int_a = 3;

  //Insert items into Q1 in order P1,P2
  //Insert items into Q2 in order P3,P1
  //Once all are inserted, we expect P1/P1 to match and P2/P3 to still be in queue
  this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi1);
  this.scb_env.syoscb[0].add_item("Q1", "P2", ctsi2);

  this.scb_env.syoscb[0].add_item("Q2", "P3", ctsi3);
  this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi1);

  if(!(this.scb_env.syoscb[0].get_total_cnt_add_items() == 4
  && this.scb_env.syoscb[0].get_total_queue_size() == 2)) begin
    `uvm_error("TEST", "Did not generate a match with ctsi1 in both queues");
  end else begin
    //No error, add remaining items to make test pass
    this.scb_env.syoscb[0].add_item("Q1", "P3", ctsi3);
    this.scb_env.syoscb[0].add_item("Q2", "P2", ctsi2);
  end

  phase.drop_objection(this);
endtask: run_phase