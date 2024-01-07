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
/// Default implementation of a scoreboard wrapper.
/// FIN: The type of input transactions. Output transactions will be of type uvm_sequence_item
class cl_syoscbs #(type FIN = int) extends cl_syoscbs_base;

  /// Define the filter transform type for the wrapper
  typedef pk_utils_uvm::filter_trfm #(FIN, uvm_sequence_item) tp_wrapper_filter_trfm;

  //-------------------------------------
  // UVM_Macros
  //-------------------------------------
  `uvm_component_param_utils_begin(cl_syoscbs#(FIN))

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscbs", uvm_component parent = null);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

  //-------------------------------------
  // Misc. functions for internal usage
  //-------------------------------------
  extern virtual protected function void create_filter(input string queue_name,
                                                   input string producer_name,
                                                   input int unsigned idx);
  extern virtual protected function void connect_filter_and_subscriber(input string queue_name,
                                                                   input string producer_name,
                                                                   input int unsigned idx);


  // *NOTE*: Function has to inline to work across all simulators
  //         Some have problems accepting FIN in the return type, stating that FIN is not defined
  /// Gets a handle to a filter transform
  /// This convenience wrapper gets a filter transform and typecasts it to the correct
  /// type for the user
  /// \param queue_name The name of the queue to connect the filter to
  /// \param producer_name The name of the producer that produced data going into this filter
  /// \param idx The index of the scoreboard in which this queue exists
  /// \return A filter transform object, if all parameters are valid.
  ///         If the parameters do not specify a valid filter, returns null and prints a UVM_INFO/DEBUG message
  virtual function cl_syoscbs::tp_wrapper_filter_trfm get_filter_trfm(string queue_name,
                                                                      string producer_name,
                                                                      int unsigned idx);
  tp_wrapper_filter_trfm ft;
  uvm_component ft_orig;
  ft_orig = this.get_filter_trfm_base(queue_name, producer_name, idx);
  if(ft_orig == null) begin
    ft = null;
  end else begin
    if(!$cast(ft, ft_orig)) begin
      `uvm_fatal("TYPECAST",$sformatf("Unable to typecast filter transform from uvm_component to %0p. Type was %0p",ft.get_type(), ft_orig.get_type()))
    end
  end
  return ft;
endfunction: get_filter_trfm
endclass: cl_syoscbs

function cl_syoscbs::new(string name = "cl_syoscbs", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

function void cl_syoscbs::build_phase(uvm_phase phase);
  super.build_phase(phase);

  foreach (this.scbs[i]) begin
    cl_syoscb_cfg tmp_cfg = this.cfg.get_cfg(i);
    this.create_filters(i, tmp_cfg);
  end
endfunction: build_phase

function void cl_syoscbs::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach (this.fts[i]) begin
    cl_syoscb_cfg tmp_cfg = this.cfg.get_cfg(i);
    this.connect_filters(i, tmp_cfg);
  end
endfunction: connect_phase

function void cl_syoscbs::create_filter(input string queue_name,
                                        input string producer_name,
                                        input int unsigned idx);
  // ft_name (filter name) = ft_<queue_name>_<producer_name>[<scoreboard index>]
  string ft_name = $sformatf("ft_%s_%s[%0d]", queue_name, producer_name, idx);

  this.fts[idx][queue_name][producer_name] = cl_syoscbs::tp_wrapper_filter_trfm::type_id::create(ft_name, this);
endfunction: create_filter

function void cl_syoscbs::connect_filter_and_subscriber(input string queue_name,
                                             input string producer_name,
                                             input int unsigned idx);
  cl_syoscb_subscriber scb_subscriber;
  uvm_component ft_orig;
  cl_syoscbs::tp_wrapper_filter_trfm ft;

  scb_subscriber = this.scbs[idx].get_subscriber(queue_name, producer_name);
  ft_orig = this.fts[idx][queue_name][producer_name];
  if(!$cast(ft, ft_orig)) begin
    `uvm_fatal("TYPECAST", $sformatf("Unable to typecast filter transform from uvm_component to %p", ft.get_type_name()))
  end

  ft.ap.connect(scb_subscriber.analysis_export);
endfunction: connect_filter_and_subscriber
