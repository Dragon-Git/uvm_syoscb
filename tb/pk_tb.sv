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
package pk_tb;
  timeunit 1ps;
  timeprecision 1ps;

  import uvm_pkg::*;
  import pk_syoscb::*;

  `include "uvm_macros.svh"

  `include "tb_common.svh"
  `include "cl_tb_seq_item.svh"
  `include "cl_tb_seq_item_real.svh"
  `include "cl_tb_seq_item_par.svh"
  `include "cl_tb_tlm_monitor.svh"
  `include "cl_tb_cfg_rnd.svh"
  `include "cl_tb_cov.svh"
  `include "cl_tb_cov_collector.svh"
  `include "cl_tb_env_base.svh"
  `include "cl_tb_arr_wrapper.svh"
  `include "cl_tb_tlm_monitor_param.svh"


  // SCB tests
  `include "cl_syoscb_cfgs.svh"
  `include "cl_tb_rnd_test_items.svh"
  `include "cl_tb_env_scb.svh"
  `include "cl_scb_test_base.svh"
  `include "cl_scb_test_double_scb.svh"
  `include "cl_scb_test_single_scb.svh"
  `include "cl_scb_test_iterator_unit_tests.svh"
  `include "cl_scb_test_iterator_unit_tests_md5.svh"
  `include "cl_scb_test_iterator_correctness.svh"
  `include "cl_scb_test_queue_find_vs_search.svh"
  `include "cl_scb_test_md5.svh"
  `include "cl_scb_test_md5_hash_collisions.svh"
  //IO tests
  `include "cl_scb_test_io_std_comparer_printer.svh"
  `include "cl_scb_test_io_std_comparer_report.svh"
  `include "cl_scb_test_io_std_disable_compare.svh"
  `include "cl_scb_test_io_std_dump_max_size_less.svh"
  `include "cl_scb_test_io_std_dump_max_size.svh"
  `include "cl_scb_test_io_std_dump.svh"
  `include "cl_scb_test_io_std_simple.svh"
  `include "cl_scb_test_io_std_simple_mutexed.svh"
  `include "cl_scb_test_io_std_tlm_mutexed.svh"
  `include "cl_scb_test_io_std_dump_custom_printer.svh"
  `include "cl_scb_test_io_std_intermediate_dump.svh"
  `include "cl_scb_test_io_std_simple_real.svh"
  `include "cl_scb_test_io_std_sbs_print.svh"
  `include "cl_scb_test_io_std_tlm_gp_test.svh"
  `include "cl_scb_test_io_std_insert_item.svh"
  `include "cl_scb_test_io_std_insert_item_md5.svh"
  `include "cl_scb_test_io_md5_disable_compare.svh"
  `include "cl_scb_test_io_md5_dump_orphans.svh"
  `include "cl_scb_test_io_md5_simple.svh"
  //IO-2HP tests
  `include "cl_scb_test_io_2hp_std_simple.svh"
  `include "cl_scb_test_io_2hp_md5_simple.svh"
  `include "cl_scb_test_io_2hp_std_sbs_print.svh"
  //OOO tests
  `include "cl_scb_test_ooo_heavy_base.svh"
  `include "cl_scb_test_ooo_io_md5_simple.svh"
  `include "cl_scb_test_ooo_io_std_simple.svh"
  `include "cl_scb_test_ooo_md5_gp.svh"
  `include "cl_scb_test_ooo_md5_heavy.svh"
  `include "cl_scb_test_ooo_md5_simple.svh"
  `include "cl_scb_test_ooo_md5_duplets.svh"
  `include "cl_scb_test_ooo_md5_tlm.svh"
  `include "cl_scb_test_ooo_std_gp.svh"
  `include "cl_scb_test_ooo_std_heavy.svh"
  `include "cl_scb_test_ooo_std_simple.svh"
  `include "cl_scb_test_ooo_std_tlm_filter_trfm.svh"
  `include "cl_scb_test_ooo_std_tlm.svh"
  `include "cl_scb_test_ooo_std_max_search_window.svh"
  `include "cl_scb_test_ooo_std_dump_orphans.svh"
  `include "cl_scb_test_ooo_std_dump_orphans_xml.svh"
  `include "cl_scb_test_ooo_std_dump_orphans_abort.svh"
  `include "cl_scb_test_ooo_md5_validate.svh"
  `include "cl_scb_test_ooo_std_primary_multiple.svh"
  `include "cl_scb_test_ooo_std_trigger_greed.svh"
  //IOP tests
  `include "cl_scb_test_iop_std_simple.svh"
  `include "cl_scb_test_iop_md5_simple.svh"
  `include "cl_scb_test_iop_std_sbs_print.svh"
  `include "cl_scb_test_iop_std_msw.svh"
  //Misc tests
  `include "cl_scb_test_rnd.svh"
  `include "cl_scb_test_copy_cfg.svh"
  `include "cl_scb_test_uvm_xml_printer.svh"


  //CMP tests
  `include "cl_tb_cmp_seq_item_base.svh"
  `include "cl_tb_cmp_a_f_seq_item.svh"
  `include "cl_tb_cmp_a_d_seq_item.svh"
  `include "cl_tb_cmp_a_m_seq_item.svh"
  `include "cl_tb_cmp_b_f_seq_item.svh"
  `include "cl_tb_cmp_b_d_seq_item.svh"
  `include "cl_tb_cmp_b_m_seq_item.svh"
  `include "cl_scb_test_cmp_base.svh"
  `include "cl_scb_test_cmp_ooo.svh"
  `include "cl_scb_test_cmp_io.svh"


  // SCBs tests
  `include "cl_tb_env_scbs.svh"
  `include "cl_scbs_test_base.svh"
  `include "cl_scbs_test_io_std_base.svh"
  `include "cl_scbs_test_io_std_cc.svh"
  `include "cl_scbs_test_iop_std_base.svh"
  `include "cl_scbs_test_ooo_std_base.svh"
  `include "cl_scbs_test_ooo_std_flush.svh"
  `include "cl_scbs_test_filter_trfm_param.svh"
  `include "cl_scbs_test_io_custom_filter_trfm.svh"

  // Benchmarks
  `include "cl_scb_test_benchmark.svh"

endpackage: pk_tb
