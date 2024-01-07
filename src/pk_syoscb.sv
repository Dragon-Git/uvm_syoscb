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
`ifndef __PK_SYOSCB_SV__
`define __PK_SYOSCB_SV__

/// @mainpage
/// User and implementationd documentation for the UVM scoreboard
///
/// This documentation provides the following additional documentation, besides
/// the normal source code documentation:
///
///   -# How to integrate the UVM scoreboard: \ref pIntegration
///
/// It is assumed that the reader is familiar with the UVM scoreboard arcitechture
/// described in: TBD: Added ref to paper!

/// @page pIntegration How to integrate the UVM scoreboard
/// The UVM scorebaord is easily integrated into your existing testbench environment.
///
/// @section sCompile Compiling the UVM scoreboard
/// To get the UVM scoreboard compiled you need to add src/pk_syoscb.sv to your list of files that are compliled when compiling your testbench. How this is done is highly dependent on the verification environment since some environemnts compile everything into different libraries and some do not etc.
///
/// @section sAcccess Accessing the UVM scoreboard from your own code
/// Once the UVM scoreboard is compiled with the veritication environment then it is accessible either by explicit scoping:
///
/// @code
///   class myclass;
///     pk_syoscb::cl_syoscb my_new_scb;
///     ...
/// @endcode
///
/// or by importing the complte package into your scope:
///
/// @code
///   import pk_syoscb::*;
///
///   class myclass;
///     cl_syoscb my_new_scb;
///     ...
/// @endcode
///
/// @section sInstantiation Instantiating the UVM scoreboard
/// The UVM scoreboard itself needs to be instantiated along with the configuration object. The simplest way to to this is to add the UVM scorebaord and the configuration object to the UVM environment:
///
/// @code
///   import pk_syoscb::*;
///
///   class cl_scbtest_env extends uvm_env;
///
///     cl_syoscb     syoscb;   
///     cl_syoscb_cfg syoscb_cfg;
///    
///     `uvm_component_utils_begin(cl_scbtest_env)
///       `uvm_field_object(syoscb,     UVM_ALL_ON)
///       `uvm_field_object(syoscb_cfg, UVM_ALL_ON)
///     `uvm_component_utils_end
///    
///     ... 
///
///   endclass: cl_scbtest_env
///
///   function void cl_scbtest_env::build_phase(uvm_phase phase);
///     super.build_phase(phase);
///   
///     this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");
///     this.syoscb = cl_syoscb::type_id::create("syoscb", this);
///   
///     ...
///               
///   endfunction: build_phase
/// @endcode
///
/// @section sConfiguration Configuring the UVM scoreboard
/// The UVM scoreboard ocnfiguration object needs to be configured after it has been created. The following example shows how two queues Q1 and Q2 wit Q1 as the primary queue. Futhermore one producer P1 is added to both queues:
///
/// @code
///   function void cl_scbtest_env::build_phase(uvm_phase phase);
///     super.build_phase(phase);
///   
///     this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");
///     this.syoscb = cl_syoscb::type_id::create("syoscb", this);
///   
///     this.syoscb_cfg.set_queues({"Q1", "Q2"});
///     void'(this.syoscb_cfg.set_primary_queue("Q1")); 
///     void'(this.syoscb_cfg.set_producer("P1", {"Q1", "Q2"})); 
///               
///     ...
///
///   endfunction: build_phase
/// @endcode
///
/// @section sFactory Factory overwrites
/// Finally, the wanted queue and compare algorithm implementation needs to be selected. This is done by facotry overwrites since they can be changed test etc.
///
/// The following queue implemenations are available:
///
///   -# Standard SV squeue (cl_syoscb_queue_std)
///
/// and the following compare alorithms are available:
///
///  -# Out-of-Order (cl_syoscb_compare_ooo)
///
/// The folloing example shows how they are configured:
///
/// @code
///   cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
///                                              cl_syoscb_queue_std::get_type(),
///                                              "*");
///
///   factory.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
///                                     cl_syoscb_compare_ooo::get_type(),
///                                     "*");
/// @endcode

package pk_syoscb;

  ////////////////////////////////////////////////////////////////////////////
  // Imported packages
  ////////////////////////////////////////////////////////////////////////////

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  ////////////////////////////////////////////////////////////////////////////
  // Type definitions
  ////////////////////////////////////////////////////////////////////////////

  typedef class cl_syoscb;
  typedef class cl_syoscb_queue;

  ////////////////////////////////////////////////////////////////////////////
  // Package source files
  ////////////////////////////////////////////////////////////////////////////

  `include "cl_syoscb_item.svh"
  `include "cl_syoscb_queue_iterator_base.svh"
  `include "cl_syoscb_queue_iterator_std.svh"
  `include "cl_syoscb_queue.svh"
  `include "cl_syoscb_queue_std.svh"
  `include "cl_syoscb_cfg_pl.svh"
  `include "cl_syoscb_cfg.svh"
  `include "cl_syoscb_compare_base.svh"
  `include "cl_syoscb_compare.svh"
  `include "cl_syoscb_compare_ooo.svh"
  `include "cl_syoscb_report_catcher.svh"
  `include "cl_syoscb.svh"


endpackage : pk_syoscb

`endif //  __PK_SYOSCB_SV__