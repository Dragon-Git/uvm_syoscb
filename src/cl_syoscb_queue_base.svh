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
/// Class which represents the base concept of a queue. All queues must extend this class
/// and implement the queue API.
class cl_syoscb_queue_base extends uvm_component;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration
  protected cl_syoscb_cfg cfg;

  /// List of iterators registered with this queue
  protected cl_syoscb_queue_iterator_base iterators[cl_syoscb_queue_iterator_base];

  /// Semaphore guarding exclusive access to the queue when
  /// multiple iterators are in play
  protected semaphore iter_sem;

  /// Associative array counting the number of items by
  /// a given producer that currently exist in the queue
  protected int unsigned cnt_producer[string];

  /// Number of items that have been inserted into this queue
  protected int unsigned cnt_add_item = 0;

  /// Maximum number of items that have been in this queue so far
  protected int unsigned max_items = 0;

  /// The most recently inserted item in this queue
  protected cl_syoscb_item last_inserted_item;

  /// Shadow queue tracking all items inserted into the queue, used for scoreboard dumps
  cl_syoscb_item shadow_items[$];

  /// Number of items that have been dumped from this queue when performing a scoreboard dump
  local int unsigned nbr_items_dumped;

  /// Associative array counting the total number of items by
  /// a given producer that have been inserted in the queue
  local int unsigned total_cnt_producer[string];

  /// Associative array counter the total number of items by
  /// a given producer that have been flused form the queue
  local int unsigned total_cnt_flushed_producer[string];

  /// AA for storing queue debug checks during the UVM check phase.
  /// These values are used in cl_syoscb#report_phase and cl_syoscb#check_phase
  local string failed_checks[string];

  /// The number of iterators that have been created for this queue so far
  protected int num_iters_created = 0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_queue_base)
    `uvm_field_object(cfg,                               UVM_DEFAULT | UVM_REFERENCE)
    `uvm_field_aa_int_string(cnt_producer,               UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(cnt_add_item,                         UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_items,                            UVM_DEFAULT | UVM_DEC)
    `uvm_field_object(last_inserted_item,                UVM_DEFAULT)
    `uvm_field_queue_object(shadow_items,                UVM_DEFAULT)
    `uvm_field_int(nbr_items_dumped,                     UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_string(total_cnt_producer,         UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_string(total_cnt_flushed_producer, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_string_string(failed_checks,           UVM_DEFAULT)
    `uvm_field_int(num_iters_created,                    UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);

    this.iter_sem = new(1);
  endfunction: new

  //-------------------------------------
  // UVM Phase methods
  //-------------------------------------
  extern function void build_phase(uvm_phase phase);
  extern function void check_phase(uvm_phase phase);

  //-------------------------------------
  // Queue API
  //-------------------------------------
  // Basic queue functions
  extern           virtual function bit            add_item(string producer, uvm_sequence_item item);
  extern           virtual function bit            delete_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function void           dump(uvm_printer printer = null, int fd = UVM_STDOUT);
  extern           virtual function cl_syoscb_item get_item(cl_syoscb_proxy_item_base proxy_item);
  extern           virtual function int unsigned   get_size();
  extern           virtual function bit            empty();
  extern           virtual function bit            insert_item(string producer,
                                                               uvm_sequence_item item,
                                                               int unsigned idx);
  extern           virtual function void           flush_queue();

  // Iterator support functions
  extern virtual function cl_syoscb_queue_iterator_base create_iterator(string name = "");
  extern virtual function cl_syoscb_queue_iterator_base get_iterator(string name);
  extern virtual function bit                           delete_iterator(cl_syoscb_queue_iterator_base iterator);

  // Locator support function
  extern virtual function cl_syoscb_queue_locator_base get_locator();

  // Misc support functions
  extern virtual function bit            exists_cnt_producer(string producer);
  extern virtual function int unsigned   get_cnt_producer(string producer);
  extern virtual function int unsigned   get_cnt_add_item();
  extern virtual function int unsigned   get_max_items();
  extern virtual function int unsigned   get_cnt_flushed_item();
  extern virtual function int unsigned   get_cnt_matched_item();
  extern virtual function cl_syoscb_item get_last_inserted_item();
  extern virtual function cl_syoscb_cfg  get_cfg();
  extern virtual function string         get_failed_checks();
  extern virtual function string         create_queue_report(int unsigned offset,
                                                       int unsigned first_column_width);

  //-------------------------------------
  // Internal support functions
  //-------------------------------------
  extern protected virtual function cl_syoscb_item pre_add_item(string producer, uvm_sequence_item item);
  extern protected virtual function void           post_add_item(cl_syoscb_item item);
  extern protected virtual function void           do_flush_queue();
  extern protected virtual function void           incr_cnt_producer(string producer);
  extern protected virtual function void           decr_cnt_producer(string producer);
  extern protected virtual function void           dump_orphans_to_file();
  extern protected virtual function void           dump_orphans_to_stdout();
  extern protected virtual function string         create_producer_stats(int unsigned offset,
                                                               int unsigned first_column_width);
  extern protected virtual function string         get_dump_extension(t_dump_type dump_type);
  extern protected virtual function void           print_orphan_xml_header(int fd);
  extern protected virtual function void           print_orphan_xml_footer(int fd);

  extern virtual function void do_print(uvm_printer printer);
  extern virtual function bit  do_compare(uvm_object rhs, uvm_comparer comparer);
  extern virtual function void do_copy(uvm_object rhs);
  extern virtual function void pre_abort();
endclass: cl_syoscb_queue_base

/// UVM Build Phase. Gets the scoreboard configuration for this SCB
function void cl_syoscb_queue_base::build_phase(uvm_phase phase);
  if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg)) begin
    `uvm_fatal("CFG_ERROR", $sformatf("[%s]: Configuration object not passed.", this.cfg.get_scb_name()))
  end
endfunction: build_phase

/// UVM check phase. Checks if the queue is empty and if it had zero insertions.
/// If either is true, a UVM_ERROR is generated in cl_syoscb
function void cl_syoscb_queue_base::check_phase(uvm_phase phase);
  // Check that this queue is empty. If not then issue an error
  if(!this.empty()) begin
    // *NOTE*: Using this.get_name() is sufficient since the component
    //         instance name is the queue name by definition
    this.failed_checks["QUEUE_NOT_EMPTY"] = $sformatf("Queue %s not empty, orphans: %0d",
                                                       this.get_name(), this.get_size());

    //Print information regarding orphans. Potentially also dump it to file if toggled
    if(this.cfg.get_max_print_orphans() >= 0) begin
      this.dump_orphans_to_stdout();

      if(this.cfg.get_dump_orphans_to_files()) begin
        this.dump_orphans_to_file();
      end
    end
  end

  // Check that the queue had at least one element insertion
  if (this.cfg.get_enable_no_insert_check && this.get_cnt_add_item === 0) begin
    this.failed_checks["QUEUE_NO_INSERTS"] = $sformatf("Queue %s had no insertions", this.get_name());
  end
endfunction: check_phase

/// <b>Queue API:</b> Adds a uvm_sequence_item to this queue.
/// The basic job of the add_item method is:
///   -# Create the new cl_syoscb_item and give it a unique name
///   -# Set the producer and other metadata of the scoreboard item
///   -# Wrap the uvm_sequence_item inside the scoreboard item
///   -# Insert the item into the queue and shadow queue
///   -# Update the producer counter and insert counter
/// \param producer The producer of the sequence item
/// \param item The item that should be add to the queue
/// \return 1 if the item was successfully added, 0 otherwise
/// \note Abstract method. Must be implemented in a subclass

function bit cl_syoscb_queue_base::add_item(string producer, uvm_sequence_item item);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::add_item() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 1'b0;
endfunction: add_item

/// <b>Queue API:</b> Deletes the item indicated by the proxy item from the queue.
/// The basic job of the delete_item method is:
///   -# Delete the element
///   -# Notify any iterators, moving them as necessary
///   -# Update the producer counter for the deleted item's producer
/// \param proxy_item A proxy item indicating which scoreboard item to delete from the queue
/// \return  if the item was successfully deleted, 0 otherwise
/// \note Abstract method. Must be implemented in a subclass

function bit cl_syoscb_queue_base::delete_item(cl_syoscb_proxy_item_base proxy_item);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::delete_item() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 1'b0;
endfunction: delete_item

/// Perform some basic bookkeeping that is the same for all sequence items before insertion.
/// Generates the scoreboard wrapper item
/// \param producer The producer of this item
/// \param item The item to be inserted into the scoreboard
/// \return A scoreboard item, wrapping the given sequence item
function cl_syoscb_item cl_syoscb_queue_base::pre_add_item(string producer, uvm_sequence_item item);
  cl_syoscb_item new_item;

  //Create a new scoreboard item with metadata that wraps the seq. item.
  //Don't need to use type_id::create since we require no customization here
  //Once created with default name, we can assign unique name using instance id
  new_item = new;
  new_item.set_name({producer,"-item-", $psprintf("%0d", new_item.get_inst_id())});

  //Assign producer to scoreboard item, assign metadata fields
  new_item.set_item(item);
  new_item.set_producer(producer);
  new_item.set_insertion_index(this.cnt_add_item);

  return new_item;

endfunction: pre_add_item

/// Perform some basic bookkeping that is the same for all sequence items after insertion
/// \param item The scoreboard item that has been inserted into the scoreboard
function void cl_syoscb_queue_base::post_add_item(cl_syoscb_item item);
  if(this.cfg.get_full_scb_dump()) begin
    this.shadow_items.push_back(item);
  end
  this.last_inserted_item = item;
  this.incr_cnt_producer(item.get_producer());
  this.cnt_add_item++;
  if(this.get_size() > this.max_items) begin
    this.max_items = this.get_size();
  end
endfunction: post_add_item

/// <b>Queue API:</b> Gets the item pointed to by the proxy item from the queue.
/// If the proxy item does not specify a valid item in the queue, print a UVM_INFO/DEBUG message
/// \param proxy_item A proxy item indicating which scoreboard item to delete from the queue
/// \return The scoreboard item indicated by the proxy item, null if the proxy item did not point to a valid item
/// \note Abstract method. Must be implemented in a subclass

function cl_syoscb_item cl_syoscb_queue_base::get_item(cl_syoscb_proxy_item_base proxy_item);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::get_item() *MUST* be overwritten", this.cfg.get_scb_name()));
  return null;
endfunction: get_item

/// <b>Queue API:</b> Returns the current size of the queue.
/// \return Number of items currently in the queue
/// \note Abstract method. Must be implemented in a subclass

function int unsigned cl_syoscb_queue_base::get_size();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::get_size() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 0;
endfunction: get_size

/// <b>Queue API:</b> Returns whether or not the queue is empty.
/// \return 1 if the queue is empty, 0 otherwise
/// \note Abstract method. Must be implemented in a subclass

function bit cl_syoscb_queue_base::empty();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::empty() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 0;
endfunction: empty

/// <b>Queue API:</b> Inserts a uvm_sequence_item at index idx.
/// The method works in the same manner as #add_item, by doing the following:
///   -# Insert the a new item as the add_item() method
///   -# Notify any iterators
/// \param producer The producer of the sequence item
/// \param item The item that should be add to the queue
/// \param idx The index at which the item should be inserted
/// \return 1 if the item was successfully inserted, 0 otherwise
/// \note Abstract method. Must be implemented in a subclass

function bit cl_syoscb_queue_base::insert_item(string producer, uvm_sequence_item item, int unsigned idx);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::insert_item() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 1'b0;
endfunction: insert_item

/// <b>Queue API:</b> Deletes all elements from the queue.
/// Updates the flush counter, sets all producer counts to 0 and resets all iterators.
function void cl_syoscb_queue_base::flush_queue();
  string producers[];

  this.cfg.get_producers(producers);

  foreach (producers[i]) begin
    if(this.cnt_producer.exists(producers[i])) begin
      this.total_cnt_flushed_producer[producers[i]] += this.cnt_producer[producers[i]];
      this.cnt_producer[producers[i]] = 0;
    end
  end

  //Reset all iterators
  while(this.iter_sem.try_get() == 0);
  foreach(this.iterators[i]) begin
    void'(this.iterators[i].first());
  end
  this.iter_sem.put();
  this.do_flush_queue();
endfunction: flush_queue

/// Performs the actual element deletion from the queue when called by #flush_queue
function void cl_syoscb_queue_base::do_flush_queue();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue::do_flush_queue() *MUST* be overwritten", this.cfg.get_scb_name()));
endfunction: do_flush_queue

/// <b>Queue API:</b> Creates an iterator for this queue.
/// Iterators are by default named "[name]_iter[X]", where [name] is the name of the queue, and [X]
/// is the number of iterators that have previusly been created for this queue
/// \param name A name to be used for the iterator. If an iterator with this name already exists,
///             prints a UVM_DEBUG message
/// \return     An iterator over this queue, or null if a queue with the requested name already exists
function cl_syoscb_queue_iterator_base cl_syoscb_queue_base::create_iterator(string name = "");
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::create_iterator() *MUST* be overwritten", this.cfg.get_scb_name()));
  return null;
endfunction: create_iterator

/// <b>Queue API:</b> Gets the iterator from this queue with a given name.
/// If no queue exists with that name, returns null
/// \param name The name of the queue to lookup
/// \return     That iterator, if it exists, or null if no such queue exists
/// \note       Will raise a UVM_ERROR if multiple iterators with the same name exist
function cl_syoscb_queue_iterator_base cl_syoscb_queue_base::get_iterator(string name);
  cl_syoscb_queue_iterator_base f[$];
  f = this.iterators.find_index() with (item.get_name() == name);
  if(f.size() > 1) begin
    `uvm_error("ITERATOR_ERROR", $sformatf("[%0s]: Found %0d iterators with the same name (%0s), don't know what to do", this.cfg.get_scb_name(), f.size(), name))
  end else if (f.size() == 1) begin
    return f[0];
  end else begin
    return null;
  end
endfunction: get_iterator

/// <b>Queue API:</b> Deletes an iterator from this queue.
/// \param iterator The iterator to delete
/// \return 1 if the iterator was successfully deleted, 0 otherwise
function bit cl_syoscb_queue_base::delete_iterator(cl_syoscb_queue_iterator_base iterator);
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::delete_item() *MUST* be overwritten", this.cfg.get_scb_name()));
  return 1'b0;
endfunction: delete_iterator

/// <b>Queue API:</b> Creates a locator for this queue.
/// \return A locator over this queue
function cl_syoscb_queue_locator_base cl_syoscb_queue_base::get_locator();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_queue_base::get_locator() *MUST* be overwritten", this.cfg.get_scb_name()));
  return null;
endfunction: get_locator

function cl_syoscb_cfg cl_syoscb_queue_base::get_cfg();
  return this.cfg;
endfunction: get_cfg

/// Increment the producer counter for a given producer.
/// \param producer The producer to increment the counter for
function void cl_syoscb_queue_base::incr_cnt_producer(string producer);
  // Reset counter if the producer does not exist
  if(!this.cnt_producer.exists(producer)) begin
    this.cnt_producer[producer] = 0;
    this.total_cnt_producer[producer] = 0;
    this.total_cnt_flushed_producer[producer] = 0;
  end

  // Increment the producer count
  this.cnt_producer[producer] = this.cnt_producer[producer]+1;

  // Increment the total producer count
  this.total_cnt_producer[producer] = this.total_cnt_producer[producer]+1;
endfunction: incr_cnt_producer

/// Decrement the producer counter for a given producer
/// \param producer The producer to decrement the counter for
function void cl_syoscb_queue_base::decr_cnt_producer(string producer);
  if(!this.cnt_producer.exists(producer)) begin
    `uvm_fatal("QUEUE_ERROR",  $sformatf("[%s]: Trying to decrement a non-existing producer: %s ", this.cfg.get_scb_name(), producer));
  end

  if(this.cnt_producer[producer] == 0) begin
    `uvm_fatal("QUEUE_ERROR",  $sformatf("[%s]: Trying to decrement the producer: %s which has count 0", this.cfg.get_scb_name(), producer));
  end

  this.cnt_producer[producer] = this.cnt_producer[producer]-1;
endfunction: decr_cnt_producer

/// <b>Queue API</b>: Check if a given producer exists in the producer counter for this queue
/// \param producer The producer to check for existence
/// 1 if the producer exists, 0 otherwise
function bit cl_syoscb_queue_base::exists_cnt_producer(string producer);
  return this.cnt_producer.exists(producer);
endfunction: exists_cnt_producer

/// <b>Queue API</b>: Get the producer count for a given producer.
/// \param producer The producer to get count for
/// \return The number of items in the queue that were from the given producer
/// \note May *ONLY* be called if the producer exists (see #exists_cnt_producer)
function int unsigned cl_syoscb_queue_base::get_cnt_producer(string producer);
  return this.cnt_producer[producer];
endfunction: get_cnt_producer

/// <b>Queue API</b>: Returns the number of items that have been inserted in this queue
function int unsigned cl_syoscb_queue_base::get_cnt_add_item();
  return this.cnt_add_item;
endfunction: get_cnt_add_item

/// <b>Queue API</b>: Returns the maximum number of elements that have been in the queue.
function int unsigned cl_syoscb_queue_base::get_max_items();
  return this.max_items;
endfunction: get_max_items

/// <b>Queue API</b>: Returns the total number of elements flushed from this queue.
function int unsigned cl_syoscb_queue_base::get_cnt_flushed_item();
  return this.total_cnt_flushed_producer.sum();
endfunction: get_cnt_flushed_item

/// <b>Queue API</b>: Returns the total number of elements matched in this queue
function int unsigned cl_syoscb_queue_base::get_cnt_matched_item();
  return this.cnt_add_item - (this.get_cnt_flushed_item()+this.get_size());
endfunction: get_cnt_matched_item

/// <b>Queue API</b>: Gets the last inserted item in the queue
function cl_syoscb_item cl_syoscb_queue_base::get_last_inserted_item();
  return this.last_inserted_item;
endfunction : get_last_inserted_item

/// <b>Queue API</b>: Loop over all the items in the shadow queue and dump them.
/// If a printer has not been passed in the arguments, used cl_syoscb_cfg#get_printer to lookup a printer for each shadow item
/// (which may be quite inefficient).
/// If cl_syoscb_cfg#full_scb_type has been set to XML, the XML printer is used, overriding any specific printers that have been set
/// \param printer The printer to use when dumping items. Defaults to null, getting a queue/producer specific printer for each item
/// \param fd File descriptor for where to dump items. Defaults to STDOUT
function void cl_syoscb_queue_base::dump(uvm_printer printer = null, int fd = UVM_STDOUT);
  //Have to use a separate printer variable to ensure that correct queue/producer
  //printer is used on every iteration if input printer is null.
  //otherwise, shadow_items[1] will use the printer set when parsing shadow_items[0].
  uvm_printer printer_used;

  if(this.cfg.get_full_scb_dump() == 1'b0) begin
    `uvm_fatal("CFG_ERROR", "Cannot dump queue contents when get_full_scb_dump is disabled")
    return;
  end

  if(this.cfg.get_full_scb_dump_type() == pk_syoscb::XML) begin
    uvm_xml_printer xp = new;
    printer_used = xp;
  end

  foreach(this.shadow_items[i])begin
    this.shadow_items[i].set_queue_index(-1); //Queue index has no meaning when performing scb dump

    case (this.cfg.get_full_scb_dump_type())
      pk_syoscb::TXT: begin //Print text header, look up printer based on queue name and producer name
        $fwrite (fd, $sformatf("\n//--item: %9d -------------------------------//\n",this.nbr_items_dumped++));

        //If a printer has been passed in the argument, use that. If not, try to get a queue/producer specific printer
        printer_used = (printer != null) ? printer : this.cfg.get_printer(this.get_name(), this.shadow_items[i].get_producer());
        if(printer_used == null) begin
          printer_used = this.cfg.get_default_printer();
        end
      end
      pk_syoscb::XML: begin //Print XML header
        $fwrite (fd, $sformatf("\n<!--  item: %9d                                -->\n",this.nbr_items_dumped++));
      end
    endcase
    cl_syoscb_printer_config::set_file_descriptor(printer_used, fd);

    if(this.cfg.get_full_scb_dump_type() == pk_syoscb::TXT && this.cfg.get_enable_c2s_full_scb_dump()) begin //Only in this case should we use convert2string
      $fwrite(fd, {this.shadow_items[i].convert2string(), "\n"});
    end else begin
      this.shadow_items[i].print(printer_used);
    end
  end
  this.shadow_items.delete();
endfunction: dump

/// Prints orphans remaining in the queue to stdout.
/// The number of orphans that are printed depends on cl_syoscb_cfg#max_print_orphans
function void cl_syoscb_queue_base::dump_orphans_to_stdout();
  cl_syoscb_queue_iterator_base l_iterator;
  cl_syoscb_item                l_scb_item;
  cl_syoscb_proxy_item_base     l_proxy_item;
  int         fd;
  uvm_printer printer;

  if(this.cfg.get_max_print_orphans() < 0) begin
    return;
  end

  l_iterator = this.create_iterator();
  void'(l_iterator.first());

  //Using (A -> B) operator below. If A=true, evaluates B. If A=false, always returns true
  while(l_iterator.has_next() &&
  (this.cfg.get_max_print_orphans() > 0 -> (l_iterator.next_index() < this.cfg.get_max_print_orphans()))) begin

    l_proxy_item = l_iterator.next();
    l_scb_item = l_proxy_item.get_item();
    l_scb_item.set_queue_index(l_iterator.previous_index());

    //Print to stdout
    if(this.cfg.get_orphans_as_errors()) begin
      `uvm_error(this.get_name(), $sformatf("\n%s", l_scb_item.sprint()))
    end
    else begin
      `uvm_info(this.get_name(), $sformatf("\n%s", l_scb_item.sprint()), UVM_NONE)
    end
  end

  void'(this.delete_iterator(l_iterator));

endfunction: dump_orphans_to_stdout

/// Dumps orphans remaining in the queue into a logfile.
/// Assumes that the caller has checked whether cl_syoscb_cfg#dump_orphans_to_files is set
function void cl_syoscb_queue_base::dump_orphans_to_file();
  cl_syoscb_queue_iterator_base l_iterator;
  cl_syoscb_item                l_scb_item;
  cl_syoscb_proxy_item_base     l_proxy_item;
  int         fd;
  uvm_printer printer;
  string ext;

  if(this.cfg.get_max_print_orphans() < 0) begin
    return;
  end

  ext = this.get_dump_extension(this.cfg.get_orphan_dump_type());
  fd = $fopen($sformatf("%s.%s.%s_orphans.%s", this.cfg.get_scb_name(), this.cfg.get_orphan_dump_file_name(), this.get_name(), ext), "w");

  //Get XML printer already if toggled
  if(this.cfg.get_orphan_dump_type() == pk_syoscb::XML) begin
    uvm_xml_printer xp = new;
    printer = xp;
    cl_syoscb_printer_config::set_file_descriptor(printer, fd);
    this.print_orphan_xml_header(fd);
  end

  l_iterator = this.create_iterator();
  void'(l_iterator.first());

  while(l_iterator.has_next() &&
  (this.cfg.get_max_print_orphans() > 0 -> (l_iterator.next_index() < this.cfg.get_max_print_orphans()))) begin

    l_proxy_item = l_iterator.next();
    l_scb_item = l_proxy_item.get_item();
    l_scb_item.set_queue_index(l_iterator.previous_index());

    //Get queue/producer specific printer if output is TXT.
    //If XML, we've already obtained the printer and set output file handle above
    if(this.cfg.get_orphan_dump_type() == pk_syoscb::TXT) begin
      printer = this.cfg.get_printer(this.get_name(), l_scb_item.get_producer());
      //If no printer set, get default
      printer = (printer != null) ? printer : this.cfg.get_default_printer();
      cl_syoscb_printer_config::set_file_descriptor(printer, fd);
    end

    l_scb_item.print(printer);
  end

  if(this.cfg.get_orphan_dump_type() == pk_syoscb::XML) begin
    this.print_orphan_xml_footer(fd);
  end
  $fclose(fd);

  void'(this.delete_iterator(l_iterator));
endfunction: dump_orphans_to_file

/// <b>Queue API</b>: Gets a string containing all queue checks that this queue have failed.
/// Failed checks include having orphans at the end of simulation, and not having any insertions
/// \return A string containing all failed checks for this queue
function string cl_syoscb_queue_base::get_failed_checks();
  if(this.failed_checks.size() == 0) begin
    return "";
  end else begin
    string failed_checks_str;

    foreach(this.failed_checks[str]) begin
      failed_checks_str = { failed_checks_str, "  ", str, ": ", failed_checks[str], "\n"};
    end

    return failed_checks_str;
  end
endfunction: get_failed_checks

/// Returns a table with statistics for all producers in this queue.
/// Outputs the number of insertions, matches, flushed items and orphans per-producer.
/// \param offset The x-offset that should be used when printing producer names
/// \param first_column_width The width of the first column in the table
/// \return A string containing producer stats for all producers in this queue.
// Producer name | Inserts | Matches | Flushed | Orphans
function string cl_syoscb_queue_base::create_producer_stats(int unsigned offset, int unsigned first_column_width);
  string producers[];
  string producer_stats;

  this.cfg.get_producers(producers);

  foreach (producers[i]) begin
    if(this.total_cnt_producer.exists(producers[i])) begin
      producer_stats = { producer_stats,
                         "\n",
                         $sformatf("%s%s | %8d | %8d | %8d | %8d |",
                                   cl_syoscb_string_library::pad_str("", offset),
           cl_syoscb_string_library::pad_str(producers[i], first_column_width, " ", 1'b1),
                                   this.total_cnt_producer[producers[i]],
                                   this.total_cnt_producer[producers[i]]-(this.total_cnt_flushed_producer[producers[i]]+this.cnt_producer[producers[i]]),
                                   this.total_cnt_flushed_producer[producers[i]],
                                   this.cnt_producer[producers[i]])};
    end else begin
      producer_stats = { producer_stats,
                         "\n",
                         $sformatf("%s%s | %8d | %8d | %8d | %8d |",
                                   cl_syoscb_string_library::pad_str("", offset),
           cl_syoscb_string_library::pad_str(producers[i], first_column_width, " ", 1'b1),
                                   0,
                                   0,
                                   0,
                                   0)};
    end
  end

  return producer_stats;
endfunction: create_producer_stats

/// <b>Queue API</b>: Returns a string with overall queues statistics.
/// Reports the number of insertions, matches, flushed items and orphans.
/// If cl_syoscb_cfg#enable_queue_stats is 1, also includes per-producer statistics (see #create_producer_stats)
/// \param offset The x-offset that should be used when printing the queue name names
/// \param first_column_width The width of the first column in the table
/// \return A string containing overall queues statistics.
// | Queue name  | Inserts | Matches | Flushed | Orphans |
// |  Producer X | Inserts | Matches | Flushed | Orphans | (only if enable_queue_stats is toggled for this queue)
function string cl_syoscb_queue_base::create_queue_report(int unsigned offset, int unsigned first_column_width);
  string stats_str;
  stats_str = { stats_str,
                "\n",
              $sformatf("%s%s | %8d | %8d | %8d | %8d |",
                cl_syoscb_string_library::pad_str("", offset),
                cl_syoscb_string_library::pad_str(this.get_name(), first_column_width, " ", 1'b1),
                this.get_cnt_add_item(),
                this.get_cnt_matched_item(),
                this.get_cnt_flushed_item(),
                this.get_size())};
  if(this.cfg.get_enable_queue_stats(this.get_name())) begin
    stats_str = {stats_str, this.create_producer_stats(offset+pk_syoscb::GLOBAL_REPORT_INDENTION, first_column_width-pk_syoscb::GLOBAL_REPORT_INDENTION)};
  end

  return stats_str;
endfunction: create_queue_report

/// Gets the file extension to be used for a dump file.
/// \param dump_type The type of dump that should be performed.
/// \return A string with the file extension that should be used for that kind of dump
function string cl_syoscb_queue_base::get_dump_extension(t_dump_type dump_type);
  string r;
  case (dump_type)
    pk_syoscb::TXT: r = "txt";
    pk_syoscb::XML: r = "xml";
    default: `uvm_fatal("CFG_ERROR", $sformatf("No file extension associated with dump type %0s/%0d", dump_type.name(), dump_type))
  endcase
  return r;
endfunction: get_dump_extension

/// Prints the header for an XML orphan dump.
///
/// \param fd File descriptor for the file to write the header into
function void cl_syoscb_queue_base::print_orphan_xml_header(int fd);
  string header;
  header = {
    "<?xml version='1.0' encoding='UTF-8'?>\n",
    "<scb name='", this.cfg.get_scb_name(), " orphans'>\n",
    "<queues>\n",
    "<queue name='", this.get_name(), "'>\n",
    "<items>\n"
  };

  $fwrite(fd, header);
endfunction: print_orphan_xml_header

/// Prints the footer for an XML orphan dump.
///
/// \param fd File descriptor for the file to write the header into
function void cl_syoscb_queue_base::print_orphan_xml_footer(int fd);
  string footer;
  footer = {
    "</items>\n",
    "</queue>\n",
    "</queues>\n",
    "</scb>\n"
  };
  $fwrite(fd, footer);
endfunction: print_orphan_xml_footer

// Custom do_print implementation for the iterators in the AA,
// in order to print the registered iterators' basic information only
function void cl_syoscb_queue_base::do_print(uvm_printer printer);
  cl_syoscb_queue_iterator_base l_iterator;

  if(this.iterators.first(l_iterator)) begin
    printer.print_generic(.name("iterators"),
                          .type_name("-"),
                          .size(this.iterators.size()),
                          .value("-"));
    do begin
      printer.print_generic(.name($sformatf("  [%s]", l_iterator.get_name())),
                            .type_name("cl_syoscb_iterator"),
                            .size(l_iterator == null ? 0 :1),
                            .value(l_iterator == null? "<null>" : $sformatf("<%0d>",
                                                                    l_iterator.get_inst_id())));
    end
    while(this.iterators.next(l_iterator));
  end

  super.do_print(printer);
endfunction: do_print

// Custom do_compare implementation in order to compare if both queues have the same iterators registered
function bit cl_syoscb_queue_base::do_compare(uvm_object rhs, uvm_comparer comparer);
  cl_syoscb_queue_base rhs_cast;
  bit compare_result = super.do_compare(rhs, comparer);

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_compare",
               $sformatf("The given object argument is not %0p type", rhs_cast.get_type()))
    return 0;
  end

  // Check if both itrerators associative arrays have the same size
  if(rhs_cast.iterators.size() != this.iterators.size()) begin
    return 0;
  end
  else begin
    // Here size are equal. Now check if both queues are registered with the same iterators.
    // Since both aa should be equal, they should also have the same items indexed by the same key
    // in the same position inside them. For this reason, looping using the foreach should be ok.
    foreach(this.iterators[i]) begin
      compare_result &= comparer.compare_object($sformatf("%0s", this.iterators[i].get_name()),
                                                this.iterators[i],
                                                rhs_cast.iterators[i]);
    end
  end

  return compare_result;
endfunction: do_compare

// Custom do_copy implementation for iterators in the AA in order
// to correctly clone each registered iterator from rhs queue
function void cl_syoscb_queue_base::do_copy(uvm_object rhs);
  cl_syoscb_queue_base rhs_cast;

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_copy",
               $sformatf("The given object argument is not %0p type", rhs_cast.get_type()))
  end

  // Delete the aa content because this queue_base might be used before calling the copy
  // method. on the other hand, the result of this.copy(rhs), should override each field values
  // without keeping memory on what was before.
  this.iterators.delete();

  foreach(rhs_cast.iterators[i]) begin
    cl_syoscb_queue_iterator_base l_iterator;

    // Need to clone each rhs_cast.iterators[i] since they cannot be shared within queues
    if(!$cast(l_iterator, rhs_cast.iterators[i].clone())) begin
      `uvm_fatal("do_copy",
                 $sformatf("Clone of iterator: '%0s' failed!", rhs_cast.iterators[i].get_name()))
    end

    this.iterators[l_iterator] = l_iterator;
  end

  super.do_copy(rhs);
endfunction: do_copy

// Implements the pre_abort hook, performing orphan dumping and shadow queue dumping if enabled,
// before the simulation finishes due to an error
function void cl_syoscb_queue_base::pre_abort();
  if(this.cfg.get_dump_orphans_to_files()) begin
    this.dump_orphans_to_file();
  end
endfunction: pre_abort