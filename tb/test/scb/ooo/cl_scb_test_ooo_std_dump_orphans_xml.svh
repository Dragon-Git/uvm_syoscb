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
/// Dumping orphans to files using XML printout
// Does so by setting cl_syoscb_cfg#orphan_dump_type to XML, overriding printer configurations
class cl_scb_test_ooo_std_dump_orphans_xml extends cl_scb_test_ooo_std_dump_orphans;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_ooo_std_dump_orphans_xml)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_ooo_std_dump_orphans_xml", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();


endclass: cl_scb_test_ooo_std_dump_orphans_xml

function void cl_scb_test_ooo_std_dump_orphans_xml::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_orphan_dump_type(pk_syoscb::XML);
endfunction: pre_build