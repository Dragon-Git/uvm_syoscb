//----------------------------------------------------------------------
//   Copyright 2014-2015 SyoSil ApS
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
`ifndef __PK_SCBTEST_SV__
`define __PK_SCBTEST_SV__

package pk_scbtest;

  import uvm_pkg::*;
  import pk_syoscb::*;
  
  `include "uvm_macros.svh"
  `include "cl_scbtest_env.svh"
  `include "cl_scbtest_seq_item.svh"
  `include "cl_scbtest_test_base.svh"
  `include "cl_scbtest_test_ooo_simple.svh"
  `include "cl_scbtest_test_io_simple.svh"
  `include "cl_scbtest_test_iop_simple.svh"
  `include "cl_scbtest_test_ooo_heavy.svh"
  `include "cl_scbtest_test_ooo_tlm.svh"
  `include "cl_scbtest_test_ooo_gp.svh"
  `include "cl_scbtest_test_ooo_io_simple.svh"
   
endpackage: pk_scbtest

`endif // __PK_SCBTEST_SV__

