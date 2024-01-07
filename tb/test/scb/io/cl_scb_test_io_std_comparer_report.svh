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
/// Illustrates how to use queue/producer-specific comparers instead of a default comparer.
// By using set_comparer_verbosity, the comparer report is shown/hidden after the scoreboard's COMPARE_ERROR message
class cl_scb_test_io_std_comparer_report extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_comparer_report)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_comparer_report",
                      uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);

  //Adds some items where they match
  task add_match(string producer);
    cl_tb_seq_item item1;
    cl_tb_seq_item item2;
    fork
      for(int i=0; i<2; i++) begin
        item1 = cl_tb_seq_item::type_id::create("item1");
        item1.int_a = i;
        this.scb_env.syoscb[0].add_item("Q1", producer, item1);
      end
      for(int i=0; i<2; i++) begin
        item2 = cl_tb_seq_item::type_id::create("item2");
        item2.int_a = i;
        this.scb_env.syoscb[0].add_item("Q2", producer, item2);
      end
    join
  endtask: add_match

  //Adds some items where they don't match
  task add_nomatch(string producer);
    cl_tb_seq_item item1;
    cl_tb_seq_item item2;
    fork
      begin
        item1 = cl_tb_seq_item::type_id::create("item1");
        item1.int_a = 4;
        this.scb_env.syoscb[0].add_item("Q1", producer, item1);
      end
      begin
        item2 = cl_tb_seq_item::type_id::create("item2");
        item2.int_a = 44;
        this.scb_env.syoscb[0].add_item("Q2", producer, item2);
      end
    join
  endtask: add_nomatch
endclass: cl_scb_test_io_std_comparer_report

function cl_scb_test_io_std_comparer_report::new(string name = "cl_scb_test_io_std_comparer_report",
                                                       uvm_component parent = null);
  super.new(name, parent);
endfunction: new

task cl_scb_test_io_std_comparer_report::run_phase(uvm_phase phase);
  uvm_comparer q2p1, q2p2;

  phase.raise_objection(this);

  super.run_phase(phase);

  //Constant cfg knob settings
  uvm_root::get().set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);

  //Create comparers and configure them before setting them info config object
  q2p1 = new;
  q2p2 = new;
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_enable_comparer_report(1'b0, '{"Q2"}, {"P1"});
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_enable_comparer_report(1'b1, '{"Q2"}, {"P2"});

  cl_syoscb_comparer_config::set_verbosity(q2p1, UVM_HIGH);
  cl_syoscb_comparer_config::set_verbosity(q2p2, UVM_HIGH);

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_comparer(q2p1, '{"Q2"}, '{"P1"});
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_comparer(q2p2, '{"Q2"}, '{"P2"});

  //Add from P1. Since verbosity=UVM_HIGH and comparer report is disabled on P1,
  // the comparer report is not printed, giving no hints as to where the error occured
  add_match("P1");
  add_nomatch("P1");
  //Flush queue before moving on
  this.scb_env.syoscb[0].flush_queues();

  //Add from P2. Now the comparer report is enabled and will be printed
  add_match("P2");
  add_nomatch("P2");
  //Flush queue before finishing
  this.scb_env.syoscb[0].flush_queues();
  phase.drop_objection(this);
endtask: run_phase