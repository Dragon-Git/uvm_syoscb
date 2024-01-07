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
//FIN: The type of sequence items generated, which are then transformed to uvm_sequence_item in the filter transfrom
//MON: The type of monitors to be used. Must be parameterized to accept items of type FIN
//FT : The type of filter transform that is used in the scoreboard wrapper. Must be parameterized correctly w.r.t the type FIN
class cl_tb_env_scbs#(type FIN = cl_tb_seq_item,
                     type MON = cl_tb_tlm_monitor#(cl_tb_seq_item),
                     type FT = pk_utils_uvm::filter_trfm#(FIN, uvm_sequence_item)) extends cl_tb_env_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  //Factory override of syoscbs in cl_scbs_test_base::pre_build
  cl_syoscbs_base syoscbs;
  cl_syoscbs_cfg              syoscbs_cfg;

  MON monitors[][string][string];

  int unsigned no_scbs     = NO_OF_SCBS;
  string       queues[]    = {"Q1", "Q2"};
  string       producers[] = {"P1"};

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_param_utils_begin(cl_tb_env_scbs#(FIN, MON, FT))
     `uvm_field_object(syoscbs, UVM_ALL_ON)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
endclass: cl_tb_env_scbs

function cl_tb_env_scbs::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

function void cl_tb_env_scbs::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.syoscbs_cfg = cl_syoscbs_cfg::type_id::create("syoscbs_cfg");

  // Get cfg object created in test base
  if(!uvm_config_db #(cl_syoscbs_cfg)::get(this, "", "cfg", this.syoscbs_cfg)) begin
    `uvm_fatal("ENV_SCBS", "syoscds_cfg not forwarded to env!")
  end

  // At this point syoscbs_cfg has only an array of cfg inside it. Now I call the
  // init method for giving it the missing cfg informations provided from the env
  this.syoscbs_cfg.init("myscbs", this.no_scbs, {}, this.queues, this.producers);

  uvm_config_db #(cl_syoscbs_cfg)::set(this, "syoscbs", "cfg", this.syoscbs_cfg);

  this.syoscbs = cl_syoscbs_base::type_id::create("syoscbs", this);

  this.monitors = new[this.no_scbs];

  foreach(this.monitors[i]) begin
    foreach (this.queues[j]) begin
      foreach (this.producers[k]) begin
        this.monitors[i][queues[j]][producers[k]] = MON::type_id::create(
          $sformatf("mon%s%s[%0d]", queues[j], producers[k], i), this);
      end
    end
  end

endfunction: build_phase

function void cl_tb_env_scbs::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  foreach(this.monitors[i]) begin
    foreach (this.queues[j]) begin
      foreach (this.producers[k]) begin
        FT ft;
        uvm_component uc;
        MON mon;

        //We cannot call get_filter_trfm, since the scoreboard is defined as just the base class
        //Instead, we get the uvm_component, then cast it to correct filter-transform type and then access the analysis_export
        uc = this.syoscbs.get_filter_trfm_base(queues[j], producers[k], i);
        if(!$cast(ft, uc)) begin
          `uvm_fatal("TYPECAST", "Unable to typecast from uvm_component to filter transform type")
        end

        mon = this.monitors[i][queues[j]][producers[k]];

        mon.anls_port.connect(ft.analysis_export);
      end
    end
  end
endfunction: connect_phase
