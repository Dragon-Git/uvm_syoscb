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
/// Queue iterator class defining the iterator API used for iterating md5 hash queues.
class cl_syoscb_queue_iterator_hash_md5 extends cl_syoscb_queue_iterator_hash#(pk_syoscb::MD5_HASH_DIGEST_WIDTH);

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_queue_iterator_hash_md5)
  `uvm_object_utils_end

  function new(string name = "cl_syoscb_queue_iterator_hash_md5");
    super.new(name);
  endfunction: new

endclass: cl_syoscb_queue_iterator_hash_md5
