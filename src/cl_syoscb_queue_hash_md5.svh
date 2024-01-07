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
/// MD5 implementation of a hash queue which optimizes the OOO compare.
/// The queue implements the queue API as defined by cl_syoscb_queue_base.
class cl_syoscb_queue_hash_md5 extends cl_syoscb_queue_hash#(pk_syoscb::MD5_HASH_DIGEST_WIDTH);

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_syoscb_queue_hash_md5)
  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name, uvm_component parent);

  // Iterator support functions
  extern virtual function cl_syoscb_queue_iterator_base create_iterator(string name = "");

  // Locator support function
  extern virtual function cl_syoscb_queue_locator_base  get_locator();

  // Misc support function
  // Implementation of the UVM function do_copy() for the hash MD5 queue. The base class only
  // defines the generic API structure for hash queue, then it is up to the derived one to
  // implement the correct do_copy behaviour for any specific implementation. do_copy in fact
  // requires to know the exact hash digest lenght for the object rhs; and for this reason
  // do_copy can't be implemented in the base class and shared over all implementations
  extern virtual function void                         do_copy(uvm_object rhs);
endclass: cl_syoscb_queue_hash_md5

function cl_syoscb_queue_hash_md5::new(string name, uvm_component parent);
  super.new(name, parent);

  this.hash_algo = cl_syoscb_hash_md5::type_id::create("hash_algo", this);
endfunction: new

/// <b>Queue API:</b> See cl_syoscb_queue_base#create_iterator for more details
function cl_syoscb_queue_iterator_base cl_syoscb_queue_hash_md5::create_iterator(string name = "");
  cl_syoscb_queue_iterator_hash_md5 result;
  string iter_name;
  cl_syoscb_queue_iterator_base f[$];

  // Wait to get exclusive access to the queue
  // if there are multiple iterators
  while(this.iter_sem.try_get() == 0);

  if(name == "") begin
    iter_name = $sformatf("%0s_iter%0d", this.get_name(), this.num_iters_created);
  end else begin
    iter_name = name;
  end

  f = this.iterators.find_index() with (item.get_name() == name);
  if(f.size() != 0) begin
    `uvm_info("ITERATOR", $sformatf("[%0s] An iterator with the name %0s already exists", this.cfg.get_scb_name(), name), UVM_DEBUG)
    this.iter_sem.put();
    return null;
  end
  result = cl_syoscb_queue_iterator_hash_md5::type_id::create(iter_name);

  // No need to check return value since set_queue will issue
  // and `uvm_error of something goes wrong
  void'(result.set_queue(this));

  this.iterators[result] = result;
  this.num_iters_created++;
  this.iter_sem.put();

  return result;
endfunction: create_iterator

/// <b>Queue API:</b> See cl_syoscb_queue_base#create_iterator for more details
function cl_syoscb_queue_locator_base cl_syoscb_queue_hash_md5::get_locator();
  cl_syoscb_queue_locator_hash_md5 locator;

  locator = cl_syoscb_queue_locator_hash_md5::type_id::create($sformatf("%s_loc", this.get_name()));
  void'(locator.set_queue(this));

  return locator;
endfunction: get_locator

// Custom do_copy implementation for iterators in AA in order to shallow copy the elements from rhs
function void cl_syoscb_queue_hash_md5::do_copy(uvm_object rhs);
  cl_syoscb_queue_hash#(pk_syoscb::MD5_HASH_DIGEST_WIDTH) rhs_cast;
  cl_syoscb_hash_aa_wrapper#(pk_syoscb::MD5_HASH_DIGEST_WIDTH) rhs_aa;
  tp_digest l_digest;

  if(!$cast(rhs_cast, rhs))begin
    `uvm_fatal("do_copy",
               $sformatf("The given object argument is not %0p type", rhs_cast.get_type()))
  end
  rhs_aa = rhs_cast.get_hash();

  // Delete the aa content because this queue_base might be used before calling the copy
  // method. on the other hand, the result of this.copy(rhs), should override each field values
  // without keeping memory on what was before.
  this.hash.delete_all();

  if(rhs_aa.first(l_digest)) begin
    do begin
      for(int idx=0; idx<rhs_aa.get_size(l_digest); idx++) begin
        cl_syoscb_item other_item;
        other_item = rhs_aa.get_item(l_digest, idx);
        this.hash.insert(l_digest, other_item);
      end
    end
    while(rhs_cast.hash.next(l_digest));
  end

  super.do_copy(rhs);
endfunction: do_copy
