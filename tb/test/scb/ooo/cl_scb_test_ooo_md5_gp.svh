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
/// Simple OOO compare test for TLM generic payload using the function based API

class cl_scb_test_ooo_md5_gp extends cl_scb_test_single_scb;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_ooo_md5_gp)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_ooo_md5_gp", uvm_component parent = null);
  extern virtual function void pre_build();
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass : cl_scb_test_ooo_md5_gp

function cl_scb_test_ooo_md5_gp::new(string name = "cl_scb_test_ooo_md5_gp",
                                     uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void cl_scb_test_ooo_md5_gp::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
endfunction : pre_build

task cl_scb_test_ooo_md5_gp::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  super.run_phase(phase);

  begin
    uvm_tlm_generic_payload gp;

    // Create
    gp = uvm_tlm_generic_payload::type_id::create("gp0");

    // Command
    gp.set_write();

    // Address
    gp.set_address(64'h0);

    // Data
    begin
      byte unsigned gp_data[];

      gp_data = new[4];

      gp_data[0] = 8'h0;
      gp_data[1] = 8'h1;
      gp_data[2] = 8'h2;
      gp_data[3] = 8'h3;

      gp.set_data_length(4);
      gp.set_data(gp_data);
    end

    // Byte enable
    begin
      byte unsigned gp_be[];

      gp_be = new[4];

      gp_be[0] = 8'hff;
      gp_be[1] = 8'hff;
      gp_be[2] = 8'hff;
      gp_be[3] = 8'hff;

      gp.set_byte_enable_length(4);
      gp.set_byte_enable(gp_be);
    end

    // Status
    gp.set_response_status(UVM_TLM_OK_RESPONSE);

    gp.print();

    scb_env.syoscb[0].add_item("Q1", "P1", gp);
  end

  begin
    uvm_tlm_generic_payload gp;

    // Create
    gp = uvm_tlm_generic_payload::type_id::create("gp1");

    // Command
    gp.set_write();

    // Address
    gp.set_address(64'h0);

    // Data
    begin
      byte unsigned gp_data[];

      gp_data = new[4];

      gp_data[0] = 8'h0;
      gp_data[1] = 8'h1;
      gp_data[2] = 8'h2;
      gp_data[3] = 8'h3;

      gp.set_data_length(4);
      gp.set_data(gp_data);
    end

    // Byte enable
    begin
      byte unsigned gp_be[];

      gp_be = new[4];

      gp_be[0] = 8'hff;
      gp_be[1] = 8'hff;
      gp_be[2] = 8'hff;
      gp_be[3] = 8'hff;

      gp.set_byte_enable_length(4);
      gp.set_byte_enable(gp_be);
    end

    // Status
    gp.set_response_status(UVM_TLM_OK_RESPONSE);

    gp.print();

    scb_env.syoscb[0].add_item("Q2", "P1", gp);
  end

  phase.drop_objection(this);
endtask: run_phase
