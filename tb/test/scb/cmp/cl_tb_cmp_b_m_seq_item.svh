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
/// A "b" type item which used a mix of do_compare implementation and field macros
class cl_tb_cmp_a_m_seq_item#(type TIOBJ = cl_tb_seq_item) extends cl_tb_cmp_seq_item_base#(TIOBJ);
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_param_utils_begin(cl_tb_cmp_a_m_seq_item#(TIOBJ))
    `uvm_field_int(ival, UVM_NOCOMPARE)
    `uvm_field_object(iobj, UVM_ALL_ON)
    `uvm_field_array_int(ivals, UVM_ALL_ON)
    `uvm_field_array_object(iobjs, UVM_NOCOMPARE)
  `uvm_object_utils_end


  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_tb_cmp_a_m_seq_item");
    super.new(name);
  endfunction

  //-------------------------------------
  // Class methods
  //-------------------------------------
  extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

endclass: cl_tb_cmp_a_m_seq_item

function bit cl_tb_cmp_a_m_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
  cl_tb_cmp_seq_item_base#(TIOBJ) that;
  do_compare = super.do_compare(rhs, comparer);
  $cast(that, rhs);

  do_compare &= comparer.compare_field_int("ival", this.ival, that.ival, $bits(this.ival));

  if(this.iobjs.size() == that.iobjs.size()) begin
    foreach(this.iobjs[i]) begin
      do_compare &= comparer.compare_object($sformatf("iobjs[%0d]", i), this.iobjs[i], that.iobjs[i]);
    end
  end else begin
    do_compare &= 0;
  end
endfunction: do_compare