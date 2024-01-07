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
/// Simple IO compare test using the function based API

class cl_scb_test_io_std_simple extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_simple)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_simple", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_io_std_simple

function cl_scb_test_io_std_simple::new(string name = "cl_scb_test_io_std_simple",
                                        uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task cl_scb_test_io_std_simple::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  fork
    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q1", "P1", item1);
    end

    for(int unsigned i=0; i<10; i++) begin
      cl_tb_seq_item item1;
      item1 = cl_tb_seq_item::type_id::create("item1");
      item1.int_a = i;
      scb_env.syoscb[0].add_item("Q2", "P1", item1);
    end
  join

  //Ensure that we really are only comparing the first item in each queue
  //Demote errors of type COMPARE_ERROR, as this should fail
  uvm_root::get().set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);
  //Add items with int_a=0, int_a=1 to Q1 (in that order)
  for(int i=0; i<2; i++) begin
    cl_tb_seq_item item1;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item1.int_a = i;
    scb_env.syoscb[0].add_item("Q1", "P1", item1);
  end


  //Add items with int_a=1, int_a=0 to Q2 (in that order)
  for(int i=1; i>=0; i--) begin
    cl_tb_seq_item item1;
    item1 = cl_tb_seq_item::type_id::create("item1");
    item1.int_a = i;
    scb_env.syoscb[0].add_item("Q2", "P1", item1);
  end

  begin
    int cnt = uvm_report_server::get_server().get_id_count("COMPARE_ERROR");
    //Ensure that exactly two compare errors were triggered
    if(cnt != 2) begin
      `uvm_error("ERR", $sformatf(
        "Did not provoke 2x compare error, got %0d x, io comparisons are broken. Primary queue: '%0s'", 
        cnt, 
        this.syoscb_cfgs.syoscb_cfg[0].get_primary_queue())
      )
    end else begin
      //If the errors did show up, we can happily flush queues
      this.scb_env.syoscb[0].flush_queues_all();
    end
  end

  phase.drop_objection(this);
endtask: run_phase
