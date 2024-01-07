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
/// Base class for all compare algorithms. The chosen compare algorithm defines how
/// matches are found. For more information on the comparison algorithms included with the SyoSil
/// UVM Scoreboard, see \ref pCompareImplementationNotes.
class cl_syoscb_compare_base extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration object
  protected cl_syoscb_cfg                 cfg;
  /// Indicates how queues should be split into a primary queue and array of secondary queues.
  /// This is done once with a static primary queue, done every time compare is invoked with a dynamic
  /// primary queue
  protected bit                           do_split        = 1'b1;
  /// Indicates whether a comparison can be started (1) or not (0)
  protected bit                           go              = 1'b1;
  /// If set to 1'b1, no comparisons are performed. If 1'b0, comparisons are executed
  protected bit                           disable_compare = 1'b0;
  /// Name of primary queue
  protected string                        primary_queue_name;
  /// Handle to primary queue
  protected cl_syoscb_queue_base          primary_queue;
  /// Names of secondary queues
  protected string                        secondary_queue_names[];
  /// Handles to secondary queues
  protected cl_syoscb_queue_base          secondary_queues[];
  /// Associative array used to indicate if a matching item was found in a secondary queue.
  /// If matches are found in all secondary queues, all items are removed from their respective queues
  protected cl_syoscb_proxy_item_base     secondary_item_found[string];
  /// Proxy item for the item being searched for in all secondary queue
  protected cl_syoscb_proxy_item_base     primary_item_proxy;
  /// Iterator into primary queue
  protected cl_syoscb_queue_iterator_base primary_queue_iter;
  /// Name of the queue currently being searched
  protected string                        current_queue_name;
  /// Handle to the item passed in by cl_syoscb#add_item
  protected cl_syoscb_item                current_item;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_compare_base)
    `uvm_field_object(cfg,                            UVM_DEFAULT| UVM_REFERENCE)
    `uvm_field_int(do_split,                          UVM_DEFAULT)
    `uvm_field_int(go,                                UVM_DEFAULT)
    `uvm_field_int(disable_compare,                   UVM_DEFAULT)
    `uvm_field_string(primary_queue_name,             UVM_DEFAULT)
    `uvm_field_object(primary_queue,                  UVM_DEFAULT)
    `uvm_field_array_string(secondary_queue_names,    UVM_DEFAULT)
    `uvm_field_aa_object_string(secondary_item_found, UVM_DEFAULT)
    `uvm_field_object(primary_item_proxy,             UVM_DEFAULT)
    `uvm_field_object(primary_queue_iter,             UVM_DEFAULT)
    `uvm_field_string(current_queue_name,             UVM_DEFAULT)
    `uvm_field_object(current_item,                   UVM_DEFAULT)
   `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_base");

  //-------------------------------------
  // Compare API
  //-------------------------------------
  extern virtual function void          compare_control(bit cc);
  extern virtual function void          compare_trigger(string queue_name = "",
                                                        cl_syoscb_item item = null);
  extern virtual function void          compare_main(t_scb_compare_greed greed);

  //-------------------------------------
  // Compare Strategy API
  //-------------------------------------
  extern protected virtual function void          init();
  extern protected virtual function void          compare_do_greed(t_scb_compare_greed greed);
  extern protected virtual function void          compare_init();
  extern protected virtual function void          compare_do();
  extern protected virtual function string        get_primary_queue_name();
  extern protected virtual function void          split_queues();
  extern protected virtual function void          check_queues();
  extern protected virtual function void          count_producers(string producer = "");
  extern protected virtual function void          create_primary_iterator();
  extern protected virtual function void          primary_loop_init();
  extern protected virtual function void          primary_loop_do();
  extern protected virtual function void          secondary_loop_do();
  extern protected virtual function void          static_queue_split_do();
  extern protected virtual function void          dynamic_queue_split_do();
  extern protected virtual function bit           delete();
  extern protected virtual function string        get_count_producer();
  extern protected virtual function int unsigned  get_queues_item_cnt();


  //-------------------------------------
  // Local misc methods
  //-------------------------------------
  extern virtual function void          set_cfg(cl_syoscb_cfg cfg);
  extern virtual function cl_syoscb_cfg get_cfg();
  extern virtual function string        generate_miscmp_table(cl_syoscb_item primary_item,
                                                              cl_syoscb_item secondary_item,
                                                              string sec_queue_name,
                                                              uvm_comparer comparer,
                                                              string cmp_name);
  extern local virtual function int     num_uvm_errors();
  extern virtual function void          do_copy(uvm_object rhs);
  extern virtual function void          do_print(uvm_printer printer);
  extern virtual function bit           do_compare(uvm_object rhs,
                                                   uvm_comparer comparer);
endclass: cl_syoscb_compare_base

function cl_syoscb_compare_base::new(string name = "cl_syoscb_compare_base");
   super.new(name);
endfunction: new

/// <b>Compare API</b>: Toggle comparisons on or off
/// \param cc compare control bit. If 1, comparisons are enabled, if 0, comparisons are disabled
function void cl_syoscb_compare_base::compare_control(bit cc);
  this.disable_compare = !cc;
endfunction: compare_control

/// <b>Compare API</b>: Starts a comparison by calling #compare_main if comparisons are not disabled.
/// \param queue_name Name of the queue which had an item inserted into it
/// \param item The scoreboard wrapper item that was inserted into the SCB
function void cl_syoscb_compare_base::compare_trigger(string queue_name = "",
                                                      cl_syoscb_item item = null);
  if(this.disable_compare == 1'b0) begin
    if(item == null) begin
      `uvm_fatal("COMPARE_ERROR", $sformatf("[%s]: The in-order by producer requires to know the current inserted item", this.cfg.get_scb_name()));
    end

    this.current_queue_name = queue_name;
    this.current_item = item;

    this.compare_main(this.cfg.get_trigger_greediness());
  end
endfunction: compare_trigger

/// <b>Compare API</b>: Main function that contains all the actual compare
/// operations requested by the compare algorithm.
/// It cares about:
///  -# Splitting queues into primary and secondary queues, generating an interator into the primary queue
///  -# Calling #compare_do_greed with the proper draining value passed as argument
///  -# Deleting the primary queue iterator after the compare algo has finished all comparisons
/// \param greed The greed level to use when performing comparisons. See cl_syoscb_cfg#trigger_greediness
function void cl_syoscb_compare_base::compare_main(t_scb_compare_greed greed);
  this.init();

  this.compare_do_greed(greed);
endfunction: compare_main

/// <b>Compare Strategy API</b>: Executes some preliminary common operations before starting comparisons:
///  -# Split queues into primary and secondary
///  -# Create iterator for the chosen primary queue
function void cl_syoscb_compare_base::init();
  if(this.do_split == 1'b1) begin
    this.split_queues();
  end

  this.create_primary_iterator();
endfunction: init

/// <b>Compare Strategy API</b>: Try to remove a match and drain all the potential remaining matches inside the
/// queues according to the greed level given as argument. Performs the following:
///  -# Calling the checkers in order to verify that starting a comparison makes sense
///  -# Calling the actual #compare_do function if a comparison should be starte
///  -# Looping to remove additional matches if the greed levels prescribes this
/// \param greed The greed level to use when performing comparisons. See cl_syoscb_cfg#trigger_greediness
function void cl_syoscb_compare_base::compare_do_greed(t_scb_compare_greed greed);
  int unsigned item_before_compare = 0;

  // Check if the conditions for starting a compare are met inside compare_init, and
  // resolve the potential other matches inside the queue depending on the while condition below
  do begin
    item_before_compare = this.get_queues_item_cnt();
    this.compare_init();

    if(this.go == 1'b1) begin
      int unsigned nbr_errors;

      nbr_errors = this.num_uvm_errors();

      this.compare_do();

      if(this.cfg.get_disable_compare_after_error() && (this.num_uvm_errors()>nbr_errors)) begin
        `uvm_info("DEBUG", $sformatf("[%s]: Disabling compare as error is detected and disable compare after error is enabled", this.cfg.get_scb_name()), UVM_FULL);
        this.disable_compare = 1'b1;
      end
    end
  end
  while( greed == pk_syoscb::SYOSCB_COMPARE_GREEDY &&
        (item_before_compare - this.get_queues_item_cnt()) ==  (this.secondary_queues.size()+1));
endfunction: compare_do_greed

/// <b>Compare Strategy API</b>: Verifies if the conditions for starting a compare are met:
/// -# Verify that all queues currently contain at least one element
/// -# Verify that all queues have at least one element from the same producer as the producer
///    returned by #get_count_producer() (the primary item being searched for)
/// If the conditions are met then go variable is triggered, and the compare process can start.
function void cl_syoscb_compare_base::compare_init();
  this.check_queues();

  this.count_producers();
endfunction: compare_init

/// <b>Compare Strategy API</b>: Starts the actual comparison operation
/// -# Perform initialization on the primary queue, if necessary
/// -# Start the primary queue loop
function void cl_syoscb_compare_base::compare_do();
  this.primary_loop_init();

  this.primary_loop_do();
endfunction: compare_do

/// <b>Compare Strategy API</b>: Gets the name of this scoreboard's primary queue.
/// Convenience method wrapping cl_syoscb_cfg#get_primary_queue
function string cl_syoscb_compare_base::get_primary_queue_name();
  return this.cfg.get_primary_queue();
endfunction: get_primary_queue_name

/// <b>Compare Strategy API</b>: Splits the scoreboard's queues into 1 primary queue and N-1 secondary queues.
/// Selects the primary queue and creates an array of secondary queues with the rest.
/// If a dynamic primary queue is used, this split is performed every time a comparison is started.
/// If a static primary queue is used, this split is only performed on the first comparison.
function void cl_syoscb_compare_base::split_queues();
  if(!this.cfg.dynamic_primary_queue()) begin
    // In case of static primary, the split can be done only once.
    this.do_split = 1'b0;
    this.static_queue_split_do();
  end else begin
    this.do_split = 1'b1;
    this.dynamic_queue_split_do();
  end

  if(this.secondary_queues.size() == 0 ||
     this.secondary_queue_names.size() == 0) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: No secondary queues found", this.cfg.get_scb_name()));
  end

  foreach(this.secondary_queues[i]) begin
    if(this.secondary_queues[i] == null) begin
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: Unable to retrieve secondary queue handle", this.cfg.get_scb_name()));
    end

    `uvm_info("DEBUG", $sformatf("[%s]: Secondary queue: %s found", this.cfg.get_scb_name(), this.secondary_queue_names[i]), UVM_FULL);
  end

endfunction: split_queues

/// <b>Compare Strategy API</b>: Check if any queue is empty.
/// Assigns 0 to the member variable #go when any of the queues are empty,
/// indicating that a comparison cannot be started. Assigns 1 if all queues are non-empty,
/// indicating that the comparison may be started.
function void cl_syoscb_compare_base::check_queues();
  if(this.primary_queue.empty() == 1'b0) begin
    cl_syoscb_queue_base empties[$];

    // Search in this.secondary_queues and stores in empties all those who are empty.
    empties = this.secondary_queues.find(x) with (x.empty() == 1'b1);

    // If i have an empty secondary queue, i cannot start the compare
    this.go = (empties.size()>0) ?  1'b0 : 1'b1;
  end else begin
    this.go = 1'b0;
  end
endfunction: check_queues

/// <b>Compare Strategy API</b>: Checks if the producer of the current item exists in all other queues,
/// and whether all other queues have at least 1 item from that producer.
/// If true, assigns 1'b1 to member variable #go
/// If false, assigns 1'b0 to member variable #go
///
/// \param producer The producer to check if exists in all other queues. If not set, checks if the
///                 producer of #current_item exists in other queues. If set, checks for that producer in other queues.
function void cl_syoscb_compare_base::count_producers(string producer = "");
  string prod;
  if(this.go == 1'b1) begin
    cl_syoscb_queue_base producers[$];
    if(producer == "") begin
      //Empty string => check for current_item.producer
      prod = this.get_count_producer();
    end else begin
      //Nonempty string => check based on producer parameter.
      //No need to check validity of producer name. If illegal name, no comparison will be run and go will be set to 1'b0
      prod = producer;
    end

    producers = this.secondary_queues.find(x) with (x.exists_cnt_producer(prod) == 1'b1);

    this.go = (this.primary_queue.exists_cnt_producer(prod) &&
          producers.size() == this.secondary_queues.size()) ? 1'b1 : 1'b0;

    if(this.go == 1'b1) begin
      cl_syoscb_queue_base cnt_producers[$];

      cnt_producers = this.secondary_queues.find(x) with (x.get_cnt_producer(prod) > 0);

      this.go = ((this.primary_queue.get_cnt_producer(prod)>0) &&
            (cnt_producers.size() == this.secondary_queues.size())) ? 1'b1 : 1'b0;
    end
  end
endfunction: count_producers

/// <b>Compare Strategy API</b>: Deletes matched items from the primary and all secondary queues if a match was found.
/// If no match is found, no items are deleted from the queues.
/// \return 1'b1 if a match was found and items were deleted, 1'b0 otherwise
function bit cl_syoscb_compare_base::delete();
  // Only start to remove items if all slave items are found (One from each slave queue)
  if(this.secondary_item_found.size() == this.secondary_queue_names.size()) begin
    `uvm_info("DEBUG", $sformatf("[%s]: cmp: Found match for primary queue item :\n%s", this.cfg.get_scb_name(), cl_syoscb_string_library::sprint_item(this.primary_queue.get_item(this.primary_item_proxy), this.cfg)), UVM_FULL);

    // Remove from primary
    if(!this.primary_queue.delete_item(this.primary_item_proxy)) begin
      `uvm_error("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to delete item from queue %s",
                                          this.cfg.get_scb_name(),this.primary_queue_name));
    end

    // Remove from all secondaries
    foreach(this.secondary_queue_names[i]) begin
      if(this.secondary_queues[i] == null) begin
        `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to retrieve secondary queue handle", this.cfg.get_scb_name()));
      end

      if(!this.secondary_queues[i].delete_item(this.secondary_item_found[this.secondary_queue_names[i]])) begin
        `uvm_error("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to delete item from queue %s",
                                            this.cfg.get_scb_name(), this.secondary_queue_names[i]));
      end
    end
    return 1'b1;
  end
  return 1'b0;
endfunction: delete

/// <b>Compare Strategy API</b>: Returns the name of the producer that the compare method should evaluate in
/// order to verify if it makes sense to start a comparison.
/// \note This function needs to be overridden by the derived compare methods in order to
///       change the behaviour accordingly to the requested needs. By default, the function returns the
///       producer of #current_item.
/// \return The name producer which should be evaluated
function string cl_syoscb_compare_base::get_count_producer();
  return this.current_item.get_producer();
endfunction: get_count_producer

/// <b>Compare Strategy API</b>: Gets the total number of items in all the queues at the
/// moment of the function call.
/// \return Number of items currently stored in all queues
function int unsigned cl_syoscb_compare_base::get_queues_item_cnt();
  int unsigned item_count = 0;
  string l_queue_names[];
  cl_syoscb_queue_base l_queue;

  this.cfg.get_queues(l_queue_names);

  foreach(l_queue_names[i]) begin
    l_queue = this.cfg.get_queue(l_queue_names[i]);

    item_count = item_count + l_queue.get_size();
  end
  return item_count;
endfunction: get_queues_item_cnt

/// <b>Compare Strategy API</b>: Loop over the primary queue, selecting primary items
/// to compare against items in the secondary queues.
/// \note Abstract method. This method must be implemented in a subclass.
function void cl_syoscb_compare_base::primary_loop_do();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_compare_base::primary_loop_do() *MUST* be overwritten", this.cfg.get_scb_name()));
endfunction

/// <b>Compare Strategy API</b>: Loop over all secondary queues to find a match for the primary item.
/// \note Abstract method. This method must be implemented in a subclass.
function void cl_syoscb_compare_base::secondary_loop_do();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_compare_base::secondary_loop_do() *MUST* be overwritten", this.cfg.get_scb_name()));
endfunction

/// <b>Compare Strategy API</b>: Splits queues into primary and secondary when a primary queue has been specified.
/// The primary queue is the one set by cl_syoscb_cfg#set_primary_queue_name, all other queues
/// will be secondary queues
function void cl_syoscb_compare_base::static_queue_split_do();
  string               queue_names[];
  int                  first = 1;
  cl_syoscb_queue_base queue_first;

  // Initialize state variables
  this.cfg.get_queues(queue_names);
  this.primary_queue_name = this.get_primary_queue_name();
  this.primary_queue = this.cfg.get_queue(this.primary_queue_name);
  if(this.primary_queue == null) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to retrieve primary queue handle", this.cfg.get_scb_name()));
  end
  foreach(queue_names[i]) begin
    if(queue_names[i] != this.get_primary_queue_name()) begin
      this.secondary_queue_names = new[this.secondary_queue_names.size()+1](this.secondary_queue_names);
      this.secondary_queue_names[this.secondary_queue_names.size()-1] = queue_names[i];
      this.secondary_queues = new[this.secondary_queues.size()+1](this.secondary_queues);
      this.secondary_queues[this.secondary_queues.size()-1] = this.cfg.get_queue(queue_names[i]);
    end
  end
endfunction

/// <b>Compare Strategy API</b>: Splits queues into primary and secondary when a primary queue has not been specified.
/// Selects as the primary queue the shortest queue, the rest are the secondary queues.
function void cl_syoscb_compare_base::dynamic_queue_split_do();
  string               queue_names[];
  int                  first = 1;
  cl_syoscb_queue_base queue_first;

  // Initialize state variables
  this.cfg.get_queues(queue_names);

  foreach(queue_names[i]) begin
    if(first) begin
      this.primary_queue = this.cfg.get_queue(queue_names[i]);
      this.primary_queue_name = queue_names[i];
      if(this.primary_queue == null) begin
        `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to retrieve primary queue handle", this.cfg.get_scb_name()));
      end
      this.secondary_queue_names.delete;
      this.secondary_queues.delete;
      first = 0;
    end else begin
      queue_first = this.cfg.get_queue(queue_names[i]);
      if(queue_first == null) begin
        `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp: Unable to retrieve primary queue handle", this.cfg.get_scb_name()));
      end

      this.secondary_queue_names = new[this.secondary_queue_names.size()+1](this.secondary_queue_names);
      this.secondary_queues = new[this.secondary_queues.size()+1](this.secondary_queues);

      if(queue_first.get_size() < this.primary_queue.get_size()) begin
        this.secondary_queue_names[this.secondary_queue_names.size()-1] = primary_queue_name;
        this.secondary_queues[this.secondary_queues.size()-1] = primary_queue;
        this.primary_queue = queue_first;
        this.primary_queue_name = queue_names[i];
      end else begin
        this.secondary_queue_names[this.secondary_queue_names.size()-1] = queue_names[i];
        this.secondary_queues[this.secondary_queues.size()-1] = queue_first;
      end
    end
  end
endfunction

/// <b>Compare Strategy API</b>: Creates the iterator for the primary queue and sets the pointer to its first element
function void cl_syoscb_compare_base::create_primary_iterator();
  //If iterator already exists, we have run at least one compare, so all queues
  //should have a "default" iterator. If using dynamic primary, the primary may change,
  //so we also have to reassign the primary queue iterator on every comparison
  this.primary_queue_iter = this.primary_queue.get_iterator("default");

  //If no iterator with that name exists, we are either running first comparison
  //or it was deleted. Create the iterator in that case
  if(this.primary_queue_iter == null) begin
    this.primary_queue_iter = this.primary_queue.create_iterator("default");
  end

  `uvm_info("DEBUG",
            $sformatf("[%s]: cmp: primary queue: %s",
                      this.cfg.get_scb_name(), this.primary_queue.get_name()), UVM_FULL);
  `uvm_info("DEBUG",
            $sformatf("[%s]: cmp: number of queues: %0d",
                      this.cfg.get_scb_name(), this.secondary_queue_names.size()+1), UVM_FULL);

  void'(this.primary_queue_iter.first());
endfunction: create_primary_iterator

/// <b>Compare Strategy API</b>: Contains all the operations to be executed immediately before
/// starting the primary loop. By default is an empty function (no other operations needed).
function void cl_syoscb_compare_base::primary_loop_init();
endfunction: primary_loop_init

/// Returns the number of UVM_ERROR messages that have been generated so far
function int cl_syoscb_compare_base::num_uvm_errors();
  uvm_report_server rs;
  rs = uvm_report_server::get_server();

  return rs.get_severity_count(UVM_ERROR);
endfunction: num_uvm_errors

/// Set the scoreboard configuration associated with this comparer's scoreboard
/// \param cfg The scoreboard configuration object
function void cl_syoscb_compare_base::set_cfg(cl_syoscb_cfg cfg);
  this.cfg = cfg;
endfunction: set_cfg

/// Gets the scoreboard configuration object associated with this scoreboard
function cl_syoscb_cfg cl_syoscb_compare_base::get_cfg();
  return this.cfg;
endfunction: get_cfg

/// Generates a side-by-side comparison of the seq. items that prompted a miscompare.
/// The table includes a header with information on which queues the items originated in,
/// a side-by-side view of the two seq. items and, if cl_syoscb_cfg#enable_comparer_report
/// is set, it also includes a number of miscompare descriptions from the uvm_comparer used.
///
/// \param primary_item The primary item in the comparison
/// \param secondary_item The secondary item in the comparison
/// \param sec_queue_name The name of the secondary queue
/// \param comparer The uvm_comparer used for the comparison
/// \param cmp_name Name of the comparison type, to be used when printing the header.
/// \return The miscompare table
function string cl_syoscb_compare_base::generate_miscmp_table(cl_syoscb_item primary_item,
                                                              cl_syoscb_item secondary_item,
                                                              string sec_queue_name,
                                                              uvm_comparer comparer,
                                                              string cmp_name);

  int table_width;
  bit ecr;
  string header;
  string miscmp_table;
  string footer;

  //Generate fields for body of miscmp table
  table_width = cl_syoscb_string_library::generate_cmp_table_body('{primary_item, secondary_item}, this.cfg, miscmp_table);

  //Generate header
  header = cl_syoscb_string_library::generate_cmp_table_header(
    table_width,
    $sformatf("[%0s]: %0s: Item from primary queue (%0s) not found in secondary queue (%0s)",
      this.cfg.get_scb_name(),
      cmp_name,
      this.primary_queue_name,
      sec_queue_name
    )
  );

  //Generate footer
  ecr = this.cfg.get_enable_comparer_report(sec_queue_name, secondary_item.get_producer());
  if(ecr) begin
    footer = cl_syoscb_string_library::generate_cmp_table_footer(table_width, comparer);
  end else begin
    footer = " ";
  end

  return {header, miscmp_table, footer};
endfunction: generate_miscmp_table

/// Custom do_dopy implementation for secondary queues
function void cl_syoscb_compare_base::do_copy(uvm_object rhs);
  cl_syoscb_compare_base rhs_cast;

  super.do_copy(rhs);

  //try to cast an object as rhs should be cl_syoscb_compare_base type
  if(!$cast(rhs_cast, rhs)) begin
    `uvm_fatal("DO_COPY", "Cast of rhs failed")
  end

  this.secondary_queues = new[rhs_cast.secondary_queues.size()];

  //now i copy all rhs.secondary_queues content in this.secondary_queues
  foreach(this.secondary_queues[i]) begin
    this.secondary_queues[i] = rhs_cast.secondary_queues[i];
  end
endfunction: do_copy

// Custom do_print implementation for secondary queues
function void cl_syoscb_compare_base::do_print(uvm_printer printer);
  super.do_print(printer);

  foreach(this.secondary_queues[i]) begin
    this.secondary_queues[i].print(printer);
  end
endfunction: do_print

// Custom do_compare implementation for secondary queues
function bit cl_syoscb_compare_base::do_compare(uvm_object rhs,
                                                uvm_comparer comparer);
  cl_syoscb_compare_base rhs_cast;
  bit compare_bit = super.do_compare(rhs, comparer);

  //try to cast an object as rhs should be cl_syoscb_compare_base type
  if(!$cast(rhs_cast, rhs)) begin
    `uvm_fatal("DO_COMPARE", "Cast of rhs failed")
    return 0;
  end

  //check if the size of secondary_queues matches
  if(compare_bit) begin
    // Some tools have problems with either $size and/or $bits on the return type
    // of the result of <dynamic array>.size()
    // On the other hand, the data type of "size" is of type INT.
    // According to SV-LRM 1800-2017, in section 6.11 (P.104) the integral type INT has a fixed
    // size equal to 32-bit. In order to keep the scb reusable across all simulators, it has
    // been choosen to hardwire the "size" argument assigning to it the value of 32, which is the
    // number of bit representation for the tipe INT, according to what is reported inside the LRM.
    compare_bit &= comparer.compare_field_int("secondary_queue_size",
                                            this.secondary_queues.size(),
                                            rhs_cast.secondary_queues.size(),
                                            32);
  end

  if(compare_bit) begin
    foreach(this.secondary_queues[i]) begin
      compare_bit &= comparer.compare_object("secondary_queues",
                                             this.secondary_queues[i],
                                             rhs_cast.secondary_queues[i]);
    end
  end

  return compare_bit;
endfunction: do_compare
