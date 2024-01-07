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
/// Base class for all comapre algorithms
class cl_syoscb_compare_base extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  /// Handle to the configuration
  protected cl_syoscb_cfg cfg;
  
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_compare_base)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_compare_base");

  //-------------------------------------
  // Compare API
  //-------------------------------------
  extern virtual function void compare();
  extern virtual function void compare_do();
  extern function void set_cfg(cl_syoscb_cfg cfg);
  extern function cl_syoscb_cfg get_cfg();
  extern function string get_primary_queue_name();   
endclass: cl_syoscb_compare_base

function cl_syoscb_compare_base::new(string name = "cl_syoscb_compare_base");
   super.new(name);
endfunction: new

/// <b>Compare API</b>: This method is the compare algorithms public compare method. It is called when the
/// compare algorithm is asked to do a compare. Typically, this method is used to check state variables etc. to compute if the compare shall be done or not. If so then do_compare() is called.
///
/// <b>NOTE:</b> This method must be implemented.
function void cl_syoscb_compare_base::compare();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_compare_base::compare() *MUST* be overwritten", this.cfg.get_scb_name()));
endfunction

/// <b>Compare API</b>: Does the actual compare.
/// <b>NOTE:</b> This method must be implemted.
function void cl_syoscb_compare_base::compare_do();
  `uvm_fatal("IMPL_ERROR", $sformatf("[%s]: cl_syoscb_compare_base::compare_do() *MUST* be overwritten", this.cfg.get_scb_name()));
endfunction

/// <b>Compare API</b>: Passes the configuration object on to the compare algorithm for faster access.
function void cl_syoscb_compare_base::set_cfg(cl_syoscb_cfg cfg);
  this.cfg = cfg;
endfunction: set_cfg

/// <b>Compare API</b>: Returns the configuration object
function cl_syoscb_cfg cl_syoscb_compare_base::get_cfg();
  return(this.cfg);
endfunction: get_cfg

/// <b>Compare API</b>: Gets the primary queue. Convinience method.
function string cl_syoscb_compare_base::get_primary_queue_name();
  cl_syoscb_cfg ch = this.get_cfg();

  return(ch.get_primary_queue());
endfunction: get_primary_queue_name
