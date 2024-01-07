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
`ifndef __PK_SYOSCB_SV__
`define __PK_SYOSCB_SV__

package pk_syoscb;
  ////////////////////////////////////////////////////////////////////////////
  // Imported packages
  ////////////////////////////////////////////////////////////////////////////
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  ////////////////////////////////////////////////////////////////////////////
  // Package source files
  ////////////////////////////////////////////////////////////////////////////
  `include "syoscb_common.svh"
  `include "uvm_xml_printer.svh"
  `include "cl_syoscb_hash_packer.svh"
  `include "cl_syoscb_md5_packer.svh"
  `include "cl_syoscb_printer_config.svh"
  `include "cl_syoscb_comparer_config.svh"


  `include "cl_syoscb_cfg_pl.svh"
  typedef class cl_syoscb_queue_base;  //Must forward declare queue_base for cfg
  `include "cl_syoscb_cfg.svh"
  `include "cl_syoscbs_cfg.svh"
  `include "cl_syoscb_item.svh"
  `include "cl_syoscb_hash_item.svh"
  `include "cl_syoscb_hash_base.svh"
  `include "cl_syoscb_hash_md5.svh"
  `include "cl_syoscb_hash_aa_wrapper.svh"

  `include "cl_syoscb_string_library.svh"



  `include "cl_syoscb_proxy_item_base.svh"
  `include "cl_syoscb_proxy_item_std.svh"
  `include "cl_syoscb_proxy_item_hash.svh"

  `include "cl_syoscb_queue_locator_base.svh"
  `include "cl_syoscb_queue_iterator_base.svh"
  `include "cl_syoscb_queue_base.svh"
  `include "cl_syoscb_queue_hash.svh"

  typedef class cl_syoscb_queue_std;             //Must forward declare queue_std for locator_std for iterator_std
  `include "cl_syoscb_queue_iterator_std.svh"
  `include "cl_syoscb_queue_iterator_hash.svh"
  `include "cl_syoscb_queue_iterator_hash_md5.svh"


  `include "cl_syoscb_queue_locator_std.svh"
  `include "cl_syoscb_queue_locator_hash.svh"
  `include "cl_syoscb_queue_locator_hash_md5.svh"

  `include "cl_syoscb_queue_std.svh"
  `include "cl_syoscb_queue_hash_md5.svh"

  `include "cl_syoscb_compare_base.svh"
  `include "cl_syoscb_compare.svh"
  `include "cl_syoscb_compare_ooo.svh"
  `include "cl_syoscb_compare_io.svh"
  `include "cl_syoscb_compare_io_2hp.svh"
  `include "cl_syoscb_compare_iop.svh"

   typedef class cl_syoscb;
  `include "cl_syoscb_subscriber.svh"

  `include "cl_syoscb.svh"
  `include "cl_syoscbs_base.svh"
  `include "cl_syoscbs.svh"
endpackage: pk_syoscb

`endif //  __PK_SYOSCB_SV__
