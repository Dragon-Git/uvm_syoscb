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
`ifndef __PK_SYOSCB_SV__
`define __PK_SYOSCB_SV__

/// @mainpage
/// User and implementation documentation for the UVM scoreboard
///
/// This documentation provides the following additional documentation, besides
/// the normal source code documentation:
///
///   -# Getting started: \ref pGettingStarted
///   -# How to integrate the UVM scoreboard: \ref pIntegration
///   -# Implementation notes: \ref pImplementationNotes
///
/// It is assumed that the reader is familiar with the UVM scoreboard architecture
/// described in the SyoSil paper on the subject: Versatile UVM Scoreboarding located in
/// in the <b>docs</b> directory.
///
/// @page pGettingStarted Getting started
/// This software package also provides some simple examples beside the source code for the UVM scoreboard. Before starting to integrate the UVM scoreboard into your own code then it might be beneficial to look at the provided examples. An example testbench is placed in the <b>tb</b> directory and the tests are in the <b>tb/test</b> directory.
///
/// To run the examples you need to select a Vendor since the examples can be run with all of the three major SystemVerilog simulator vendors: Mentor Graphics, Cadence and Synopsys. See <b>README.txt</b> for a description of how to select the vendor.
///
/// Once the vendor has been selected then the available Make targets for that vendor can be listed by typing: "make". Typically, you run the simulation with: <b>make sim</b>.
///
/// In general you can type: <b>make help</b> to get information about what Make options are available.
///
/// @page pIntegration How to integrate the UVM scoreboard
/// The UVM scoreboard is easily integrated into your existing testbench environment.
///
/// @section sCompile Compiling the UVM scoreboard
/// To get the UVM scoreboard compiled you need to add <b>src/pk_syoscb.sv</b> to your list of files that are complied when compiling your testbench. How this is done is highly dependent on the verification environment since some environments compile everything into different libraries and some do not etc.
///
/// @section sAcccess Accessing the UVM scoreboard from your own code
/// Once the UVM scoreboard is compiled with the verification environment then it is accessible either by explicit scoping:
///
/// @code
///   class myclass;
///     pk_syoscb::cl_syoscb my_new_scb;
///     ...
/// @endcode
///
/// or by importing the complete package into your scope:
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
/// The UVM scoreboard itself needs to be instantiated along with the configuration object. The simplest way to to this is to add the UVM scoreboard and the configuration object to the UVM environment - note that the configuration object is passed to the scoreboard via the config_db:
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
///     // Create the scoreboard configuration object
///     this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");
///
///     // Pass the scoreboard configuration object to the config_db
///     uvm_config_db #(cl_syoscb_cfg)::set(this, "syoscb", "cfg", this.syoscb_cfg);
///
///     // Create the scoreboard
///     this.syoscb = cl_syoscb::type_id::create("syoscb", this);
///   
///     ...
///               
///   endfunction: build_phase
/// @endcode
///
/// @section sConfiguration Configuring the UVM scoreboard
/// The UVM scoreboard configuration object needs to be configured after it has been created. The following example shows how two queues Q1 and Q2 wit Q1 as the primary queue. Furthermore, one producer P1 is added to both queues:
///
/// @code
///   function void cl_scbtest_env::build_phase(uvm_phase phase);
///     super.build_phase(phase);
///   
///     // Create the scoreboard configuration object
///     this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");
///
///     // Configure the scoreboard
///     this.syoscb_cfg.set_queues({"Q1", "Q2"});
///     void'(this.syoscb_cfg.set_primary_queue("Q1")); 
///     void'(this.syoscb_cfg.set_producer("P1", {"Q1", "Q2"})); 
///
///     // Pass the scoreboard configuration object to the config_db
///     uvm_config_db #(cl_syoscb_cfg)::set(this, "syoscb", "cfg", this.syoscb_cfg);
///
///     // Create the scoreboard
///     this.syoscb = cl_syoscb::type_id::create("syoscb", this);
///               
///     ...
///
///   endfunction: build_phase
/// @endcode
///
/// @section sFunctionAPIHookUp Function based API hook up
/// The function based API is very easy to use once you have done the configuration and instantiation
/// of the scoreboard as describe above.
///
/// Whenever you need to add an UVM sequence item to a queue produced by a specified producer then you simply
/// invoke the cl_syoscb::add_item() method:
///
/// @code
///   // *NOTE*: Assumes syoscb is handle to an instance of the scoreboard and
///   //         item1 is a handle to a UVM sequence item
///
///   ...
///
///   // Insert UVM sequence item for queue: Q1, for producer: P1
///   syoscb.add_item("Q1", "P1", item1);
/// @endcode
///
/// Invoking the cl_syoscb::add_item() method will simply wrap the UVM sequence item in a cl_syoscb_item object, add it the correct queue
/// and finally invoke the configured compare method.
///
/// The UVM environment will typically contain a handle to the scoreboard as described above. This can then be utilized if UVM sequences
/// needs to be added from a test case:
///
/// @code
///   class cl_scbtest_seq_item extends uvm_sequence_item;
///     //-------------------------------------
///     // Randomizable variables
///     //-------------------------------------
///     rand int unsigned int_a;
///   
///     //-------------------------------------
///     // UVM Macros
///     //-------------------------------------
///     `uvm_object_utils_begin(cl_scbtest_seq_item)
///       `uvm_field_int(int_a, UVM_ALL_ON)
///     `uvm_object_utils_end
///   
///     //-------------------------------------
///     // Constructor
///     //-------------------------------------
///     function cl_scbtest_seq_item::new (string name = "cl_scbtest_seq_item");
///        super.new(name);
///     endfunction
///   endclass: cl_scbtest_seq_item
///
///   class cl_scbtest_test extends uvm_test;
///     //-------------------------------------
///     // Non randomizable variables
///     //-------------------------------------
///     cl_scbtest_env scbtest_env;
///   
///     //-------------------------------------
///     // UVM Macros
///     //-------------------------------------
///     `uvm_component_utils(cl_scbtest_test)
///   
///     //-------------------------------------
///     // Constructor
///     //-------------------------------------
///     function new(string name = "cl_scbtest_test", uvm_component parent = null);
///       super.new(name, parent);
///     endfunction: new
///   
///     //-------------------------------------
///     // UVM Phase methods
///     //-------------------------------------
///     function void build_phase(uvm_phase phase);
///       super.build_phase(phase);
///       scbtest_env = cl_scbtest_env::type_id::create("scbtest_env", this);
///     endfunction: build_phase
///   
///     task run_phase(uvm_phase phase);
///       super.run_phase(phase);
///       begin
///         cl_scbtest_seq_item item1;
///         item1 = cl_scbtest_seq_item::type_id::create("item1");
///         item1.int_a = 'h3a;
///         scbtest_env.syoscb.add_item("Q1", "P1", item1);
///       end
///       begin
///         cl_scbtest_seq_item item1;
///         item1 = cl_scbtest_seq_item::type_id::create("item1");
///         item1.int_a = 'h3a;
///         scbtest_env.syoscb.add_item("Q2", "P1", item1);
///       end
///     endtask: run_phase
///   endclass: cl_scbtest_test
/// @endcode
///
/// @section sTLMAPIHookUp TLM based API hook up
/// The TLM API is even easier to use than the function based API. The scoreboard provides generic UVM subscribers which
/// can be connected to anything which has a UVM analysis port (e.g. a UVM monitor). Typically, the UVM agents inside the UVM environment
/// contain one or more monitors with UVM analysis ports which should be connected to the scoreboard. The following example has two agents which
/// each has a monitor. The monitors are connected to Q1 and Q2 in the scoreboard:
///
/// @code
///   import pk_syoscb::*;
///
///   class cl_scbtest_env extends uvm_env;
///
///     cl_syoscb     syoscb;   
///     cl_syoscb_cfg syoscb_cfg;
///     myagent       agent1;
///     myagent       agent2;
///
///     ...
///
///     function void build_phase(uvm_phase phase);
///       
///       ...     
///
///       // Configure and create the scoreboard
///       // Create and configure the agents
///       
///       ...     
///
///     endfunction: build_phase
///
///     ...
///
///     function void connect_phase(uvm_phase phase);
///       super.connect_phase(phase);
///
///       begin
///         cl_syoscb_subscriber subscriber;
///
///         // Get the subscriber for Producer: P1 for queue: Q1 and connect it
///         // to the UVM monitor producing transactions for this queue
///         subscriber = this.syoscb.get_subscriber("Q1", "P1");
///         this.agent1.mon.<analysis port>.connect(subscriber.analysis_export);
///
///         // Get the subscriber for Producer: P1 for queue: Q2 and connect it
///         // to the UVM monitor producing transactions for this queue
///         subscriber = this.syoscb.get_subscriber("Q2", "P1");
///         this.agent1.mon.<analysis port>.connect(subscriber.analysis_export);
///       end
///     endfunction: connect_phase
///   @endcode
///  
/// @section sFactory Factory overwrites
/// Finally, the wanted queue and compare algorithm implementation needs to be selected. This is done by factory overwrites since they can be changed test etc.
///
/// <B>NOTE: This MUST be done before creating the scoreboard!</B>
///
/// The following queue implementations are available:
///
///   -# Standard SV queue (cl_syoscb_queue_std)
///
/// and the following compare algorithms are available:
///
///   -# Out-of-Order (cl_syoscb_compare_ooo)
///   -# In-Order (cl_syoscb_compare_io)
///   -# In-Order by producer (cl_syoscb_compare_iop)
///
/// The following example shows how they are configured:
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
///
/// The full build phase, including the factory overwrites, of cl_scbtest_env is shown here for completeness:
///
/// @code
///   function void cl_scbtest_env::build_phase(uvm_phase phase);
///     super.build_phase(phase);
///
///     // Use the standard SV queue implementation as scoreboard queue
///     cl_syoscb_queue::set_type_override_by_type(cl_syoscb_queue::get_type(),              
///                                                cl_syoscb_queue_std::get_type(),
///                                                "*");
///
///     // Set the compare strategy to be OOO
///     factory.set_type_override_by_type(cl_syoscb_compare_base::get_type(),
///                                       cl_syoscb_compare_ooo::get_type(),
///                                       "*");
///
///     // Create the scoreboard configuration object
///     this.syoscb_cfg = cl_syoscb_cfg::type_id::create("syoscb_cfg");
///
///     // Configure the scoreboard
///     this.syoscb_cfg.set_queues({"Q1", "Q2"});
///     void'(this.syoscb_cfg.set_primary_queue("Q1")); 
///     void'(this.syoscb_cfg.set_producer("P1", {"Q1", "Q2"})); 
///
///     // Pass the scoreboard configuration object to the config_db
///     uvm_config_db #(cl_syoscb_cfg)::set(this, "syoscb", "cfg", this.syoscb_cfg);
///
///     // Create the scoreboard
///     this.syoscb = cl_syoscb::type_id::create("syoscb", this);
///               
///     ...
///
///   endfunction: build_phase
/// @endcode
///
/// @page pImplementationNotes Implementation notes
///
/// @section sAPIs Implementation APIs
///
/// The following APIs have been defined for easy extension fo the scoreboard classes:
///
///   -# Configuration API: cl_syoscb_cfg
///   -# Item API: cl_syoscb_item
///   -# Queue API: cl_syoscb_queue
///   -# Compare API: cl_syoscb_compare_base
///   -# Subscriber API: cl_syoscb_subscriber
///   -# Iterator API: cl_syoscb_queue_iterator_base
///
/// @section sGeneralErrorHandling General error handling
/// In general when a lower level method detects an error then two concepts are used. Primarily, the method will either issue a UVM info with some information about what went wrong or issue a UVM error/fatal immediately. The first one will then return <b>1'b0</b> to signal that something went wrong. Thus, it is up to the parent levels to catch the error and convert them into UVM errors/fatals etc. This method was chosen since the parent level typically provides more and better information when things go wrong. 
/// @section sErrorCategories Error categories
/// There are several ERROR categories. The following table lists them with some explanation:
///
///  <table>
///  <tr>
///    <th>Error Category</th>
///    <th>Description</th>
///  </tr>
///  <tr>
///    <td>IMPL_ERROR</td>
///    <td>Implementation error. Something is really broken</td>
///  </tr>
///  <tr>
///    <td>QUEUE_ERROR</td>
///    <td>A queue related error, e.g. the queue could not be found</td>
///  </tr>
///  <tr>
///    <td>CFG_ERROR</td>
///    <td>Configuration error. Usually, because the configuration object is missing</td>
///  </tr>
///  <tr>
///    <td>TYPE_ERROR</td>
///    <td>Type error. Typically issued when $cast() fails</td>
///  </tr>
///  <tr>
///    <td>COMPARE_ERROR</td>
///    <td>Compare error. Issued, e.g. when the in order compare fails</td>
///  </tr>
///  <tr>
///    <td>SUBSCRIBER_ERROR</td>
///    <td>Subscriber error. Issued, e.g. when the call to cl_syoscb::get_subscriber() fails</td>
///  </tr>
///  </table>
///   
/// @section sMultipleQueueRefs Multiple queue references
/// Both the top level class cl_syoscb and the configuration class cl_syoscb_cfg contains
/// handles to all queues. The former uses an ordinary array which provides a fast way of
/// looping over the queues and the latter an associative which makes it easy to find
/// a queue using only its name.

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
  typedef class cl_syoscb_cfg;
  typedef class cl_syoscb_queue;

  ////////////////////////////////////////////////////////////////////////////
  // Package source files
  ////////////////////////////////////////////////////////////////////////////
  `include "cl_syoscb_cfg_pl.svh"
  `include "cl_syoscb_cfg.svh"
  `include "cl_syoscb_item.svh"
  `include "cl_syoscb_queue_iterator_base.svh"
  `include "cl_syoscb_queue_iterator_std.svh"
  `include "cl_syoscb_queue.svh"
  `include "cl_syoscb_queue_std.svh"
  `include "cl_syoscb_compare_base.svh"
  `include "cl_syoscb_compare.svh"
  `include "cl_syoscb_compare_ooo.svh"
  `include "cl_syoscb_compare_io.svh"
  `include "cl_syoscb_compare_iop.svh"
  `include "cl_syoscb_report_catcher.svh"
  `include "cl_syoscb_subscriber.svh"
  `include "cl_syoscb.svh"
endpackage: pk_syoscb

`endif //  __PK_SYOSCB_SV__