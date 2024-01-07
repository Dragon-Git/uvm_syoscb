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
/// An XML printer for cl_syoscb_items
class uvm_xml_printer extends uvm_printer;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  int unsigned indent_level;
  local string spaces = "                                                                                ";

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new();
    super.new();
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  //uvm_printer functions
  extern virtual function string emit();

  //Helper functions for formatting data
  `ifdef UVM_VERSION // UVM-IEEE version
    extern virtual function string format_syoscb_item(uvm_printer_element element);
    extern virtual function string format_primitive(uvm_printer_element element);
    extern virtual function string format_object(uvm_printer_element element);
    extern virtual function string format_array(uvm_printer_element element);

    extern virtual function bit    is_primitive(uvm_printer_element element);
    extern virtual function bit    is_object(uvm_printer_element element);
    extern virtual function bit    is_array(uvm_printer_element element);
  `else
    extern virtual function string         format_syoscb_item(int unsigned idx);
    extern virtual function int unsigned   format_object(int unsigned idx, ref string result);
    extern virtual function int unsigned   format_primitive(int unsigned idx, ref string result);
    extern virtual function int unsigned   format_array(int unsigned idx, ref string result);

    extern virtual function bit            is_primitive(uvm_printer_row_info row);
    extern virtual function bit            is_object(uvm_printer_row_info row);
    extern virtual function bit            is_array(uvm_printer_row_info row);
  `endif

  //Internal helper functions
  extern virtual function void   increase_indent(int unsigned steps = 1);
  extern virtual function void   decrease_indent(int unsigned steps = 1);
  extern virtual function string get_indent();

endclass: uvm_xml_printer

// BEGIN UVM-IEEE IMPLEMENTATATION
`ifdef UVM_VERSION
function string uvm_xml_printer::emit();
  string result;
  indent_level = 0;

  result = this.format_syoscb_item(this.get_bottom_element());

  return result;
endfunction: emit

/// Formats a cl_syoscb_item and all of its children.
/// \param element The element representing the cl_syoscb_item
/// \return        The XML formatted string of this cl_syoscb_item
function string uvm_xml_printer::format_syoscb_item(uvm_printer_element element);
  string result, producer, queue_index, insertion_index, inst;
  uvm_printer_element children[$];
  static uvm_printer_element_proxy proxy = new("proxy");

  proxy.get_immediate_children(element, children);

  //Perform preliminary error checks to ensure that the uvm_xml_printer is being invoked on a cl_syoscb_item
  if (element.get_element_type_name() != "cl_syoscb_item") begin
    `uvm_warning("XML_PRINT", $sformatf({"The uvm_xml_printer is only meant to be invoked on items of type cl_syoscb_item. ",
    "This item has type %s. Formatting as a uvm_sequence_item instead. This breaks the built-in XML transformations."}, element.get_element_type_name()))
    return this.format_object(element);
  end else if (children[0].get_element_name() != "insertion_index" ||
    children[1].get_element_name() != "queue_index" ||
    children[2].get_element_name() != "producer") begin
      `uvm_warning("XML_PRINT", $sformatf({"cl_syoscb_item metadata fields must be in the order [insertion_index, queue_index, producer]. ",
      "This item had order [%s, %s, %s]"}, children[0].get_element_type_name(), children[1].get_element_type_name(), children[2].get_element_type_name()))
      return "";
  end

  inst = element.get_element_name();
  insertion_index = children[0].get_element_value();
  queue_index = children[1].get_element_value();
  producer = children[2].get_element_value();

  result = $sformatf("<item inst=\"%s\" producer=\"%s\" queue_index=\"%s\" insertion_index=\"%s\">\n",
                      inst,
                      producer,
                      queue_index,
                      insertion_index.substr(2, insertion_index.len()-1)); //Using substr[2..len-1] to strip out leading 'd

  this.increase_indent();
  result = {result, this.format_object(children[3])};
  this.decrease_indent();
  result = {result, "</item>\n"};

  return result;
endfunction: format_syoscb_item

/// Formats a sequence item/object, and recursively formats all children of this seq item
/// \param element The element being formatted
/// \return        The formatted string for this object and all of its children
function string uvm_xml_printer::format_object(uvm_printer_element element);
  string result;
  uvm_printer_element children[$];
  static uvm_printer_element_proxy proxy = new("proxy");

  proxy.get_immediate_children(element, children);

  result = $sformatf("%s<member_object name=\"%s\" type=\"%s\">\n",
                      this.get_indent(),
                      element.get_element_name(),
                      element.get_element_type_name());

  if(element.get_element_value() == "<null>") begin
    this.increase_indent();
    result = {result, $sformatf("%s<null/>\n", this.get_indent())};
    this.decrease_indent();
    result = {result, $sformatf("%s</member_object>\n", this.get_indent())};
    return result;
  end

  this.increase_indent();
  result = {result, $sformatf("%s<members>\n", this.get_indent())};
  this.increase_indent();

  foreach(children[i]) begin
    if(is_primitive(children[i])) begin
      result = {result, this.format_primitive(children[i])};
    end else if (is_object(children[i])) begin
      result = {result, this.format_object(children[i])};
    end else if (is_array(children[i])) begin
      result = {result, this.format_array(children[i])};
    end else begin //It's most likely an enum if this is the case, can be formatted as a primitive
      result = {result, this.format_primitive(children[i])};
    end
  end

  this.decrease_indent();
  result = {result, $sformatf("%s</members>\n", this.get_indent())};
  this.decrease_indent();
  result = {result, $sformatf("%s</member_object>\n", this.get_indent())};

  return result;
endfunction: format_object

/// Formats an array and all of its children
/// \param element The element representing the array to format
/// \return        The formatted string for this array and all children
function string uvm_xml_printer::format_array(uvm_printer_element element);
  string result, member_array;
  uvm_printer_element children[$];
  static uvm_printer_element_proxy proxy = new("proxy");

  proxy.get_immediate_children(element, children);

  result = $sformatf("%s<member_array name=\"%s\" type=\"%s\" size=\"%s\">\n", this.get_indent(), element.get_element_name(), element.get_element_type_name(), element.get_element_size());

  if(element.get_element_size() == "0") begin
    result = {result, $sformatf("%s</member_array>\n", this.get_indent())};
    return result;
  end

  this.increase_indent();
  result = {result, $sformatf("%s<values>\n", this.get_indent())};
  this.increase_indent();

  foreach(children[i]) begin
    result = {result, $sformatf("%s<value>\n", this.get_indent())};
    this.increase_indent();
    if(is_primitive(children[i])) begin
      result = {result, this.format_primitive(children[i])};
    end else if (is_object(children[i])) begin
      result = {result, this.format_object(children[i])};
    end else if (is_array(children[i])) begin
      result = {result, this.format_array(children[i])};
    end else begin //It's most likely an enum if this is the case, can be formatted as a primitive
      result = {result, this.format_primitive(children[i])};
    end
    this.decrease_indent();
    result = {result, $sformatf("%s</value>\n", this.get_indent())};
  end

  this.decrease_indent();
  result = {result, $sformatf("%s</values>\n", this.get_indent())};
  this.decrease_indent();
  result = {result, $sformatf("%s</member_array>\n", this.get_indent())};

  return result;
endfunction: format_array

/// Formats a primitive value
/// \param element The element being formatted
/// \return        That element formatted as XML
function string uvm_xml_printer::format_primitive(uvm_printer_element element);
  return $sformatf("%s<member name=\"%s\" type=\"%s\" size=\"%s\">%s</member>\n",
                    this.get_indent(),
                    element.get_element_name(),
                    element.get_element_type_name(),
                    element.get_element_size(),
                    element.get_element_value());

endfunction: format_primitive

/// Checks whether an element is a SystemVerilog primitive.
/// Here, a "primitive" is one that maps to the UVM printer representations: integral, real, string
/// \param element The element to check against
/// \return        1'b1 if the current element is a primitive, 1'b0 otherwise
function bit uvm_xml_printer::is_primitive(uvm_printer_element element);
  string type_name;
  type_name = element.get_element_type_name();

  return (type_name == "integral") || (type_name == "real") || (type_name == "string");
endfunction: is_primitive

/// Checks whether an element is an array
/// Arrays are recognized as dynamic, associative or static arrays.
/// The UVM printer interprets queues as dynamic arrays
/// \param element The element to check against
/// \return        1 if the current element is an array, 0 otherwise
function bit uvm_xml_printer::is_array(uvm_printer_element element);
  //If type name start with 'da(', 'sa(' or 'aa(' and ends with ')', it's most likely an array
  //If value is also "-", then it must be an array
  string type_name, val;
  type_name = element.get_element_type_name();
  val = element.get_element_value();

  return (type_name.substr(0,2) == "da(" || type_name.substr(0,2) == "aa(" || type_name.substr(0,2) == "sa(") &&
    type_name[type_name.len()-1] == ")" && val[0] == "-";
endfunction: is_array

/// Checks whether an element is an object.
/// \param element The element to check against
/// \return        1 if the current element is an object, 0 otherwise
function bit uvm_xml_printer::is_object(uvm_printer_element element);
  //It is an object if size is "-" and value starts with "@", or if it is null
  string size, val;
  size = element.get_element_size();
  val = element.get_element_value();

  return size == "-" && (val[0] == "@" || val == "<null>");
endfunction: is_object


`else //BEGIN UVM-NON-IEEE IMPLEMENTATION

function string uvm_xml_printer::emit();
  string result;
  indent_level = 0;

  result = this.format_syoscb_item(0);
  m_rows.delete();
  return result;
endfunction: emit

/// Formats a cl_syoscb_item and all of its children. It is assumed
/// that the cl_syoscb_item is at position m_rows[idx]
/// \param idx The id at which this cl_syoscb_item is placed (should always be 0)
/// \return    The XML formatted string
function string uvm_xml_printer::format_syoscb_item(int unsigned idx);
  string result, producer, queue_index, insertion_index, inst;

  //Perform preliminary error checks to ensure that the uvm_xml_printer is being invoked on a correctly formatted cl_syoscb_item
  if(m_rows[idx].type_name != "cl_syoscb_item") begin
    `uvm_warning("XML_PRINT", $sformatf({"The uvm_xml_printer is only meant to be invoked on items of type cl_syoscb_item. ",
    "This item has type %s. Formatting as a uvm_sequence_item instead. This breaks the built-in XML transformations."}, m_rows[idx].type_name))
    void'(this.format_object(idx, result));
    return result;
  end else if(m_rows[idx+1].name != "insertion_index" ||
    m_rows[idx+2].name != "queue_index" ||
    m_rows[idx+3].name != "producer") begin
      `uvm_warning("XML_PRINT", $sformatf({"cl_syoscb_item metadata fields must be in the order [insertion_index, queue_index, producer]. ",
      "This item had order [%s, %s, %s]"}, m_rows[idx+1].name, m_rows[idx+2].name, m_rows[idx+3].name))
      return "";
  end

  inst = m_rows[idx].name;
  insertion_index = m_rows[idx+1].val;
  queue_index = m_rows[idx+2].val;
  producer = m_rows[idx+3].val;
  //At idx+4 is the start of our member_object. This is always the case

  result = $sformatf("<item inst=\"%s\" producer=\"%s\" queue_index=\"%s\" insertion_index=\"%s\">\n",
                      inst,
                      producer,
                      queue_index,
                      insertion_index.substr(2, insertion_index.len()-1)); //Using substr[2..len-1] to strip out leading 'd

  this.increase_indent();
  void'(this.format_object(idx+4, result));
  this.decrease_indent();

  result = {result, "</item>\n"};

  return result;
endfunction: format_syoscb_item

/// Formats a sequence item/object, and recursively formats all children of this seq item
/// \param idx The position in m_rows where this sequence item is located
/// \param     result The result string being built
function int unsigned uvm_xml_printer::format_object(int unsigned idx, ref string result);
  string member_object;
  uvm_printer_row_info row, child;

  row = m_rows[idx];
  member_object = $sformatf("%s<member_object name=\"%s\" type=\"%s\">\n", this.get_indent(), row.name, row.type_name);
  result = {result, member_object};

  if(row.val == "<null>") begin
    this.increase_indent();
    result = {result, $sformatf("%s<null/>\n", this.get_indent())};
    this.decrease_indent();
    result = {result, $sformatf("%s</member_object>\n", this.get_indent())};
    return idx + 1;
  end

  this.increase_indent();
  result = {result, $sformatf("%s<members>\n", this.get_indent())};
  this.increase_indent();

  //Parse all children.
  idx = idx+1;
  while(m_rows[idx].level > row.level && idx < m_rows.size()) begin
    child = m_rows[idx];
    if(is_primitive(child)) begin
      idx = this.format_primitive(idx, result);
    end else if (is_object(child)) begin
      idx = this.format_object(idx, result);
    end else if (is_array(child)) begin
      idx = this.format_array(idx, result);
    end else begin //It's most likely an enum if this is the case, can be formatted as a primitive
      idx = this.format_primitive(idx, result);
    end
  end

  this.decrease_indent();
  result = {result, $sformatf("%s</members>\n", this.get_indent())};
  this.decrease_indent();
  result = {result, $sformatf("%s</member_object>\n", this.get_indent())};

  return idx;
endfunction: format_object

/// Formats an array and all of its children
/// \param idx The position in m_rows where the array is located
/// \param     result The result string being built
function int unsigned uvm_xml_printer::format_array(int unsigned idx, ref string result);
  string member_array;
  uvm_printer_row_info row, child;

  row = m_rows[idx];
  member_array = $sformatf("%s<member_array name=\"%s\" type=\"%s\" size=\"%s\">\n", this.get_indent(), row.name, row.type_name, row.size);
  result = {result, member_array};

  if(row.size == "0") begin
    result = {result, $sformatf("%s</member_array>\n", this.get_indent())};
    return idx+1;
  end

  this.increase_indent();
  result = {result, $sformatf("%s<values>\n", this.get_indent())};
  this.increase_indent();

  idx = idx+1;
  child = m_rows[idx]; //Type of all children is the same, only need to access child once
  while(m_rows[idx].level > row.level && idx < m_rows.size()) begin
    result = {result, $sformatf("%s<value>\n", this.get_indent())};
    this.increase_indent();
    if(is_primitive(child)) begin
      idx = this.format_primitive(idx, result);
    end else if (is_object(child)) begin
      idx = this.format_object(idx, result);
    end else if (is_array(child)) begin
      idx = this.format_array(idx, result);
    end else begin //It's most likely an enum if this is the case, can be formatted as a primitive
      idx = this.format_primitive(idx, result);
    end
    this.decrease_indent();
    result = {result, $sformatf("%s</value>\n", this.get_indent())};
  end

  this.decrease_indent();
  result = {result, $sformatf("%s</values>\n", this.get_indent())};
  this.decrease_indent();
  result = {result, $sformatf("%s</member_array>\n", this.get_indent())};

  return idx;
endfunction: format_array

/// Formats a primitive value
/// \param idx The position in m_rows where the primitive is located
/// \param     result The result being built
function int unsigned uvm_xml_printer::format_primitive(int unsigned idx, ref string result);
  uvm_printer_row_info row;

  row = m_rows[idx];
  result = {result, $sformatf("%s<member name=\"%s\" type=\"%s\" size=\"%s\">%s</member>\n", this.get_indent(), row.name, row.type_name, row.size, row.val)};
  return idx+1;
endfunction: format_primitive


/// Checks whether an element is a SystemVerilog primitive.
/// Here, a "primitive" is one that maps to the UVM printer representations: integral, real, string
/// \param type_name The type name field of the currently parsed element
/// \return          1 if the current element is a primitive, 0 otherwise
function bit uvm_xml_printer::is_primitive(uvm_printer_row_info row);
  string type_name;
  type_name = row.type_name;

  return (type_name == "integral") || (type_name == "real") || (type_name == "string");
endfunction: is_primitive

/// Checks whether an element is an array
/// Arrays are recognized as dynamic, associative or static arrays.
/// The UVM printer interprets queues as dynamic arrays
/// \param type_name The type name field of the currently parsed element
/// \param value     The value field of the currently parsed element
/// \return          1'b1 if the current element is an array, 1'b0 otherwise
function bit uvm_xml_printer::is_array(uvm_printer_row_info row);
  //If type name start with 'da(', 'sa(' or 'aa(' and ends with ')', it's most likely an array
  //If value is "-", then it must be an array
  string type_name, val;
  type_name = row.type_name;
  val = row.val;

  return (type_name.substr(0,2) == "da(" || type_name.substr(0,2) == "aa(" || type_name.substr(0,2) == "sa(") &&
    type_name[type_name.len()-1] == ")" && val[0] == "-";
endfunction: is_array

/// Checks whether an element is an object.
/// \param size The size field of the currently parsed element.
/// \param val  The value field of the currently parsed element
/// \return     1 if the current element is an object, 0 otherwise
function bit uvm_xml_printer::is_object(uvm_printer_row_info row);
  //It is an object if size is "-" and value starts with "@"
  string size, val;
  size = row.size;
  val = row.val;

  return size == "-" && (val[0] == "@" || val == "<null>");
endfunction: is_object


`endif

/// Increases the indentation used by a set amount of steps
/// The size of each step is controlled by knobs.indent
function void uvm_xml_printer::increase_indent(int unsigned steps = 1);
  `ifdef UVM_VERSION
    this.indent_level += this.get_knobs().indent*steps;
  `else
    this.indent_level += this.knobs.indent*steps;
  `endif
endfunction: increase_indent

/// Decreases the indentation used by a set amount of steps
/// The size of each step is controlled by knobs.indent
function void uvm_xml_printer::decrease_indent(int unsigned steps = 1);
  `ifdef UVM_VERSION
    this.indent_level -= this.get_knobs().indent*steps;
  `else
    this.indent_level -= this.knobs.indent*steps;
  `endif
  if(this.indent_level < 0) begin
    this.indent_level = 0;
  end
endfunction: decrease_indent

/// Gets an indentation string consisting of this.indent_level spaces
function string uvm_xml_printer::get_indent();
  return this.spaces.substr(0, indent_level-1);
endfunction: get_indent
