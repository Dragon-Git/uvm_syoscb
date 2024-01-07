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
/// Implementation of the 2-queue, high speed in-order comparison algorithm.
class cl_syoscb_compare_io_2hp extends cl_syoscb_compare_io;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils(cl_syoscb_compare_io_2hp)

  /// Handle to the secondary queue
  protected cl_syoscb_queue_base secondary_queue;

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_compare_io_2hp");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Compare Strategy API
  //-------------------------------------
  extern protected virtual function void compare_do();
  extern protected virtual function void primary_loop_do();
endclass: cl_syoscb_compare_io_2hp

/// <b>Compare Strategy API</b>: Mandatory overwriting of the base class' do_compare method.
/// Here the actual in-order 2-queue compare is implemented.
///
/// The algorithm is a specialization of the normal in-order compare which handles N queues.
/// Here, only 2 queues are allowed and the compare simply just checks if the first item in the
/// primary queue matches the first item in the secondary queue. If not then a UVM error is issued.
function void cl_syoscb_compare_io_2hp::compare_do();

  if(this.secondary_queues.size() != 1) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s]: cmp-io-2hp: This in order compare only works with a single secondary queue. %0d secondary queues defined", this.cfg.get_scb_name(), this.secondary_queues.size()));
  end

  this.primary_loop_init();

  this.primary_loop_do();
endfunction: compare_do

/// <b>Compare Strategy API:</b> Selects the primary queue's first element, comparing it to the secondary queue's first element.
/// Does this without using #secondary_loop_do, as no looping is required.
function void cl_syoscb_compare_io_2hp::primary_loop_do();
  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io-2hp: number of queues: %0d", this.cfg.get_scb_name(), this.secondary_queues.size()+1), UVM_FULL);
  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io-2hp: primary queue: %s", this.cfg.get_scb_name(), this.primary_queue_name), UVM_FULL);

  this.primary_item_proxy = this.primary_queue_iter.next();
  this.primary_item       = this.primary_queue.get_item(this.primary_item_proxy);

  `uvm_info("DEBUG", $sformatf("[%s]: cmp-io-2hp: Now comparing primary transaction:\n%s",
                               this.cfg.get_scb_name(),
                               cl_syoscb_string_library::sprint_item(primary_item, this.cfg)),
            UVM_FULL);

  this.secondary_item_found.delete();

  // Do the compare
  begin
    cl_syoscb_queue_iterator_base iter;
    cl_syoscb_proxy_item_base     sec_proxy;
    cl_syoscb_item                secondary_item;
    uvm_comparer                  comparer;


    //Get first item from sec. queue using an iterator
    //Cannot use proxy item to get it, as this will allow hash-queues to find items that are not in order
    iter = this.secondary_queues[0].get_iterator("default");
    if(iter == null) begin
      iter = this.secondary_queues[0].create_iterator("default");
    end
    void'(iter.first());
    sec_proxy = iter.next();
    secondary_item = this.secondary_queues[0].get_item(sec_proxy);

    comparer = this.cfg.get_comparer(this.primary_queue_name, this.primary_item.get_producer());
    if(comparer == null) begin
      comparer = this.cfg.get_default_comparer();
    end

    if(secondary_item.compare(primary_item, comparer) == 1'b1) begin
      `uvm_info("DEBUG", $sformatf("[%s]: cmp-io-2hp: Secondary item found:\n%s",
                                   this.cfg.get_scb_name(),
                                   cl_syoscb_string_library::sprint_item(secondary_item, this.cfg)),
                UVM_FULL);

      this.secondary_item_found[secondary_queue_names[0]] = sec_proxy;
    end else begin
      string miscmp_table;

      miscmp_table = this.generate_miscmp_table(primary_item, secondary_item, this.secondary_queue_names[0], comparer, "cmp-io-2hp");
      `uvm_error("COMPARE_ERROR", $sformatf("\n%0s", miscmp_table))
    end
  end

  void'(this.delete());
endfunction: primary_loop_do
