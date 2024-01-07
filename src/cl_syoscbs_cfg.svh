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
/// Configuration object for the cl_syoscbs_base scoreboard wrapper.
class cl_syoscbs_cfg extends uvm_object;
  /// Array holding handles to all the UVM scoreboard configurations
  local cl_syoscb_cfg  cfgs[];

  /// Scoreboard wrapper name
  local string         scbs_name;

  /// Number of scoreboards
  local int unsigned   no_scbs;

  /// Whether to disable report printing in the report_phase.
  /// - 0 => Reports are enabled
  /// - 1 => Reports are disabled
  local bit disable_report;

  /// Enable/disable the printing of scb statistics per queue by each scb
  local bit enable_scb_stats[];

  /// Whether to print scoreboard wrapper configuration in the UVM build_phase
  /// - 0 => Disable print of scb wrapper configuration
  /// - 1 => Enable  print of scb wrapper configuration
  local bit print_cfg = 1'b1;

  //-------------------------------------
  // UVM_Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscbs_cfg)
    `uvm_field_array_object(cfgs,          UVM_DEFAULT | UVM_NOPRINT | UVM_REFERENCE)
    `uvm_field_string(scbs_name,           UVM_DEFAULT)
    `uvm_field_int(no_scbs,                UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(disable_report,         UVM_DEFAULT)
    `uvm_field_array_int(enable_scb_stats, UVM_DEFAULT)
    `uvm_field_int(print_cfg,              UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscbs_cfg");

  //-------------------------------------
  // Configuration API
  //-------------------------------------
  extern virtual function void          init(string       scbs_name="",
                                             int unsigned no_scbs,
                                             string       scb_names[],
                                             string       queues[],
                                             string       producers[]);
  extern virtual function void          set_cfg(cl_syoscb_cfg cfg, int unsigned idx);
  extern virtual function cl_syoscb_cfg get_cfg(int unsigned idx);
  extern virtual function void          set_no_scbs(int unsigned no_scbs);
  extern virtual function int unsigned  get_no_scbs();
  extern virtual function void          set_scbs_name(string scbs_name);
  extern virtual function string        get_scbs_name();
  extern virtual function void          set_scb_names(string scb_names[], int unsigned idxs[] = {});
  extern virtual function void          get_scb_names(output string scb_names[],
                                                      input int unsigned idxs[] = {});
  extern virtual function void          set_queues(string queues[], int unsigned idxs[] = {});
  extern virtual function void          get_queues(output string queues[], input int unsigned idx);
  extern virtual function void          set_producers(string producer, string queues[] = {},
                                                      int unsigned idxs[] = {});
  extern virtual function void          set_queue_type(t_scb_queue_type queue_types[],
                                                       int unsigned idxs[] = {});
  extern virtual function void          set_compare_type(t_scb_compare_type compare_types[],
                                                         int unsigned idxs[] = {});
  extern virtual function int           get_scb_index_by_name(string scb_name);
  extern virtual function void          set_scb_trigger_greediness(int unsigned idxs[] = {},
                                                                   t_scb_compare_greed tg[]);
  extern virtual function void          get_scb_trigger_greediness(output t_scb_compare_greed tg[],
                                                                   input int unsigned idxs[] = {});
  extern virtual function void          set_scb_end_greediness(int unsigned idxs[] = {},
                                                               t_scb_compare_greed eg[]);
  extern virtual function void          get_scb_end_greediness(output t_scb_compare_greed eg[],
                                                               input int unsigned idxs[] = {});
  extern virtual function void          set_disable_report(bit dr);
  extern virtual function bit           get_disable_report();
  extern virtual function void          set_enable_scb_stats(input int unsigned idxs[] = {}, bit ess);
  extern virtual function bit           get_enable_scb_stats(int unsigned idx);
  extern virtual function int unsigned  get_max_length_scb_name();
  extern virtual function int unsigned  get_max_length_queue_name();
  extern virtual function int unsigned  get_max_length_producer();
  extern virtual function void          set_print_cfg(bit pc);
  extern virtual function bit           get_print_cfg();
  extern virtual function void          do_print(uvm_printer printer);

  //-------------------------------------
  // Misc. functions for internal usage
  //-------------------------------------
  extern protected virtual function bit     is_scb_names_unique(input string scb_name);

endclass: cl_syoscbs_cfg

function cl_syoscbs_cfg::new(string name = "cl_syoscbs_cfg");
  super.new(name);
endfunction: new

/// <b>Configuration API:</b> Initializes the scoreboard wrapper and all contained scoreboards.
/// See #set_scb_names for important restrictions on the values of parameter \c scb_names

/// \param scbs_name The name of the scoreboard wrapper
/// \param no_scbs Number of scoreboards to wrap
/// \param scb_names Names of the scoreboards that should be wrapped.
/// \param queues Names of the queues that should be created in *all* scoreboards given by scb_names
/// \param producers Names of the produceres that should be created for *all* queues in *all* scoreboards
function void cl_syoscbs_cfg::init(string       scbs_name = "",
                                   int unsigned no_scbs,
                                   string       scb_names[],
                                   string       queues[],
                                   string       producers[]);
  this.set_no_scbs(no_scbs);
  this.set_scbs_name(scbs_name);
  this.set_scb_names(scb_names);
  if(queues.size()!= 0) begin
    this.set_queues(queues);
  end
  foreach (producers[i]) begin
     this.set_producers(producers[i]);
  end
endfunction: init

/// <b>Configuration API:</b> Sets the configuration object for the scoreboard at a given index
/// \param cfg The scoreboard configuration to set
/// \param idx The index of the scoreboard config to set
/// \note If the index is invalid, throws a UVM_FATAL
function void cl_syoscbs_cfg::set_cfg(cl_syoscb_cfg cfg, int unsigned idx);
  if(idx >= this.cfgs.size()) begin
    `uvm_fatal("CFG_ERROR",
               $sformatf("No set_cfg possible at index %0d. Allowed range is between 0 and %0d",
                         idx, this.cfgs.size()-1))
    return;
  end

  this.cfgs[idx] = cfg;

  // Report for the SCB is handled by the wrapper
  this.cfgs[idx].set_disable_report(1'b1);

  // Print for the cfgs is handled by wrapper
  this.cfgs[idx].set_print_cfg(1'b0);
endfunction: set_cfg

/// <b>Configuration API:</b> Returns the configuration object of the scoreboard with a given index
/// \param idx The index of the scoreboard configuration to retrieve
/// \return That scoreboard configuration, or null if none could be found
/// \note If the index is invalid, throws a UVM_FATAL
function cl_syoscb_cfg cl_syoscbs_cfg::get_cfg(int unsigned idx);
  if(idx >= this.cfgs.size()) begin
    `uvm_fatal("CFG_ERROR",
               $sformatf("No get_cfg possible at index %0d. Allowed range is between 0 and %0d",
                         idx, this.cfgs.size()-1))
    return null;
  end

  return this.cfgs[idx];
endfunction: get_cfg

/// <b>Configuration API:</b> Sets the number of scoreboards that should be wrapped.
/// Creates an empty scoreboard configuration for each scoreboard.
/// If this has previously been called, previously existing scoreboard configs are preserved.
/// If the new number of scoreboards is greater than the old, additional configs are created.
/// If the new number of scoreboards is smaller than the old, some of the old configs are discarded.
/// \param no_scbs The number of scoreboards
function void cl_syoscbs_cfg::set_no_scbs(int unsigned no_scbs);
  this.no_scbs = no_scbs;

  // Potentially resize but preserve what was there
  this.cfgs = new[this.no_scbs](this.cfgs);

  this.enable_scb_stats = new[this.no_scbs](this.enable_scb_stats);

  foreach (this.cfgs[i]) begin
    if(this.cfgs[i] == null) begin
      this.set_cfg(pk_syoscb::cl_syoscb_cfg::type_id::create($sformatf("scb[%0d]_cfg", i)), i);
    end

    this.enable_scb_stats[i] = 1'b0;
  end
endfunction: set_no_scbs

/// <b>Configuration API:</b> Returns the number of scoreboards wrapped by this wrapper.
function int unsigned cl_syoscbs_cfg::get_no_scbs();
  return this.no_scbs;
endfunction: get_no_scbs

/// <b>Configuration API:</b> Sets the name of this scoreboard wrapper
function void cl_syoscbs_cfg::set_scbs_name(string scbs_name);
  this.scbs_name = scbs_name;
endfunction: set_scbs_name

/// <b>Configuration API:</b> Returns the name of this scoreboard wrapper
function string cl_syoscbs_cfg::get_scbs_name();
  return this.scbs_name;
endfunction: get_scbs_name

/// <b>Configuration API:</b> Sets the scoreboard name of all scoreboards under this wrapper.
/// - If the 'names' and 'idxs' arguments are empty, scoreboards are given auto-generated name: (scb[x])
/// - If the 'names' argument has exactly one entry and 'idxs' is empty, scoreboards are named: (<names[0]>[x])
/// - If the 'names' argument and 'idxs' argument both have the same number of entries, scoreboards are given
///   names based on the idxs: scb[idxs[i]].name = scb_names[i]
/// \note If multiple SCB names are passed, these must be unique. Otherwise, a UVM_FATAL is issued
/// \note If the parameters do not follow one of the three structures presented, a UVM_FATAL is issued
/// \param scb_names The names that scoreboards should be assigned.
/// \param idxs The indexes at which a given scoreboard name should be given.
function void cl_syoscbs_cfg::set_scb_names(string scb_names[], int unsigned idxs[] = {});
  // Set all SCB names to an unique default
  if(scb_names.size() == 0 && idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_scb_name($sformatf("scb[%0d]", i));
    end

    return;
  end

  // Set the same name for all or specific indexes
  if(scb_names.size() == 1) begin
    if(idxs.size() == 0) begin
      // Unique name made by <scb_names[0]> root, followed by a progressive index
      foreach (this.cfgs[i]) begin
        this.cfgs[i].set_scb_name($sformatf("%s[%0d]", scb_names[0], i));
      end
    end
    else begin
      // Names might not be unique, depending on the values inside idxs. Need to check for unicity
      foreach (idxs[i]) begin
        string l_scb_name;

        l_scb_name = $sformatf("%s[%0d]", scb_names[0], idxs[i]);

        if(!this.is_scb_names_unique(l_scb_name)) begin
          `uvm_fatal("CFG_ERROR", $sformatf("the provided scb name '%0s' is not unique", l_scb_name))
        end
        else begin
          this.cfgs[idxs[i]].set_scb_name(l_scb_name);
        end
      end
    end

    return;
  end

  // Set specific names for specific indexes
  if(scb_names.size()>0 && idxs.size()>0 && scb_names.size() == idxs.size()) begin
    // Names might not be unique, depending on the values in both arrays. Need to check for unicity
    foreach (idxs[i]) begin
      string l_scb_name;

      l_scb_name = scb_names[idxs[i]];

      if(!this.is_scb_names_unique(l_scb_name)) begin
        `uvm_fatal("CFG_ERROR", $sformatf("the provided scb name '%0s' is not unique", l_scb_name))
      end
      else begin
        this.cfgs[idxs[i]].set_scb_name(l_scb_name);
      end
    end

    return;
  end

  `uvm_fatal("CFG_ERROR", "set_scb_names invoked with unsupported args")
endfunction: set_scb_names

/// <b>Configuration API:</b> Returns the names of some or all scoreboards wrapped by this wrapper.
/// If \c idxs is empty, all names are returned. Otherwise, only the names at the requested indexes are returned.
/// \param scb_names Handle to a string array where scoreboard names are returned. Should not point to an
///                  existing array, as a new array is allocated
/// \param idxs The indexes of the scoreboard names that should be returned. If empty, all names are returned
///             such that scb_names[i] corresponds to scb[i]. Otherwise, scb_names[i] = scbs[idxs[i]]
function void cl_syoscbs_cfg::get_scb_names(output string scb_names[], input int unsigned idxs[] = {});
  scb_names = new[idxs.size() == 0 ? this.no_scbs : idxs.size()];

  foreach (scb_names[i]) begin
    scb_names[i] = this.cfgs[idxs.size() == 0 ? i : idxs[i]].get_scb_name();
  end
endfunction: get_scb_names

/// <b>Configuration API:</b> Sets the legal queue names for the scoreboards indicated by the idxs argument.
/// If idxs is empty, the given queue names are set for all scoreboards
/// \param queues The queue names that should be used for the given scoreboards
/// \param idxs The indexes of the scoreboards that should have these names. If empty, all scoreboards get these queue names.
/// or for the scoreboards specified in the idxs argument.
function void cl_syoscbs_cfg::set_queues(string queues[], int unsigned idxs[] = {});
  // Generate a fatal if queues doesn't contain elements
  if(queues.size() == 0) begin
    `uvm_fatal("CFG_ERROR",
               "cl_syoscbs_cfg::set_queues has been called with empty queues argument")
  end

  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_queues(queues);
    end
  end else begin
    foreach (idxs[i]) begin
      this.cfgs[idxs[i]].set_queues(queues);
    end
  end
endfunction: set_queues

/// <b>Configuration API:</b> Returns the names of the queues for the scoreboard with a given index
/// \param queues Handle to an array where queue names are returned. Should not point to an existing array,
///               as a new array is allocated
/// \param ids    The index of the scoreboard to get queue names for
/// \note If idx >= the number of scoreboards, a UVM_FATAL is issued
function void cl_syoscbs_cfg::get_queues(output string queues[], input int unsigned idx);
  if(idx >= this.cfgs.size()) begin
    `uvm_fatal("CFG_ERROR",
               $sformatf("No get_queue possible at index %0d. Allowed range is between 0 and %0d",
                         idx, this.cfgs.size()-1))
    queues = {};
  end

  this.cfgs[idx].get_queues(queues);
endfunction: get_queues

/// <b>Configuration API:</b> Sets the producer for the specified queues of the scoreboards with given indexes
/// If no queues are specified, the producer is set for all the queues.
/// If no indicies are specifies, the producer is set for the queues of all scoreboards.
/// \param producer The name of the producer that should be associated with some queues
/// \param queues The names of the queues that the producer can generate for
/// \note If idx >= the number of scoreboards, a UVM_FATAL is issued
function void cl_syoscbs_cfg::set_producers(string producer, string queues[] = {}, int unsigned idxs[] = {});
  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      if(queues.size() == 0) begin
        this.cfgs[i].get_queues(queues);
      end

      if(!this.cfgs[i].set_producer(producer, queues)) begin
        `uvm_fatal("CFG_ERROR",
                   $sformatf("[%0s]: Unable to set producer %0s for the given queues",
                             this.cfgs[i].get_name(), producer))
        return;
      end
    end
  end else begin
    foreach (idxs[i]) begin
      // Execute index check
      if(idxs[i] >= this.cfgs.size()) begin
        `uvm_fatal("CFG_ERROR",
                   $sformatf("No set_producers not possible at index %0d. Allowed range is between 0 and %0d",
                             idxs[i], this.cfgs.size()-1))
        return;
      end
      if(queues.size() == 0) begin
        this.cfgs[idxs[i]].get_queues(queues);
      end

      if(!this.cfgs[idxs[i]].set_producer(producer, queues)) begin
        `uvm_fatal("CFG_ERROR",
                   $sformatf("[%0s]: Unable to set producer %0s for the given queues",
                             this.cfgs[idxs[i]].get_name(), producer))
        return;
      end
    end
  end
endfunction: set_producers

/// <b>Configuration API:</b> Sets the queue types for the given scoreboards inside the wrapper.
/// \param queue_types The queue type that should be used for a scoreboard.
/// \param idxs The indexes of the scoreboards that should have their queue type set. If idxs is empty,
///             queue_types[i] is applied to scb[i]. Otherwise, queue_types[i] is applied to scb[idxs[i]]
function void cl_syoscbs_cfg::set_queue_type(t_scb_queue_type queue_types[], int unsigned idxs[] = {});
  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_queue_type(queue_types[i]);
    end
  end else begin
    foreach (idxs[i]) begin
      this.cfgs[idxs[i]].set_queue_type(queue_types[i]);
    end
  end
endfunction: set_queue_type

/// <b>Configuration API:</b> Sets the compare strategy for the given scoreboards inside the wrapper
/// \param compare_types The compare type that should be used for a scoreboard.
/// \param idxs The indexes of the scoreboards that should have their queue type set. If idxs is empty,
///             compare_types[i] is applied to scb[i]. Otherwise, compare_types[i] is applied to scb[idxs[i]]
function void cl_syoscbs_cfg::set_compare_type(t_scb_compare_type compare_types[],
                                               int unsigned idxs[] = {});
  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_compare_type(compare_types[i]);
    end
  end else begin
    foreach (idxs[i]) begin
      this.cfgs[idxs[i]].set_compare_type(compare_types[i]);
    end
  end
endfunction: set_compare_type


// Implementation notes:
//
//   * This just returns the first match and does not check for dublets
//   * Can be optimized using a hash which is updated on insertion. Then the search can be avoided completely
//   * Consider flagging error if not found?
/// <b>Configuration API:</b> Gets the index of a scoreboard with a given name
/// \param scb_name The name of the scoreboard to find the index of
/// \return The index of that scoreboard, -1 if the name did not match any scoreboard
function int cl_syoscbs_cfg::get_scb_index_by_name(string scb_name);
  int scb_idxs[$];

  scb_idxs = this.cfgs.find_first_index() with (item.get_scb_name() == scb_name);

  return scb_idxs.size() > 0 ? scb_idxs[0] : -1;
endfunction: get_scb_index_by_name

/// <b>Configuration API:</b> Sets trigger greediness status for all or a subset of the scoreboards.
/// \param idxs The indexes of the scoreboards that should have their trigger greed level set. If idxs is empty,
///             tg[i] is applied to scb[i]. Otherwise, tg[i] is applied to scb[idxs[i]]
/// \param tg The trigger greed level that should be used for a scoreboard.
function void cl_syoscbs_cfg::set_scb_trigger_greediness(int unsigned idxs[] = {},
                                                           t_scb_compare_greed tg[]);
  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_trigger_greediness(tg[0]);
    end
  end else begin
    foreach (idxs[i]) begin
      this.cfgs[idxs[i]].set_trigger_greediness(tg[i]);
    end
  end
endfunction: set_scb_trigger_greediness

/// <b>Configuration API:</b> Gets the trigger greediness status for all or a subset of the scoreboards.
/// \param tg The trigger greediness levels of the requested scoreboards. If idxs is empty,
///           tg[i] is the trigger greediness of scb[i]. Otherwise, tg[i] is the trigger greedines of scb[idxs[i]]
/// \param idxs The indexes of the scoreboards for which to get the trigger greed level. If empty, all greed
///             levels are returned.
function void cl_syoscbs_cfg::get_scb_trigger_greediness(output t_scb_compare_greed tg[],
                                                           input int unsigned idxs[] = {});
  if(idxs.size() == 0) begin
    tg = new[this.cfgs.size()];
    foreach (this.cfgs[i]) begin
      tg[i] = this.cfgs[i].get_trigger_greediness();
    end
  end else begin
    tg = new[idxs.size()];
    foreach (idxs[i]) begin
      tg[idxs[i]] = this.cfgs[idxs[i]].get_trigger_greediness();
    end
  end
endfunction: get_scb_trigger_greediness

/// <b>Configuration API:</b> Sets the end greediness status for all or a subset of the scoreboards.
/// \param idxs The indexes of the scoreboards that should have their end greed level set. If idxs is empty,
///             eg[i] is applied to scb[i]. Otherwise, eg[i] is applied to scb[idxs[i]]
/// \param eg The end greed level that should be used for a scoreboard.
function void cl_syoscbs_cfg::set_scb_end_greediness(int unsigned idxs[] = {},
                                                     t_scb_compare_greed eg[]);
  if(idxs.size() == 0) begin
    foreach (this.cfgs[i]) begin
      this.cfgs[i].set_end_greediness(eg[0]);
    end
  end else begin
    foreach (idxs[i]) begin
      this.cfgs[idxs[i]].set_end_greediness(eg[i]);
    end
  end
endfunction: set_scb_end_greediness

/// <b>Configuration API:</b> Gets the end greediness status for all or a subset of the scoreboards.
/// \param eg The end greediness levels of the requested scoreboards. If idxs is empty,
///           eg[i] is the end greediness of scb[i]. Otherwise, eg[i] is the end greedines of scb[idxs[i]]
/// \param idxs The indexes of the scoreboards for which to get the end greed level. If empty, all greed
///             levels are returned.
function void cl_syoscbs_cfg::get_scb_end_greediness(output t_scb_compare_greed eg[],
                                                     input int unsigned idxs[] = {});
  if(idxs.size() == 0) begin
    eg = new[this.cfgs.size()];
    foreach (this.cfgs[i]) begin
      eg[i] = this.cfgs[i].get_end_greediness();
    end
  end else begin
    eg = new[idxs.size()];
    foreach (idxs[i]) begin
      eg[idxs[i]] = this.cfgs[idxs[i]].get_end_greediness();
    end
  end
endfunction: get_scb_end_greediness

/// <b>Configuration API:</b> Sets the value of the #disable_report member variable
function void cl_syoscbs_cfg::set_disable_report(bit dr);
  this.disable_report = dr;
endfunction: set_disable_report

/// <b>Configuration API:</b> Returns the value of the #disable_report member variable
function bit cl_syoscbs_cfg::get_disable_report();
  return this.disable_report;
endfunction: get_disable_report

/// <b>Configuration API:</b> Sets the value of the #enable_scb_stats flag for all or a subset of scoreboards
/// \param idxs The indexes of the scoreboards to set the value of the flag for.
///             If empty, the value is set for all scoreboards.
/// \param ess The value to set the flag to
function void cl_syoscbs_cfg::set_enable_scb_stats(input int unsigned idxs[] = {}, bit ess);
  if(idxs.size() == 0) begin
    foreach (this.enable_scb_stats[i]) begin
      this.enable_scb_stats[i] = ess;
    end
  end else begin
    foreach (idxs[i]) begin
      this.enable_scb_stats[idxs[i]] = ess;
    end
  end
endfunction: set_enable_scb_stats

/// <b>Configuration API:</b> Returns the value of the #enable_scb_stats member variable for the
/// scoreboard at the given index
function bit cl_syoscbs_cfg::get_enable_scb_stats(int unsigned idx);
  if(idx >= this.enable_scb_stats.size()) begin
        `uvm_fatal("CFG_ERROR",
                   $sformatf("No get_enable_scb_stats not possible at index %0d. Allowed range is between 0 and %0d",
                             idx, this.enable_scb_stats.size()-1))
        return 0;
      end

  return this.enable_scb_stats[idx];
endfunction: get_enable_scb_stats

/// Returns the length of the longest scoreboard name that is wrapped by this
function int unsigned cl_syoscbs_cfg::get_max_length_scb_name();
  string       scb_names[];
  int unsigned max_length_scb_name;

  this.get_scb_names(scb_names);

  foreach (scb_names[i]) begin
    if(scb_names[i].len() > max_length_scb_name) begin
      max_length_scb_name = scb_names[i].len();
    end
  end

  return max_length_scb_name;
endfunction: get_max_length_scb_name

/// Returns the length of the longest queue name that is wrapped by this
function int unsigned cl_syoscbs_cfg::get_max_length_queue_name();
  int unsigned max_length_queue_name;

  foreach (this.cfgs[i]) begin
    if(this.cfgs[i].get_max_length_queue_name() > max_length_queue_name) begin
      max_length_queue_name = this.cfgs[i].get_max_length_queue_name();
    end
  end

  return max_length_queue_name;
endfunction: get_max_length_queue_name

/// Returns the length of the producer name with maximum length
function int unsigned cl_syoscbs_cfg::get_max_length_producer();
  int unsigned max_length_producer;

  foreach (this.cfgs[i]) begin
    if(this.cfgs[i].get_max_length_producer() > max_length_producer) begin
      max_length_producer = this.cfgs[i].get_max_length_producer();
    end
  end

  return max_length_producer;
endfunction: get_max_length_producer

/// <b>Configuration API:</b> Sets the value of the #print_cfg member variable
function void cl_syoscbs_cfg::set_print_cfg(bit pc);
  this.print_cfg = pc;
endfunction: set_print_cfg

/// Gets the value of the #print_cfg member variable
function bit cl_syoscbs_cfg::get_print_cfg();
  return this.print_cfg;
endfunction:get_print_cfg

/// Custom do_print implementation. Print only the wrapped configuration objects which have #print_cfg == 1
function void cl_syoscbs_cfg::do_print(uvm_printer printer);
  foreach (this.cfgs[i]) begin
    printer.print_object(.name($sformatf("cfgs[%0d]", i)), .value(this.cfgs[i]));
  end

  super.do_print(printer);
endfunction: do_print

/// Checks if a given name is not yet used by a scoreboard under this wrapper
/// \param scb_name The name that should be checked against all other scoreboard names
function bit cl_syoscbs_cfg::is_scb_names_unique(input string scb_name);
  string l_scb_names[];
  string duplicate_names[$];

  this.get_scb_names(l_scb_names);

  duplicate_names = l_scb_names.find(x) with(x == scb_name);

  // If the return queue has size zero, i don't have dublicate names for the given argument
  return duplicate_names.size() == 0;
endfunction: is_scb_names_unique
