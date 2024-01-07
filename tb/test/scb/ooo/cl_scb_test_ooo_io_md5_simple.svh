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
/// Simple test with two SCBs with different compares, both using MD5 queues

class cl_scb_test_ooo_io_md5_simple extends cl_scb_test_double_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_io_md5_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_io_md5_simple", uvm_component parent = null);
  extern virtual function void pre_build();

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_ooo_io_md5_simple

function cl_scb_test_ooo_io_md5_simple::new(string name = "cl_scb_test_ooo_io_md5_simple",
                                            uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_ooo_io_md5_simple::pre_build();
  super.pre_build();

  // Both scbs runs with MD5 queues
  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  this.syoscb_cfgs.syoscb_cfg[1].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);

  // syoscb0 runs with the OOO compare
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);

  // syoscb1 runs with the IO compare
  this.syoscb_cfgs.syoscb_cfg[1].set_compare_type(pk_syoscb::SYOSCB_COMPARE_IO);
endfunction : pre_build

task cl_scb_test_ooo_io_md5_simple::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  fork
    // Insert items in Q1 as P1 with int_a from 0 to 9
    // in both syoscb[0] and syoscb[1]
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item1);
      scb_env.syoscb[1].add_item("Q1", "P1", item1);
    end

    // Insert items in Q2 as P1 with int_a from 9 to 0
    // but only in syoscb[0] as it runs with an OOO compare
    for(int i=9; i>=0; i--) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end

    // Insert items in Q2 as P1 with int_a from 0 to 9
    // but only in syoscb[1] as it runs with an IO compare
    for(int i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[1].add_item("Q2", "P1", item1);
    end
  join

  phase.drop_objection(this);
endtask: run_phase
