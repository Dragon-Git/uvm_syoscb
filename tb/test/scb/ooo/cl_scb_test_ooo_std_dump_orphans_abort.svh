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
/// Tests queue and orphan dumping when an error occurs mid-simulation
/// This test fails on purpose, and is therefore not included in the regression tests
class cl_scb_test_ooo_std_dump_orphans_abort extends cl_scb_test_single_scb;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_ooo_std_dump_orphans_abort)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_ooo_std_dump_orphans_abort", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task run_phase(uvm_phase phase);


endclass: cl_scb_test_ooo_std_dump_orphans_abort

function void cl_scb_test_ooo_std_dump_orphans_abort::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  this.syoscb_cfgs.syoscb_cfg[0].set_dump_orphans_to_files(1'b1); //Print to file
  this.syoscb_cfgs.syoscb_cfg[0].set_max_print_orphans(0); //Print all orphans (5 in Q1, 2 in Q2)
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1); //Dump all entries
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_max_queue_size("Q1", 15); //Set queue size larger than input size
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_max_queue_size("Q2", 15); //Set queue size larger than input size
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::XML);
  this.syoscb_cfgs.syoscb_cfg[0].set_orphan_dump_type(pk_syoscb::XML);


  this.syoscb_cfgs.syoscb_cfg[0].set_orphan_dump_file_name("abort");
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("abort");
endfunction: pre_build

task cl_scb_test_ooo_std_dump_orphans_abort::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.run_phase(phase);

  //Add items
  fork
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      this.scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<5; i++) begin //Only match the first 5 items in Q1, leaving 5 orphans in Q1
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      this.scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end

    for(int unsigned i=10; i<12; i++) begin //Add another 2 items to Q2 which will be orphaned
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      this.scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  phase.drop_objection(this);
endtask: run_phase