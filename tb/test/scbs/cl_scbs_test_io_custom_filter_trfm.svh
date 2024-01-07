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
//This file contains the test for a custom filter transform + some additional
//classes necessary to make the test work.
//The classes are defined here to avoid cluttering the test directory
//The classes are a custom filter transform, a new scoreboard implementation and the test itself (in that order)
//All methods are implemented in-line to keep things slightly condensed

// Custom filter transform
// Implementation is the same as pk_utils_uvm::filter_trfm, but they are two entirely separate classes
// Also does not inherit from uvm_subscriber to prove that they can have separate base classes, so long as
// uvm_component is a parent
class my_custom_filter_trfm#(type IN = int, type OUT = uvm_sequence_item) extends uvm_component;
  typedef my_custom_filter_trfm#(IN,OUT) this_type;

  uvm_analysis_imp#(IN, this_type) analysis_export;
  uvm_analysis_port#(OUT) ap;

  `uvm_component_param_utils(my_custom_filter_trfm#(IN, OUT))

  function new(string name = "my_custom_filter_trfm", uvm_component parent = null);
    super.new(name, parent);
    this.analysis_export = new("my_analysis_imp", this);
    this.ap = new("ap", this);
  endfunction: new

  //Function transform
  virtual function void transform(IN t, output OUT items[]);
    items = new[1];
    items[0] = t;
  endfunction: transform

  //Function write
  virtual function void write(IN t);
    OUT items[];
    this.transform(t, items);
    foreach(items[i]) begin
      this.ap.write(items[i]);
    end
  endfunction: write
endclass: my_custom_filter_trfm

//Custom scoreboard implementation
//We need a custom scoreboard implementation since the implementation of create_filter()
//and connect_filter_and_subscriber() depend on the kind of filter transform that we are employing.
//The rest of the code is a straight copy-paste from cl_syoscbs, as the functionality is the same
class my_custom_syoscbs#(type FIN = int) extends cl_syoscbs_base;

  typedef my_custom_filter_trfm #(FIN, uvm_sequence_item) tp_ft;

  `uvm_component_param_utils(my_custom_syoscbs#(FIN))

  //Function new
  function new(string name="my_custom_syoscbs", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  //Function get_filter_trfm
  virtual function tp_ft get_filter_trfm(string queue_name,
                                                          string producer_name,
                                                          int unsigned idx);
    //Get base object, typecast to this scb's filter transform, return typecasted version
    tp_ft ft;
    uvm_component ft_orig;
    ft_orig = this.get_filter_trfm_base(queue_name, producer_name, idx);
    if(ft_orig == null) begin
      ft = null;
    end else begin
      if(!$cast(ft, ft_orig)) begin
        `uvm_fatal("TYPECAST", "Unable to typecast from uvm_component to filter transform type")
      end
    end
    return ft;
  endfunction: get_filter_trfm

  //Function build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    foreach (this.scbs[i]) begin
      cl_syoscb_cfg tmp_cfg = this.cfg.get_cfg(i);
      this.create_filters(i, tmp_cfg);
    end
  endfunction: build_phase

  //Function connect_phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    foreach (this.fts[i]) begin
      cl_syoscb_cfg tmp_cfg = this.cfg.get_cfg(i);
      this.connect_filters(i, tmp_cfg);
    end
  endfunction: connect_phase

  //Function create_filter
  protected function void create_filter(input string queue_name,
                              input string producer_name,
                              input int unsigned idx);
    string ft_name = $sformatf("ft_%s_%s[%0d]", queue_name, producer_name, idx);
    this.fts[idx][queue_name][producer_name] = tp_ft::type_id::create(ft_name, this);
  endfunction: create_filter

  //Function connect_filter_and_subscriber
  protected function void connect_filter_and_subscriber(input string queue_name,
                                             input string producer_name,
                                             input int unsigned idx);

    cl_syoscb_subscriber scb_subscriber;
    tp_ft ft;

    scb_subscriber = this.scbs[idx].get_subscriber(queue_name, producer_name);
    ft = this.get_filter_trfm(queue_name, producer_name, idx);

    ft.ap.connect(scb_subscriber.analysis_export);
  endfunction: connect_filter_and_subscriber

endclass: my_custom_syoscbs

/// SCBs test using a filter transform not inherited from pk_uvm_utils::filter_trfm, to show that all
/// types of filter transforms work
// All this test does is set a type override from cl_syoscbs_base to my_custom_syoscbs#(cl_tb_seq_item)
// In main phase, verifies that filters are of correct type
class cl_scbs_test_io_custom_filter_trfm extends cl_scbs_test_base#(cl_tb_seq_item,
  cl_tb_tlm_monitor#(cl_tb_seq_item),
  my_custom_filter_trfm#(cl_tb_seq_item, uvm_sequence_item));
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_io_custom_filter_trfm)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scbs_test_io_custom_filter_trfm", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task          main_phase(uvm_phase phase);


endclass: cl_scbs_test_io_custom_filter_trfm


function void cl_scbs_test_io_custom_filter_trfm::pre_build();
  super.pre_build();
  //Perform a factory override of the filter transform to be created
  cl_syoscbs_base::type_id::set_type_override(my_custom_syoscbs#(cl_tb_seq_item)::get_type());
endfunction: pre_build

task cl_scbs_test_io_custom_filter_trfm::main_phase(uvm_phase phase);
  uvm_component uc;
  my_custom_filter_trfm#(cl_tb_seq_item, uvm_sequence_item) mcft;

  phase.raise_objection(this);
  super.main_phase(phase);

  uc = this.scbs_env.syoscbs.get_filter_trfm_base("Q1", "P1", 0);
  if(!$cast(mcft, uc)) begin
    `uvm_fatal("TYPECAST", "uvm_component could not be cast to my_custom_filter_trfm")
  end else if(mcft.analysis_export.get_name() != "my_analysis_imp") begin
    `uvm_fatal("TYPECAST", "my_custom_filter_trfm did not have the correct analysis_imp name")
  end
  phase.drop_objection(this);
endtask: main_phase