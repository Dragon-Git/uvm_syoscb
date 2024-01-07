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
/// Proxy item implementation for hash queues.
/// Contains a reference to the digest value of the item for easy AA lookup.
/// \param HASH_DIGEST_WIDTH Number of bits used for hash digests in the used hash algorithm
class cl_syoscb_proxy_item_hash#(int unsigned HASH_DIGEST_WIDTH = 1) extends cl_syoscb_proxy_item_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// The digest for the hashed scoreboard item
  cl_syoscb_hash_base#(HASH_DIGEST_WIDTH)::tp_hash_digest digest;

  ///The index in the cl_syoscb_hash_item with that digest where the item is located.
  ///This field is only really used when hash collisions occur (very rarely)
  int unsigned idx = 0;

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_syoscb_proxy_item_hash#(HASH_DIGEST_WIDTH))
    `uvm_field_int(digest, UVM_DEFAULT)
    `uvm_field_int(idx,    UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_proxy_item_hash");
    super.new(name);
  endfunction: new

endclass: cl_syoscb_proxy_item_hash
