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
/// Simple IO compare test using the function based API and mutexed add_item calls.
// Unable to provoke situations where the mutex is unreachable, since all simulators
// run threads to completion, as item insertion happens in 0 time.
// Mutex has been proven to work by inserting an artificial delay inside add_item_mutexed,
// but obviously this cannot be included in the source files.
class cl_scb_test_io_std_simple_mutexed extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_simple_mutexed)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_simple_mutexed", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void pre_build();
  extern function void build_phase(uvm_phase phase);
  extern task main_phase(uvm_phase phase);
  extern task access_queue(string queue, string producer, int start);
endclass : cl_scb_test_io_std_simple_mutexed

function cl_scb_test_io_std_simple_mutexed::new(string name = "cl_scb_test_io_std_simple_mutexed",
                                        uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_io_std_simple_mutexed::pre_build();
  super.pre_build();
  this.syoscb_cfgs.syoscb_cfg[0].set_mutexed_add_item_enable(1'b1);
endfunction: pre_build

function void cl_scb_test_io_std_simple_mutexed::build_phase(uvm_phase phase);
  this.pre_build();
  super.build_phase(phase);
endfunction: build_phase

task cl_scb_test_io_std_simple_mutexed::main_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.main_phase(phase);

  fork
    for(int i=0; i<100; i++) begin
      this.access_queue("Q1", "P1", i*1000);
    end

    for(int i=0; i<100; i++) begin
      this.access_queue("Q2", "P1", i*1000);
    end
  join

  phase.drop_objection(this);
endtask: main_phase

// Performs 100 acceses to queue/producer
// Sets the int_a field of the cl_tb_seq_item to start+i, where i<-[0:99]
task cl_scb_test_io_std_simple_mutexed::access_queue(string queue, string producer, int start);
  cl_tb_seq_item item;
  for(int i=0; i<100; i++) begin
    int w;
    void'(std::randomize(w) with {
      w inside {0, 1000, 2000};
    });

    item = cl_tb_seq_item::type_id::create("item");
    item.int_a = i + start;
    #w; //Wait for a random amount of time
    this.scb_env.syoscb[0].add_item_mutexed(queue, producer, item);
  end
endtask: access_queue