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
/// Base class for specializations of cl_scb_test_cmp_base using IO compare.
/// Implementations are provided below using typedefs
/// \param ATYPE Type of the top-level objects to instantiate
/// \param suffix A string suffix to add to the nest name
class cl_scb_test_cmp_io#(type ATYPE = cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                          string suffix = "") extends cl_scb_test_cmp_base#(ATYPE);

  //Since this is a parameterized test which we wish to run directly, we can't use the uvm factory macros
  //https://forums.accellera.org/topic/730-running-a-parameterized-test/
  typedef uvm_component_registry #(cl_scb_test_cmp_io#(ATYPE, suffix), $sformatf("cl_scb_test_cmp_io_%s", suffix)) type_id;

  static function type_id get_type();
    return type_id::get();
  endfunction

  virtual function uvm_object_wrapper get_object_type();
    return type_id::get();
  endfunction

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_cmp_io", uvm_component parent = null);

  extern virtual function void check_phase(uvm_phase phase);

endclass: cl_scb_test_cmp_io

function cl_scb_test_cmp_io::new(string name = "cl_scb_test_cmp_io", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void cl_scb_test_cmp_io::check_phase(uvm_phase phase);
  uvm_report_server rs;
  int num_cmp_err;
  super.check_phase(phase);

  //We expect exactly 7 errors to have occured
  rs = uvm_report_server::get_server();
  num_cmp_err = rs.get_id_count("COMPARE_ERROR");

  if(num_cmp_err != 7) begin
    `uvm_error("TEST", $sformatf("Number of COMPARE_ERRORs was not 1 as expected. Got %0d COMPARE_ERROR instead", num_cmp_err))
  end
endfunction: check_phase

// Specializations: The suffix <xy> indicates which comparison method is used in a/b respectively:
// f: field macros. d: manual do_compare implementation. m: mix of field macros and manual do_compare implementation
typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                             "ff") cl_scb_test_cmp_io_ff;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                              "fd") cl_scb_test_cmp_io_fd;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_f_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                              "fm") cl_scb_test_cmp_io_fm;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                              "df") cl_scb_test_cmp_io_df;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                              "dd") cl_scb_test_cmp_io_dd;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_d_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                              "dm") cl_scb_test_cmp_io_dm;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_f_seq_item#(cl_tb_seq_item)),
                              "mf") cl_scb_test_cmp_io_mf;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_d_seq_item#(cl_tb_seq_item)),
                              "md") cl_scb_test_cmp_io_md;

typedef cl_scb_test_cmp_io#(cl_tb_cmp_a_m_seq_item#(cl_tb_cmp_b_m_seq_item#(cl_tb_seq_item)),
                              "mm") cl_scb_test_cmp_io_mm;


