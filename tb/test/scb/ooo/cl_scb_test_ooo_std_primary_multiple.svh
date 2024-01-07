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
/// OOO compare test for ensuring that multiple items in the primary queue are checked against the secondary queue.
/// If eg. cl_syoscb_cfg#max_search_window = 5, the first 5 items in the primary queue shall be compared
/// against the first 5 elements in all secondary queues.
class cl_scb_test_ooo_std_primary_multiple extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_ooo_std_primary_multiple)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_ooo_std_primary_multiple", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();
  extern task                  run_phase(uvm_phase phase);

endclass: cl_scb_test_ooo_std_primary_multiple

function void cl_scb_test_ooo_std_primary_multiple::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  void'(this.syoscb_cfgs.syoscb_cfg[0].set_primary_queue("Q1"));
endfunction: pre_build

task cl_scb_test_ooo_std_primary_multiple::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.run_phase(phase);

  //Add items to both queues. First item in Q1 does not match anything, but we will still have matches
  begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item"); //This should not match anything yet
    item.int_a = 1234;
    this.scb_env.syoscb[0].add_item("Q1", "P1", item);
  end

  //These items should all match
  fork
    begin
      for(int i=0; i<10; i++) begin
        cl_tb_seq_item item1 = cl_tb_seq_item::type_id::create("item1");
        item1.int_a = i;
        this.scb_env.syoscb[0].add_item("Q1", "P1", item1);
      end
    end

    begin
      for(int i=9; i>=0; i--) begin
        cl_tb_seq_item item2 = cl_tb_seq_item::type_id::create("item2");
        item2.int_a = i;
        this.scb_env.syoscb[0].add_item("Q2", "P1", item2);
      end
    end
  join

  //Add a final object which matches the initial insertion into Q1
  begin
    cl_tb_seq_item item = cl_tb_seq_item::type_id::create("item");
    item.int_a = 1234;
    this.scb_env.syoscb[0].add_item("Q2", "P1", item);
  end

  //Expect 11 matches and 22 insertions
  if(this.scb_env.syoscb[0].get_total_cnt_add_items() != 22) begin
    `uvm_error("TEST_ERROR", $sformatf("Did not have exactly 22 item added to the scb. Total number was %0d", this.scb_env.syoscb[0].get_total_cnt_add_items()))
  end


  phase.drop_objection(this);
endtask: run_phase