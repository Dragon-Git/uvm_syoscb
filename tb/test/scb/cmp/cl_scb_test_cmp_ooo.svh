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
/// Base class for specializations of cl_scb_test_cmp_base using OOO compare.
/// Implementations are provided below using typedefs
/// \param ATYPE Type of the top-level objects to instantiate
/// \param suffix A string suffix to add to the nest name
class cl_scb_test_cmp_ooo#(type ATYPE = cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                           string suffix = "") extends cl_scb_test_cmp_base#(ATYPE);

  typedef uvm_component_registry #(cl_scb_test_cmp_ooo #(ATYPE, suffix), $sformatf("cl_scb_test_cmp_ooo_%s", suffix)) type_id;

  static function type_id get_type();
    return type_id::get();
  endfunction

  virtual function uvm_object_wrapper get_object_type();
    return type_id::get();
  endfunction

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_cmp_ooo", uvm_component parent = null);
  extern virtual function void pre_build();
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern virtual function void drive_stimuli(string queue, string producer, stim_wrapper stim);

endclass: cl_scb_test_cmp_ooo

function cl_scb_test_cmp_ooo::new(string name = "cl_scb_test_cmp_ooo", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void cl_scb_test_cmp_ooo::pre_build();
  super.pre_build();
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
endfunction: pre_build

function void cl_scb_test_cmp_ooo::drive_stimuli(string queue, string producer, stim_wrapper stim);
  if(queue == "Q2") begin
    stim.items.shuffle();
  end

  foreach(stim.items[i]) begin
    scb_env.syoscb[0].add_item(queue, producer, stim.items[i]);
  end
endfunction: drive_stimuli

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                               "ff") cl_scb_test_cmp_ooo_ff;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                                "fd") cl_scb_test_cmp_ooo_fd;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                                "fm") cl_scb_test_cmp_ooo_fm;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                                "df") cl_scb_test_cmp_ooo_df;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                                "dd") cl_scb_test_cmp_ooo_dd;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                                "dm") cl_scb_test_cmp_ooo_dm;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                                "mf") cl_scb_test_cmp_ooo_mf;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                                "md") cl_scb_test_cmp_ooo_md;

typedef cl_scb_test_cmp_ooo#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                                "mm") cl_scb_test_cmp_ooo_mm;


