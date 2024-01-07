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
/// A wrapper around an associative array, used for storing hash queues.
/// Supports all of the same functions that an ordinary AA supports
class cl_syoscb_hash_aa_wrapper #(int unsigned HASH_DIGEST_WIDTH = 1) extends uvm_object;
  ///Typedef for hash algorithm digests
  typedef cl_syoscb_hash_base#(HASH_DIGEST_WIDTH)::tp_hash_digest tp_digest;

  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  ///Queue implemented as assoc array
  cl_syoscb_hash_item hash[tp_digest];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH))
    //  No Macro exists for assoc arrays with user defined keys
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_hash_aa_wrapper");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function int                 size();
  extern function int                 get_size(tp_digest digest);
  extern function void                insert(tp_digest digest, cl_syoscb_item item);
  extern function cl_syoscb_item      get_item(tp_digest digest, int unsigned idx = 0);
  extern function cl_syoscb_hash_item get_hash_item(tp_digest digest);
  extern function void                delete(tp_digest digest, int unsigned idx = 0);
  extern function void                delete_all();
  extern function bit                 exists(tp_digest digest);
  extern function bit                 first(ref tp_digest digest);
  extern function bit                 last(ref tp_digest digest);
  extern function bit                 next(ref tp_digest digest);
  extern function bit                 prev(ref tp_digest digest);

  extern function void                do_print(uvm_printer printer);
  extern function bit                 do_compare(uvm_object rhs, uvm_comparer comparer);

endclass: cl_syoscb_hash_aa_wrapper



/// Returns the size (number of entries) in the wrapped assoc array
/// \note This does not necessarily match the size of the contained queue,
///       as a hash item may have multiple entries
function int cl_syoscb_hash_aa_wrapper::size();
  return this.hash.size();
endfunction: size

/// Return the size of a hash item in the wrapped assoc array
/// \param digest The digest of the hash item to retrieve
/// \return       The size of that hash item, 0 if none exists
function int cl_syoscb_hash_aa_wrapper::get_size(tp_digest digest);
  if(this.hash.exists(digest)) begin
    return this.hash[digest].get_size();
  end
  return 0;
endfunction: get_size

/// Inserts an item into the wrapped assoc array.
/// \param digest The hash digest of the item to insert
/// \param item  The item to insert
function void cl_syoscb_hash_aa_wrapper::insert(tp_digest digest, cl_syoscb_item item);
  if(!this.hash.exists(digest)) begin
    cl_syoscb_hash_item hash_item;
    hash_item = cl_syoscb_hash_item::type_id::create($sformatf("hash-item-%s",digest));
    this.hash[digest] = hash_item;
  end
  this.hash[digest].add_item(item);
endfunction: insert

///Gets a hash item in the wrapped assoc array
/// \param digest The hash digest of the item to get
/// \return       The hash item at that digest, or null if none exists
function cl_syoscb_hash_item cl_syoscb_hash_aa_wrapper::get_hash_item(tp_digest digest);
  if(this.hash.exists(digest)) begin
    return this.hash[digest];
  end
  return null;
endfunction: get_hash_item

/// Gets the scoreboard item at an index with a given hash value
/// \param digest The hash value of the item to get
/// \param idx    The index in the hash item. Defaults to 0.
/// \return       That item, or null if no item with that hash exists or idx was too large
function cl_syoscb_item cl_syoscb_hash_aa_wrapper::get_item(tp_digest digest, int unsigned idx = 0);
  if(this.hash.exists(digest)) begin
    return this.hash[digest].get_item(idx);
  end
  return null;
endfunction: get_item

/// Deletes a sequence item with a given hash value
/// \param digest The hash digest of the item to delete
/// \param idx    The index in the hash item of the sequence item to delete. Defaults to 0.
function void cl_syoscb_hash_aa_wrapper::delete(tp_digest digest, int unsigned idx = 0);
  this.hash[digest].delete_item(idx);
  ///Must remove to avoid iterating over empty hash items
  if(this.hash[digest].get_size() == 0) begin
    this.hash.delete(digest);
  end
endfunction: delete

/// Deletes all items in the assoc array
function void cl_syoscb_hash_aa_wrapper::delete_all();
  this.hash.delete();
endfunction: delete_all

/// Checks if an entry exists with the given hash value
/// \param digest The hash value to check for
/// \return      1 if an item with that hash exists, 0 otherwise
function bit cl_syoscb_hash_aa_wrapper::exists(tp_digest digest);
  return this.hash.exists(digest);
endfunction: exists

/// Retrieves the hash of the first item in the wrapped AA
/// The first item is not necessarily the item first inserted, but the item
/// that comes first "alphabetically"
/// \param digest A reference to a digest, where the digest of the first entry is returned
/// \return      1 if the digest is valid, 0 otherwise
function bit cl_syoscb_hash_aa_wrapper::first(ref tp_digest digest);
  return this.hash.first(digest);
endfunction: first

/// Retrieves the hash of the last item in the wrapped AA
/// The last item is not necessarily the item last inserted, but the item
/// that comes last "alphabetically"
/// \param digest A reference to a digest, where the digest of the last entry is returned
/// \return      1 if the digest is valid, 0 otherwise
function bit cl_syoscb_hash_aa_wrapper::last(ref tp_digest digest);
  return this.hash.last(digest);
endfunction: last

/// Retrieves the hash of the next item in the wrapped AA
/// The first item is not necessarily the next item in insertion order,
/// but the item  that comes next "alphabetically"
/// \param digest A reference to the digest of the current value. The digest of the next entry is returned here
/// \return      1 if the digest is valid, 0 otherwise
function bit cl_syoscb_hash_aa_wrapper::next(ref tp_digest digest);
  return this.hash.next(digest);
endfunction: next

/// Retrieves the hash of the previous item in the wrapped AA
/// The previous item is not necessarily the previous item in insertion order,
/// but the prevoius item "alphabetically"
/// \param digest A reference to the digest of the current value. The digest of the previous entry is returned here
/// \return      1 if the digest is valid, 0 otherwise
function bit cl_syoscb_hash_aa_wrapper::prev(ref tp_digest digest);
  return this.hash.prev(digest);
endfunction: prev


// Implements do_print for the hash AA to print all items contained in it
function void cl_syoscb_hash_aa_wrapper::do_print(uvm_printer printer);
  tp_digest digest;
  int unsigned idx;

  if(this.hash.first(digest)) begin
    printer.print_generic("hash", "-", this.hash.size(), "-");
    do begin
      printer.print_object(.name($sformatf("hash[%0d]", idx)), .value(this.hash[digest]));
      idx++;
    end while(this.hash.next(digest));
  end
endfunction: do_print

//Implements do_compare to verify if two hash AA's have the same contents
function bit cl_syoscb_hash_aa_wrapper::do_compare(uvm_object rhs, uvm_comparer comparer);
  cl_syoscb_hash_aa_wrapper#(HASH_DIGEST_WIDTH) rhs_aa;
  tp_digest digest;

  bit compare_result = super.do_compare(rhs, comparer);

  if(!$cast(rhs_aa, rhs)) begin
    `uvm_fatal("TYPECAST", $sformatf("Unable to cast RHS to cl_syoscb_hash_aa_wrapper#(%0d), it is %0s", this.HASH_DIGEST_WIDTH, rhs.get_type_name()))
  end
  if(rhs_aa.size() != this.hash.size()) begin
    return 0; //Uneven sizies, definitely not a match
  end else begin
    if(this.hash.first(digest)) begin
      do begin
        compare_result &= comparer.compare_object(
          this.get_hash_item(digest).get_name(),
          this.get_hash_item(digest),
          rhs_aa.get_hash_item(digest));
      end while(this.hash.next(digest));
    end
  end
endfunction: do_compare