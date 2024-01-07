//----------------------------------------------------------------------
//   Copyright 2014 SyoSil ApS
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
class cl_syoscb_queue_std extends cl_syoscb_queue;
   // TBD: This is a hack to get things going!!
   int 	unsigned name_hack = 0;

   // Poor mans queue implementation as a SV queue
   cl_syoscb_item items[$];

   `uvm_component_utils_begin(cl_syoscb_queue_std)
     `uvm_field_queue_object(items, UVM_DEFAULT)
   `uvm_component_utils_end

   // Basic queue functions
   extern function new(string name, uvm_component parent);
   extern virtual function bit add_item(string producer, uvm_sequence_item item);
   extern virtual function bit delete_item(int unsigned idx);
   extern virtual function uvm_sequence_item get_item(int unsigned idx);
   extern virtual function int unsigned get_size();
   extern virtual function bit insert_item(string producer, uvm_sequence_item item, int unsigned idx);

   // Iterator support functions
   extern virtual function cl_syoscb_queue_iterator_base create_iterator();
   extern virtual function bit delete_iterator(cl_syoscb_queue_iterator_base iterator);
endclass: cl_syoscb_queue_std

function cl_syoscb_queue_std::new(string name, uvm_component parent);
   super.new(name, parent);
endfunction : new

function bit cl_syoscb_queue_std::add_item(string producer, uvm_sequence_item item);
  // TBD consequences of not using create instead of new?
  cl_syoscb_item new_item = new(.name({producer,"-item-", $psprintf("%0d", this.name_hack++)}));
  new_item.set_producer(.producer(producer));
  new_item.set_item(.item(item));
  this.items.push_back(new_item);
  return 1;
endfunction : add_item

function bit cl_syoscb_queue_std::delete_item(int unsigned idx);
  if(idx < this.items.size()) begin
    cl_syoscb_queue_iterator_base iter[$];

    while(!this.iter_sem.try_get());
    items.delete(idx);

    // Update iterators
    iter = this.iterators.find(x) with (x.get_idx() < idx);
    for(int i = 0; i < iter.size(); i++) begin
      void'(iter[i].previous());
    end

    this.iter_sem.put();
    return 1;
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("Idx: %0d is not present in queue: %0s", idx, this.get_name()), UVM_MEDIUM);
    return 0;
  end
endfunction : delete_item

function uvm_sequence_item cl_syoscb_queue_std::get_item(int unsigned idx);
  if(idx < this.items.size()) begin
    return items[idx].get_item();
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("Idx: %0d is not present in queue: %0s", idx, this.get_name()), UVM_MEDIUM);
    return null;
  end
endfunction : get_item

function int unsigned cl_syoscb_queue_std::get_size();
  return this.items.size();
endfunction : get_size

function bit cl_syoscb_queue_std::insert_item(string producer, uvm_sequence_item item, int unsigned idx);
  cl_syoscb_item new_item = new(.name({producer,"-item-", $psprintf("%0d", this.name_hack++)}));
  new_item.set_producer(.producer(producer));
  new_item.set_item(.item(item));

  if(idx < this.items.size()) begin
    cl_syoscb_queue_iterator_base iter[$];

    while(!this.iter_sem.try_get());
    this.items.insert(idx, new_item);

    // Update iterators
    iter = this.iterators.find(x) with (x.get_idx() >= idx);
    for(int i = 0; i < iter.size(); i++) begin
      void'(iter[i].next());
    end

    this.iter_sem.put();
    return 1;
  end else if(idx == this.items.size()) begin
    this.items.push_back(new_item);
    return 1;
  end else begin
    `uvm_info("OUT_OF_BOUNDS", $sformatf("Idx: %0d too large for queue %0s", idx, this.get_name()), UVM_MEDIUM);
    return 0;
  end
endfunction : insert_item

function cl_syoscb_queue_iterator_base cl_syoscb_queue_std::create_iterator();
  cl_syoscb_queue_iterator_std result;

  // TBD: Hmmm, busywait due to function?
  while(this.iter_sem.try_get() == 0);

  result = cl_syoscb_queue_iterator_std::type_id::create(
  		$sformatf("%s_iter%0d", this.get_name(), this.iter_idx));

  // No need to check return value since set_queue will issue
  // and `uvm_error of something goes wrong
  void'(result.set_queue(this));

  this.iterators[result] = result;
  this.iter_idx++;
  this.iter_sem.put();

  return result;
endfunction : create_iterator

function bit cl_syoscb_queue_std::delete_iterator(cl_syoscb_queue_iterator_base iterator);
  if(iterator == null) begin
    `uvm_info("NULL", $sformatf("Asked to delete null iterator from list of iterators in %s",
                                this.get_name()), UVM_MEDIUM);
    return 0;
  end else begin 	
    // TBD: Hmmm busy wait+function?
    while(!this.iter_sem.try_get());

    this.iterators.delete(iterator);
    this.iter_idx--;
    this.iter_sem.put();
    return 1;
  end
endfunction : delete_iterator
