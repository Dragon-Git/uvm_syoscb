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
/// Locator class for searching over generic hash queues
class cl_syoscb_queue_locator_hash#(int unsigned HASH_DIGEST_WIDTH = 1) extends cl_syoscb_queue_locator_base;
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils(cl_syoscb_queue_locator_hash#(HASH_DIGEST_WIDTH))

  function new(string name = "cl_syoscb_queue_locator_hash");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Locator API
  //-------------------------------------
  extern virtual function cl_syoscb_proxy_item_base search(cl_syoscb_proxy_item_base proxy_item);

  //-------------------------------------
  // Internal support functions
  //-------------------------------------
  extern virtual function bit  validate_match(cl_syoscb_proxy_item_base primary_proxy,
                                                                  cl_syoscb_proxy_item_base secondary_proxy);
  extern virtual function void validate_no_match(cl_syoscb_proxy_item_base primary_proxy);
endclass: cl_syoscb_queue_locator_hash

/// <b>Locator API:</b> See cl_syoscb_queue_locator_base#search for details
function cl_syoscb_proxy_item_base cl_syoscb_queue_locator_hash::search(cl_syoscb_proxy_item_base proxy_item);
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)             qh, q_primary;
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH)        proxy_item_hash;
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH)        proxy_item_hash_return;
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH)        hash, hash_primary;

  proxy_item_hash_return = cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH)::type_id::create("proxy_item_hash_return");

  if(!$cast(proxy_item_hash,proxy_item))begin
    `uvm_fatal("Incorrect item type", $sformatf("[%s]:Proxy_item ", this.cfg.get_scb_name()));
    return null;
  end

  if(!$cast(qh,this.owner))begin
    `uvm_fatal("Incorrect queue type", $sformatf("[%s]:Queue ", this.cfg.get_scb_name()));
    return null;
  end
  if(!$cast(q_primary, proxy_item.get_queue())) begin
    `uvm_fatal("TYPECAST", $sformatf("[%0s]Incorrect queue type from proxy item. Expected hash queue, got %0s", this.cfg.get_scb_name(), proxy_item.get_queue().get_type_name()))
    return null;
  end


  hash = qh.get_hash();
  hash_primary = q_primary.get_hash();

  if(hash.exists(proxy_item_hash.digest) == 1) begin
    bit found = 0;
    proxy_item_hash_return.digest = proxy_item_hash.digest;
    proxy_item_hash_return.set_queue(qh);
    proxy_item_hash_return.idx = 0;

    //If there is more than one item in hash item from primary queue or this queue,
    //we must manually compare items to ensure that a hash collision doesn't remove the wrong item from the queues
    if(hash.get_size(proxy_item_hash.digest) != 1 || hash_primary.get_size(proxy_item_hash.digest) != 1) begin
      cl_syoscb_item primary_item, sec_item;
      uvm_comparer comparer;

      primary_item = proxy_item_hash.get_item();
      comparer = this.cfg.get_comparer(this.owner.get_name(), primary_item.get_producer());
      if(comparer == null) begin
        comparer = this.cfg.get_default_comparer();
      end
      for(int i=0; i<hash.get_size(proxy_item_hash.digest) && !found; i++) begin
        sec_item = hash.get_item(proxy_item_hash.digest, i);
        if(primary_item.compare(sec_item, comparer)) begin
          proxy_item_hash_return.idx = i;
          found = 1;
        end
      end
    end else begin //only one item in each queue at that hash, they should match
      found = 1'b1;
    end


    if(found && this.validate_match(proxy_item, proxy_item_hash_return)) begin
      return proxy_item_hash_return;
    end else begin
      //If match was not validated, a uvm_error was raised
      //We can just return null here to signal that no match was found
      return null;
    end
  end else begin
    this.validate_no_match(proxy_item);
    //validate_no_match raises a uvm_error if an actual match is found. We still return
    //null no matter what, as something went wrong
    return null;
  end
endfunction: search

/// Validates that a sequence item found in a secondary hash queue matches the sequence item
/// being searched for. Raises a UVM_ERROR if the items do not match
/// \param primary_proxy The proxy item from the primary queue
/// \param secondary_proxy The proxy item found in the secondary queue
/// \return 1 is the two items match represented by proxy items match, 0 otherwise
function bit cl_syoscb_queue_locator_hash::validate_match(cl_syoscb_proxy_item_base primary_proxy,
  cl_syoscb_proxy_item_base secondary_proxy);
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) primary_proxy_hash;

  //Cast to hash item as we need the digest
  if(!$cast(primary_proxy_hash, primary_proxy)) begin
    `uvm_fatal("ITEM_TYPE", "Primary item was not a hash item")
  end

  case (this.cfg.get_hash_compare_check())
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_NO_MATCH,
    pk_syoscb::SYOSCB_HASH_COMPARE_NO_VALIDATION: begin
      return 1'b1;
    end
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_ALL,
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_MATCH: begin
      cl_syoscb_item primary, secondary;
      uvm_comparer comparer;

      primary = primary_proxy.get_item();
      secondary = secondary_proxy.get_item();
      comparer = this.cfg.get_comparer(this.owner.get_name(), primary.get_producer());
      if(comparer == null) begin
        comparer = this.cfg.get_default_comparer();
      end
      if(primary.compare(secondary, comparer)) begin
        return 1'b1;
      end else begin
        string header, body, footer;
        int table_width;
        table_width = cl_syoscb_string_library::generate_cmp_table_body('{primary, secondary}, this.cfg, body);
        header = cl_syoscb_string_library::generate_cmp_table_header(
          table_width,
          $sformatf("[%s] Seq. items with same hash did not have the same contents.\nHash=%x",
            this.cfg.get_scb_name(),
            primary_proxy_hash.digest
          )
        );
        footer = cl_syoscb_string_library::generate_cmp_table_footer(table_width, comparer);

        `uvm_error("MISCMP_HASH", {"\n", header, body, footer})
        return 1'b0;
      end
    end
    default: begin
      t_hash_compare_check hcc = this.cfg.get_hash_compare_check();
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%s] Value of cfg.hash_compare_check (%s, %d) was not valid",
        this.cfg.get_scb_name(),
        hcc.name(),
        hcc))
    end
  endcase
endfunction: validate_match

/// Validates that no sequence item in this secondary hash queue matches the primary
/// sequence item being searched for.
/// Raises a UVM_ERROR if a match is actually found
/// \param primary_proxy The proxy item from the primary queue
function void cl_syoscb_queue_locator_hash::validate_no_match(cl_syoscb_proxy_item_base primary_proxy);
  cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH) owner_hash;
  cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH) primary_proxy_hash;
  cl_syoscb_item primary, secondary;
  uvm_comparer comparer;

  if(!$cast(owner_hash, this.owner)) begin
    `uvm_fatal("QUEUE_ERROR", $sformatf("[%s] Queue %s is not a hash queue. It must be to work with hash items", this.cfg.get_scb_name(), this.owner.get_name()))
  end

  if(!$cast(primary_proxy_hash, primary_proxy)) begin
    `uvm_fatal("ITEM_TYPE", "Primary item was not a hash item")
  end

  case (this.cfg.get_hash_compare_check())
    pk_syoscb::SYOSCB_HASH_COMPARE_NO_VALIDATION,
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_MATCH: begin
      return;
    end
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_ALL,
    pk_syoscb::SYOSCB_HASH_COMPARE_VALIDATE_NO_MATCH: begin
      cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) hash;
      cl_syoscb_queue_hash#(HASH_DIGEST_WIDTH)::tp_digest sec_digest;

      hash = owner_hash.get_hash();
      primary = primary_proxy.get_item();
      comparer = this.cfg.get_comparer(this.owner.get_name(), primary.get_producer());
      if(comparer == null) begin
        comparer = this.cfg.get_default_comparer();
      end

      //Iterate through hash, comparing every entry to our primary entry
      if(hash.first(sec_digest)) begin
        do begin
          int size_before = hash.get_size(sec_digest);

          //Iterate through all items with this hash:
          for(int i=0; i<hash.get_size(sec_digest); i++) begin

            secondary = hash.get_item(sec_digest, i);

            if(primary.compare(secondary, comparer)) begin //True comparison => different hash but same contents
              string header, body;
              int table_width;

              table_width = cl_syoscb_string_library::generate_cmp_table_body('{primary, secondary}, this.cfg, body);
              header = cl_syoscb_string_library::generate_cmp_table_header(
                table_width,
                $sformatf(
                  "[%s] Seq. items with different hash but same contents were found\nPrimary: %x. Secondary: %x",
                  this.cfg.get_scb_name(),
                  primary_proxy_hash.digest,
                  sec_digest
                )
              );
              `uvm_error("MISCMP_HASH", {"\n", header, body})
            end
          end
        end while (hash.next(sec_digest));
      end
    end
    default: begin
      t_hash_compare_check hcc = this.cfg.get_hash_compare_check();
      `uvm_fatal("QUEUE_ERROR", $sformatf("[%s] Value of cfg.hash_compare_check (%s, %d) was not valid",
        this.cfg.get_scb_name(),
        hcc.name(),
        hcc))
    end
  endcase
endfunction: validate_no_match