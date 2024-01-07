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
// NOTE: This file contains a number of tests that showcase using queue/producer-specific printers when printing
// as well as performing queue overrides / using the xml printer supplied with the syoscb

/// Sets custom printer overrides for Q1/P1 and Q2/P2. The remaining queues will use the default printer.
// Dump everything into the same file
class cl_scb_test_io_std_dump_simple extends cl_scb_test_io_std_dump;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_dump_simple)

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_dump_simple", uvm_component parent = null);
  extern function void check_phase(uvm_phase phase);
endclass: cl_scb_test_io_std_dump_simple

function cl_scb_test_io_std_dump_simple::new(string name = "cl_scb_test_io_std_dump_simple",
                                                    uvm_component parent = null);
  super.new(name, parent);
endfunction: new

function void cl_scb_test_io_std_dump_simple::check_phase(uvm_phase phase);
  uvm_tree_printer q1p1;
  uvm_line_printer q2p2;

  super.check_phase(phase);

  q1p1 = new;
  q2p2 = new;

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::TXT);
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b0));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("simple");
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_printer(q1p1, '{"Q1"}, '{"P1"});
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_printer(q2p2, '{"Q2"}, '{"P2"});
endfunction: check_phase

/// Sets the default printer override. Since no specific printers are set, all queues rely on the default printer.
// Dumps everything into the same file
class cl_scb_test_io_std_dump_default extends cl_scb_test_io_std_dump;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_dump_default)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_dump_default", uvm_component parent = null);

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void check_phase(uvm_phase phase);
endclass: cl_scb_test_io_std_dump_default

function cl_scb_test_io_std_dump_default::new(string name = "cl_scb_test_io_std_dump_default", uvm_component parent = null);
  super.new(name, parent);
endfunction: new


function void cl_scb_test_io_std_dump_default::check_phase(uvm_phase phase);
  uvm_tree_printer default_printer;

  super.check_phase(phase);

  default_printer = new;

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::TXT);
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b0));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("default");
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_printer(default_printer);
endfunction: check_phase

/// Sets the default printer override as well as specific printer overrides.
// Dumps into separate files for each queue
class cl_scb_test_io_std_dump_mixed extends cl_scb_test_io_std_dump;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_io_std_dump_mixed)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_io_std_dump_mixed", uvm_component parent = null);

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void check_phase(uvm_phase phase);
endclass: cl_scb_test_io_std_dump_mixed

function cl_scb_test_io_std_dump_mixed::new(string name = "cl_scb_test_io_std_dump_mixed", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

function void cl_scb_test_io_std_dump_mixed::check_phase(uvm_phase phase);
  uvm_tree_printer  q1p1;
  uvm_line_printer  q2p2;
  uvm_table_printer  default_printer;

  super.check_phase(phase);

  q1p1 = new;
  q2p2 = new;
  default_printer = new;

  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::TXT);
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b1));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("mixed");
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_printer(q1p1, '{"Q1"}, '{"P1"});
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_printer(q2p2, '{"Q2"}, '{"P2"});
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_default_printer(default_printer);
endfunction: check_phase

/// Uses XML/split printing to generate multiple XML files once the test is finished.
class cl_scb_test_io_std_dump_xml_split extends cl_scb_test_io_std_dump;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_std_dump_xml_split)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_dump_xml_split", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void check_phase(uvm_phase phase);


endclass: cl_scb_test_io_std_dump_xml_split

function void cl_scb_test_io_std_dump_xml_split::check_phase(uvm_phase phase);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::XML);
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b1));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("xml_split");
endfunction: check_phase

/// Uses XML/join printing to generate a single XML file once the test is finished.
class cl_scb_test_io_std_dump_xml_join extends cl_scb_test_io_std_dump;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_std_dump_xml_join)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_dump_xml_join", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void check_phase(uvm_phase phase);

endclass: cl_scb_test_io_std_dump_xml_join

function void cl_scb_test_io_std_dump_xml_join::check_phase(uvm_phase phase);
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::XML);
  void'(this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b0));
  this.scb_env.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("xml_join");
endfunction: check_phase