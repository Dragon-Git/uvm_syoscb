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
/// Shows that SCB dumping still works when full_scb_max_queue_size > the actual number of transactions
class cl_scb_test_io_std_dump_max_size_less extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_dump_max_size_less)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_dump_max_size_less",
                      uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_dump_max_size_less

function cl_scb_test_io_std_dump_max_size_less::new(
                                                string name = "cl_scb_test_io_std_dump_max_size_less",
                                                uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scb_test_io_std_dump_max_size_less::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("test_io_std_dump_max_size_less");
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b1));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_max_queue_size("Q1",20);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_max_queue_size("Q2",20);

  fork
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      this.scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      this.scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  phase.drop_objection(this);
endtask: run_phase
