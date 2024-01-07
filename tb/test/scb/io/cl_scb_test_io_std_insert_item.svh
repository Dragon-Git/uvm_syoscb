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
/// IO test that validates the behavior of cl_syoscb_queue_base#insert_item
class cl_scb_test_io_std_insert_item extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_std_insert_item)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_insert_item", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task main_phase(uvm_phase phase);


endclass: cl_scb_test_io_std_insert_item

task cl_scb_test_io_std_insert_item::main_phase(uvm_phase phase);
  cl_tb_seq_item ctsi_100, ctsi_9001, ctsi_neg42;
  cl_syoscb_queue_base q;
  int new_ordering[];

  phase.raise_objection(this);
  super.main_phase(phase);

  //Add some items to Q1
  for(int i=0; i<10; i++) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
  end

  //Insert some items - we expect the order to get changed up
  q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
  ctsi_100 = cl_tb_seq_item::type_id::create("ctsi_100");
  ctsi_9001 = cl_tb_seq_item::type_id::create("ctsi_9001");
  ctsi_neg42 = cl_tb_seq_item::type_id::create("ctsi_neg42");

  ctsi_100.int_a = 100;
  ctsi_9001.int_a = 9001;
  ctsi_neg42.int_a = -42;

  if(!q.insert_item("P1", ctsi_100, 0)) begin
    `uvm_fatal("ERR", "Unable to insert item at index 0")
  end

  if(!q.insert_item("P1", ctsi_9001, 5)) begin
    `uvm_fatal("ERR", "Unable to insert item in the middle of queue")
  end

  if(!q.insert_item("P1", ctsi_neg42, q.get_size())) begin
    `uvm_fatal("ERR", "Unable to insert item at the end of queue")
  end
  //Order should now be as follows
  new_ordering = '{100, 0, 1, 2, 3, 9001, 4, 5, 6, 7, 8, 9, -42};

  //Check that it disallows indices that are too large
  if(q.insert_item("P1", ctsi_neg42, q.get_size()+1)) begin
    `uvm_fatal("ERR", "Was able to insert item past end of queue, should not be allowed")
  end

  //Add items to get matches
  foreach(new_ordering[i]) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = new_ordering[i];
    this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi);
  end

  //Verify that both queues have the same number of insertions
  if(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").get_cnt_add_item() !=
  this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q2").get_cnt_add_item()) begin
    `uvm_fatal("ERR", "Number of items added to Q1 and Q2 is not the same")
  end

  phase.drop_objection(this);
endtask: main_phase