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
///SCBs test using a parameterized sequence item and filter transforms.
class cl_scbs_test_filter_trfm_param extends cl_scbs_test_base#(cl_tb_seq_item_par#(8), cl_tb_tlm_monitor_param#(cl_tb_seq_item_par#(8)));
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scbs_test_filter_trfm_param)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scbs_test_filter_trfm_param", uvm_component parent = null);

  //-------------------------------------
  // Functions
  //-------------------------------------


endclass: cl_scbs_test_filter_trfm_param

function cl_scbs_test_filter_trfm_param::new(string name = "cl_scbs_test_filter_trfm_param", uvm_component parent = null);
  super.new(name, parent);
endfunction: new