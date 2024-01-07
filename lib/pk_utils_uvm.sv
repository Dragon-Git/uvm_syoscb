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
// ------------------------------------------------------------------------
// Classes for UVM utilities
// ------------------------------------------------------------------------
`ifndef __UTILS_UVM__
`define __UTILS_UVM__
package pk_utils_uvm;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  /// Base class for a filter transformation.
  /// If type IN is a subtype of uvm_sequence_item, this filter transforms simply performs
  /// an identity transform by upcasting the input item to a uvm_sequence_item
  /// If another transformation is desired, extend the class and override the #evaluate
  /// and #transform methods
  /// \param IN Input type of objects to transform
  /// \param OUT Output type of transformed objects
  class filter_trfm #(type IN = int, type OUT = uvm_sequence_item) extends uvm_subscriber #(IN);
    /// Analysis port where transformed items are output
    uvm_analysis_port#(OUT) ap;

    //--------------------------------------
    // UVM macros
    //--------------------------------------
    `uvm_component_param_utils(filter_trfm#(IN, OUT))

    //--------------------------------------
    // Constructor
    //--------------------------------------
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);

      this.ap = new("ap", this);
    endfunction : new

    /// Transforms the item of type IN to one or more items of type OUT
    /// \param t The input object which should be transformed
    /// \param items A reference to an array where output items will be returned.
    ///              If the handle is to an existing array, that array will be lost.
    virtual function void transform(IN t, output OUT items[]);
      items = new[1];

      items[0] = t;
    endfunction : transform

    /// Evaluates whether the input should be transformed and forwarded, or whether it should be discarded.
    /// If the method returns 0, the input item is discarded and may not be retrievable
    /// \return 1 if the item should be transformed and forwarded, 0 otherwise.
    virtual function bit evaluate(IN t);
      return(1'b1);
    endfunction : evaluate

    /// This filter transform's write-implementation from uvm_subscriber
    /// When items are written to the filter transform, they are first evaluated with #evaluate to
    /// decide whether a transformation should occur. If true, they are transformed with
    /// #transform, and all output items are then written out on #ap
    /// \param t The item written to this filter transform
    function void write(IN t);
      if(this.evaluate(t) == 1'b1) begin
        OUT items[];

        this.transform(t, items);

        foreach (items[i]) begin
          this.ap.write(items[i]);
        end
      end
    endfunction : write
  endclass : filter_trfm
endpackage : pk_utils_uvm
`endif // __UTILS_UVM__
