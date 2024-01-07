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
/// Simple IO compare test on real values using the function based API
class cl_scb_test_io_std_simple_real extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_simple_real)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_simple_real", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass: cl_scb_test_io_std_simple_real

function cl_scb_test_io_std_simple_real::new(string name = "cl_scb_test_io_std_simple_real",
                                            uvm_component parent = null);
  super.new(name, parent);
endfunction: new

task cl_scb_test_io_std_simple_real::run_phase(uvm_phase phase);
  real reals[10];

  phase.raise_objection(this);
  super.run_phase(phase);

  //Generate 10 random real variables in range (0;100) for testing purposes
  for(int i=0; i<10; i++) begin
    int u = $urandom_range(100000000, 1000000);
    reals[i] = real'(u)/1000000;
  end


  fork
    for(int i=0; i<10; i++) begin
      cl_tb_seq_item_real item;
      item = cl_tb_seq_item_real::type_id::create("item");
      item.int_a = i;
      item.b = reals[i];
      scb_env.syoscb[0].add_item("Q1", "P1", item);
    end

    for(int i=0; i<10; i++) begin
      cl_tb_seq_item_real item;
      item = cl_tb_seq_item_real::type_id::create("item");
      item.int_a = i;
      item.b = reals[i];
      scb_env.syoscb[0].add_item("Q2", "P1", item);
    end
  join

  phase.drop_objection(this);
endtask: run_phase