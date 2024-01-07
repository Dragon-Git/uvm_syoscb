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
typedef class uxp_parent_seq_item; //parent, child, small seq items are defined below tests
typedef enum {ON, OFF} t_on_off; //Defined below tests

/// A test which can be used to generate an XML printout for verifying the uvm_xml_printer
class cl_scb_test_uvm_xml_printer extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_uvm_xml_printer)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_uvm_xml_printer", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
  extern function void pre_build();
endclass: cl_scb_test_uvm_xml_printer

function void cl_scb_test_uvm_xml_printer::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_enable_no_insert_check(0);
  this.syoscb_cfgs.syoscb_cfg[0].set_disable_report(1'b1);
  this.syoscb_cfgs.syoscb_cfg[0].set_end_greediness(pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY);


  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump(1'b1);
  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_type(pk_syoscb::XML);
  void'(this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_split(1'b0));

  this.syoscb_cfgs.syoscb_cfg[0].set_full_scb_dump_file_name("xml_printer");
endfunction: pre_build

task cl_scb_test_uvm_xml_printer::run_phase(uvm_phase phase);
  uxp_parent_seq_item parent;
  cl_syoscb_item syoscb_item;
  uvm_xml_printer xp;
  uvm_table_printer tp;
  int fd;
  string sxp;

  phase.raise_objection(this);
  super.run_phase(phase);

  this.scb_env.syoscb[0].compare_control(1'b0);

  parent = uxp_parent_seq_item::type_id::create("parent");
  syoscb_item = cl_syoscb_item::type_id::create("syoscb_item");

  for(int i=1; i<=2; i++) begin
    if(!parent.randomize()) begin
      `uvm_fatal("RAND", "Unable to randomize")
    end
    parent.str = "Hello, world";
    parent.q.push_back(1*i);
    parent.q.push_back(2*i);
    parent.q.push_back(100*i);
    parent.r = 3.14*i;

    parent.aa["one"] = 1*i;
    parent.aa["two"] = 2*i;
    parent.aa["hundred"] = 100*i;

    this.scb_env.syoscb[0].add_item("Q1", "P1", parent);
  end

  if(!parent.randomize()) begin
    `uvm_fatal("RAND", "Unable to randomize")
  end

  this.scb_env.syoscb[0].add_item("Q2", "P1", parent.child);

  phase.drop_objection(this);
endtask: run_phase

/// Tests whether the uvm_xml_printer correctly outputs a warning when it is used on a non-cl_syoscb_item sequencei item.
class cl_scb_test_uvm_xml_printer_break extends cl_scb_test_uvm_xml_printer;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_uvm_xml_printer_break)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_uvm_xml_printer_break", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task run_phase(uvm_phase phase);

endclass: cl_scb_test_uvm_xml_printer_break

task cl_scb_test_uvm_xml_printer_break::run_phase(uvm_phase phase);
  uvm_xml_printer xml_printer;
  uxp_parent_seq_item item;
  uvm_root uvm_top;

  phase.raise_objection(this);
  uvm_top = uvm_root::get();
  uvm_top.set_report_severity_id_override(UVM_WARNING, "XML_PRINT", UVM_INFO);

  super.run_phase(phase);

  xml_printer = new;
  item = uxp_parent_seq_item::type_id::create("item");

  if(!item.randomize()) begin
    `uvm_fatal("RAND", "Unable to randomize seq. item")
  end
  void'(item.sprint(xml_printer));

  phase.drop_objection(this);
endtask: run_phase

//Definitions for auxilliary classes for these tests
class uxp_small_seq_item extends uvm_sequence_item;
  rand int i;
  rand byte by;

  `uvm_object_utils_begin(uxp_small_seq_item)
    `uvm_field_int(i, UVM_DEFAULT)
    `uvm_field_int(by, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "uxp_small_seq_item");
    super.new(name);
  endfunction: new
endclass: uxp_small_seq_item

class uxp_child_seq_item extends uvm_sequence_item;
  rand int arr[15];
  uxp_small_seq_item children[3];

  `uvm_object_utils_begin(uxp_child_seq_item)
    `uvm_field_sarray_int(arr, UVM_DEFAULT)
    `uvm_field_sarray_object(children, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "uxp_child_seq_item");
    super.new(name);

    children[0] = new("child0");
    //Child1 intentionally left as null
    children[2] = new("child2");

  endfunction: new

endclass: uxp_child_seq_item

class uxp_parent_seq_item extends uvm_sequence_item;
  rand int a;
  rand byte b;
  rand t_on_off t;
  real r;
  string str;
  int q[$];
  int aa[string];
  uxp_child_seq_item child;
  int empt[];
  uxp_child_seq_item null_object;

  `uvm_object_utils_begin(uxp_parent_seq_item)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_enum(t_on_off, t, UVM_DEFAULT)
    `uvm_field_real(r, UVM_DEFAULT)
    `uvm_field_string(str, UVM_DEFAULT)
    `uvm_field_queue_int(q, UVM_DEFAULT)
    `uvm_field_aa_int_string(aa, UVM_DEFAULT)
    `uvm_field_object(child, UVM_DEFAULT)
    `uvm_field_array_int(empt, UVM_DEFAULT)
    `uvm_field_object(null_object, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "uxp_parent_seq_item");
    super.new(name);
  endfunction: new

  function void pre_randomize();
    this.child = uxp_child_seq_item::type_id::create("child");
  endfunction: pre_randomize
endclass: uxp_parent_seq_item