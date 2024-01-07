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
/// Random test to hit all the coverage holes which are not covered
/// by tests derived from cl_scb_test_double_scb.
// It is based on cl_scb_test_base and instantiates two scoreboards, syoscb[0] and syoscb[1].
// Cfg knobs are randomly generated

class cl_scb_test_rnd extends cl_scb_test_base;
  cl_tb_rnd_test_items rnd_items[];


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_rnd)
    `uvm_field_array_object(rnd_items,  UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_rnd", uvm_component parent = null);
  extern virtual function void pre_build();
  extern function void split_loops( input string names[],
                                   output string primary[],
                                   output string secondary[]);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_rnd


function cl_scb_test_rnd::new(string name = "cl_scb_test_rnd",
                              uvm_component parent = null);
  super.new(name, parent);
endfunction : new


function void cl_scb_test_rnd::pre_build();
  string l_queues_name[];

  this.syoscb_cfgs = cl_syoscb_cfgs::type_id::create("syoscb_cfgs");
  this.syoscb_cfgs.init(pk_tb::NO_OF_SCB);

  this.rnd_items = new[pk_tb::NO_OF_SCB];

  foreach(this.syoscb_cfgs.syoscb_cfg[i]) begin
    this.rnd_items[i] = cl_tb_rnd_test_items::type_id::create($sformatf("rnd_items%0d", i));

    // Forward the cfg_rnd handle into rnd_item
    this.rnd_items[i].cfg_rnd = this.config_create_and_randomize();

    if(!this.rnd_items[i].randomize()) begin
      `uvm_fatal("TEST_RND", "Randomization of rnd_items failed!")
    end

    `uvm_info("TEST_RND", $sformatf("\n rnd_item %0d: \n %s", i,
                                    this.rnd_items[i].sprint()), UVM_NONE)

    this.syoscb_cfgs.syoscb_cfg[i] = cl_syoscb_cfg::type_id::create($sformatf("syoscb_cfg%0d", i));

    //Creates a number of queues depending from the randomization field inside rnd_items.rnd_cfg
    l_queues_name = new[this.rnd_items[i].queues_no];

    foreach(l_queues_name[i]) begin
      // Queue names are starting from "Q1"
      l_queues_name[i] = $sformatf("Q%0d", i+1);
    end

    // Set queues
    this.syoscb_cfgs.syoscb_cfg[i].set_queues(l_queues_name);

    // Set the primary queue
    if (this.rnd_items[i].cfg_rnd.dynamic_primary_queue == 1'b0) begin
      if(!this.syoscb_cfgs.syoscb_cfg[i].set_primary_queue("Q1")) begin
        `uvm_fatal("CFG_ERROR", "syoscb_cfg.set_primary_queue call failed!")
      end
    end

    // Set producer "P1" for the current generated queues list
    if(!this.syoscb_cfgs.syoscb_cfg[i].set_producer("P1", l_queues_name)) begin
      `uvm_fatal("CFG_ERROR", "syoscb_cfg.set_producer call failed!")
    end

    this.rnd_items[i].cfg_rnd.set_rnd_fields(this.syoscb_cfgs.syoscb_cfg[i]);
  end
endfunction : pre_build


function void cl_scb_test_rnd::build_phase(uvm_phase phase);
  this.pre_build();

  super.build_phase(phase);

  uvm_config_db #(cl_syoscb_cfgs)::set(this, "scb_env",
                                        "cfg", this.syoscb_cfgs);

  this.scb_env = cl_tb_env_scb::type_id::create("scb_env", this);
endfunction: build_phase


task cl_scb_test_rnd::run_phase(uvm_phase phase);
  string l_queues_name [];
  string primary_loop_names [];
  string secondary_loop_names [];

  phase.raise_objection(this);

  super.run_phase(phase);

  foreach (this.scb_env.syoscb[w]) begin
    this.syoscb_cfgs.syoscb_cfg[w].get_queues(l_queues_name);

    l_queues_name.shuffle();

    this.split_loops(l_queues_name, primary_loop_names, secondary_loop_names);

    fork
      begin : primary_iteration
        `uvm_info("RND_TEST",
                  $sformatf("%0s: Primary iteration: adding item on primary group of queues: ",
                            this.scb_env.syoscb[w].get_name()), UVM_LOW)

        // Fill primary group of queues
        for(int unsigned k=0; k < this.rnd_items[w].max_generated_item; k++) begin
          cl_tb_seq_item item1;
          item1 = cl_tb_seq_item::type_id::create("item1");
          if(this.rnd_items[w].enable_duplets && this.rnd_items[w].duplet_insertion_idx == k) begin
            `uvm_info("RND_TEST", $sformatf("Inserted duplet at position: %d. Duplet value: %d",
                                            k, k-1), UVM_MEDIUM)
            item1.int_a = k-1;
          end
          else begin
            item1.int_a = k;
          end

          foreach(primary_loop_names[j]) begin
            scb_env.syoscb[w].add_item(primary_loop_names[j], "P1", item1);
          end
        end
        `uvm_info("RND_TEST",
                  $sformatf("%0s: Primary iteration done",
                            this.scb_env.syoscb[w].get_name()), UVM_LOW)
      end : primary_iteration

      begin : secondary_iteration
        `uvm_info("RND_TEST",
                  $sformatf("%0s: Secondary iteration: adding item on secondary group of queues: ",
                            this.scb_env.syoscb[w].get_name()), UVM_LOW)

        // Fill secondary group of queues
        for(int unsigned k=0; k < this.rnd_items[w].max_generated_item; k++) begin
          cl_tb_seq_item item1;
          item1 = cl_tb_seq_item::type_id::create("item1");
          if(this.rnd_items[w].enable_duplets && this.rnd_items[w].duplet_insertion_idx == k) begin
            `uvm_info("RND_TEST", $sformatf("inserted duplet at position: %d. Duplet value: %d",
                                            k, k-1), UVM_MEDIUM)
            item1.int_a = k-1;
          end
          else begin
            item1.int_a = k;
          end

          foreach(secondary_loop_names[j]) begin
            scb_env.syoscb[w].add_item(secondary_loop_names[j], "P1", item1);
          end
        end
        `uvm_info("RND_TEST",
                  $sformatf("%0s: Secondary iteration done",
                            this.scb_env.syoscb[w].get_name()), UVM_LOW)
      end : secondary_iteration
    join
  end

  phase.drop_objection(this);
endtask: run_phase


// Creates two different groups in order to fill queues in 2 different loops
function void cl_scb_test_rnd::split_loops( input string names[],
                                           output string primary[],
                                           output string secondary[]);
  int unsigned primary_size;
  int unsigned secondary_size;

  // In the primary loop I ever want one element at least
  primary_size = (($urandom) % (names.size()-1)) +1;

  // Set the remaining queues as secondary size
  secondary_size = (names.size()) - primary_size;

  primary = new[primary_size];
  secondary = new[secondary_size];

  foreach(primary[i]) begin
    primary[i] = names[i];
    `uvm_info("TEST_RND",$sformatf("Primary #%0d: %0s", i, primary[i]), UVM_DEBUG);
  end

  foreach(secondary[i]) begin
    secondary[i] = names[primary_size+i];
    `uvm_info("TEST_RND",$sformatf("Secondary #%0d: %0s", i, secondary[i]), UVM_DEBUG);
  end
endfunction: split_loops
