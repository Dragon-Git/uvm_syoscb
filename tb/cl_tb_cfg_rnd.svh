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
class cl_tb_cfg_rnd extends uvm_object;
  rand t_scb_queue_type queue_type;

  rand t_scb_compare_type compare_type;

  rand t_scb_compare_greed trigger_greediness;

  rand t_scb_compare_greed end_greediness;

  rand bit enable_no_insert_check;

  rand bit disable_clone;

  rand bit disable_compare_after_error;

  rand bit dynamic_primary_queue;

  rand bit orphans_as_errors;

  rand int max_print_orphans;

  rand bit disable_report;

  rand bit full_scb_dump;

  rand bit full_scb_dump_split;

  rand t_dump_type full_scb_dump_type;

  rand bit ordered_next;

  rand bit default_enable_comparer_report;

  rand bit default_printer_verbosity;

  rand bit print_cfg;

  rand bit full_scb_max_queue_size;

  //Only when queue type is md5
  rand t_hash_compare_check hash_compare_check;

  //only valid when compare type is OOO or IOP
  //Requires some thought in how to correctly implement in rand tests
  rand int unsigned max_search_window;

  rand bit mutexed_add_item_enable;

  rand int unsigned queue_stat_interval;

  rand int unsigned scb_stat_interval;

  // Since user defined queue implementation is depending by the user,
  // we don't want to test this case internally.
  constraint c_queue_type_no_user_def {
    this.queue_type != pk_syoscb::SYOSCB_QUEUE_USER_DEFINED;
  }

  // Since user defined comparison implementation is depending by the user,
  // we don't want to test this case internally.
  constraint c_compare_type_no_user_def {
    this.compare_type != pk_syoscb::SYOSCB_COMPARE_USER_DEFINED;
  }

  // For now, just TXT dump file format is supported into scb
  constraint c_full_scb_type_supported {
    this.full_scb_dump_type == pk_syoscb::TXT;
  }

  // Using an MD5 queue, the "in-order" compare make sense only if ordered next is 1'b1.
  // Moreover, since the domain change between the item and its hash digest doesn't
  // preserve the insertion order in the domain of time (The hash digest is a value which
  // can't be defined a priori, unless ordered next is = 1) it  migh be that some matches
  // can be resolved only once the queues have been filled and each hash has been computed.
  // For this reason, one between trigger or end greediness must be greedy. in this condition
  // we know that one of the two drains mechanism will resolve the mathces inside the queues
  // If not, some orphans will be found.
  constraint c_qmd5_cio_only_ordered {
    if (this.ordered_next == 1'b0 && this.queue_type == pk_syoscb::SYOSCB_QUEUE_MD5){
      this.compare_type inside {pk_syoscb::SYOSCB_COMPARE_OOO,
                                pk_syoscb::SYOSCB_COMPARE_USER_DEFINED};
      this.trigger_greediness != this.end_greediness;
    }
  }

  // Set a value for maximum number of print orphans
  constraint c_max_print_orphans {
    this.max_print_orphans dist{
      [0 :9 ] :/ 10,
      [10:19] :/ 10,
      [20:49] :/ 10,
      [50:$ ] :/ 1,
       -1     :/ 1
    };
  }

  constraint c_queue_stat_interval {
    this.queue_stat_interval dist {
      0     :/ 1,
      [1:$] :/ 1
    };
  }

  constraint c_scb_stat_interval {
    this.scb_stat_interval dist {
      0     :/ 1,
      [1:$] :/ 1
    };
  }

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_tb_cfg_rnd)
    `uvm_field_int(disable_report,                           UVM_DEFAULT)
    `uvm_field_enum(t_scb_queue_type, queue_type,            UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_type, compare_type,        UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_greed, trigger_greediness, UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_greed, end_greediness,     UVM_DEFAULT)
    `uvm_field_int(disable_clone,                            UVM_DEFAULT)
    `uvm_field_int(enable_no_insert_check,                   UVM_DEFAULT)
    `uvm_field_int(disable_compare_after_error,              UVM_DEFAULT)
    `uvm_field_int(dynamic_primary_queue,                    UVM_DEFAULT)
    `uvm_field_int(orphans_as_errors,                        UVM_DEFAULT)
    `uvm_field_int(max_print_orphans,                        UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(disable_report,                           UVM_DEFAULT)
    `uvm_field_int(full_scb_dump,                            UVM_DEFAULT)
    `uvm_field_int(full_scb_dump_split,                      UVM_DEFAULT)
    `uvm_field_enum(t_dump_type, full_scb_dump_type,              UVM_DEFAULT)
    `uvm_field_int(ordered_next,                             UVM_DEFAULT)
    `uvm_field_int(default_printer_verbosity,                UVM_DEFAULT)
    `uvm_field_int(default_enable_comparer_report,           UVM_DEFAULT)
    `uvm_field_int(print_cfg,                                UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_cfg_rnd");
    super.new(name);
  endfunction : new

  extern function void set_rnd_fields(cl_syoscb_cfg cfg);
endclass: cl_tb_cfg_rnd


function void cl_tb_cfg_rnd::set_rnd_fields(cl_syoscb_cfg cfg);
  cfg.set_queue_type(this.queue_type);
  cfg.set_compare_type(this.compare_type);

  cfg.set_trigger_greediness(this.trigger_greediness);
  cfg.set_end_greediness(this.end_greediness);

  cfg.set_enable_no_insert_check(this.enable_no_insert_check);
  cfg.set_disable_clone(this.disable_clone);
  cfg.set_disable_compare_after_error(this.disable_compare_after_error);
  cfg.set_orphans_as_errors(this.orphans_as_errors);
  cfg.set_max_print_orphans(this.max_print_orphans);
  cfg.set_disable_report(this.disable_report);
  cfg.set_full_scb_dump(this.full_scb_dump);
  cfg.set_ordered_next(this.ordered_next);
  void'(cfg.set_full_scb_dump_split(this.full_scb_dump_split));
  cfg.set_full_scb_dump_type(this.full_scb_dump_type);
  cfg.set_default_enable_comparer_report(this.default_enable_comparer_report);
  cfg.set_default_printer_verbosity(this.default_printer_verbosity);
  cfg.set_print_cfg(this.print_cfg);
  cfg.set_hash_compare_check(this.hash_compare_check);
  cfg.set_scb_stat_interval(this.scb_stat_interval);
endfunction: set_rnd_fields
