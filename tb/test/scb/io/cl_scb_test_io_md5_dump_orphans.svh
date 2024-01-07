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
/// Uses io-compare and MD5 queues showing orphan dumps & shadow queues / scb dump.
// Note: Generally, io-md5 comparisons are overkill and md5-queues should only be used for ooo comparisons
class cl_scb_test_io_md5_dump_orphans extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_md5_dump_orphans)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_md5_dump_orphans", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task run_phase(uvm_phase phase);


endclass: cl_scb_test_io_md5_dump_orphans

function void cl_scb_test_io_md5_dump_orphans::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
endfunction: pre_build

task cl_scb_test_io_md5_dump_orphans::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_dump_orphans_to_files(1'b1); //Print to file
  this.scb_env.syoscb[0].set_report_severity_id_override(UVM_ERROR, "QUEUE_ERROR", UVM_INFO); //Demote the error that is triggered due to orphans
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_max_print_orphans(0); //Print all orphans (5 in Q1, 2 in Q2)
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_orphan_dump_type(pk_syoscb::XML); //Dump as XML output
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_orphan_dump_file_name("md5_dump_orphans");

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1); //Enable dump
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::TXT); //Text output
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b0)); //All tx in same file
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("md5_dump_orphans");

  fork
      for(int unsigned i=0; i<10; i++) begin
        cl_tb_seq_item item1;
        item1 = cl_tb_seq_item::type_id::create("item1");
        item1.int_a = i;
        this.scb_env.syoscb[0].add_item("Q1", "P1", item1);
      end

      for(int unsigned i=0; i<5; i++) begin //Only match the first 5 items in Q1, leaving 5 orphans
        cl_tb_seq_item item1;
        item1 = cl_tb_seq_item::type_id::create("item1");
        item1.int_a = i;
        this.scb_env.syoscb[0].add_item("Q2", "P1", item1);
      end
  join

  phase.drop_objection(this);
endtask: run_phase