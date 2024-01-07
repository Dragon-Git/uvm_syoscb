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
/// Base class for a wrapper around multiple SyoSil Scoreboards.
/// An implementation is found in cl_syoscbs_base
class cl_syoscbs_base extends uvm_component;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------

  /// Array holding handles to all scoreboards
  protected cl_syoscb scbs[];

  /// Handle to scoreboard wrapper configuration object
  protected cl_syoscbs_cfg cfg;

  /// Array holding handles to filter transforms, used to transform inputs of one type
  /// to outputs of another type, for feeding into the wrapped scoreboards.
  /// Declared as type \c uvm_component for flexibility. See example of implementation in cl_syoscbs_base.
  /// AA is indexed by [scb_idx][queue_name][producer_name]
  protected uvm_component fts[][string][string];


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscbs_base)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscbs_base", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // UVM Phase Methods
  //-------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

  //-------------------------------------
  // Function based API
  //-------------------------------------
  extern virtual function cl_syoscbs_cfg   get_cfg();
  extern virtual function cl_syoscb        get_scb(int unsigned idx);
  extern virtual function void             flush_queues_all();
  extern virtual function void             flush_queues_by_index(int unsigned idxs[] = {},
                                                                 string queue_names[] = {});
  extern virtual function void             flush_queues_by_name(string scb_names[] = {},
                                                                string queue_names[] = {});
  extern virtual function void             compare_control_all(bit cc);
  extern virtual function void             compare_control_by_index(int unsigned idxs[] = {}, bit cc);
  extern virtual function void             compare_control_by_name(string scb_names[]   = {}, bit cc);
  extern protected virtual function string create_scb_stats(int unsigned offset,
                                                            int unsigned first_column_width);
  extern virtual function string           create_report(int unsigned offset,
                                                         int unsigned first_column_width);
  extern virtual function uvm_component    get_filter_trfm_base(string queue_name,
                                                               string producer_name,
                                                               int unsigned idx);

  //-------------------------------------
  // Misc. Functions for internal usage
  //-------------------------------------
  extern virtual protected function void   create_filters(int unsigned idx, cl_syoscb_cfg cfg);
  extern virtual protected function void   connect_filters(int unsigned idx, cl_syoscb_cfg cfg);
  extern virtual protected function void   create_filter(string queue_name,
                                                         string producer_name,
                                                         int unsigned idx);
  extern virtual protected function void   connect_filter_and_subscriber(string queue_name,
                                                                       string producer_name,
                                                                       int unsigned idx);
  extern protected virtual function string create_total_stats(int unsigned offset,
                                                              int unsigned first_column_width);
  extern virtual protected function string get_scb_failed_checks();

  extern virtual function void do_print(uvm_printer printer);
  extern virtual function bit  do_compare(uvm_object rhs, uvm_comparer comparer);
  extern virtual function void do_copy(uvm_object rhs);

endclass: cl_syoscbs_base

/// UVM build phase.
/// Receives a cl_syoscbs_cfg object, creates wrapped scoreboards and their configuration objects,
/// forwards configuration objects to each wrapped scoreboard.
function void cl_syoscbs_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(cl_syoscbs_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", "Configuration object not passed.")
  end

  if(this.cfg.get_scbs_name() == "") begin
    this.cfg.set_scbs_name(this.get_name());
  end

  // Print the SCB cfg according to its internal member field knob
  if(this.cfg.get_print_cfg()) begin
    this.cfg.print();
  end

  //For each scoreboard, create and forward configs and allocate space for filter transforms
  this.scbs = new[this.cfg.get_no_scbs()];
  this.fts  = new[this.cfg.get_no_scbs()];

  foreach (this.scbs[i]) begin
    cl_syoscb_cfg tmp_cfg  = this.cfg.get_cfg(i);
    string        scb_name = tmp_cfg.get_scb_name();

    if(scb_name == "") begin
       scb_name = $sformatf("scb[%0d]", i);
    end

    uvm_config_db #(cl_syoscb_cfg)::set(this, scb_name, "cfg", tmp_cfg);

    this.scbs[i] = cl_syoscb::type_id::create(scb_name, this);
  end
endfunction: build_phase

/// UVM connect phase. syoscbs_base only calls super.connect_phase
function void cl_syoscbs_base::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction: connect_phase

/// UVM report_phase.
/// Prints the status of all scoreboard instances.
function void cl_syoscbs_base::report_phase(uvm_phase phase);
  let max(a,b)      = (a > b) ? a : b;
  let min_width(sl) = ((sl>pk_syoscb::MIN_FIRST_COLUMN_WIDTH)? sl : pk_syoscb::MIN_FIRST_COLUMN_WIDTH);

  super.report_phase(phase);

  if(!this.cfg.get_disable_report()) begin
     int unsigned offset = 2;
     int unsigned first_column_width;
     string stats_str;


     first_column_width = min_width(max(this.cfg.get_max_length_scb_name(),
          max(pk_syoscb::GLOBAL_REPORT_INDENTION+this.cfg.get_max_length_queue_name(),
              (2*pk_syoscb::GLOBAL_REPORT_INDENTION)+this.cfg.get_max_length_producer())));

     stats_str = cl_syoscb_string_library::scb_header_str("Name", offset+first_column_width, 1'b1);

     stats_str = { stats_str, this.create_report(offset, first_column_width) };

     stats_str = { stats_str, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) };

     // *NOTE*: Using this.get_name() is sufficient since the component
     //         instance name is the queue name by definition
     `uvm_info("QUEUE", $sformatf("[%s]: Statistics summary:%s", this.cfg.get_scbs_name(), stats_str), UVM_NONE)
  end

  // Report any errors
  begin
    string failed_checks;

    failed_checks = { failed_checks, this.get_scb_failed_checks() };

    if(failed_checks != "") begin
      `uvm_error("SCB_ERROR", $sformatf("[%s]: scb errors:\n%s", this.cfg.get_scbs_name(), failed_checks))
    end
  end
endfunction: report_phase

/// Gets the configuration object associated with this scoreboard wrapper
function cl_syoscbs_cfg cl_syoscbs_base::get_cfg();
  return this.cfg;
endfunction: get_cfg

/// <b>Scoreboard Wrapper API</b>: Get a handle to a scoreboard inside this wrapper
/// \param idx The index of that scoreboard
/// \return A handle to scoreboard [idx]. If idx >= number of scoreboards, throws a uvm_fatal error
function cl_syoscb cl_syoscbs_base::get_scb(int unsigned idx);
  if(idx >= this.scbs.size()) begin
    `uvm_fatal("SCB_ERROR",
               $sformatf("No scb existing at index %0d. Allowed index range betwen 0 and %0d",
                         idx, this.scbs.size()-1))
    return null;
  end

  return this.scbs[idx];
endfunction: get_scb

/// <b>Scoreboard Wrapper API</b>: Gets a handle to a filter transform as a uvm_component.
/// The end user must typecast this uvm_component to the correct type, based on the kind
/// of filter transforms that is implemented
/// \param queue_name The name of the queue to connect the filter to
/// \param producer_name The name of the producer that produced data going into this filter
/// \param fts_idx The index of the scoreboard in which this queue exists
/// \return A uvm_component which represents a filter, if all parameters are valid.
///         If the parameters do not specify a valid filter, returns null and prints a UVM_INFO/DEBUG message
function uvm_component cl_syoscbs_base::get_filter_trfm_base(string queue_name,
                                                             string producer_name,
                                                             int unsigned idx);
  if(idx < this.fts.size()) begin
    if(this.fts[idx].exists(queue_name)) begin
      if(this.fts[idx][queue_name].exists(producer_name)) begin
        return this.fts[idx][queue_name][producer_name];
      end else begin //Bad producer name
        `uvm_info("BAD_ARG", $sformatf("Producer name %0s was not valid for idx=%0d, queue_name=%0s", producer_name, idx, queue_name), UVM_DEBUG)

      end
    end else begin //Bad queue name
      `uvm_info("BAD_ARG", $sformatf("Queue name %0s was not valid for idx=%0d", queue_name, idx), UVM_DEBUG)

    end
  end else begin //Bad index
    `uvm_info("BAD_ARG", $sformatf("Index %0d was invalid, must be in range 0 to %0d", 0, this.fts.size()-1), UVM_DEBUG)
  end
  return null;
endfunction: get_filter_trfm_base

/// <b>Scoreboard Wrapper API</b>: Flush all queues of all scoreboards.
function void cl_syoscbs_base::flush_queues_all();
  this.flush_queues_by_index();
endfunction: flush_queues_all

/// <b>Scoreboard Wrapper API</b>: Flush the queues indicated by queue_names of the scoreboards with indexes idxs.
/// If no indexes are specified, all scoreboards will be affected by the flush.
/// If no queue names are specified all queues are flushed.
/// \param idxs indexes of the scoreboards to flush
/// \param queue_names Names of the queues under those scoreboards to flush
function void cl_syoscbs_base::flush_queues_by_index(int unsigned idxs[] = {}, string queue_names[] = {});
  if(idxs.size() == 0) begin
    if(queue_names.size() == 0) begin
      foreach (this.scbs[i]) begin
         this.scbs[i].flush_queues();
      end
    end else begin
      foreach (this.scbs[i]) begin
        foreach (queue_names[j]) begin
          this.scbs[i].flush_queues(queue_names[j]);
        end
      end
    end
  end else begin
    if(queue_names.size() == 0) begin
      foreach (idxs[i]) begin
         this.scbs[idxs[i]].flush_queues();
      end
    end else begin
      foreach (idxs[i]) begin
        foreach (queue_names[j]) begin
          this.scbs[idxs[i]].flush_queues(queue_names[j]);
        end
      end
    end
  end
endfunction: flush_queues_by_index

/// <b>Scoreboard Wrapper API</b>: Flush the queues indicated by queue_names of the scoreboards with
/// names scb_names.
/// If no scoreboard names are specified all the scoreboards will be affected by the flush.
/// If no queue names are specified all queues are flushed.
/// \param scb_names Names of the scoreboards to flush
/// \param queue_names Names of the queues under those scoreboards to flush
function void cl_syoscbs_base::flush_queues_by_name(string scb_names[] = {}, string queue_names[] = {});
  if(scb_names.size() == 0) begin
    this.flush_queues_by_index({}, queue_names);
  end else begin
    int unsigned idxs[];

    idxs = new[scb_names.size()];

    foreach (scb_names[i]) begin
      int an_index;

      an_index = this.cfg.get_scb_index_by_name(scb_names[i]);

      // Only the existing scb_names[i] will be flushed
      if(an_index >= 0) begin

        idxs[i] = an_index;
      end
      else begin
        `uvm_fatal("SCB_ERROR", $sformatf("No scb with name '%0s' found.", scb_names[i]))
      end
    end

    this.flush_queues_by_index(idxs, queue_names);
  end
endfunction: flush_queues_by_name

/// <b>Scoreboard Wrapper API</b>: Disable or enable the compare in all scoreboards.
/// \param cc Compare control bit. If 1'b1, enables compare in all scoreboards. If 1'b0, disables compare
function void cl_syoscbs_base::compare_control_all(bit cc);
  this.compare_control_by_index({}, cc);
endfunction: compare_control_all

/// <b>Scoreboard Wrapper API</b>: Disable or enable the compare in scoreboards with given indexes.
/// If no indexes are specified, all scoreboards are affected.
/// \param idxs The indexes of the scoreboards to enable/disable compare control for
/// \param cc Compare control bit. If 1'b1, enables compare in all scoreboards. If 1'b0, disables compare
function void cl_syoscbs_base::compare_control_by_index(int unsigned idxs[] = {}, bit cc);
  if(idxs.size() == 0) begin
    foreach (this.scbs[i]) begin
      this.scbs[i].compare_control(cc);
    end
  end else begin
    foreach (idxs[i]) begin
      this.scbs[idxs[i]].compare_control(cc);
    end
  end
endfunction: compare_control_by_index

/// <b>Scoreboard Wrapper API</b>: Disable or enable the compare in scoreboards with given names.
/// If no names are specified, all scoreboards are affected.
/// \param scb_names The names of the scoreboards to enable/disable compare control for
/// \param cc Compare control bit. If 1'b1, enables compare in all scoreboards. If 1'b0, disables compare
function void cl_syoscbs_base::compare_control_by_name(string scb_names[] = {}, bit cc);
  if(scb_names.size() == 0) begin
    this.compare_control_by_index({}, cc);
  end else begin
    int unsigned idxs[];

    idxs = new[scb_names.size()];

    foreach (scb_names[i]) begin
      int an_index;

      an_index = this.cfg.get_scb_index_by_name(scb_names[i]);

      // Only the existing scb_names[i] will be affected by compare_control change
      if(an_index >= 0) begin

        idxs[i] = an_index;
      end
      else begin
        `uvm_fatal("SCB_ERROR", $sformatf("No scb name '%0s' found.", scb_names[i]))
      end
    end

    this.compare_control_by_index(idxs, cc);
  end
endfunction: compare_control_by_name

/// <b>Scoreboard Wrapper API</b>: Creates a summary report once simulation has finished.
/// The report contains insert/match/flush/orphan statistics for the wrapped scoreboards.
/// If the cl_syoscb_cfg#gen_enable_scb_stats configuration knob is active then the report of the different
/// queues in each scoreboard is also included.
/// At the end of the report is a table with the statistics of all scoreboards.
/// \param offset Horizontal offset at which text should start
/// \param first_column_width The width of the first column in the output table
/// \return A string containing the entire report, ready to print
function string cl_syoscbs_base::create_report(int unsigned offset, int unsigned first_column_width);
  string stats_str;

  stats_str = { stats_str, this.create_scb_stats(offset, first_column_width)     };
  stats_str = { stats_str, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) };
  stats_str = { stats_str, this.create_total_stats(offset, first_column_width)   };

  return stats_str;
endfunction: create_report


/// Returns a table with summed scoreboard statistics for all wrapped scoreboards
/// \param offset Horizontal offset at which text should start
/// \param first_column_width The width of the first column in the output table
/// \return A string containing the table
// Total | Inserts | Matches | Flushed | Orphans
function string cl_syoscbs_base::create_total_stats(int unsigned offset, int unsigned first_column_width);
  string       total_stats;
  int unsigned total_cnt_add_item;
  int unsigned total_cnt_flushed_item;
  int unsigned total_queue_size;

  // For now get the numbers here but should be refactored
  // into individual functions for better reuse
  foreach (this.scbs[i]) begin
    total_cnt_add_item     += this.scbs[i].get_total_cnt_add_items();
    total_cnt_flushed_item += this.scbs[i].get_total_cnt_flushed_items();
    total_queue_size       += this.scbs[i].get_total_queue_size();
  end

  total_stats = { "\n",
      $sformatf("%s%s | %8d | %8d | %8d | %8d |",
                cl_syoscb_string_library::pad_str("", offset),
                cl_syoscb_string_library::pad_str("Total", first_column_width, " ", 1'b1),
                total_cnt_add_item,
                total_cnt_add_item-(total_cnt_flushed_item+total_queue_size),
                total_cnt_flushed_item,
                total_queue_size)};

  return total_stats;
endfunction: create_total_stats

/// Returns a string containing the tables with statistics of the different scoreboards.
/// If the cl_syoscbs_cfg#enable_scb_stats configuration knob is active for a given scoreboard,
/// the report of the individual queues of that scoreboard is also included.
/// \param offset Horizontal offset at which text should start. Depends on the level of nested calls
///               (see cl_syoscbs_base#report_phase implementation)
/// \param first_column_width The width of the first column in the output table
/// \return A string containing the table
function string cl_syoscbs_base::create_scb_stats(int unsigned offset, int unsigned first_column_width);
  string scb_stats;

  foreach (this.scbs[i]) begin
    scb_stats = { scb_stats, this.scbs[i].create_total_stats(offset, first_column_width) };

    if(this.cfg.get_enable_scb_stats(i) == 1'b1) begin
      scb_stats = { scb_stats, this.scbs[i].create_report_contents(offset+pk_syoscb::GLOBAL_REPORT_INDENTION, first_column_width-pk_syoscb::GLOBAL_REPORT_INDENTION)};

       if(i != this.scbs.size()-1) begin
         scb_stats = { scb_stats, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) };
      end
    end
  end

  return scb_stats;
endfunction: create_scb_stats

/// Gets information on whether any of the wrapped scoreboards failed to pass error checks.
/// These error checks include orphan checking and no-insertion checks.
/// \return A string combining the error checks of all queues.
function string cl_syoscbs_base::get_scb_failed_checks();
  string failed_checks;

  foreach(this.scbs[i]) begin
    string a_failed_check;

    a_failed_check = this.scbs[i].get_failed_checks();

    failed_checks = { failed_checks, a_failed_check, a_failed_check.len()==0 ? "" : "\n" };
   end

  return failed_checks;
endfunction: get_scb_failed_checks

/// Create all filter transforms for the given scoreboard. Should be called in the UVM build phase
/// \param idx Index of the scoreboard to create filters for
/// \param cfg The configuration object for that scoreboard
function void cl_syoscbs_base::create_filters(int unsigned idx,
                                              cl_syoscb_cfg cfg);
  string producer_names[];
  cfg.get_producers(producer_names);
  foreach(producer_names[i]) begin
    cl_syoscb_cfg_pl pl = cfg.get_producer(producer_names[i]);
    string queue_names[] = pl.list;
    foreach(queue_names[j]) begin
      this.create_filter(queue_names[j], producer_names[i], idx);
    end
  end
endfunction: create_filters

/// Connects all filter transforms with their respective subscribers in the scoreboard.
/// Should be called in the UVM connect phase
/// \param idx Index of the scoreboard for which all filters should be connected
/// \param cfg The configuration object for that scoreboard
function void cl_syoscbs_base::connect_filters(int unsigned idx, cl_syoscb_cfg cfg);
  string producer_names[];
  cfg.get_producers(producer_names);
  foreach(producer_names[i]) begin
    cl_syoscb_cfg_pl pl = cfg.get_producer(producer_names[i]);
    string queue_names[] = pl.list;
    foreach(queue_names[j]) begin
      this.connect_filter_and_subscriber(queue_names[j], producer_names[i], idx);
    end
  end
endfunction: connect_filters

/// Creates a filter for given scoreboard/queue name/producer combination
/// \param queue_name The name of the queue to connect the filter to
/// \param producer_name The name of the producer that produced data going into this filter
/// \param idx The index of the scoreboard in which this queue exists
/// \note Abstract method. Must override in a child class to create filters of the correct type
function void cl_syoscbs_base::create_filter(string queue_name,
                                             string producer_name,
                                             int unsigned idx);
  `uvm_fatal("IMPL_ERROR", "create_filter MUST be implemented in a child class")
endfunction: create_filter

/// Connects a filter's output to a scoreboard's subscriber
/// \param queue_name The name of the queue to connect the filter to
/// \param producer_name The name of the producer that produced data going into this filter
/// \param fts_idx The index of the scoreboard in which this queue exists
/// \note Abstract method, will throw UVM_FATAL if called. Must override in a child class
function void cl_syoscbs_base::connect_filter_and_subscriber(string queue_name,
                                             string producer_name,
                                             int unsigned idx);
  `uvm_fatal("IMPL_ERROR", "connect_filter_and_subscriber() MUST be implemented in a child class")

endfunction: connect_filter_and_subscriber

/// Implementation of UVM do_print-hmethod
/// Prints information of all wrapped scoreboards, as well as all filter transforms
/// \param printer The UVM printer to use
function void cl_syoscbs_base::do_print(uvm_printer printer);
  // Print all scb instantiated by the wrapper, if any
  if(this.scbs.size() != 0) begin
    printer.print_generic(.name("scbs"),
                          .type_name("-"),
                          .size(this.scbs.size()),
                          .value("-"));

    foreach(this.scbs[i]) begin
      printer.print_object(.name($sformatf("scbs[%0d]", i)),
                           .value(scbs[i]));
    end
  end

  // Print all filter transform instances
  if(this.fts.size() !=0) begin
    printer.print_generic(.name("fts"),
                          .type_name("-"),
                          .size(this.fts.size()),
                          .value("-"));

    foreach(this.fts[i,q,p]) begin
      printer.print_object(.name($sformatf("fts[%0d][%0s][%0d]", i, q, p)), .value(fts[i][q][p]));
    end
  end

  super.do_print(printer);
endfunction: do_print

// Implementation of UVM do_compare-method
// Compares information on all wrapped scoreboards, as well as all filter transforms
function bit cl_syoscbs_base::do_compare(uvm_object rhs, uvm_comparer comparer);
  cl_syoscbs_base rhs_cast;
  bit compare_result = super.do_compare(rhs, comparer);

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_compare",
               $sformatf("The given object argument is not %0p type", rhs_cast.get_type()))
    return 0;
  end

  // Compare scbs
  if(rhs_cast.scbs.size() != this.scbs.size()) begin
    return 0;
  end
  else begin
    foreach(this.scbs[i]) begin
      compare_result &= comparer.compare_object($sformatf("%0s", this.scbs[i].get_name()),
                                                this.scbs[i],
                                                rhs_cast.scbs[i]);
    end
  end

  //compare fts transform filters
  if(rhs_cast.fts.size() != this.fts.size()) begin
    return 0;
  end
  else begin
    foreach(rhs_cast.fts[i,j,k]) begin
      compare_result &= comparer.compare_object($sformatf("%0s", this.fts[i][j][k].get_name()),
                                                          this.fts[i][j][k],
                                                          rhs_cast.fts[i][j][k]);
    end
  end

  return compare_result;
endfunction: do_compare

// Implementation of UVM do_copy-method
// Copies all wrapped scoreboard information, as well as filter transform information
function void cl_syoscbs_base::do_copy(uvm_object rhs);
  cl_syoscbs_base rhs_cast;

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_copy",
               $sformatf("The given object argument is not %0p type", rhs_cast.get_type()))
  end

  // Clone all scbs contained in rhs_cast.scbs
  // Delete the this.scbs content before copying
  this.scbs.delete();
  this.scbs = new[rhs_cast.scbs.size()];

  foreach(rhs_cast.scbs[i]) begin
    cl_syoscb l_scb;

    // Clone each scb since copying at this level should means create a copy of the entire wrapper
    if(!$cast(l_scb, rhs_cast.scbs[i].clone())) begin
      `uvm_fatal("do_copy",
                 $sformatf("Clone of scb: '%0s' failed!", rhs_cast.scbs[i].get_name()))
    end

    this.scbs[i] = l_scb;
  end

  // Clone all filter transforms inside the wrapper
  // Delete fts array before copying
  this.fts.delete();
  this.fts = new[rhs_cast.fts.size()];

  foreach(rhs_cast.fts[i,q,p]) begin
    uvm_component filter_clone;
    if(!$cast(filter_clone, rhs_cast.fts[i][q][p].clone())) begin
      `uvm_fatal("DO_COPY", $sformatf("Cloning filter transform %0s failed", rhs_cast.fts[i][q][p].get_name()))
    end
    this.fts[i][q][p] = filter_clone;
  end
  super.do_copy(rhs);
endfunction: do_copy