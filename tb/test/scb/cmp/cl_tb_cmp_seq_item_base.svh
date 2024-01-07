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
/// A sequence item to be used in cmp-tests extending from cl_scb_test_cmp_base.
/// \param TIOBJ the type of objects that this class should contain
/// \param MAX_ARRAY_SIZE The maximum size of arrays in the object
class cl_tb_cmp_seq_item_base#(type TIOBJ = cl_tb_seq_item, int unsigned MAX_ARRAY_SIZE = 5) extends uvm_sequence_item;
  //-------------------------------------
  // Member variables
  //-------------------------------------
  rand int ival;
  rand int ivals[];
  rand TIOBJ iobj;
  rand TIOBJ iobjs[];

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils(cl_tb_cmp_seq_item_base#(TIOBJ))


  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_cmp_seq_item_base");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Constraints
  //-------------------------------------
  constraint co_ivals_size {
    this.ivals.size() >= 1;
    this.ivals.size() <= MAX_ARRAY_SIZE;
  }

  constraint co_iobjs_size {
    this.iobjs.size() >= 1;
    this.iobjs.size() <= MAX_ARRAY_SIZE;
  }

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern function void pre_randomize();
endclass: cl_tb_cmp_seq_item_base

function void cl_tb_cmp_seq_item_base::pre_randomize();
  iobj = TIOBJ::type_id::create($sformatf("iobj"));
  ivals = new[MAX_ARRAY_SIZE];
  iobjs = new[MAX_ARRAY_SIZE];
  foreach(iobjs[i]) begin
    iobjs[i] = TIOBJ::type_id::create($sformatf("iobjs_%0d", i));
  end
endfunction: pre_randomize