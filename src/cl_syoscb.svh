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
/// Top level class implementing the root of the SyoSil UVM scoreboard
class cl_syoscb extends uvm_scoreboard;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the global UVM scoreboard configuration
  local cl_syoscb_cfg cfg;

  /// Array holding handles to all queues
  local cl_syoscb_queue_base queues[];

  /// Handle to the compare strategy
  local cl_syoscb_compare compare_strategy;

  /// Associative array holding a uvm_subscriber for each queue
  local cl_syoscb_subscriber subscribers[string];

  /// Flag indicating if a scoreboard header has been dumped when dumping shadow queues
  local bit header_dumped[string];

  /// AA containing failed scoreboard check (e.g. no items inserted))
  local string failed_checks[string];

  /// Mutex to be used when calls to #add_item should be mutexed
  local semaphore add_item_mutex;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb)
    `uvm_field_object(cfg,                   UVM_DEFAULT)
    //`uvm_field_array_object(queues,          UVM_DEFAULT)
    `uvm_field_object(compare_strategy,      UVM_DEFAULT)
    `uvm_field_aa_object_string(subscribers, UVM_DEFAULT)
    `uvm_field_aa_int_string(header_dumped,  UVM_DEFAULT)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb", uvm_component parent = null);
  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern function void check_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
  extern function void final_phase(uvm_phase phase);

  //-------------------------------------
  // Function based API
  //-------------------------------------
  extern virtual function void          add_item(string queue_name, string producer,
                                                 uvm_sequence_item item);
  extern virtual task                   add_item_mutexed(string queue_name, string producer,
                                                         uvm_sequence_item item);
  extern virtual function void          compare_trigger(string queue_name= "",
                                                        cl_syoscb_item item = null);
  extern virtual function void          dump();
  extern virtual function void          flush_queues_all();
  extern virtual function void          flush_queues(string queue_name = "");
  extern virtual function bit           empty_queues(string queue_name = "");
  extern virtual function bit           insert_queues(string queue_name = "");
  extern virtual function void          compare_control(bit cc);
  extern virtual function string        create_total_stats(int unsigned offset,
                                                           int unsigned first_column_width);
  extern virtual function string        create_report(bit end_of_sim = 1'b1);
  extern virtual function int unsigned  get_total_cnt_add_items();
  extern virtual function int unsigned  get_total_cnt_flushed_items();
  extern virtual function int unsigned  get_total_queue_size();
  extern virtual function string        get_failed_checks();


  //-------------------------------------
  // Transaction based API
  //-------------------------------------
  extern virtual function cl_syoscb_subscriber get_subscriber(string queue_name, string producer);

  //-------------------------------------
  // Misc. functions for internal usage
  //-------------------------------------
  extern virtual function cl_syoscb_cfg get_cfg();
  extern virtual function string       create_report_contents(int unsigned offset,
                                                              int unsigned first_column_width);
  extern virtual function void         pre_abort();

  extern protected virtual function void   dump_txt();
  extern protected virtual function void   dump_xml();
  extern protected virtual function void   dump_split_txt();
  extern protected virtual function void   dump_join_txt();
  extern protected virtual function void   dump_split_xml();
  extern protected virtual function void   dump_join_xml();
  extern protected virtual function string print_header(string queue_name);
  extern protected virtual function string create_queues_stats(int unsigned offset,
                                                               int unsigned first_column_width);
  extern protected virtual function string get_queue_failed_checks();
  extern protected virtual function void   override_queue_type();
  extern protected virtual function void   override_compare_type();
  extern protected virtual function void   config_validation();
  extern protected virtual function void   intermediate_queue_stat_dump(string queue_name);
endclass: cl_syoscb

function cl_syoscb::new(string name = "cl_syoscb", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

/// UVM build phase. Gets the scoreboard configuration and forwards it to the child components
/// (cl_syoscb_queue and cl_syoscb_compare). Additionally, it creates all of the queues defined
/// in the configuration object.
/// Finally, it also creates the compare strategy via a factory create call.
function void cl_syoscb::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    // *NOTE*: If no cfg object is given then no scb name is available
    //         Thus, no scb name is printed here
    `uvm_fatal("CFG_ERROR", "Configuration object not passed.")
  end

  // Set the default SCB name if not specified explicitly
  if(this.cfg.get_scb_name() == "") begin
    this.cfg.set_scb_name(this.get_name());
  end

  // Print the SCB cfg according to its internal member field knob
  if(this.cfg.get_print_cfg()) begin
    this.cfg.print();
  end

  // Create list of queues
  this.queues = new[this.cfg.size_queues()];

  // Override the queue type basing on current scb cfg
  this.override_queue_type();

  // Forward the configuration to the compare_strategy
  uvm_config_db #(cl_syoscb_cfg)::set(this, "compare_strategy", "cfg", this.cfg);

  // Override the compare type basing on current scb cfg
  this.override_compare_type();

  // Create the compare strategy
  this.compare_strategy = cl_syoscb_compare::type_id::create(.name("compare_strategy"),
                                                             .parent(this));

  //Initialize mutex if necessary
  if(this.cfg.get_mutexed_add_item_enable()) begin
    this.add_item_mutex = new(1);
  end

  begin
    string producers[];

    this.cfg.get_producers(producers);

    foreach(producers[i]) begin
      cl_syoscb_cfg_pl pl = this.cfg.get_producer(producers[i]);

      foreach(pl.list[j]) begin
        cl_syoscb_subscriber subscriber;

        subscriber = cl_syoscb_subscriber::type_id::create({producers[i], "_", pl.list[j], "_subscr"}, this);
        subscriber.set_queue_name(pl.list[j]);
        subscriber.set_producer(producers[i]);
        subscriber.set_mutexed_add_item_enable(this.cfg.get_mutexed_add_item_enable());
        this.subscribers[{pl.list[j], producers[i]}] = subscriber;
      end
    end
  end
endfunction: build_phase

/// UVM end of elaboration phase. Validate the scb configuration before proceding forward.
/// Generate a UVM_FATAL for configuration combinations which are not allowed, or a warning if the combination
/// has been internally evaluated as not recommended.
function void cl_syoscb::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  this.config_validation();
endfunction: end_of_elaboration_phase

/// UVM check phase. Checks if the SCB is empty. If true and cl_syoscb_cfg#enable_no_insert_check is true,
/// a UVM error is issued.
function void cl_syoscb::check_phase(uvm_phase phase);
  // Check that this scb is empty. If not then issue an error
  if(!this.empty_queues()) begin
    this.failed_checks["SCB_NOT_EMPTY"] = $sformatf("Scb %s not empty", this.cfg.get_scb_name());
  end

  // Check if insert check is enabled, and issue an error if one of the queues has not been filled with at least one element
  if(this.cfg.get_enable_no_insert_check() && !this.insert_queues()) begin
    this.failed_checks["SCB_NO_INSERTS"] = $sformatf("Nothing has been inserted in Scb %s", this.cfg.get_scb_name());
  end
endfunction: check_phase

/// UVM report phase. Prints the status of the scoreboard instance.
function void cl_syoscb::report_phase(uvm_phase phase);
  super.report_phase(phase);

  if(!this.cfg.get_disable_report()) begin
    string report;

    report = this.create_report();
    // *NOTE*: Using this.get_name() is sufficient since the component
    //         instance name is the queue name by definition
    `uvm_info("QUEUE", $sformatf("[%s]: Statistics summary:%s", this.cfg.get_scb_name(), report), UVM_NONE)

    // Report any errors when in control
    begin
      string failed_checks;

      failed_checks = { failed_checks, this.get_queue_failed_checks() };

      if(failed_checks != "") begin
        `uvm_error("QUEUE_ERROR", $sformatf("[%s]: Queue errors:\n%s", this.cfg.get_scb_name(), failed_checks))
      end
    end
  end
endfunction: report_phase

/// UVM final phase. Prints in the file called dump.txt the information about the shadow queue of all the queues.
function void cl_syoscb::final_phase(uvm_phase phase);
  if(this.cfg.get_full_scb_dump() == 1'b1) begin
    this.dump();
  end
endfunction: final_phase

/// Gets the configuration for this scoreboard
function cl_syoscb_cfg cl_syoscb::get_cfg();
  return this.cfg;
endfunction: get_cfg

/// <b> Scoreboard API:</b> Adds a uvm_sequence_item to a given queue for a given producer.
/// The method will check if the queue and producer exists before adding it to the queue.
///
/// \param queue_name The name of the queue the item should be added to
/// \param producer   The name of the producer that generated this item
/// \param item       The sequence item that should be added to the queue
function void cl_syoscb::add_item(string queue_name, string producer, uvm_sequence_item item);
  cl_syoscb_queue_base queue;
  uvm_sequence_item item_clone;

  // Check queue
  if(!this.cfg.exist_queue(queue_name)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.cfg.get_scb_name(), queue_name));
  end

  // Check producer
  if(!this.cfg.exist_producer(producer)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Producer: %0s is not found", this.cfg.get_scb_name(), producer));
  end

  // Clone the item if not disabled
  // Clone the item in order to isolate the UVM scb from the rest of the TB
  if(this.cfg.get_disable_clone() == 1'b0) begin
    if(!$cast(item_clone, item.clone())) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: Unable to cast cloned item to uvm_sequence_item", this.cfg.get_scb_name()));
    end
  end else begin
    item_clone = item;
  end

  // Add the uvm_sequence_item to the queue for the given producer
  queue = this.cfg.get_queue(queue_name);

  if(queue == null) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: Queue: %s not found by add_item method", this.cfg.get_scb_name(), queue_name));
  end

  // Check that the max_queue_size for this queue is not reached
  if(this.cfg.get_max_queue_size(queue_name)>0 &&
     queue.get_size()==this.cfg.get_max_queue_size(queue_name)) begin
    `uvm_error("QUEUE_ERROR", $sformatf("[%s]: Maximum number of items (%0d) for queue: %s reached",
                                       this.cfg.get_scb_name(),
                                       this.cfg.get_max_queue_size(queue_name),
                                       queue_name))
  end

  if(!queue.add_item(producer, item_clone)) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: Unable to add item to queue: %s", this.cfg.get_scb_name(), queue_name));
  end

  `uvm_info("DEBUG", $sformatf("[%s]: Trigger compare by queue: %s, producer: %s", this.cfg.get_scb_name(), queue_name, producer), UVM_FULL);

  // Invoke the compare algorithm
  // Pass the last added item for compare optimization
  this.compare_trigger(queue_name, queue.get_last_inserted_item());

  if(this.cfg.get_full_scb_dump() == 1'b1                 &&
     this.cfg.get_full_scb_max_queue_size(queue_name) > 0 &&
     queue.shadow_items.size() == this.cfg.get_full_scb_max_queue_size(queue_name)) begin
    this.dump();
  end

  //Check if queue stats should be dumped
  if(this.cfg.get_queue_stat_interval(queue_name) > 0 && queue.get_cnt_add_item() % this.cfg.get_queue_stat_interval(queue_name) == 0) begin
    this.intermediate_queue_stat_dump(queue_name);
  end

  //And if full SCB stats should also be dumped
  if(this.cfg.get_scb_stat_interval() > 0 && this.get_total_cnt_add_items() % this.cfg.get_scb_stat_interval() == 0) begin
    `uvm_info("QUEUE_STAT", $sformatf("[%s] %0d items added to this scoreboard, intermediate statistics summary:%0s",
      this.get_name(),
      this.get_total_cnt_add_items(),
      this.create_report(1'b0)),
    UVM_LOW);
  end
endfunction: add_item

/// <b> Scoreboard API:</b> Add an item to the scoreboard, using a mutex to ensure than no more
/// than one item is ever added to the SCB at the same time.
/// For additional details on adding items to the SCB, see #add_item
/// \param queue_name The name of the queue the item should be added to
/// \param producer   The name of the producer that generated this item
/// \param item       The sequence item that should be added to the queue
task cl_syoscb::add_item_mutexed(string queue_name, string producer, uvm_sequence_item item);
  if(!this.cfg.get_mutexed_add_item_enable()) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Cannot add an item in mutexed fashion when mutexed_add_item_enable is 0", this.get_name()));
  end
  this.add_item_mutex.get();
  this.add_item(queue_name, producer, item);
  this.add_item_mutex.put();
endtask: add_item_mutexed


/// <b> Scoreboard API:</b> Invokes the scoreboard's compare strategy
function void cl_syoscb::compare_trigger(string queue_name = "", cl_syoscb_item item = null);
  this.compare_strategy.compare_trigger(queue_name, item);
endfunction: compare_trigger

/// <b> Scoreboard API:</b> Dump items to files if cl_syoscb_cfg#full_scb_dump is enabled
function void cl_syoscb::dump();
  case (this.cfg.get_full_scb_dump_type())
    pk_syoscb::TXT:
      this.dump_txt();
    pk_syoscb::XML:
      this.dump_xml();
    default: begin
      `uvm_fatal("DUMP_ERROR", $sformatf("Incorrect full_scb_type"));
    end
  endcase
endfunction: dump

/// <b>Scoreboard API:</b> Shorthand for flushing all queues
function void cl_syoscb::flush_queues_all();
  this.flush_queues();
endfunction: flush_queues_all

/// <b> Scoreboard API:</b> Flushes the contents of either all queues or a specific queue.
/// \param queue_name The name of the queue to flush. If "" is passed, flushes all queues
function void cl_syoscb::flush_queues(string queue_name = "");
   if(queue_name == "") begin
      foreach(this.queues[i]) begin
        this.queues[i].flush_queue();
      end
   end else begin
      cl_syoscb_queue_base queue;

      // Check queue
      if(!this.cfg.exist_queue(queue_name)) begin
        `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue: %0s is not found", this.cfg.get_scb_name(), queue_name));
      end else begin
        queue = this.cfg.get_queue(queue_name);
      end

      // Flush the requested queue
      queue.flush_queue();
   end
endfunction: flush_queues

/// Returns whether all queues or a specific queue is empty or not:
/// \param queue_name The queue that should be checked for emptiness. If "" is passed, checks all queues
/// \return 1 if the given queue (or all queues) are empty, 0 otherwise
function bit cl_syoscb::empty_queues(string queue_name = "");
  if(queue_name == "") begin
    bit empty_queues = 1'b1;

    foreach(this.queues[i]) begin
      empty_queues &= this.queues[i].empty();
    end

    return empty_queues;
  end else begin
    cl_syoscb_queue_base queue;

    // Check queue
    if(!this.cfg.exist_queue(queue_name)) begin
      `uvm_fatal("CFG_ERROR",
                 $sformatf("[%s]: Queue: %0s is not found", this.cfg.get_scb_name(), queue_name));
      return 0;
    end else begin
      queue = this.cfg.get_queue(queue_name);
    end

    return queue.empty();
  end
endfunction: empty_queues

/// Returns whether at least one element has been inserted in all queues or in a specific queue
/// \param queue_name The queue to check for insertions. If "" is passed, checks all queues
/// \return 1 if the given queue (or all queues) has had at least one insertion, 0 otherwise
function bit cl_syoscb::insert_queues(string queue_name = "");
  if(queue_name == "") begin
    bit insert_queues = 1'b1;

    foreach(this.queues[i]) begin
      insert_queues &= (this.queues[i].get_cnt_add_item() != 0) ? 1 : 0;
    end

    return insert_queues;
  end
  else begin
    cl_syoscb_queue_base queue;

    // Check if queue exists
    if(!this.cfg.exist_queue(queue_name)) begin
      `uvm_fatal("CFG_ERROR",
                 $sformatf("[%s]: Queue: %0s is not found", this.cfg.get_scb_name(), queue_name));
      return 0;
    end
    else begin
      queue = this.cfg.get_queue(queue_name);
    end

    return (queue.get_cnt_add_item() != 0) ? 1 : 0;
  end
endfunction: insert_queues

/// <b> Scoreboard API:</b> Toggles the scoreboard's comparison control.
/// \param cc Compare control bit. If 1, comparisons are enabled, if 0 they are disabled
function void cl_syoscb::compare_control(bit cc);
  this.compare_strategy.compare_control(cc);
endfunction: compare_control

/// Performs a factory override of the queue type to be used,
/// based on the value of the cl_syoscb_cfg#queue_type cfg. knob.
/// Once factory override has been performed, creates all queues in this scoreboard and forwards
/// the configuration object to them
function void cl_syoscb::override_queue_type();
  // Override the queue type as defined in the configuration and create them
  begin
    string queue_names[];

    // Get the list of queue names
    this.cfg.get_queues(queue_names);

    foreach(queue_names[i]) begin
      // Select queue type override type based on queue_type cfg member variable
      unique case (this.cfg.get_queue_type())
        pk_syoscb::SYOSCB_QUEUE_STD : begin
          cl_syoscb_queue_base::type_id::set_inst_override(cl_syoscb_queue_std::get_type(),
                                                           $sformatf("%s.%s",
                                                                     this.get_full_name(),
                                                                     queue_names[i]));
        end
        pk_syoscb::SYOSCB_QUEUE_MD5 : begin
          cl_syoscb_queue_base::type_id::set_inst_override(cl_syoscb_queue_hash_md5::get_type(),
                                                           $sformatf("%s.%s",
                                                                     this.get_full_name(),
                                                                     queue_names[i]));
        end
        pk_syoscb::SYOSCB_QUEUE_USER_DEFINED : begin
          `uvm_info("SCB",
                    $sformatf("queue_type for %s scb is set to USER_DEFINED. Inst overrides must be provided by user",
                              this.cfg.get_scb_name()), UVM_NONE)
        end
        default : begin
          `uvm_fatal("SCB", $sformatf("Error in overriding queue_type in %s cfg",
                                      this.cfg.get_scb_name()))
        end
      endcase

      this.queues[i] = cl_syoscb_queue_base::type_id::create(queue_names[i], this);
      this.cfg.set_queue(queue_names[i], this.queues[i]);

      // Forward the configuration to the queue
      uvm_config_db #(cl_syoscb_cfg)::set(this, queue_names[i], "cfg", this.cfg);
    end
  end
endfunction: override_queue_type

/// Performs a factory override of the compare type to be used,
/// based on the value of this scoreboard's cl_syoscb_cfg#compare_type
function void cl_syoscb::override_compare_type();
  unique case (this.cfg.get_compare_type())
    pk_syoscb::SYOSCB_COMPARE_IO : begin
      cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_io::get_type(),
                                           $sformatf("%0s.*", this.get_full_name()));
    end
    pk_syoscb::SYOSCB_COMPARE_IO2HP : begin
      cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_io_2hp::get_type(),
                                           $sformatf("%0s.*", this.get_full_name()));
    end
    pk_syoscb::SYOSCB_COMPARE_IOP : begin
      cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_iop::get_type(),
                                           $sformatf("%0s.*", this.get_full_name()));
    end
    pk_syoscb::SYOSCB_COMPARE_OOO : begin
      cl_syoscb_compare_base::type_id::set_inst_override(cl_syoscb_compare_ooo::get_type(),
                                           $sformatf("%0s.*", this.get_full_name()));
    end
    pk_syoscb::SYOSCB_COMPARE_USER_DEFINED : begin
      `uvm_info("SCB",
                $sformatf("compare_type for %s scb is set to USER_DEFINED. Inst overrides must be provided by user",
                          this.cfg.get_scb_name()), UVM_NONE)
    end
    default : begin
      `uvm_fatal("SCB", $sformatf("Error in overriding compare_type in %s cfg",
                                  this.cfg.get_scb_name()))
    end
  endcase
endfunction: override_compare_type

/// Validates that the current scoreboard configuration is not invalid.
/// If the configuration is invalid, raises a UVM_FATAL
/// If the configuration is not recommended but still valid, prints a UVM_INFO message
function void cl_syoscb::config_validation();
  // Validation involving MD5 queue
  if(this.cfg.get_queue_type() == pk_syoscb::SYOSCB_QUEUE_MD5) begin
    if(this.cfg.get_compare_type() inside {pk_syoscb::SYOSCB_COMPARE_IO,
                                           pk_syoscb::SYOSCB_COMPARE_IOP,
                                           pk_syoscb::SYOSCB_COMPARE_IO2HP}) begin
      if(this.cfg.get_ordered_next() == 1'b0) begin
        `uvm_fatal("CFG_VALIDATION",
                   $sformatf("[%0s]: The 'in-order' compares are not allowed to be used when ordered next is 0",
                             this.cfg.get_scb_name()))
      end
      else begin
        `uvm_info("CFG_VALIDATION",
                  $sformatf("[%0s]: The use of MD5 with 'in-order' compares and ordered_next = 1 works. However, std queue is reccomended if using 'in-order' compares.",
                            this.cfg.get_scb_name()), UVM_LOW)

      end
    end
  end

  // Validation involving compare IO-2HP: this compare works with 2 queues only.
  if(this.cfg.get_compare_type() == pk_syoscb::SYOSCB_COMPARE_IO2HP) begin
    string l_scb_names[];
    this.cfg.get_queues(l_scb_names);

    if(l_scb_names.size() != 2) begin
      `uvm_fatal("CFG_VALIDATION",
                 $sformatf("[%s]: The compare io-2hp only works with 2 queues. %0d secondary queues defined instead",
                           this.cfg.get_scb_name(), l_scb_names.size()));
    end
  end
endfunction: config_validation


/// <b>Scoreboard API</b>: Creates a report containing information about this scoreboard.
/// The report contains information about the number of insertions, matches, flushed items and orphaned items.
/// \param end_of_sim A bit to indicate whether this function is called at the end of simulation or not.
///                   This changes the name used to refer to items remaining
///                   in the queue when the function is called (orphans vs. remaining)
/// \return That report
function string cl_syoscb::create_report(bit end_of_sim = 1'b1);
  int unsigned offset = 2;
  int unsigned first_column_width;
  string stats_str;

  // Enforce first column to be minimum 8 or the max of queue name and producer name+global_report_indention
  // as producers are printed with global_report_indention indention
  first_column_width = min_width(max(this.cfg.get_max_length_queue_name(), pk_syoscb::GLOBAL_REPORT_INDENTION+this.cfg.get_max_length_producer()));

  if(end_of_sim) begin
    stats_str = cl_syoscb_string_library::scb_header_str("Name", offset+first_column_width, 1'b1); //Header
  end else begin
    stats_str = cl_syoscb_string_library::scb_header_str("Name", offset+first_column_width, 1'b1 ,
                                      .col_names('{"  Inserts ", "  Matches ", "  Flushed ", "   Remain "})); //Header row
  end
  stats_str = { stats_str, this.create_report_contents(offset, first_column_width) }; //Data
  stats_str = { stats_str, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) }; //Final separator

  return stats_str;
endfunction: create_report


/// <b>Scoreboard API</b>: Returns a table line summarising the insert/match/flush/orphan stats over all queues in the SCB.
/// \param offset The x-offset to used when printing items in the first column of the table
/// \param first_column_width The width of the first column of the table
// Scoreboard name | Inserts | Matches | Flushed | Orphans
function string cl_syoscb::create_total_stats(int unsigned offset, int unsigned first_column_width);
  string       total_stats;
  int unsigned total_cnt_add_item;
  int unsigned total_cnt_flushed_item;
  int unsigned total_queue_size;
  string       name;

  total_cnt_add_item     = this.get_total_cnt_add_items();
  total_cnt_flushed_item = this.get_total_cnt_flushed_items();
  total_queue_size       = this.get_total_queue_size();

  if(!this.cfg.get_disable_report()) begin
    name = "Total";
  end else begin
    name = this.cfg.get_scb_name();
  end

  total_stats = { "\n",
      $sformatf("%s%s | %8d | %8d | %8d | %8d |",
                cl_syoscb_string_library::pad_str("", offset),
                cl_syoscb_string_library::pad_str(name, first_column_width, " ", 1'b1),
                total_cnt_add_item,
                total_cnt_add_item-(total_cnt_flushed_item+total_queue_size),
                total_cnt_flushed_item,
                total_queue_size)};

  return total_stats;
endfunction: create_total_stats

/// <b>Scoreboard API</b>: Returns a string with all queue's statistics, to be inserted into the final report generated by #create_report.
/// \param offset The x-offset to used when printing items in the first column of the table
/// \param first_column_width The width of the first column of the table
function string cl_syoscb::create_report_contents(int unsigned offset, int unsigned first_column_width);
  string stats_str;

  stats_str = { stats_str, this.create_queues_stats(offset, first_column_width) };

  // Add separator and totals if not wrapped by cl_syoscbs
  if(!this.cfg.get_disable_report()) begin
    stats_str = { stats_str, this.create_total_stats(offset, first_column_width) };
  end

  return stats_str;
endfunction: create_report_contents

/// <b>Scoreboard API:</b> Returns the number of elements that have been inserted into the scoreboard
function int unsigned cl_syoscb::get_total_cnt_add_items();
  string       queue_names[];
  int unsigned total_cnt_add_item;

  this.cfg.get_queues(queue_names);

  foreach (queue_names[i]) begin
    cl_syoscb_queue_base queue;

    queue = this.cfg.get_queue(queue_names[i]);
    total_cnt_add_item += queue.get_cnt_add_item();
  end

  return total_cnt_add_item;
endfunction: get_total_cnt_add_items

/// <b>Scoreboard API: </b> Returns the number of elements that have been flushed out of the scoreboard
function int unsigned cl_syoscb::get_total_cnt_flushed_items();
  string       queue_names[];
  int unsigned total_cnt_flushed_item;

  this.cfg.get_queues(queue_names);

  foreach (queue_names[i]) begin
    cl_syoscb_queue_base queue;

    queue = this.cfg.get_queue(queue_names[i]);
    total_cnt_flushed_item += queue.get_cnt_flushed_item();
  end

  return total_cnt_flushed_item;
endfunction: get_total_cnt_flushed_items

/// <b>Scoreboard API:</b> Returns the number of elements that the scoreboard currently contains
function int unsigned cl_syoscb::get_total_queue_size();
  string       queue_names[];
  int unsigned total_queue_size;

  this.cfg.get_queues(queue_names);

  foreach (queue_names[i]) begin
    cl_syoscb_queue_base queue;

    queue = this.cfg.get_queue(queue_names[i]);
    total_queue_size += queue.get_size();
  end

  return total_queue_size;
endfunction: get_total_queue_size

/// Returns a string with information on which checks the different queues
/// have failed (e.g. not empty at end of sim, no insertions).
/// If they are not empty it also shows the number of orphans.
function string cl_syoscb::get_queue_failed_checks();
  string failed_checks;

  foreach(this.queues[i]) begin
    failed_checks = { failed_checks, this.queues[i].get_failed_checks()};
  end

  return failed_checks;
endfunction: get_queue_failed_checks

/// <b>Scoreboard API:</b> Returns a string with information on which checks the scoreboard
/// has failed (e.g. any queues non-empty, any queues with no insertions)
/// This report also contains the per-queue information generated
/// by #get_queue_failed_checks
function string cl_syoscb::get_failed_checks();
  if(this.failed_checks.size() == 0) begin
    return "";
  end else begin
    string failed_checks_str;

    // SCB errors
    foreach(this.failed_checks[str]) begin
      failed_checks_str = { failed_checks_str, "  ", str, ": ", this.failed_checks[str], "\n"};
    end

    // Queue errors
    failed_checks_str = { failed_checks_str, this.get_queue_failed_checks() };

    return failed_checks_str;
  end
endfunction: get_failed_checks


/// Returns a table with per-queue statistics for all queues of the scoreboard
/// \param offset The x-offset to used when printing items in the first column of the table
/// \param first_column_width The width of the first column of the table
function string cl_syoscb::create_queues_stats(int unsigned offset, int unsigned first_column_width);
  // Queue name | Inserts | Matches | Flushed | Orphans
    string               queue_names[];
    cl_syoscb_queue_base queue;
    string               queue_stats;

    this.cfg.get_queues(queue_names);

    foreach (queue_names[i]) begin
      queue = this.cfg.get_queue(queue_names[i]);
      queue_stats = {queue_stats, queue.create_queue_report(offset, first_column_width)} ;
      if(!this.cfg.get_disable_report() && i == queue_names.size()-1) begin
        queue_stats = { queue_stats, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) };
      end
    end

    return queue_stats;
  endfunction: create_queues_stats

/// <b>Scoreboard API:</b> Returns a UVM subscriber for a given combination of queue and producer.
/// The returned UVM subscriber can then be connected to a UVM monitor or similar
/// which produces transactions which should be scoreboarded.
/// \param queue_name The name of the queue that items should be added to
/// \param producer The name of the producer that should add items to the queue
/// \return A handle to a uvm_subscriber that will insert items into the given queue with that producer's name
function cl_syoscb_subscriber cl_syoscb::get_subscriber(string queue_name, string producer);
  if(this.subscribers.exists({queue_name, producer})) begin
    return this.subscribers[{queue_name, producer}];
  end else begin
    `uvm_fatal("SUBSCRIBER_ERROR",
               $sformatf("[%s]: Unable to get subscriber for queue: %s and producer: %s",
                         this.cfg.get_scb_name(), queue_name, producer));
    return null;
  end
endfunction: get_subscriber

/// Dumps the shadow queue into text files.
/// Will either dump shadow items into one or more files depending on cl_syoscb_cfg#full_scb_dump_split
function void cl_syoscb::dump_txt();
  if (this.cfg.get_full_scb_dump_split() == 1'b1) begin
    this.dump_split_txt();
  end else begin
    this.dump_join_txt();
  end
endfunction: dump_txt

/// Dump the shadow queue into XML files.
/// Will either dump shadow items into one or more files depending on cl_syoscb_cfg#full_scb_dump_split
function void cl_syoscb::dump_xml();
  if (this.cfg.get_full_scb_dump_split() == 1'b1) begin
    this.dump_split_xml();
  end else begin
    this.dump_join_xml();
  end
endfunction: dump_xml

/// Dumps the shadow queue into separate text files for each queue.
/// The text files are named  [scoreboard_name].[queue_name].[full_scb_dump_file_name].txt
function void cl_syoscb::dump_split_txt();
  int fd;
  string fname;
  string queue_names[];
  string name;
  string aa_name;

  this.cfg.get_queues(queue_names);

  foreach (this.queues[i]) begin
    aa_name = {this.get_name(), ".", queue_names[i]};

    name = cl_syoscb_string_library::pad_str(queue_names[i], 40, " ", 1'b1);

    fname = {this.get_name(), ".", queue_names[i], ".", this.cfg.get_full_scb_dump_file_name(), ".txt"};

    if(!this.header_dumped.exists(aa_name)) begin
        this.header_dumped[aa_name] = 1'b0;
    end

    if(this.header_dumped[aa_name] == 1'b0) begin
      fd = $fopen (fname, "w");
    end else begin
      fd = $fopen (fname, "a");
    end

    if(fd) begin
      if(this.header_dumped[aa_name] == 1'b0) begin
        $fwrite (fd, this.print_header(name));
        this.header_dumped[aa_name] = 1'b1;
      end
      this.queues[i].dump(null, fd);
      $fclose(fd);
    end else begin
      `uvm_fatal("FILE_ERROR", $sformatf("The file %s could not be opened",fname));
    end
  end
endfunction: dump_split_txt

/// Dumps the shadow queue into one combined text file called
/// [scoreboard_name].[full_scb_dump_file_name].txt
function void cl_syoscb::dump_join_txt();
  int fd;
  string fname;
  string queue_names[];
  string name;

  fname = {this.get_name(), ".", this.cfg.get_full_scb_dump_file_name(), ".txt"};

  this.cfg.get_queues(queue_names);

  fd = $fopen (fname, "w");

  if(fd) begin
    foreach (this.queues[i]) begin
      name = cl_syoscb_string_library::pad_str(queue_names[i], 40, " ", 1'b1);
      $fwrite (fd, this.print_header(name));
      this.queues[i].dump(null, fd);
    end
  end else begin
    `uvm_fatal("FILE_ERROR", $sformatf("The file %s could not be opened",fname));
  end
  $fclose(fd);
endfunction: dump_join_txt

/// Dumps the shadow queue into separate XML files for each queue.
/// The files are named  [scoreboard_name].[queue_name].[full_scb_dump_file_name].xml
function void cl_syoscb::dump_split_xml();
  int fd;
  string fname;
  string queue_names[];
  string name;
  string aa_name;

  this.cfg.get_queues(queue_names);

  foreach (this.queues[i]) begin
    aa_name = {this.get_name(), ".", queue_names[i]};

    name = cl_syoscb_string_library::pad_str(queue_names[i], 40, " ", 1'b1);

    fname = {this.get_name(), ".", queue_names[i], ".", this.cfg.get_full_scb_dump_file_name(), ".xml"};

    if(!this.header_dumped.exists(aa_name)) begin
        this.header_dumped[aa_name] = 1'b0;
    end

    if(this.header_dumped[aa_name] == 1'b0) begin
      fd = $fopen (fname, "w");
    end else begin
      fd = $fopen (fname, "a");
    end

    if(fd) begin
      if(this.header_dumped[aa_name] == 1'b0) begin
        $fwrite (fd, "<?xml version='1.0' encoding='UTF-8'?>\n");
        $fwrite (fd, $sformatf("<scb name='%s'>\n", this.get_name()));
        $fwrite (fd, "<queues>\n");
        $fwrite (fd, this.print_header(name));
        this.header_dumped[aa_name] = 1'b1;
        $fwrite (fd, $sformatf("<queue name='%s'>\n", queue_names[i]));
        $fwrite (fd, "<items>\n");
      end
      this.queues[i].dump(null, fd);
      $fwrite (fd, "</items>\n");
      $fwrite (fd, "</queue>\n");
      $fwrite (fd, "</queues>\n");
      $fwrite (fd, "</scb>");
      $fclose (fd);
    end else begin
      `uvm_fatal("FILE_ERROR", $sformatf("The file %s could not be opened",fname));
    end
  end
endfunction: dump_split_xml

/// Dumps the shadow queue into one combined XML file called
/// [scoreboard_name].[full_scb_dump_file_name].xml
function void cl_syoscb::dump_join_xml();
  int fd;
  string fname;
  string queue_names[];
  string name;
  string xsd_fname;

  fname = {this.get_name(), ".", this.cfg.get_full_scb_dump_file_name(), ".xml"};

  this.cfg.get_queues(queue_names);

  fd = $fopen (fname, "w");

  if(fd) begin
    $fwrite (fd, $sformatf("<?xml version='1.0' encoding='UTF-8'?>\n<scb name='%s'>\n", this.get_name()));
    $fwrite (fd, "<queues>\n");

    foreach (this.queues[i]) begin
      $fwrite (fd, $sformatf("<queue name='%s'>\n", queue_names[i]));
      $fwrite (fd, "<items>\n");
      this.queues[i].dump(null, fd);
      $fwrite (fd, "</items>\n");
      $fwrite (fd, "</queue>\n");
    end

    $fwrite (fd, "</queues>\n");
    $fwrite (fd, "</scb>");
    $fclose(fd);
  end else begin
    `uvm_fatal("FILE_ERROR", $sformatf("The file %s could not be opened",fname));
  end
endfunction: dump_join_xml


/// Prints the current queue statistics for a queue.
/// This can be used to get queue statistics throughout simulation.
/// \param queue_name The name of the queue to dump statistics for.
function void cl_syoscb::intermediate_queue_stat_dump(string queue_name);
  int unsigned first_column_width;
  string stats_str;
  int unsigned offset = 2;
  cl_syoscb_queue_base queue;

  if(!this.cfg.exist_queue(queue_name)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Queue %0s was not found", this.cfg.get_scb_name(), queue_name))
  end
  queue = this.cfg.get_queue(queue_name);

  first_column_width = min_width(max(this.cfg.get_max_length_queue_name(), pk_syoscb::GLOBAL_REPORT_INDENTION+this.cfg.get_max_length_producer()));
  stats_str = cl_syoscb_string_library::scb_header_str("Name", offset+first_column_width, 1'b1 ,
                                    .col_names('{"  Inserts ", "  Matches ", "  Flushed ", "   Remain "})); //Header row
  stats_str = { stats_str, queue.create_queue_report(offset, first_column_width) }; //Data
  stats_str = { stats_str, cl_syoscb_string_library::scb_separator_str(offset+first_column_width+1) }; //Final separator str

  `uvm_info("QUEUE_STAT", $sformatf("[%s] %0d items added to %s, intermediate statistics summary:%s",
    this.get_name(),
    queue.get_cnt_add_item(),
    queue_name,
    stats_str),
  UVM_LOW)
endfunction: intermediate_queue_stat_dump

/// UVM pre_abort hook. Ensures that all shadow items are dumped if a
/// UVM_ERROR is about to stop simulation
function void cl_syoscb::pre_abort();
  if(this.cfg.get_full_scb_dump()) begin
    this.dump();
  end
endfunction: pre_abort

/// Gets a header string to print into a shadow queue dump file
/// \param queue_name The header for that queue
function string cl_syoscb::print_header(string queue_name);
  case (this.cfg.get_full_scb_dump_type())
    pk_syoscb::TXT:
      return $sformatf({"/////////////////////////////////////////////////////\n",
                        "// Queue: %s //\n",
                        "/////////////////////////////////////////////////////\n"},queue_name);
    pk_syoscb::XML:
      return $sformatf({"<!--/////////////////////////////////////////////////\n",
                        "// Queue: %s //\n",
                        "//////////////////////////////////////////////////-->\n"},queue_name);
  endcase
endfunction: print_header
