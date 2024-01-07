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
/// Configuration class for the SyoSil UVM scoreboard
class cl_syoscb_cfg extends uvm_object;
  //---------------------------------
  // Non randomizable member variables
  //---------------------------------
  /// Associative array holding handles to each queue. Indexed by queue name.
  local cl_syoscb_queue_base queues[string];

  /// Associative array indexed by producer name. Returns the list of queues which
  /// this producer is related to.
  local cl_syoscb_cfg_pl producers[string];

  /// Name of the primary queue used in this scoreboard. If set to an empty string,
  /// the primary queue is dynamically selected when performing comparions (takes the shortest queue)
  local string primary_queue;

  /// The name of the SCB. Default will be the instance name of the SCB component if the name is not set explicitly
  local string scb_name;

  /// Queue topology used in the SCB. Defaults to \c pk_syoscb::SYOSCB_QUEUE_USER_DEFINED.
  local t_scb_queue_type queue_type = pk_syoscb::SYOSCB_QUEUE_USER_DEFINED;

  /// Compare strategy used in the SCB. Defaults to \c pk_syoscb::SYOSCB_COMPARE_IO
  local t_scb_compare_type compare_type = pk_syoscb::SYOSCB_COMPARE_USER_DEFINED;

  /// Defines the greed level for comparison operations. Defaults to \c pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY
  /// The greed level controls whether a comparison trigger will attempt to drain the SCB
  /// by performing additional comparisons if the previous comparison was successful (greedy)
  /// or if only a single comparison is performed when triggered (not greedy)
  local t_scb_compare_greed trigger_greediness = pk_syoscb::SYOSCB_COMPARE_NOT_GREEDY;

  /// See \c trigger_greediness for description. Defaults to \c pk_syoscb::SYOSCB_COMPARE_GREEDY
  /// This greed level is used in the cl_syoscb_compare::extract_phase() to drain remaining matches if they exist.
  local t_scb_compare_greed end_greediness = pk_syoscb::SYOSCB_COMPARE_GREEDY;

  /// Enable/disable insertion checking on queues. Defaults to 1'b1.
  ///   - 1'b1 => Enables the check. If a queue has not had any insertions at the end of simulation, a UVM_ERROR is raised
  ///   - 1'b0 => Disables the insertion check. No error is raised if a queue did not have any insertions.
  local bit enable_no_insert_check = 1'b1;

  /// Controls whether calls to cl_syoscb::add_item will clone the given uvm_sequence_item or reuse the handle. Defaults to 1'b0
  ///   - 1'b0 => Calls to cl_syoscb::add_item will clone the uvm_sequence_item
  ///   - 1'b1 => Calls to cl_syoscb::add_item will not clone the uvm_sequence_item
  local bit disable_clone = 1'b0;

  /// Controls whether comparisons should be disabled after the first UVM_ERROR is raised. Defaults to 1'b0.
  ///   - 1'b0 => Comparions are not disabled after the first UVM_ERROR
  ///   - 1'b1 => Comparisons are disabled after the first UVM_ERROR
  local bit disable_compare_after_error = 1'b0;

  /// Maximum number of elements in each queue before an error is signaled. 0 means no limit (default).
  /// Indexed by queue name.
  local int unsigned max_queue_size[string];

  /// Controls whether orphaned items in the queues should be treated as errors when printing at the end of simulation. Defaults to 1'b0.
  ///   -1'b0 => Orphans are printed with UVM_INFO
  ///   -1'b1 => Orphans are printed as UVM_ERRORs
  local bit print_orphans_as_errors = 1'b0;

  /// Select the maximum number of orphaned elements to print if any orphans are left in a queue after simulation. Defaults to 0 (print everything).
  /// If set to -1, no orphans are printed. If set to 0, all orphans are printed.
  /// If set to a positive value N, prints up to N orphans from each queue.
  /// See also #dump_orphans_to_files for the ability to log orphans into a file
  local int max_print_orphans = 0;

  /// Controls whether all orphaned items should be dumped to queue-specific files at the end of simulation. Defaults to 1'b0.
  /// If set, a number of files named <scb_name>.<orphan_dump_file_name>.<queue_name>_orphans.log are generated at the end of simulation.
  /// The number of orphans that are printed is controlled by the knob #max_print_orphans
  /// The value of <orphan_dump_file_name> is set by #orphan_dump_file_name
  ///   - 1'b0 => Orphans are not dumped to files at the end of simulation
  ///   - 1'b1 => Orphans are dumped to files at the end of simulation
  local bit dump_orphans_to_files = 1'b0;

  /// Controls whether a report should be generated in the report_phase. Defaults to 1'b0
  /// Used when e.g. this scb is wrapped by cl_syoscbs wrapper.
  ///   - 1'b0 => Report is not disabled
  ///   - 1'b1 => Report is disabled
  local bit disable_report = 1'b0;

  /// Enable/disable the printing of queue's statistics per producer. Defaults to 1'b0.
  /// Indexed by queue name.
  ///   - 1'b0 => Queue's producer-specific stats are disabled
  ///   - 1'b1 => Queue's producer-specific stats are enabled
  local bit enable_queue_stats[string];

  /// Controls whether all transactions going into the SCB should be dumped to a logfile. Defaults to 1'b0 (off).
  ///   - 1'b0 => Disables dumping all transactions to a logfile
  ///   - 1'b1 => Enables dumping all transactions to a logfile
  local bit full_scb_dump = 1'b0;

  /// Controls whether items in the full scoreboard dump should be dumped using print() or convert2string().
  /// Defaults to 1'b0 (using object.print()).
  /// If enabled and #full_scb_dump_type is set to TXT, the convert2string()-implementation of the wrapped object
  /// is used when dumping. The output of convert2string must be one line, otherwise a UVM_WARNING is raised.
  ///   - 1'b0 => Items are dumped using their .print()-representation
  ///   - 1'b1 >= Items are dumped using their .convert2string()-representation
  local bit enable_c2s_full_scb_dump = 1'b0;

  /// Controls whether SCB dumps (controlled by \c full_scb_dump) print all transactions in the same file,
  /// or if separate files are used for each queue. Defaults to 1'b0
  ///   - 1'b0 => Dump the transactions of all the queues into the same file.
  ///   - 1'b1 => Dump the transactions of each queue in separate file.
  local bit full_scb_dump_split = 1'b0;

  /// Controls the number of elements that a queue in the SCB can receive before transaction dumping starts.
  /// Defaults to 0 (items are logged every time they are added to the SCB)
  local int unsigned full_scb_max_queue_size[string];

  /// File format used when dumping SCB contents to a logfile. Defaults to TXT.
  /// Valid values are pk_syoscb::TXT and pk_syoscb::XML.
  local t_dump_type full_scb_dump_type = pk_syoscb::TXT;

  /// File format used when dumping orphans to logfiles. Default to TXT
  /// Valid values are pk_syoscb::TXT and pk_syoscb::XML
  /// If set to XML, orphan dump logfiles will use .xml extension instead of .log
  local t_dump_type orphan_dump_type = pk_syoscb::TXT;

  /// Base file name used when dumping SCB contents to a logfile.
  local string full_scb_dump_file_name = "full_scb_dump";

  /// Base file name used when dumping orphans to a logfile
  local string orphan_dump_file_name = "orphan_dump";

  /// Controls whether a strict item ordering should be used in assoc. arrays in hash-based queue. Defaults to 1'b1.
  ///   - 1'b0 => Use the SystemVerilog implementation of the next() function for associative arrays
  ///             in the hash queue implementations. This does not guarantee the order to insertion order
  ///             For OOO compares using the hash queues this is an option
  ///             which makes the OOO compare perform at its maximum
  ///   - 1'b1 => Guarantee the order of insertions by maintaining some metadata. The OOO compare with
  ///             hashed queues take a minor performance hit when this is enabled.
  /// Only valid for hash based queue implementations. Defaults to 1'b1 (guaranteed order of insertions)
  local bit ordered_next = 1'b1;

  /// Controls sanity check comparisons on hash queues.
  /// - NO_VALIDATION =>     Does not perform any additional validations after finding an item
  ///                        in the secondary queue which matches the digest of the primary item.
  /// - VALIDATE_MATCH =>    If an item is found in the secondary queue, compares the fields of the
  ///                        primary item to those of the secondary to validate the match.
  /// - VALIDATE_NO_MATCH => If a match is not found in the secondary queue, performs ordinary
  ///                        comparison of the primary item to all items in the secondary queue.
  ///                        This may incur a significant performance hit due to the many additional comparisons.
  /// - VALIDATE_ALL =>      Performs validation when matches are found and when matches are not found.
  /// Only used for hash-based queue implementations. Defaults to SYOSCB_HASH_COMPARE_NO_VALIDATION.
  local t_hash_compare_check hash_compare_check = pk_syoscb::SYOSCB_HASH_COMPARE_NO_VALIDATION;

  /// Controls whether the scoreboard's configuration values should be printed in the cl_syoscb::build_phase().
  /// Defaults to 1'b0 (disable).
  ///   - 1'b0 => Disable print of cfg configuration in cl_syoscb::build_phase()
  ///   - 1'b1 => Enable  print of cfg configuration in cl_syoscb::build_phase()
  local bit print_cfg = 1'b0;

  /// Associative array holding the bit enabling the comparer report for a specific queue/producer combination.
  /// The comparer report contains information on the specific fields where a miscompare happens.
  /// If no value has been set the value of #default_enable_comparer_report is used.
  ///   - 1'b0 => Disable comparer report.
  ///   - 1'b1 => Enable comparer report.
  local bit enable_comparer_report[string][string]; //First index is the producer, second index is the queue

  /// The default comparer report toggle for a uvm_comparer that can be used when no other verbosity has been assigned to a queue's comparer.
  /// Defaults to 1'b1 (comparer report is enabled) for IO, IOP and IO-2HP comparisons.
  /// Defaults to 1'b0 (comparer report is disabled) for OOO and User Defned comparisons.
  /// See #enable_comparer_report for additional details.
  local bit default_enable_comparer_report = 1'b1; //Value modified in set_compare_type() based on input compare strategy

  /// Associative array holding handles to comparers used for a specific queue/producer combination.
  /// If no comparer has been set for a given queue/producer combination, the #default_comparer is used.
  local uvm_comparer comparers[string][string]; //First index is the producer, second index is the queue

  /// The default uvm_comparer that can be used when no other comparer has been assigned to a queue/producer.
  /// By default, this comparer has a verbosity of UVM_LOW, causing miscompare information to be printed when performing OOO compares.
  /// To change this, use cl_syoscb_comparer_config::set_verbosity to change the verbosity level
  local uvm_comparer default_comparer;

  /// Associative array holding the printer verbosity bit for a specific queue/producer combination.
  /// This verbosity bit controls the number of elements to be printed at the start/end of a list in a tx item.
  /// If no entry has been set for a specific queue/producer combination the value of #default_printer_verbosity is used.
  ///   - 1'b0 => Number of elements at the head and at the end of a list is 5 (unless changed with cl_syoscb_printer_config::set_printer_begin/end_elements)
  ///   - 1'b1 => No maximum number of elements (the entire list contents are printed)
  local bit printer_verbosity[string][string]; //First index is producer, second index is queue

  /// Default printer verbosity bit. Controls the number of array elements to output when printing a tx item.
  /// See field #printer_verbosity for value descriptions. Defaults to 1'b0 (5 elements are printed at the head/tail of lists)
  local bit default_printer_verbosity = 1'b0;

  /// Associative array holding handles to printers used for a specific queue/producer combination.
  /// If no printer has been set for a specific queue/producer combination, uses the printer set in #default_printer.
  local uvm_printer printers[string][string]; //First index is the producer, second index is the queue

  /// The default printer used for all printing purposes if no specific printer has been associated with a queue.
  /// Defaults to being a uvm_default_printer
  local uvm_printer default_printer;

  /// The maximum number of entries to iterate through in a queue when performing OOO compare.
  /// If no matches are found within the search window, it is registered as no match occuring.
  /// If max_search_window == 0, all items in a given queue are searched.
  /// The maximum search window can be set on a per-queue basis using set_max_search_window()
  /// Defaults to 0 (search everything)
  local int unsigned max_search_window[string]; //indexed by queue name

  /// Controls whether cl_syoscb::add_item() should be mutexed or not. Defaults to 1'b0 (not mutexed).
  /// When enabled, whenever an item is added to the SCB, the mutex cl_syoscb#add_item_mutex must be acquired.
  /// This ensures that no other items are added while scanning for a match, preserving queue order when iterating.
  ///   - 1'b0 => Adding items is not mutexed
  ///   - 1'b1 => Adding items is mutexed
  local bit mutexed_add_item_enable = 1'b0;

  /// Defines an interval value N for each queue, such that the queue's statistics are printed on every N'th insertion.
  /// All entries default to 0 (stat printouts disabled)
  ///   - 0 => Printing stats are disabled for the given queue
  ///   - N>0 => The given queue's stats are printed every N insertions into the queue.
  local int unsigned queue_stat_interval[string]; //indexed by queue name

  /// Defines an interval value N, similar to #queue_stat_interval, causing a printout of all queue stats in the SCB on every N'th insertion.
  /// Default value is 0 (stat printout disabled)
  ///   - 0 => Printing SCB stats is disabled
  ///   - N>0 => The SCB stats are printed after every N insertions into the SCB.
  local int unsigned scb_stat_interval = 0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  // Note: fields 'queues' and 'primary_queues' have a manual print implementation in do_print
  // field 'queues' is not copied, since the actual queue handles are generated by cl_syoscb in its build_phase
  // 'default_comparer' and 'default_printer' are not field macro-enabled and are manually copied in do_copy
  `uvm_object_utils_begin(cl_syoscb_cfg)
    `uvm_field_aa_object_string(queues,                       UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOPY | UVM_NOPACK)
    `uvm_field_aa_object_string(producers,                    UVM_DEFAULT)
    `uvm_field_string(primary_queue,                          UVM_DEFAULT | UVM_NOPRINT)
    `uvm_field_enum(t_scb_queue_type, queue_type,             UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_type, compare_type,         UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_greed, trigger_greediness,  UVM_DEFAULT)
    `uvm_field_enum(t_scb_compare_greed, end_greediness,      UVM_DEFAULT)
    `uvm_field_int(enable_no_insert_check,                    UVM_DEFAULT)
    `uvm_field_int(disable_clone,                             UVM_DEFAULT)
    `uvm_field_int(disable_compare_after_error,               UVM_DEFAULT)
    `uvm_field_aa_int_string(max_queue_size,                  UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(print_orphans_as_errors,                   UVM_DEFAULT)
    `uvm_field_int(max_print_orphans,                         UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(disable_report,                            UVM_DEFAULT)
    `uvm_field_aa_int_string(enable_queue_stats,              UVM_DEFAULT)
    `uvm_field_int(full_scb_dump,                             UVM_DEFAULT)
    `uvm_field_int(full_scb_dump_split,                       UVM_DEFAULT)
    `uvm_field_aa_int_string(full_scb_max_queue_size,         UVM_DEFAULT)
    `uvm_field_enum(t_dump_type, full_scb_dump_type,          UVM_DEFAULT)
    `uvm_field_string(full_scb_dump_file_name,                UVM_DEFAULT)
    `uvm_field_string(scb_name,                               UVM_DEFAULT)
    `uvm_field_int(ordered_next,                              UVM_DEFAULT)
    `uvm_field_enum(t_hash_compare_check, hash_compare_check, UVM_DEFAULT)
    `uvm_field_int(print_cfg,                                 UVM_DEFAULT)
    `uvm_field_int(default_enable_comparer_report,            UVM_DEFAULT)
    `uvm_field_int(default_printer_verbosity,                 UVM_DEFAULT)
    `uvm_field_aa_int_string(max_search_window,               UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(dump_orphans_to_files,                     UVM_DEFAULT)
    `uvm_field_string(orphan_dump_file_name,                  UVM_DEFAULT)
    `uvm_field_enum(t_dump_type, orphan_dump_type,            UVM_DEFAULT)
    `uvm_field_int(mutexed_add_item_enable,                   UVM_DEFAULT)
    `uvm_field_aa_int_string(queue_stat_interval,             UVM_DEFAULT)
    `uvm_field_int(scb_stat_interval,                         UVM_DEFAULT)
  `uvm_object_utils_end


  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_cfg");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Configuration API
  //-------------------------------------
  extern virtual function void                 init(string scb_name, string queues[],
                                                    string producers[]);
  extern virtual function cl_syoscb_queue_base get_queue(string queue_name);
  extern virtual function void                 set_queue(string queue_name,
                                                         cl_syoscb_queue_base queue);
  extern virtual function void                 get_queues(output string queue_names[]);
  extern virtual function void                 set_queues(string queue_names[]);
  extern virtual function bit                  exist_queue(string queue_name);
  extern virtual function int unsigned         size_queues();
  extern virtual function cl_syoscb_cfg_pl     get_producer(string producer);
  extern virtual function bit                  set_producer(string producer, queue_names[]);
  extern virtual function bit                  exist_producer(string producer);
  extern virtual function void                 get_producers(output string producers[]);
  extern virtual function string               get_primary_queue();
  extern virtual function bit                  set_primary_queue(string primary_queue_name);
  extern virtual function void                 set_queue_type(t_scb_queue_type qt);
  extern virtual function t_scb_queue_type     get_queue_type();
  extern virtual function void                 set_compare_type(t_scb_compare_type ct);
  extern virtual function t_scb_compare_type   get_compare_type();
  extern virtual function void                 set_trigger_greediness(t_scb_compare_greed tg);
  extern virtual function t_scb_compare_greed  get_trigger_greediness();
  extern virtual function void                 set_end_greediness(t_scb_compare_greed eg);
  extern virtual function t_scb_compare_greed  get_end_greediness();
  extern virtual function void                 set_disable_clone(bit dc);
  extern virtual function bit                  get_disable_clone();
  extern virtual function void                 set_disable_compare_after_error(bit dcae);
  extern virtual function bit                  get_disable_compare_after_error();
  extern virtual function void                 set_max_queue_size(string queue_name, int unsigned mqs);
  extern virtual function int unsigned         get_max_queue_size(string queue_name);
  extern virtual function void                 set_orphans_as_errors(oae);
  extern virtual function bit                  get_orphans_as_errors();
  extern virtual function void                 set_max_print_orphans(int mpo);
  extern virtual function int                  get_max_print_orphans();
  extern virtual function void                 set_disable_report(bit dr);
  extern virtual function bit                  get_disable_report();
  extern virtual function void                 set_enable_queue_stats(string queue_name, bit eqs);
  extern virtual function bit                  get_enable_queue_stats(string queue_name);
  extern virtual function string               get_scb_name();
  extern virtual function void                 set_scb_name(string scb_name);
  extern virtual function bit                  get_ordered_next();
  extern virtual function void                 set_ordered_next(bit ordered_next);
  extern virtual function t_hash_compare_check get_hash_compare_check();
  extern virtual function void                 set_hash_compare_check(t_hash_compare_check hcc);
  extern virtual function bit                  get_print_cfg();
  extern virtual function void                 set_print_cfg(bit pc);
  extern virtual function bit                  dynamic_primary_queue();
  extern virtual function void                 set_full_scb_dump(bit fsd);
  extern virtual function bit                  get_full_scb_dump();
  extern virtual function void                 set_enable_c2s_full_scb_dump(bit ecfsd);
  extern virtual function bit                  get_enable_c2s_full_scb_dump();
  extern virtual function void                 set_full_scb_dump_type(t_dump_type fsdt);
  extern virtual function t_dump_type          get_full_scb_dump_type();
  extern virtual function string               get_full_scb_dump_file_name();
  extern virtual function void                 set_full_scb_dump_file_name(string full_scb_dump_file_name);
  extern virtual function bit                  set_full_scb_dump_split(bit fsds);
  extern virtual function bit                  get_full_scb_dump_split();
  extern virtual function void                 set_full_scb_max_queue_size(string queue_name,
                                                                           int unsigned fsmqs);
  extern virtual function int unsigned         get_full_scb_max_queue_size(string queue_name);
  extern virtual function int unsigned         get_max_length_queue_name();
  extern virtual function int unsigned         get_max_length_producer();
  extern virtual function void                 set_enable_comparer_report(bit ecr, string queue_names[], string producer_names[]);
  extern virtual function bit                  get_enable_comparer_report(string queue_name, string producer_name);
  extern virtual function void                 set_default_enable_comparer_report(bit ecr);
  extern virtual function bit                  get_default_enable_comparer_report();
  extern virtual function void                 set_comparer(uvm_comparer comparer, string queue_names[], string producer_names[]);
  extern virtual function uvm_comparer         get_comparer(string queue_name, string producer_name);
  extern virtual function void                 set_default_comparer(uvm_comparer comparer);
  extern virtual function uvm_comparer         get_default_comparer();
  extern virtual function void                 set_printer_verbosity(bit pv, string queue_names[], string producer_names[]);
  extern virtual function bit                  get_printer_verbosity(string queue_name, string producer_name);
  extern virtual function void                 set_default_printer_verbosity(bit pv);
  extern virtual function bit                  get_default_printer_verbosity();
  extern virtual function void                 set_printer(uvm_printer printer, string queue_names[], string producer_names[]);
  extern virtual function uvm_printer          get_printer(string queue_name, string producer_name);
  extern virtual function uvm_printer          get_default_printer();
  extern virtual function void                 set_default_printer(uvm_printer printer);
  extern virtual function void                 set_enable_no_insert_check(bit enic);
  extern virtual function bit                  get_enable_no_insert_check();
  extern virtual function void                 do_print(uvm_printer printer);
  extern virtual function void                 do_copy(uvm_object rhs);
  extern virtual function void                 set_max_search_window(int unsigned sw, string queue_names[]);
  extern virtual function int unsigned         get_max_search_window(string queue_name);
  extern virtual function void                 do_pack(uvm_packer packer);
  extern virtual function void                 do_unpack(uvm_packer packer);
  extern virtual function bit                  get_dump_orphans_to_files();
  extern virtual function void                 set_dump_orphans_to_files(bit dotf);
  extern virtual function string               get_orphan_dump_file_name();
  extern virtual function void                 set_orphan_dump_file_name(string odfn);
  extern virtual function void                 set_mutexed_add_item_enable(bit maie);
  extern virtual function bit                  get_mutexed_add_item_enable();
  extern virtual function void                 set_queue_stat_interval(string queue_name, int unsigned qsi);
  extern virtual function int unsigned         get_queue_stat_interval(string queue_name);
  extern virtual function void                 set_scb_stat_interval(int unsigned ssi);
  extern virtual function int unsigned         get_scb_stat_interval();
  extern virtual function void                 set_orphan_dump_type(t_dump_type odt);
  extern virtual function t_dump_type          get_orphan_dump_type();
endclass: cl_syoscb_cfg

/// <b>Configuration API:</b> Initializes the scoreboard's cfg with the given input parameters.
/// \param scb_name The name of the SCB that this cfg is related to
/// \param queues Names of all queues used in this SCB
/// \param producers Names of all producers used in this scb
function void cl_syoscb_cfg::init(string scb_name, string queues[], string producers[]);
  uvm_comparer comparer;

  this.set_scb_name(scb_name);
  this.set_queues(queues);

  foreach(producers[i]) begin
    if (!this.set_producer(producers[i], queues)) begin
      `uvm_fatal("CFG_ERROR",
                 $sformatf("[%s]: Unable to set producer %s for queues.", this.scb_name,
                                                                          producers[i]));
    end
  end

  //Mute the miscompare output of default comparer - it will be printed into miscmp tables
  comparer = this.get_default_comparer();
  cl_syoscb_comparer_config::set_verbosity(comparer, UVM_HIGH);
  this.set_default_comparer(comparer);
endfunction: init

/// <b>Configuration API:</b> Returns a queue handle for the specificed queue.
/// \param queue_name The name of the queue to get a handle for
/// \return A handle to the requested queue, null if no queue with that name exists
function cl_syoscb_queue_base cl_syoscb_cfg::get_queue(string queue_name);
  // If queue does not exist then return NULL
  if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.scb_name, queue_name), UVM_DEBUG);
    return null;
  end

  return this.queues[queue_name];
endfunction: get_queue

/// <b>Configuration API:</b> Sets the queue object for a given queue.
/// Also sets the values of #max_queue_size and #enable_queue_stats for the given queue to 0
/// \param queue_name The name of the queue
/// \param queue The queue object to set the queue name to point to
function void cl_syoscb_cfg::set_queue(string queue_name, cl_syoscb_queue_base queue);
  this.queues[queue_name] = queue;

  // Set default max queue size to no limit
  this.max_queue_size[queue_name] = 0;

  // Set default enable_queue_stats to 0 (Off)
  this.enable_queue_stats[queue_name] = 1'b0;
endfunction: set_queue

/// <b>Configuration API:</b> Returns all queue names as a string list
/// \param queue_names A handle to a dynamic string array where all queue names will be returned.
///                   If this handle already points to an allocated array, that array will be lost.
function void cl_syoscb_cfg::get_queues(output string queue_names[]);
  string queue_name;
  int    unsigned idx = 0;

  queue_names = new[this.queues.size()];

  while(this.queues.next(queue_name)) begin
    queue_names[idx++] = queue_name;
  end
endfunction: get_queues

/// <b>Configuration API:</b> Will set the legal queues when provided with a list of queue names.
/// An example could be: set_queues('{"Q1", "Q2"})
/// \param queue_names The legal queue names to use for this SCB.
/// \note Throws a UVM_FATAL if queue_names is empty
function void cl_syoscb_cfg::set_queues(string queue_names[]);
  // Generate a fatal if queue_names doesn't contain element
  if(queue_names.size() == 0) begin
    `uvm_fatal("CFG_ERROR",
               "cl_syoscb_cfg::set_queues has been called with empty queue_names argument")
  end
  foreach(queue_names[i]) begin
    this.set_queue(queue_names[i], null);
  end
endfunction: set_queues

/// <b>Configuration API:</b> Checks if a queue with a given name exists.
/// \param queue_name The name of the queue to check
/// \return 1'b1 if a queue with that name exists, 1'b0 if not
function bit cl_syoscb_cfg::exist_queue(string queue_name);
  return this.queues.exists(queue_name)==0 ? 1'b0 : 1'b1;
endfunction

/// <b>Configuration API:</b> Returns the number of queues in this SCB
/// \return That value
function int unsigned cl_syoscb_cfg::size_queues();
  return this.queues.size();
endfunction: size_queues

/// <b>Configuration API:</b> Gets the producer object for a specified producer.
/// \param producer The name of the producer to get the producer object for
/// \return The producer object for the requested producer, null if no producer has that name
function cl_syoscb_cfg_pl cl_syoscb_cfg::get_producer(string producer);
  if(this.exist_producer(producer)) begin
    return this.producers[producer];
  end else begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Unable to get producer: %s", this.scb_name, producer), UVM_DEBUG);
    return null;
  end
endfunction: get_producer

/// <b>Configuration API:</b> Sets the given producer for the listed queues
/// If any errors occur, information about this is printed as a UVM_DEBUG message
/// If a list of queues has already been set for a given producer, overrides that list.
/// \param producer The name of the producer
/// \param queue_names Array of queue names which the producer should be associated with
/// \return 1'b1 if everything works correctly, 1'b0 if an errors occurs
function bit cl_syoscb_cfg::set_producer(string producer, queue_names[]);
  cl_syoscb_cfg_pl prod_list;

  // Check that all queues exists
  begin
    bit unique_queue_name[string];

    foreach (queue_names[i]) begin
      if(!unique_queue_name.exists(queue_names[i])) begin
        unique_queue_name[queue_names[i]] = 1'b1;
      end else begin
        `uvm_info("CFG_ERROR", $sformatf("[%s]: Unable to set producer: %s. List of queue names contains dublicates", this.scb_name, producer), UVM_DEBUG);
        return 1'b0;
      end

      // If queue does not exist then return 1'b0
      if(!this.exist_queue(queue_names[i])) begin
        `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.scb_name, queue_names[i]), UVM_DEBUG);
        return 1'b0;
      end
    end
  end

  // All queues exist -> set the producer
  prod_list = new();                    // Create producer list
  prod_list.set_list(queue_names);      // Set queue names in producer list
  this.producers[producer] = prod_list; // Set producer list for producer

  // Return 1'b1 since all is good
  return 1'b1;
endfunction: set_producer

/// <b>Configuration API:</b> Checks if a given producer exists.
/// \param producer The name of the producer to check
/// \return 1'b1 if that producer exists, 1'b0 otherwise
function bit cl_syoscb_cfg::exist_producer(string producer);
  return this.producers.exists(producer)==0 ? 1'b0 : 1'b1;
endfunction: exist_producer

/// <b>Configuration API:</b> Returns the names of all producers
/// \param producers Handle to dynamic string array in which producer names are returned.
///                  If the handle already points to an allocated array, that handle is overwritten.
function void cl_syoscb_cfg::get_producers(output string producers[]);
  string producer;
  int    unsigned idx = 0;

  producers = new[this.producers.size()];

  while(this.producers.next(producer)) begin
    producers[idx++] = producer;
  end
endfunction: get_producers

/// <b>Configuration API:</b> Gets the name of primary queue for this SCB.
/// The primary queue is used by the compare algorithms to select which queue to use as the primary one.
/// \return The name of the primary queue. If no primary queue has been set, returns an empty string
function string cl_syoscb_cfg::get_primary_queue();
  return(this.primary_queue);
endfunction: get_primary_queue

/// <b>Configuration API:</b> Sets the primary queue.
/// The primary queue is used by the compare algorithms to select which queue to use as the primary one.
/// If the given name does not match an existing queue's name, prints a UVM_DEBUG message.
/// \param primary_queue_name The name of the queue to make the primary queue
/// \return 1'b1 if the primary queue was successfully set, 1'b0 if the input queue name does not match a valid queue name
function bit cl_syoscb_cfg::set_primary_queue(string primary_queue_name);
  // If queue does not exist then return 1'b0
  if(!this.exist_queue(primary_queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.scb_name, primary_queue_name), UVM_DEBUG);
    return 1'b0;
  end

  // Set the primary queue
  this.primary_queue = primary_queue_name;

  // Return 1'b1 since all is good
  return 1'b1;
endfunction: set_primary_queue

/// <b>Configuration API:</b> Set the value of the #queue_type member variable
function void cl_syoscb_cfg::set_queue_type(t_scb_queue_type qt);
  this.queue_type = qt;
endfunction: set_queue_type

/// <b>Configuration API:</b> Get the value of the #queue_type member variable
function t_scb_queue_type cl_syoscb_cfg::get_queue_type();
  return this.queue_type;
endfunction: get_queue_type

/// <b>Configuration API:</b> Set the value of the #compare_type member variable
function void cl_syoscb_cfg::set_compare_type(t_scb_compare_type ct);
  this.compare_type = ct;
  //If we're performing OOO or UD comparisons, we generally don't want to print a miscompare report
  //If we're performing IO, IOP or IO2HP comparisons, we generally want it
  case (this.compare_type)
    pk_syoscb::SYOSCB_COMPARE_OOO,
    pk_syoscb::SYOSCB_COMPARE_USER_DEFINED: this.default_enable_comparer_report = 1'b0;

    default: this.default_enable_comparer_report = 1'b1;
  endcase
endfunction: set_compare_type

/// <b>Configuration API:</b> Get the value of the #compare_type member variable
function t_scb_compare_type cl_syoscb_cfg::get_compare_type();
  return this.compare_type;
endfunction: get_compare_type

/// <b>Configuration API:</b> Set the value of the #trigger_greediness member variable
function void cl_syoscb_cfg::set_trigger_greediness(t_scb_compare_greed tg);
  this.trigger_greediness = tg;
endfunction: set_trigger_greediness

/// <b>Configuration API:</b> Get the value of the #trigger_greediness member variable
function t_scb_compare_greed cl_syoscb_cfg::get_trigger_greediness();
  return this.trigger_greediness;
endfunction: get_trigger_greediness

/// <b>Configuration API:</b> Set the value of the #end_greediness member variable
function void cl_syoscb_cfg::set_end_greediness(t_scb_compare_greed eg);
  this.end_greediness = eg;
endfunction: set_end_greediness

/// <b>Configuration API:</b> Get the value of the #end_greediness member variable
function t_scb_compare_greed cl_syoscb_cfg::get_end_greediness();
  return this.end_greediness;
endfunction: get_end_greediness

/// <b>Configuration API:</b> Set the value of the #disable_clone member variable
function void cl_syoscb_cfg::set_disable_clone(bit dc);
  this.disable_clone = dc;
endfunction: set_disable_clone

/// <b>Configuration API:</b> Get the value of the #disable_clone member variable
function bit cl_syoscb_cfg::get_disable_clone();
  return this.disable_clone;
endfunction: get_disable_clone

/// <b>Configuration API:</b> Set the value of the #disable_compare_after_error member variable
function void cl_syoscb_cfg::set_disable_compare_after_error(bit dcae);
  this.disable_compare_after_error = dcae;
endfunction: set_disable_compare_after_error

/// <b>Configuration API:</b> Get the value of the #disable_compare_after_error member variable
function bit cl_syoscb_cfg::get_disable_compare_after_error();
  return this.disable_compare_after_error;
endfunction: get_disable_compare_after_error

/// <b>Configuration API:</b> Set the maximum number of items allowed in a given queue.
/// Defaults to 0 (no maximum number of items).
/// If no queue exists with that name, throws a UVM_FATAL
/// \param queue_name The name of the queue to modify
/// \param mqs The maximum number of items allowed in that queue
function void cl_syoscb_cfg::set_max_queue_size(string queue_name, int unsigned mqs);
  if(this.exist_queue(queue_name)) begin
    this.max_queue_size[queue_name] = mqs;
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %s not found when trying to set max_queue_size", this.scb_name, queue_name))
  end
endfunction: set_max_queue_size

/// <b>Configuration API:</b> Returns the maximum number of items allowed in a given queue.
/// If no queue exists with that name, throws a UVM_FATAL
/// \param queue_name The name of the queue to get the maximum size for
function int unsigned cl_syoscb_cfg::get_max_queue_size(string queue_name);
  if(this.exist_queue(queue_name)) begin
    return(this.max_queue_size[queue_name]);
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %s not found when trying to get max_queue_size", this.scb_name, queue_name))
    return(0);
  end
endfunction: get_max_queue_size

/// <b>Configuration API:</b> Set the value of the #print_orphans_as_errors member variable
function void cl_syoscb_cfg::set_orphans_as_errors(oae);
  this.print_orphans_as_errors = oae;
endfunction: set_orphans_as_errors

/// <b>Configuration API:</b> Get the value of the #print_orphans_as_errors member variable
function bit cl_syoscb_cfg::get_orphans_as_errors();
  return this.print_orphans_as_errors;
endfunction: get_orphans_as_errors

/// <b>Configuration API:</b> Set the value of the #max_print_orphans member variable
/// Not that if mpo < -1 throws a UVM_FATAL
function void cl_syoscb_cfg::set_max_print_orphans(int mpo);
  if(mpo < -1) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s] Input to set_max_print_orphans was illegal value (%0d). See field documentation for legal values", this.scb_name, mpo));
  end
  this.max_print_orphans = mpo;
endfunction: set_max_print_orphans

/// <b>Configuration API:</b> Get the value of the #max_print_orphans member variable
function int cl_syoscb_cfg::get_max_print_orphans();
  return this.max_print_orphans;
endfunction: get_max_print_orphans

/// <b>Configuration API:</b> Set the value of the #disable_report member variable
function void cl_syoscb_cfg::set_disable_report(bit dr);
  this.disable_report = dr;
endfunction: set_disable_report

/// <b>Configuration API:</b> Get the value of the #disable_report member variable
function bit cl_syoscb_cfg::get_disable_report();
  return this.disable_report;
endfunction: get_disable_report

/// <b>Configuration API:</b> Set the value of #enable_queue_stats for a given queue
/// If no queue exists with that name, throws a UVM_FATAL
/// \param queue_name The name of the queue to set the value of enable_queue_stats for
/// \param eqs The new value of enable_queue_stats for that queue
function void cl_syoscb_cfg::set_enable_queue_stats(string queue_name, bit eqs);
  if(this.exist_queue(queue_name)) begin
    this.enable_queue_stats[queue_name] = eqs;
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %s not found when trying to set enable_queue_stats", this.scb_name, queue_name))
  end
endfunction: set_enable_queue_stats

/// <b>Configuration API:</b> Get the value of #enable_queue_stats for a given queue
/// If no queue exists with that name, throws a UVM_FATAL
/// \param queue_name The name of the queue to get the value of enable_queue_stats for
function bit cl_syoscb_cfg::get_enable_queue_stats(string queue_name);
  if(this.exist_queue(queue_name)) begin
    return this.enable_queue_stats[queue_name];
  end else begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %s not found when trying to get enable_queue_stats", this.scb_name, queue_name))
    return 1'b0;
  end
endfunction: get_enable_queue_stats

/// <b>Configuration API:</b> Get the name of the SCB that this cfg is related to
function string cl_syoscb_cfg::get_scb_name();
  return this.scb_name;
endfunction: get_scb_name

/// <b>Configuration API:</b> Set the name of the SCB that this cfg is related to
function void cl_syoscb_cfg::set_scb_name(string scb_name);
  this.scb_name = scb_name;
endfunction: set_scb_name

/// <b>Configuration API:</b> Get the value of the #ordered_next member variable.
function bit cl_syoscb_cfg::get_ordered_next();
  return this.ordered_next;
endfunction: get_ordered_next

/// <b>Configuration API:</b> Set the value of the #ordered_next member variable.
function void cl_syoscb_cfg::set_ordered_next(bit ordered_next);
  this.ordered_next = ordered_next;
endfunction: set_ordered_next

/// <b>Configuration API:</b> Get the value of the #hash_compare_check member variable
function t_hash_compare_check cl_syoscb_cfg::get_hash_compare_check();
  return this.hash_compare_check;
endfunction: get_hash_compare_check

/// <b>Configuration API:</b> Set the value of the #hash_compare_check member variable
function void cl_syoscb_cfg::set_hash_compare_check(t_hash_compare_check hcc);
  this.hash_compare_check = hcc;
endfunction: set_hash_compare_check

/// <b>Configuration API:</b> Get the value of the #print_cfg member variable
function bit cl_syoscb_cfg::get_print_cfg();
  return this.print_cfg;
endfunction: get_print_cfg

/// <b>Configuration API:</b> Set the value of the #print_cfg member variable
function void cl_syoscb_cfg::set_print_cfg(bit pc);
  this.print_cfg = pc;
endfunction: set_print_cfg

/// <b>Configuration API:</b> Checks whether this SCB uses a dynamic or static primary queue.
/// \return 1'b1 if the primary queue is dynamic, 1'b0 if it is static
function bit cl_syoscb_cfg::dynamic_primary_queue();
  return this.get_primary_queue() == "";
endfunction: dynamic_primary_queue

/// <b>Configuration API:</b> Set the value of the #full_scb_dump member variable
function void cl_syoscb_cfg::set_full_scb_dump(bit fsd);
  this.full_scb_dump = fsd;
endfunction: set_full_scb_dump

/// <b>Configuration API:</b> Get the value of the #full_scb_dump member variable
function bit cl_syoscb_cfg::get_full_scb_dump();
  return this.full_scb_dump;
endfunction: get_full_scb_dump

/// <b>Configuration API:</b> Get the value of the #enable_c2s_full_scb_dump member variable
function void cl_syoscb_cfg::set_enable_c2s_full_scb_dump(bit ecfsd);
  this.enable_c2s_full_scb_dump = ecfsd;
endfunction: set_enable_c2s_full_scb_dump

/// <b>Configuration API:</b> Set the value of the #enable_c2s_full_scb_dump member variable
function bit cl_syoscb_cfg::get_enable_c2s_full_scb_dump();
  return this.enable_c2s_full_scb_dump;
endfunction: get_enable_c2s_full_scb_dump

/// <b>Configuration API:</b> Set the value of the full_scb_dump_type member variable
function void cl_syoscb_cfg::set_full_scb_dump_type(t_dump_type fsdt);
  this.full_scb_dump_type = fsdt;
endfunction: set_full_scb_dump_type

/// <b>Configuration API:</b> Get the value of the full_scb_dump_type member variable
function t_dump_type cl_syoscb_cfg::get_full_scb_dump_type();
  return this.full_scb_dump_type;
endfunction: get_full_scb_dump_type

/// <b>Configuration API:</b> Get the value of the #full_scb_dump_file_name member variable
function string cl_syoscb_cfg::get_full_scb_dump_file_name();
  return(this.full_scb_dump_file_name);
endfunction: get_full_scb_dump_file_name

/// <b>Configuration API:</b> Set the value of the #full_scb_dump_file_name member variable
function void cl_syoscb_cfg::set_full_scb_dump_file_name(string full_scb_dump_file_name);
  this.full_scb_dump_file_name = full_scb_dump_file_name;
endfunction: set_full_scb_dump_file_name

/// <b>Configuration API:</b> Set the value of the #full_scb_dump_split member variable
/// Note that setting #full_scb_max_queue_size > 0 for any queue in the SCB will
/// make it impossible to set fsds=0. A UVM_DEBUG message is printed if this happens.
/// \return 1'b1 if the value was successfully set, 1'b0 otherwise
function bit cl_syoscb_cfg::set_full_scb_dump_split(bit fsds);
  string queue_names[];

  this.get_queues(queue_names);

  foreach (queue_names[i]) begin
    if(fsds == 0 && this.get_full_scb_max_queue_size(queue_names[i]) > 0) begin
      `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s. Disabling full_scb_dump_split when full_scb_max_queue_size enabled is not supported.",this.scb_name, queue_names[i]),UVM_DEBUG);
      return 1'b0;
    end
  end

  this.full_scb_dump_split = fsds;
  return 1'b1;
endfunction: set_full_scb_dump_split

/// <b>Configuration API:</b> Get the value of the #full_scb_dump_split member variable
function bit cl_syoscb_cfg::get_full_scb_dump_split();
  return this.full_scb_dump_split;
endfunction: get_full_scb_dump_split

/// <b>Configuration API:</b> Set the value of the #full_scb_max_queue_size member variable.
/// #full_scb_dump_split must be enabled before setting this value. If not, a UVM_DEBUG message is printed and the call fails
/// If no queue exists with that name, throws a UVM_FATAL
/// \param queue_name The name of the queue for which to set the value of full_scb_max_queue_size
/// \param fsmqs The new value of full_scb_max_queue_size
function void cl_syoscb_cfg::set_full_scb_max_queue_size(string queue_name,int unsigned fsmqs);
   if(fsmqs > 0 && this.get_full_scb_dump_split() == 0) begin
     `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s. Cannot set full_scb_max_queue_size when full_scb_dump_split is 0. Must set to 1 beforehand.",this.scb_name, queue_name),UVM_DEBUG);
   end else begin
     if(!this.exist_queue(queue_name)) begin
       `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.scb_name, queue_name));
     end
     this.full_scb_max_queue_size[queue_name] = fsmqs;
   end
endfunction: set_full_scb_max_queue_size

/// <b>Configuration API:</b> Get the value of the #full_scb_max_queue_size member variable for a given queue.
/// If no queue exists with that name, prints a UVM_DEBUG message
/// \return The value of full_scb_max_queue_size if the queue name is valid, 0 otherwise
function int unsigned cl_syoscb_cfg::get_full_scb_max_queue_size(string queue_name);
  if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.scb_name, queue_name), UVM_DEBUG);
    return 0;
  end

  if(this.full_scb_max_queue_size.exists(queue_name)) begin
    return this.full_scb_max_queue_size[queue_name];
  end else begin
    return 0;
  end
endfunction: get_full_scb_max_queue_size

/// <b>Configuration API:</b> Returns the length of the queue name with maximum length
function int unsigned cl_syoscb_cfg::get_max_length_queue_name();
  int unsigned max_length_queue_name;

  foreach (this.queues[name]) begin
    if(name.len() > max_length_queue_name) begin
      max_length_queue_name = name.len();
    end
  end

  return max_length_queue_name;
endfunction: get_max_length_queue_name

/// <b>Configuration API:</b> Returns the length of the producer name with maximum length
function int unsigned cl_syoscb_cfg::get_max_length_producer();
  int unsigned max_length_producer;

  foreach (this.producers[name]) begin
    if(name.len() > max_length_producer) begin
      max_length_producer = name.len();
    end
  end

  return max_length_producer;
endfunction: get_max_length_producer

/// <b>Configuration API:</b> Enables or disables the comparer report for a number of comparers.
/// If both "queue_names" and "producer_names" are empty, sets the comparer report enable bit for all queue/producer combinations
/// If an invalid/non-existent queue or producer name is passed, a DEBUG message is printed,
///
/// \param ecr: The value of the comparer report enable/disable flag. See #enable_comparer_report for value descriptions.
/// \param queue_names: Names of the queues for which the designated comparers should use this comparer report enable bit
/// \param producer_names: Names of the producers for which all associated queues' comparers should use the given value
function void cl_syoscb_cfg::set_enable_comparer_report(bit ecr, string queue_names[], string producer_names[]);
  //If no queues or producers are given, set all comparer reports
  if(queue_names.size() == 0 && producer_names.size() == 0) begin
    this.get_queues(queue_names);
    this.get_producers(producer_names);
  end

  //For each producer, get their list of queues. Then, check if that list also contains a given queue
  //If it does, set that producer/queue combination
  foreach(producer_names[i]) begin
    if(!this.exist_producer(producer_names[i])) begin
      `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_names[i]), UVM_DEBUG)
    end else begin
      cl_syoscb_cfg_pl prod_list;

      prod_list = this.get_producer(producer_names[i]);
      foreach(queue_names[j]) begin
        if(!this.exist_queue(queue_names[j])) begin
          `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_names[i]), UVM_DEBUG)
        end else begin
          string f[$];

          f = prod_list.list.find(x) with (x == queue_names[j]);
          if(f.size() == 1) begin //We only expect exactly one match
            this.enable_comparer_report[producer_names[i]][queue_names[j]] = ecr;
          end
        end
      end
    end
  end
endfunction: set_enable_comparer_report

/// <b>Configuration API:</b> Returns the comparer report enable bit associated with a given queue/producer combination.
/// If no bit has been set for a given queue's comparer by using #set_enable_comparer_report,
/// returns #default_enable_comparer_report
///
/// \param queue_name Name of the queue for which the designated comparer's enable report bit should be returned
/// \param producer_name Name of the producer for which the associated queue's comparer's enable report bit should be returned
/// \return The given queue/producer combination's comparer enable report bit, or the default value if none has been set
///         for this specific queue/producer combination
function bit cl_syoscb_cfg::get_enable_comparer_report(string queue_name, string producer_name);
  if(!this.exist_producer(producer_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_name), UVM_DEBUG)
  end else if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_name), UVM_DEBUG)
  end else if(this.enable_comparer_report.exists(producer_name) && this.enable_comparer_report[producer_name].exists(queue_name)) begin
    return this.enable_comparer_report[producer_name][queue_name];
  end

  //Explicitly returns default value if no entry exists for the given producer/queue combo
  return this.default_enable_comparer_report;
endfunction: get_enable_comparer_report

/// <b>Configuration API:</b> Set the value of the #default_enable_comparer_report member variable.
///                           See #enable_comparer_report for legal values.
function void cl_syoscb_cfg::set_default_enable_comparer_report(bit ecr);
  this.default_enable_comparer_report = ecr;
endfunction: set_default_enable_comparer_report

/// <b>Configuration API:</b> Get the value of the #default_enable_comparer_report member variable
function bit cl_syoscb_cfg::get_default_enable_comparer_report();
  return this.default_enable_comparer_report;
endfunction: get_default_enable_comparer_report

/// <b>Configuration API:</b> Sets the comparer to be used for a number of queues.
/// If both "queue_names" and "producer_names" are empty, sets the given comparer for all queue/producer combinations.
/// If an invalid/non-existent queue or producer name is passed, a DEBUG message is printed.
///
/// \param comparer The comparer to be used for the given queues and producers.
/// \param queue_names Names of the queues for which the given comparer should be used.
/// \param producer_names Names of the producers for which all associated queues' should use the given comparer.
function void cl_syoscb_cfg::set_comparer(uvm_comparer comparer, string queue_names[], string producer_names[]);
  //If no queues or producers are given, set all comparers
  if(queue_names.size() == 0 && producer_names.size() == 0) begin
    this.get_queues(queue_names);
    this.get_producers(producer_names);
  end

  //For each producer, get their list of queues. Then, check if that list also contains a given queue
  //If it does, set that producer/queue combination
  foreach(producer_names[i]) begin
    if(!this.exist_producer(producer_names[i])) begin
      `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_names[i]), UVM_DEBUG)
    end else begin
      cl_syoscb_cfg_pl prod_list;

      prod_list = this.get_producer(producer_names[i]);
      foreach(queue_names[j]) begin
        if(prod_list.exists(queue_names[j])) begin //We only expect exactly one match
          this.comparers[producer_names[i]][queue_names[j]] = comparer;
        end else begin
            `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_names[i]), UVM_DEBUG)
        end
      end
    end
  end
endfunction: set_comparer

/// <b>Configuration API:</b> Returns the comparer associated with a given queue and producer.
/// \param queue_name Name of the queue for which the comparer should be returned
/// \param producer_name Name of the producer for which the associated queue's comparer should be returned
/// \return The requested comparer. If no comparer has been set for a given queue/producer, returns null.
///         Also returns null if either of the input parameters are invalid.
function uvm_comparer cl_syoscb_cfg::get_comparer(string queue_name, string producer_name);
  if(!this.exist_producer(producer_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_name), UVM_DEBUG)
  end else if(!this.get_producer(producer_name).exists(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_name), UVM_DEBUG)
  end else if(this.comparers.exists(producer_name) && this.comparers[producer_name].exists(queue_name)) begin
    return this.comparers[producer_name][queue_name];
  end

  //Explicitly returns null if producer/queue name does not exist,
  //or if no entry exists for the given producer / for the given queue under that producer
  return null;
endfunction: get_comparer

/// <b>Configuration API:</b> Set the value of the #default_comparer member variable
function void cl_syoscb_cfg::set_default_comparer(uvm_comparer comparer);
  this.default_comparer = comparer;
endfunction: set_default_comparer

/// <b>Configuration API:</b> Get the value of the #default_comparer member variable
function uvm_comparer cl_syoscb_cfg::get_default_comparer();
  if(this.default_comparer == null) begin
    `ifdef UVM_VERSION
      this.default_comparer = uvm_comparer::get_default();
    `else
      this.default_comparer = uvm_default_comparer;
    `endif
    //Set default verbosity to UVM_HIGH, as we generally don't want to print MISCMP messages
    cl_syoscb_comparer_config::set_verbosity(this.default_comparer, UVM_HIGH);
  end

  return this.default_comparer;
endfunction: get_default_comparer


/// <b>Configuration API:</b> Sets the verbosity level to be used for a number of printers.
/// If both "queue_names" and "producer_names" are empty, sets the verbosity bit for all queue/producer combinations
/// If an invalid/non-existent queue or producer name is passed, a DEBUG message is printed,
///
/// \param pv The value of the verbosity bit to set. See #printer_verbosity for value descriptions
/// \param queue_names Names of the queues for which the designated printers should use this verbosity bit
/// \param producer_names Names of the producers for which all associated queues' printers should use the given verbosity bit.
function void cl_syoscb_cfg::set_printer_verbosity(bit pv, string queue_names[], string producer_names[]);
  //If no queues or producers are given, set all verbosity bits
  if(queue_names.size() == 0 && producer_names.size() == 0) begin
    this.get_queues(queue_names);
    this.get_producers(producer_names);
  end

  //For each producer, get their list of queues. Then, check if that list also contains a given queue
  //If it does, set that producer/queue combination
  foreach(producer_names[i]) begin
    if(!this.exist_producer(producer_names[i])) begin
      `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_names[i]), UVM_DEBUG)
    end else begin
      cl_syoscb_cfg_pl prod_list;

      prod_list = this.get_producer(producer_names[i]);
      foreach(queue_names[j]) begin
        if(!this.exist_queue(queue_names[j])) begin
          `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_names[i]), UVM_DEBUG)
        end else begin
          string f[$];

          f = prod_list.list.find(x) with (x == queue_names[j]);
          if(f.size() == 1) begin //We only expect exactly one match
            this.printer_verbosity[producer_names[i]][queue_names[j]] = pv;
          end
        end
      end
    end
  end
endfunction: set_printer_verbosity

/// <b>Configuration API:</b> Returns the verbosity bit associated with a given queue/producer combination.
/// \param queue_name Name of the queue for which the designated printers's verbosity bit should be returned
/// \param producer_name Name of the producer for which the associated queue's printers's verbosity bit should be returned
/// \return That queue/producer combination's printer verbosity bit. If none has been set, or either argument is invalid,
///         returns #default_printer_verbosity.
function bit cl_syoscb_cfg::get_printer_verbosity(string queue_name, string producer_name);
  if(!this.exist_producer(producer_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_name), UVM_DEBUG)
  end else if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_name), UVM_DEBUG)
  end else if(this.printer_verbosity.exists(producer_name) && this.printer_verbosity[producer_name].exists(queue_name)) begin
    return this.printer_verbosity[producer_name][queue_name];
  end

  //Always return default verbosity in case queue/producer name does not exist or no other verbosity is set
  return this.default_printer_verbosity;
endfunction: get_printer_verbosity

/// <b>Configuration API:</b> Set the value of the #default_printer_verbosity member variable.
///                           See #printer_verbosity for legal values
function void cl_syoscb_cfg::set_default_printer_verbosity(bit pv);
  this.default_printer_verbosity = pv;
endfunction: set_default_printer_verbosity

/// <b>Configuration API:</b> Get the value of the #default_printer_verbosity member variable
function bit cl_syoscb_cfg::get_default_printer_verbosity();
  return this.default_printer_verbosity;
endfunction: get_default_printer_verbosity

/// <b>Configuration API:</b> Sets the given uvm_printer to be used for some queue/producer-combinations.
/// If both "queue_names" and "producer_names" are empty, sets that printer to be used for all queue/producers
/// If an invalid/non-existent queue or producer name is passed, a DEBUG message is printed,
///
/// \param printer: The printer to be used for the given queues and producers
/// \param queue_names: Names of the queues which should use the printer.
/// \param producer_names: Names of the producers for which all associated queues should use the given printer.
function void cl_syoscb_cfg::set_printer(uvm_printer printer, string queue_names[], string producer_names[]);

  //If no queues or producers are given, set all printers
  if(queue_names.size() == 0 && producer_names.size() == 0) begin
    this.get_queues(queue_names);
    this.get_producers(producer_names);
  end

  //For each producer, get their list of queues. Then, check if that list also contains a given queue
  //If it does, set that producer/queue combination
  foreach(producer_names[i]) begin
    if(!this.exist_producer(producer_names[i])) begin
      `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_names[i]), UVM_DEBUG)
    end else begin
      cl_syoscb_cfg_pl prod_list;

      prod_list = this.get_producer(producer_names[i]);
      foreach(queue_names[j]) begin
        if(prod_list.exists(queue_names[j])) begin //We only expect exactly one match
          this.printers[producer_names[i]][queue_names[j]] = printer;
        end else begin
            `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_names[i]), UVM_DEBUG)
        end
      end
    end
  end
endfunction: set_printer

/// <b>Configuration API:</b> Returns the printer associated with a given producer/queue combination.
/// \param queue_name: Name of the queue for which the printer should be returned
/// \param producer_name: Name of the producer for which the associated queue's printer should be returned
/// \return That queue/producer combination's printer. If none has been set, or either argument is invalid,
///         returns null.
function uvm_printer cl_syoscb_cfg::get_printer(string queue_name, string producer_name);
  if(!this.exist_producer(producer_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Producer %0s does not exist", this.scb_name, producer_name), UVM_DEBUG)
  end else if(!this.get_producer(producer_name).exists(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s]: Queue: %0s was not found", this.scb_name, queue_name), UVM_DEBUG)
  end else if(this.printers.exists(producer_name) && this.printers[producer_name].exists(queue_name)) begin
    return this.printers[producer_name][queue_name];
  end

  //Explicitly returns null if producer/queue name does not exist,
  //or if no entry exists for the given producer / for the given queue under that producer
  return null;
endfunction: get_printer

/// <b>Configuration API:</b> Get the value of the #default_printer member variable
function uvm_printer cl_syoscb_cfg::get_default_printer();
  if(this.default_printer == null) begin
    `ifdef UVM_VERSION
      this.default_printer = uvm_printer::get_default();
    `else
      this.default_printer = uvm_default_printer;
    `endif
    end
  return this.default_printer;
endfunction: get_default_printer

/// <b>Configuration API:</b> Set the value of the #default_printer member variable
function void cl_syoscb_cfg::set_default_printer(uvm_printer printer);
  this.default_printer = printer;
endfunction: set_default_printer

/// <b>Configuration API:</b> Set the value of the #enable_no_insert_check member variable.
function void cl_syoscb_cfg::set_enable_no_insert_check(bit enic);
  this.enable_no_insert_check = enic;
endfunction: set_enable_no_insert_check

/// <b>Configuration API:</b> Gets the values of the #enable_no_insert_check member variable
function bit cl_syoscb_cfg::get_enable_no_insert_check();
  return this.enable_no_insert_check;
endfunction: get_enable_no_insert_check

/// <b>Configuration API:</b> Sets the maximum search window when performing OOO, IOP or user defined comparison operations.
/// If the current comparison type is not \c SYOSCB_COMPARE_OOO, \c SYOSCB_COMPARE_IOP or \c SYOSCB_COMPARE_USER_DEFINED,
/// a uvm_fatal is generated.
/// All other comparison types expect matching items to be at the head of their respective queues, so these
/// comparisons are the only place where the notion of a maximum search window makes sense.
/// Will also throw a fatal if the given queue's type is not one of \c SYOSCB_QUEUE_STD or \c SYOSCB_QUEUE_USER_DEFINED.
/// A maximum search window does not make sense when using MD5-queues,
/// as all lookups are performed in O(1) time, independent of the number of elements in the queue.
///
/// \param sw: The maximum search window the for given queues. If set to 0, all items in the given queues are searched
/// \param queue_names: Names of the queues to set the maximum search window for. If an empty array is given, the maximum search window for all queues is set to \c sw.
///       If an invalid queue name is passed, a UVM_FATAL is raised.
function void cl_syoscb_cfg::set_max_search_window(int unsigned sw, string queue_names[]);
  //If no queue names are given, act on all queues
  if(queue_names.size() == 0) begin
    this.get_queues(queue_names);
  end

  foreach(queue_names[i]) begin
    if(!this.exist_queue(queue_names[i])) begin
      `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue %0s was not found", this.scb_name, queue_names[i]))
    end else if((this.compare_type != pk_syoscb::SYOSCB_COMPARE_OOO && this.compare_type != pk_syoscb::SYOSCB_COMPARE_USER_DEFINED)) begin
      `uvm_fatal("CFG_ERROR", $sformatf("Can only set max search window if compare type is OOO or USER_DEFINED. Got %0s", this.compare_type.name()));
    end else if (this.queue_type != pk_syoscb::SYOSCB_QUEUE_STD && this.queue_type != pk_syoscb::SYOSCB_QUEUE_USER_DEFINED) begin
      `uvm_fatal("CFG_ERROR", $sformatf("Can only set max search window when queue type is STD or USER_DEFINED. Got %0s", this.queue_type.name()));
    end else begin
      //Queue name exists and everything is valid
      this.max_search_window[queue_names[i]] = sw;
    end
  end
endfunction: set_max_search_window

/// <b>Configuration API:</b> Returns the value of #max_search_window for a given queue.
/// If an invalid queue name is passed, prints a UVM_DEBUG message
/// \param queue_name: The queue for which to get the maximum search window.
/// \return That queue's max. search window. If no maximum search window has been set, returns 0
function int unsigned cl_syoscb_cfg::get_max_search_window(string queue_name);
  if(!this.exist_queue(queue_name)) begin
    `uvm_info("CFG_ERROR", $sformatf("[%s] Cannot get max search window for queue named '%0s'. No queue with this name.", this.scb_name, queue_name), UVM_DEBUG)
    return 0;
  end else if(!this.max_search_window.exists(queue_name)) begin
    this.max_search_window[queue_name] = 0;
  end

  return this.max_search_window[queue_name];
endfunction: get_max_search_window

/// <b>Configuration API:</b> Sets the value of the #mutexed_add_item_enable member variable.
function void cl_syoscb_cfg::set_mutexed_add_item_enable(bit maie);
  this.mutexed_add_item_enable = maie;
endfunction: set_mutexed_add_item_enable

/// <b>Configuration API:</b> Gets the value of the #mutexed_add_item_enable member variable.
function bit cl_syoscb_cfg::get_mutexed_add_item_enable();
  return this.mutexed_add_item_enable;
endfunction: get_mutexed_add_item_enable

/// <b>Configuration API:</b> Sets the value of the #dump_orphans_to_files member variable.
/// \note If dotf == 1'b1 and #max_print_orphans < 0, a UVM_FATAL is thrown as it
/// does not make sense to dump orphans when no orphans are printed.
function void cl_syoscb_cfg::set_dump_orphans_to_files(bit dotf);
  if(this.max_print_orphans < 0 && dotf == 1'b1) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Enabling dump_orphans_to_files while max_print_orphans < 0 will cause nothing to be dumped. Ensure that max_print_orphans >= 0 before enabling dumping.", this.scb_name))
  end
  this.dump_orphans_to_files = dotf;
endfunction: set_dump_orphans_to_files

/// <b>Configuration API:</b> Gets the value of the #dump_orphans_to_files member variable
function bit cl_syoscb_cfg::get_dump_orphans_to_files();
  return this.dump_orphans_to_files;
endfunction: get_dump_orphans_to_files

/// <b>Configuration API:</b> Sets the value of the #orphan_dump_type member variable
function void cl_syoscb_cfg::set_orphan_dump_type(t_dump_type odt);
  this.orphan_dump_type = odt;
endfunction: set_orphan_dump_type

/// <b>Configuration API:</b> Get the value of the #orphan_dump_type member variable
function t_dump_type cl_syoscb_cfg::get_orphan_dump_type();
  return this.orphan_dump_type;
endfunction: get_orphan_dump_type

/// <b>Configuration API:</b> Sets the value of the #orphan_dump_file_name member variable
function void cl_syoscb_cfg::set_orphan_dump_file_name(string odfn);
  this.orphan_dump_file_name = odfn;
endfunction: set_orphan_dump_file_name

/// <b>Configuration API:</b> Gets the value of the #orphan_dump_file_name member variable
function string cl_syoscb_cfg::get_orphan_dump_file_name();
  return this.orphan_dump_file_name;
endfunction: get_orphan_dump_file_name

/// <b>Configuration API:</b> Sets the value of the #queue_stat_interval member variable for the given queue.
/// If the given queue name does not match an existing queue, throws a UVM_FATAL.
/// \param queue_name The name of the queue for which to set the value
/// \param qsi The new value of the queue's statistic printout interval
function void cl_syoscb_cfg::set_queue_stat_interval(string queue_name, int unsigned qsi);
  if(!this.exist_queue(queue_name)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s] Queue %0s was not found", this.scb_name, queue_name))
  end
  this.queue_stat_interval[queue_name] = qsi;

endfunction: set_queue_stat_interval

/// <b>Configuration API:</b> Gets the value of the #queue_stat_interval member variable for the given queue.
/// If the given queue name does not match an existing queue, throws a UVM_FATAL.
/// If no stat interval has been set for the given queue yet, returns 0
/// \param queue_name The name of the queue for which to get the value
function int unsigned cl_syoscb_cfg::get_queue_stat_interval(string queue_name);
  if(!this.exist_queue(queue_name)) begin
    `uvm_fatal("CFG_ERRO", $sformatf("[%s] Queue %0s was not found", this.scb_name, queue_name))
  end else if(!this.queue_stat_interval.exists(queue_name)) begin
    this.queue_stat_interval[queue_name] = 0;
  end
  return this.queue_stat_interval[queue_name];
endfunction: get_queue_stat_interval

/// <b>Configuration API:</b> Sets the value of the #scb_stat_interval member variable
/// \param ssi The new value of the field
function void cl_syoscb_cfg::set_scb_stat_interval(int unsigned ssi);
  this.scb_stat_interval = ssi;
endfunction: set_scb_stat_interval

/// <b>Configuration API:</b> Gets the value of the #scb_stat_interval member variable
function int unsigned cl_syoscb_cfg::get_scb_stat_interval();
  return this.scb_stat_interval;
endfunction: get_scb_stat_interval


// Custom do_print implementation.
// Primarily used to print queue names and static/dynamic primary queue
function void cl_syoscb_cfg::do_print(uvm_printer printer);
  string queue_name;

  if(this.queues.first(queue_name)) begin
    int unsigned idx = 0;

    printer.print_generic(.name("queues"),
                          .type_name("-"),
                          .size(this.queues.size()),
                          .value("-"));
    do begin
      printer.print_generic(.name($sformatf("  [%0d]", idx++)),
                            .type_name(" "),
                            .size(queue_name.len()),
                            .value(queue_name));
    end
    while(this.queues.next(queue_name));
  end

  printer.print_string(.name("primary_queue"),
                       .value(this.dynamic_primary_queue() == 1'b1 ? "<dynamic>" :
                                                                     $sformatf("<static: %0s>",
                                                                               primary_queue)));

  super.do_print(printer);
endfunction: do_print

// The implementation of do_copy for cfg objects is used
// in order to copy printer and comparer handles as these cannot be registered
// with the uvm macros
function void cl_syoscb_cfg::do_copy(uvm_object rhs);
  cl_syoscb_cfg rhs_cast;
  uvm_comparer  comparer;
  uvm_printer   printer;
  uvm_printer   new_printer;
  string        queue_names[];
  string        producer_names[];
  bit           verbosity;

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_copy",
               $sformatf("the given object argument is not %0p type", rhs_cast.get_type()))
  end

  rhs_cast.get_queues(queue_names);
  rhs_cast.get_producers(producer_names);

  //Copy RHS default and queue-specific comparers
  comparer = this.get_default_comparer();
  cl_syoscb_comparer_config::copy_comparer(rhs_cast.get_default_comparer(), comparer);
  this.set_default_comparer(comparer);

  verbosity = rhs_cast.get_default_enable_comparer_report();
  this.set_default_enable_comparer_report(verbosity);

  foreach(producer_names[i]) begin
    foreach(queue_names[j]) begin
      uvm_comparer new_comparer;
      bit new_ecr;
      comparer = rhs_cast.get_comparer(queue_names[j], producer_names[i]);
      if(comparer != null) begin
        $cast(new_comparer, comparer);
        cl_syoscb_comparer_config::copy_comparer(comparer, new_comparer);
        this.set_comparer(new_comparer, '{queue_names[j]}, '{producer_names[i]});

        new_ecr = rhs_cast.get_enable_comparer_report(queue_names[j], producer_names[i]);
        this.set_enable_comparer_report(new_ecr, '{queue_names[j]}, '{producer_names[i]});
      end
    end
  end

  //Copy RHS default and queue-specific printers
  printer = rhs_cast.get_default_printer();
  $cast(new_printer, printer);
  cl_syoscb_printer_config::copy_printer(new_printer, printer);
  this.set_default_printer(new_printer);

  verbosity = rhs_cast.get_default_printer_verbosity();
  this.set_default_printer_verbosity(verbosity);

  foreach(producer_names[i]) begin
    foreach(queue_names[j]) begin
      bit new_verbosity;
      printer = rhs_cast.get_printer(queue_names[j], producer_names[i]);

      if(printer != null) begin
        $cast(new_printer, printer);
        cl_syoscb_printer_config::copy_printer(printer, new_printer);
        this.set_printer(new_printer, '{queue_names[j]}, '{producer_names[i]});

        new_verbosity = rhs_cast.get_printer_verbosity(queue_names[j], producer_names[i]);
        this.set_printer_verbosity(new_verbosity, '{queue_names[j]}, '{producer_names[i]});
      end
    end
  end

  super.do_copy(rhs);
endfunction: do_copy

// The implementation of do_pack is primarily used to pack information
// about printers and comparers as these are not automatically packed.
function void cl_syoscb_cfg::do_pack(uvm_packer packer);
  string            queue_names[];
  string            producer_names[];
  cl_syoscb_cfg_pl  prod_list;
  bit               printer_verbosity;
  uvm_printer       printer;
  uvm_comparer      comparer;
  bit               ecr;

  super.do_pack(packer);
  this.get_producers(producer_names);

  //Ensure that we are using metadata when packing
  //Start by packing the number of producers
  packer.pack_field_int(this.producers.size(), $bits(this.producers.size()));
  foreach(producer_names[i]) begin
    // Using producer list to get queue names since this.get_queues returns an
    // empty list if this cfg was generated by copying another cfg
    prod_list = this.get_producer(producer_names[i]);
    queue_names = prod_list.list;

    //Pack producer name, number of queues and iteratively pack queue names and queue-specific values
    packer.pack_string(producer_names[i]);
    packer.pack_field_int(queue_names.size(), $bits(queue_names.size()));

    foreach(queue_names[j]) begin
      printer = this.get_printer(queue_names[j], producer_names[i]);
      comparer = this.get_comparer(queue_names[j], producer_names[i]);
      ecr = this.get_enable_comparer_report(queue_names[j], producer_names[i]);
      printer_verbosity = this.get_printer_verbosity(queue_names[j], producer_names[i]);

      packer.pack_string(queue_names[j]);
      cl_syoscb_comparer_config::do_help_pack(comparer, packer);
      cl_syoscb_printer_config::do_help_pack(printer, packer);
      packer.pack_field_int(printer_verbosity, $bits(printer_verbosity));
      packer.pack_field_int(ecr, $bits(ecr));
    end
  end

  cl_syoscb_comparer_config::do_help_pack(this.get_default_comparer(), packer);
  cl_syoscb_printer_config::do_help_pack(this.get_default_printer(), packer);
  packer.pack_field_int(this.default_printer_verbosity, $bits(this.default_printer_verbosity));
  packer.pack_field_int(this.default_enable_comparer_report, $bits(this.default_enable_comparer_report));
endfunction: do_pack

// The implementation of do_unpack ensures that printers and comparers
// are correctly unpacked and new objects instantiated
function void cl_syoscb_cfg::do_unpack(uvm_packer packer);
  string           queue_names[];
  string           producer_names[];
  bit              printer_verbosity;
  bit              ecr;
  int              num_producers;
  int              num_queues;
  uvm_comparer     comparer;
  uvm_printer      printer;

  super.do_unpack(packer);

  //Get number of producers to loop through
  num_producers = packer.unpack_field_int($bits(num_producers));
  for(int i=0; i<num_producers; i++) begin
    string producer_name;

    //Get producer name and associated number of queues, generate producer list
    producer_name = packer.unpack_string();
    num_queues = packer.unpack_field_int($bits(num_queues));
    this.producers[producer_name] = new;
    this.producers[producer_name].list = new[num_queues];
    for(int j=0; j<num_queues; j++) begin

      //Get queue name and associated printers/comparers
      string queue_name;

      queue_name = packer.unpack_string();

      this.producers[producer_name].list[j] = queue_name;
      comparer = cl_syoscb_comparer_config::do_help_unpack(packer);
      printer = cl_syoscb_printer_config::do_help_unpack(packer);
      printer_verbosity = packer.unpack_field_int($bits(printer_verbosity));
      ecr = packer.unpack_field_int($bits(ecr));

      this.set_comparer(comparer, '{queue_name}, '{producer_name});
      this.set_printer(printer, '{queue_name}, '{producer_name});
      this.set_printer_verbosity(printer_verbosity, '{queue_name}, '{producer_name});
      this.set_enable_comparer_report(ecr, '{queue_name}, '{producer_name});
    end
  end
  comparer = cl_syoscb_comparer_config::do_help_unpack(packer);
  printer = cl_syoscb_printer_config::do_help_unpack(packer);
  this.set_default_comparer(comparer);
  this.set_default_printer(printer);
  printer_verbosity = packer.unpack_field_int($bits(printer_verbosity));
  ecr = packer.unpack_field_int($bits(ecr));
endfunction: do_unpack