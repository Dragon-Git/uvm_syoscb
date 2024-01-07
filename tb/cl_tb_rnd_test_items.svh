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
class cl_tb_rnd_test_items extends uvm_object;

  // rnd_cfg handle
  cl_tb_cfg_rnd cfg_rnd;

  // Test related constraints:
  rand int unsigned max_generated_item;
  rand int unsigned queues_no;

  // Enable duplet, and randomize the insertion index also
  rand bit          enable_duplets;
  rand int unsigned duplet_insertion_idx;

  // Set the distribution for max number of items to be generated and added into queues.
  constraint c_max_generated_item_range {
    this.max_generated_item dist{
      [1    :9    ] := 1,
      [10   :30   ] :/ 10,
      [100  :999  ] :/ 10,
      [1000 :1999 ] :/ 10,
      [2000 :2999 ] :/ 10,
      [3000 :3999 ] :/ 10,
      [4000 :4999 ] :/ 10,
      [5000 :5999 ] :/ 10,
      [6000 :6999 ] :/ 10,
      [7000 :7999 ] :/ 10,
      [8000 :8999 ] :/ 10,
      [9000 :9999 ] :/ 10,
      [10000:15000] :/ 10
    };
  }


  //-------------------------------------
  // Structural Test bench constraint
  //-------------------------------------

  // Sets scb cfg to have between 2 and 5 queues
  constraint c_queues_no {
    this.queues_no >= 2;
    this.queues_no <= 5;
  }

  // Compare IO2HP works only with 2 queues
  constraint c_queue_no_and_compare_type {
    if(this.cfg_rnd.compare_type == pk_syoscb::SYOSCB_COMPARE_IO2HP) {
      this.queues_no == 2;
    }
  }

  // MD5 queue with compare different by ooo or user defined cannot handle duplets when
  // ordered next is disabled.
  constraint c_disable_duplets_md5_onext_disabled {
    if(this.cfg_rnd.ordered_next == 0                 &&
       this.cfg_rnd.queue_type == pk_syoscb::SYOSCB_QUEUE_MD5 &&
       this.cfg_rnd.compare_type inside {pk_syoscb::SYOSCB_COMPARE_IO,
                                         pk_syoscb::SYOSCB_COMPARE_IOP,
                                         pk_syoscb::SYOSCB_COMPARE_IO2HP}){
      this.enable_duplets == 1'b0;
    }
  }

  // If enabled_duplets, the insertion index should be in the range of max generated items
  constraint c_duplet_index_range {
    this.duplet_insertion_idx > 0;
    if(this.enable_duplets == 1'b1){
      this.duplet_insertion_idx < this.max_generated_item;
    }
  }


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_tb_rnd_test_items)
    `uvm_field_object(cfg_rnd,              UVM_DEFAULT          )
    `uvm_field_int(max_generated_item,      UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(queues_no,               UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(enable_duplets,          UVM_DEFAULT          )
    `uvm_field_int(duplet_insertion_idx,    UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_rnd_test_items");
    super.new(name);
  endfunction : new

  extern function void pre_randomize();
endclass: cl_tb_rnd_test_items


function void cl_tb_rnd_test_items::pre_randomize();
  if(this.cfg_rnd == null) begin
    `uvm_fatal("TEST_ITEMS","Need to forward a rnd_cfg before randomize other items")
  end
endfunction: pre_randomize
