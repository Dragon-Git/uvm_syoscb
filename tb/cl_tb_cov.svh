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
class cl_tb_cov extends uvm_object;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_tb_cov)
  `uvm_object_utils_end

  // Covergroup defining cfg configuration statuses for built-in knobs
  covergroup cg_knob_status(
    string name
  ) with function sample (cl_syoscb_cfg cfg, cl_syoscb_queue_base queue);

    option.per_instance = 1;
    option.name         = name;

    cp_queue_type: coverpoint(cfg.get_queue_type()) {
      bins STD          = {pk_syoscb::SYOSCB_QUEUE_STD         };
      bins MD5          = {pk_syoscb::SYOSCB_QUEUE_MD5         };
      ignore_bins USER_DEFINED = {pk_syoscb::SYOSCB_QUEUE_USER_DEFINED};
      illegal_bins ilg_action = default;
    }

    cp_compare_type: coverpoint (cfg.get_compare_type()) {
      bins IO           = {pk_syoscb::SYOSCB_COMPARE_IO          };
      bins IO2HP        = {pk_syoscb::SYOSCB_COMPARE_IO2HP       };
      bins IOP          = {pk_syoscb::SYOSCB_COMPARE_IOP         };
      bins OOO          = {pk_syoscb::SYOSCB_COMPARE_OOO         };
      ignore_bins USER_DEFINED = {pk_syoscb::SYOSCB_COMPARE_USER_DEFINED};
      illegal_bins ilg_action = default;
    }

    cp_trigger_greediness_status : coverpoint (cfg.get_trigger_greediness()) {
      bins NOT_GREEDY = {pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY};
      bins GREEDY     = {pk_syoscb::SYOSCB_COMPARE_GREEDY    };
      illegal_bins ilg_action = default;
    }

    cp_end_greediness_status : coverpoint (cfg.get_end_greediness()) {
      bins NOT_GREEDY = {pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY};
      bins GREEDY     = {pk_syoscb::SYOSCB_COMPARE_GREEDY    };
      illegal_bins ilg_action = default;
    }

    cp_queues_cnt_inserted_item: coverpoint(queue.get_cnt_add_item()) {
      bins val[]   = {[0    :9    ]};
      bins rng_10  = {[10   :99   ]};
      bins rng_100 = {[100  :999  ]};
      bins rng_1k  = {[1000 :1999 ]};
      bins rng_2k  = {[2000 :2999 ]};
      bins rng_3k  = {[3000 :3999 ]};
      bins rng_4k  = {[4000 :4999 ]};
      bins rng_5k  = {[5000 :5999 ]};
      bins rng_6k  = {[6000 :6999 ]};
      bins rng_7k  = {[7000 :7999 ]};
      bins rng_8k  = {[8000 :8999 ]};
      bins rng_9k  = {[9000 :9999 ]};
      bins rng_10_15_k = {[10000:15000]};
      illegal_bins ilg_action = default;
    }

    cp_max_queues_size: coverpoint(queue.get_max_items()){
      bins val[]   = {[0    :9    ]};
      bins rng_10  = {[10   :99   ]};
      bins rng_100 = {[100  :999  ]};
      bins rng_1k  = {[1000 :1999 ]};
      bins rng_2k  = {[2000 :2999 ]};
      bins rng_3k  = {[3000 :3999 ]};
      bins rng_4k  = {[4000 :4999 ]};
      bins rng_5k  = {[5000 :5999 ]};
      bins rng_6k  = {[6000 :6999 ]};
      bins rng_7k  = {[7000 :7999 ]};
      bins rng_8k  = {[8000 :8999 ]};
      bins rng_9k  = {[9000 :9999 ]};
      bins rng_10_15_k = {[10000:15000]};
      illegal_bins ilg_action = default;
    }

    cp_queues_number:coverpoint(cfg.size_queues()){
      bins num[] = {[2 : 5]};
      illegal_bins ilg_action = default;
    }

    cp_enable_no_insert_check_status: coverpoint(cfg.get_enable_no_insert_check()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_disable_clone_status: coverpoint(cfg.get_disable_clone()) {
      bins enabled  = {0};
      bins disabled = {1};
      illegal_bins ilg_action = default;
    }

    cp_disable_compare_after_error_status: coverpoint(cfg.get_disable_compare_after_error()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_print_cfg_status: coverpoint(cfg.get_print_cfg()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_is_dynamic_primary_queue: coverpoint(cfg.dynamic_primary_queue()) {
      bins static_primary  = {0};
      bins dynamic_primary = {1};
      illegal_bins ilg_action = default;
    }

    cp_orphans_as_errors_status: coverpoint(cfg.get_orphans_as_errors()){
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_max_print_orphans_values: coverpoint(cfg.get_max_print_orphans()){
      bins none      = {-1};
      bins all       = {0};
      bins val_1_9   = {[1 :9 ]};
      bins val_10_19 = {[10:19]};
      bins val_20_49 = {[20:49]};
      bins val_up_50 = {[50:$ ]};
      illegal_bins ilg_action = default;
    }

    cp_disable_report_status: coverpoint(cfg.get_disable_report()) {
      bins enabled  = {0};
      bins disabled = {1};
      illegal_bins ilg_action = default;
    }

    cp_ordered_next_status: coverpoint(cfg.get_ordered_next()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_full_scb_dump_status: coverpoint(cfg.get_full_scb_dump()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_scb_report_type: coverpoint(cfg.get_full_scb_dump_type()) {
      bins TXT = {pk_syoscb::TXT};
      bins XML = {pk_syoscb::XML};
      illegal_bins ilg_action = default;
    }

    cp_full_scb_dump_split_status: coverpoint(cfg.get_full_scb_dump_split()) {
      bins enabled  = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_enable_comparer_report: coverpoint(cfg.get_default_enable_comparer_report()) {
      bins zero = {0};
      bins one  = {1};
      illegal_bins ilg_action = default;
    }

    cp_printer_verbosity_status: coverpoint(cfg.get_default_printer_verbosity()) {
      bins zero = {0};
      bins one  = {1};
      illegal_bins ilg_action = default;
    }

    cp_add_item_mutexed: coverpoint(cfg.get_mutexed_add_item_enable()) {
      bins enabled = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_dump_orphans_to_files: coverpoint(cfg.get_dump_orphans_to_files()) {
      bins enabled = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_enable_c2s_full_scb_dump: coverpoint(cfg.get_enable_c2s_full_scb_dump()) {
      bins enabled = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    //Must be dumped with dump orphans to files
    cp_orphan_dump_type: coverpoint(cfg.get_orphan_dump_type()) {
      bins TXT = {pk_syoscb::TXT};
      bins XML = {pk_syoscb::XML};
      illegal_bins ilg_action = default;
    }

    //Must be crossed with queue type (md5 vs all others)
    cp_hash_compare_check: coverpoint(cfg.get_hash_compare_check()) {
      bins NONE = {pk_syoscb::SYOSCB_HASH_COMPARE_NO_VALIDATION};
      bins MATCH = {pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_MATCH};
      bins NO_MATCH = {pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_NO_MATCH};
      bins ALL = {pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_ALL};
      illegal_bins ilg_action = default;
    }

    cp_scb_stat_interval: coverpoint(cfg.get_scb_stat_interval()) {
      bins val_0 = {0};
      bins val_up_1 = {[1:$]};
      illegal_bins ilg_action = default;
    }

    cp_full_scb_max_queue_size: coverpoint(cfg.get_max_queue_size(queue.get_name())) {
      bins val_o = {0};
      bins val_up_1 = {[1:$]};
      illegal_bins ilg_action = default;
    }

    cp_max_search_window: coverpoint(cfg.get_max_search_window(queue.get_name())) {
      bins val_0 = {0};
      bins val_up_1 = {[1:$]};
      illegal_bins ilg_action = default;
    }

    cp_enable_queue_stats: coverpoint(cfg.get_enable_queue_stats(queue.get_name())) {
      bins enabled = {1};
      bins disabled = {0};
      illegal_bins ilg_action = default;
    }

    cp_queue_stat_interval: coverpoint(cfg.get_queue_stat_interval(queue.get_name())) {
      bins val_0 = {0};
      bins val_up_1 = {[1:$]};
      illegal_bins ilg_action = default;
    }


    // Cross between queue types and compare strategies (queues-strategy)
    cr_qtype_cstrategy : cross cp_queue_type, cp_compare_type;

    // Cross between trigger and end greediness values
    cr_trigger_end_greediness : cross cp_trigger_greediness_status, cp_end_greediness_status;

    // Cross between (tr-end greediness) and all combos (type-strategy)
    cr_greed_all_type_strategy : cross cr_trigger_end_greediness, cr_qtype_cstrategy;

    // Cross between inserted item in queues and all combinations (queue-strategy)
    cr_cnt_item_queues_type_strategy : cross cp_queues_cnt_inserted_item, cr_qtype_cstrategy;

    // Cross between the maximum number of insertions in queues and all combos (queue-strategy)
    cr_max_queues_type_strategy : cross cp_max_queues_size, cr_qtype_cstrategy;

    // Cross between report type and dump split. Excludes cross bins when scb dump is disabled
    cr_report_and_split_type : cross cp_scb_report_type, cp_full_scb_dump_split_status {
      ignore_bins dump_inactive = binsof(cp_full_scb_dump_split_status) intersect {0};
    }

    // Cross between (queues-strategy) and no insert check
    cr_type_strategy_no_insert_check : cross cr_qtype_cstrategy, cp_enable_no_insert_check_status;

    // Cross between (queues-strategy) and disable clone
    cr_type_strategy_disable_clone : cross cr_qtype_cstrategy, cp_disable_clone_status;

    // Cross between (queues-strategy) and disable compare after error
    cr_type_strategy_disable_compare_after_error : cross cr_qtype_cstrategy,
                                                         cp_disable_compare_after_error_status;

    // Cross between (queues-strategy) and is dynamic primary queue
    cr_type_strategy_is_dynamic_queue : cross cr_qtype_cstrategy, cp_is_dynamic_primary_queue;

    // Cross between (queues-strategy) and ordered next.
    // Exclude the cases when queue is MD5 and comparison is "in-order" type, while we don't keep the
    // informations about the insertion order (combinations not allowed)
    cr_type_strategy_ordered_next : cross cp_queue_type, cp_compare_type, cp_ordered_next_status{
      ignore_bins md5_illegal_use_cio = binsof(
                                        cp_queue_type.MD5) intersect {pk_syoscb::SYOSCB_COMPARE_IO,
                                                                      pk_syoscb::SYOSCB_COMPARE_IOP,
                                                                      pk_syoscb::SYOSCB_COMPARE_IO2HP}
                                                                      with (cp_ordered_next_status == 0);
    }

    // Cross between (queues-strategy) and comparer verbosity
    cr_type_strategy_comparer_verbosity : cross cr_qtype_cstrategy, cp_enable_comparer_report;

    // Cross between (queues-strategy) and printer verbosity
    cr_type_strategy_printer_verbosity : cross cr_qtype_cstrategy, cp_printer_verbosity_status;

    // Cross between (orphan report status and orphan print max values). Exclude cross bins
    // when the orphans are printed as errors
    cr_orphans_stat_print_val: cross cp_orphans_as_errors_status, cp_max_print_orphans_values{
      ignore_bins error_inactive = binsof(cp_orphans_as_errors_status) intersect {0};
    }

    // Cross between the cross report (orphans as print - threshold max values) and (type of queue)
    cr_orphan_print_per_queue: cross cr_orphans_stat_print_val, cp_queue_type;

    //Cross between (queues-strategy) and add_item_enable
    cr_type_strategy_add_item_enable : cross cr_qtype_cstrategy, cp_add_item_mutexed;

    //Cross between orphan dump type and orphan dump enable
    cr_orphan_dump: cross cp_orphan_dump_type, cp_dump_orphans_to_files {
      ignore_bins dotf_disabled = binsof(cp_dump_orphans_to_files) intersect {0};
    }

    //Cross between queue type and hash compare enable
    cr_queue_type_hash_compare: cross cp_hash_compare_check, cp_queue_type {
      ignore_bins std_disabled = binsof(cp_queue_type) intersect {pk_syoscb::SYOSCB_QUEUE_STD,
                                                                  pk_syoscb::SYOSCB_QUEUE_USER_DEFINED};
    }

  endgroup

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_cov");
    super.new(name);

    // create basic knob status cogergroup
    this.cg_knob_status = new($sformatf("%s.cg_knob_status", name));
  endfunction : new

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern function void sample(cl_syoscb_cfg cfg);
endclass: cl_tb_cov

function void cl_tb_cov::sample(cl_syoscb_cfg cfg);
  string               l_queue_names[];
  cl_syoscb_queue_base l_queue;

  cfg.get_queues(l_queue_names);

  // Note: we are aware that, in this way, the coverage collected using cfg is sampled twice.
  foreach(l_queue_names[i]) begin
    l_queue = cfg.get_queue(l_queue_names[i]);
    this.cg_knob_status.sample(cfg, l_queue);
  end
endfunction: sample
