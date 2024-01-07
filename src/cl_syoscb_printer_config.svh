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
/// Utility class used to perform manipulations of uvm_printer objects.
/// Contains a number of functions that simplify uvm_printer related code, as the printer API
/// differs based on the UVM version used.
/// These functions encapsulate those differences, providing a unified API regardless of UVM version.
class cl_syoscb_printer_config extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_printer_config)

  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_printer_config");

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern static function void             set_file_descriptor(uvm_printer printer, int fd = 0);
  extern static function int              get_file_descriptor(uvm_printer printer);
  extern static function void             copy_printer(uvm_printer from, uvm_printer to);
  extern static function void             set_printer_begin_elements(uvm_printer printer, int elements);
  extern static function void             set_printer_end_elements(uvm_printer printer, int elements);
  extern static function void             do_help_pack(uvm_printer printer, uvm_packer packer);
  extern static function uvm_printer      do_help_unpack(uvm_packer packer);
  extern static function t_printer_type   get_printer_type(uvm_printer printer);
  extern static function uvm_printer      get_printer_of_type(t_printer_type ptype);

endclass: cl_syoscb_printer_config

function cl_syoscb_printer_config::new(string name = "cl_syoscb_printer_config");
  super.new(name);
endfunction: new

/// Sets the file descriptor to be used for a given printer.
/// \param printer The printer on which to set the file descriptor
/// \param fd The file descriptor
function void cl_syoscb_printer_config::set_file_descriptor(uvm_printer printer, int fd = 0);
  `ifdef UVM_VERSION
    printer.set_file(fd);
`else
    printer.knobs.mcd = fd;
`endif
endfunction: set_file_descriptor

/// Gets the file descriptor used for a given printer.
///
/// \param printer The printer for which to get the file descriptor
/// \return The file descriptor used by this printer
function int cl_syoscb_printer_config::get_file_descriptor(uvm_printer printer);
  `ifdef UVM_VERSION
    return printer.get_file();
  `else
    return printer.knobs.mcd;
  `endif
endfunction: get_file_descriptor

/// Gets the type of printer that a given uvm_printer represents.
/// The valid printer types are limited to uvm_table_printer, uvm_line_printer, uvm_tree_printer
/// and uvm_xml_printer.
/// If the given printer does not match one of these 4 types, an error is thrown
///
/// \param printer The printer for which the type should be found
/// \return A SYOSCB_PRINTER_TYPE enum indicating which type of printer was passed
function t_printer_type cl_syoscb_printer_config::get_printer_type(uvm_printer printer);
  uvm_table_printer table_printer;
  uvm_line_printer line_printer;
  uvm_tree_printer tree_printer;
  uvm_xml_printer xml_printer;
  t_printer_type ptype;

  if($cast(table_printer, printer)) begin
    ptype = pk_syoscb::SYOSCB_PRINTER_TABLE;
  end else if ($cast(line_printer, printer)) begin
    ptype = pk_syoscb::SYOSCB_PRINTER_LINE;
  end else if ($cast(tree_printer, printer)) begin
    ptype = pk_syoscb::SYOSCB_PRINTER_TREE;
  end else if ($cast(xml_printer, printer)) begin
    ptype = pk_syoscb::SYOSCB_PRINTER_XML;
  end else begin
    string res;
    ptype = ptype.first();
    res = "Unable to determine printer type as it was not of of ";
    res = {res, $sformatf("%s(%0d)", ptype.name(), ptype)};
    while(ptype != ptype.last()) begin
      ptype = ptype.next();
      res = {res, $sformatf(", %s(%0d)", ptype.name(), ptype)};
    end
    `uvm_fatal("PRINTER", res)
  end

  return ptype;
endfunction: get_printer_type

/// Generates a new printer of the correct type.
/// The type is one of the enum values defined in pk_syoscb::t_printer_type (TABLE, LINE, TREE or XML)
/// If the given enum does not match one of the 4 valid options, an error is thrown
///
/// \param ptype The type of printer which should be generated
/// \return A printer of the indicated type, null if the printer type was not recognized
function uvm_printer cl_syoscb_printer_config::get_printer_of_type(t_printer_type ptype);
  uvm_printer printer;

  case(ptype)
    pk_syoscb::SYOSCB_PRINTER_TABLE: begin
      uvm_table_printer p;
      p = new;
      printer = p;
    end

    pk_syoscb::SYOSCB_PRINTER_TREE: begin
      uvm_tree_printer p;
      p = new;
      printer = p;
    end

    pk_syoscb::SYOSCB_PRINTER_LINE: begin
      uvm_line_printer p;
      p = new;
      printer = p;
    end

    pk_syoscb::SYOSCB_PRINTER_XML: begin
      uvm_xml_printer p;
      p = new;
      printer = p;
    end

    default: begin
      string res;
      t_printer_type loop;

      loop = loop.first();

      res = "Unable to generate a printer object as input type did not match one of ";
      res = {res, $sformatf("%s(%0d)", loop.name(), loop)};

      while(loop != loop.last()) begin
        loop = loop.next();
        res = {res, $sformatf(", %s(%0d)", loop.name(), loop)};
      end
      res = {res, $sformatf(". Got %s(%0d)", ptype.name(), ptype)};
      `uvm_fatal("PRINTER", res)
    end
  endcase

  return printer;
endfunction: get_printer_of_type

/// Copies all config information from one printer to another printer
///
/// \param from Printer containing the data to be copied
/// \param to Printer to inherit configuration data in \c from
function void cl_syoscb_printer_config::copy_printer(uvm_printer from, uvm_printer to);
  `ifdef UVM_VERSION
    to.set_name_enabled(from.get_name_enabled());
    to.set_type_name_enabled(from.get_type_name_enabled());
    to.set_size_enabled(from.get_size_enabled());
    to.set_id_enabled(from.get_id_enabled());
    to.set_radix_enabled(from.get_radix_enabled());
    to.set_radix_string(UVM_DEC,      from.get_radix_string(UVM_DEC));
    to.set_radix_string(UVM_BIN,      from.get_radix_string(UVM_BIN));
    to.set_radix_string(UVM_OCT,      from.get_radix_string(UVM_OCT));
    to.set_radix_string(UVM_UNSIGNED, from.get_radix_string(UVM_UNSIGNED));
    to.set_radix_string(UVM_HEX,      from.get_radix_string(UVM_HEX));
    to.set_default_radix(from.get_default_radix());
    to.set_root_enabled(from.get_root_enabled());
    to.set_recursion_policy(from.get_recursion_policy());
    to.set_max_depth(from.get_max_depth());
    to.set_file(from.get_file());
    to.set_line_prefix(from.get_line_prefix());
    to.set_begin_elements(from.get_begin_elements());
    to.set_end_elements(from.get_end_elements());
  `else
    to.knobs.header         = from.knobs.header;
    to.knobs.footer         = from.knobs.footer;
    to.knobs.full_name      = from.knobs.full_name;
    to.knobs.identifier     = from.knobs.identifier;
    to.knobs.type_name      = from.knobs.type_name;
    to.knobs.size           = from.knobs.size;
    to.knobs.depth          = from.knobs.depth;
    to.knobs.reference      = from.knobs.reference;
    to.knobs.begin_elements = from.knobs.begin_elements;
    to.knobs.end_elements   = from.knobs.end_elements;
    to.knobs.prefix         = from.knobs.prefix;
    to.knobs.indent         = from.knobs.indent;
    to.knobs.show_root      = from.knobs.show_root;
    to.knobs.mcd            = from.knobs.mcd;
    to.knobs.separator      = from.knobs.separator;
    to.knobs.show_radix     = from.knobs.show_radix;
    to.knobs.default_radix  = from.knobs.default_radix;
    to.knobs.dec_radix      = from.knobs.dec_radix;
    to.knobs.bin_radix      = from.knobs.bin_radix;
    to.knobs.oct_radix      = from.knobs.oct_radix;
    to.knobs.unsigned_radix = from.knobs.unsigned_radix;
    to.knobs.hex_radix      = from.knobs.hex_radix;
  `endif
endfunction: copy_printer

/// Packs all configuration data for the given uvm_printer using the given uvm_packer.
/// Since uvm_printer does not natively support pack/unpack operations,
/// these helper methods can be used to pack/unpack a printer
/// \note The uvm_packer used *must* have the flag use_metadata set to 1'b1 for this to work correctly
///
/// \param printer The uvm_printer for which all configuration values should be packed
/// \param packer The uvm_packer to use when packing the item
function void cl_syoscb_printer_config::do_help_pack(uvm_printer printer, uvm_packer packer);
// This function is primarily used in cl_syoscb_cfg::do_pack to pack configuration data
  bit name_enabled; //identifier
  bit type_name_enabled; //type_name
  bit size_enabled; //size
  bit id_enabled; //reference
  bit radix_enabled; //show_radix
  string dec_radix;
  string bin_radix;
  string oct_radix;
  string hex_radix;
  string unsigned_radix;
  uvm_radix_enum default_radix;
  bit root_enabled; //show_root
  uvm_recursion_policy_enum policy;
  int max_depth; //depth
  UVM_FILE file; //mcd
  string line_prefix; //prefix
  int begin_elements;
  int end_elements;
  t_printer_type ptype;

  //Pack 4 bits to indicate null/non-null printer
  if(printer != null) begin
    packer.pack_field_int(1, 4);
  end else begin
    packer.pack_field_int(0, 4);
    return;
  end

  `ifdef UVM_VERSION
    name_enabled      = printer.get_name_enabled();
    type_name_enabled = printer.get_type_name_enabled();
    size_enabled      = printer.get_size_enabled();
    id_enabled        = printer.get_id_enabled();
    radix_enabled     = printer.get_radix_enabled();
    dec_radix         = printer.get_radix_string(UVM_DEC);
    bin_radix         = printer.get_radix_string(UVM_BIN);
    oct_radix         = printer.get_radix_string(UVM_OCT);
    hex_radix         = printer.get_radix_string(UVM_HEX);
    unsigned_radix    = printer.get_radix_string(UVM_UNSIGNED);
    default_radix     = printer.get_default_radix();
    root_enabled      = printer.get_root_enabled();
    policy            = printer.get_recursion_policy();
    max_depth         = printer.get_max_depth();
    file              = printer.get_file();
    line_prefix       = printer.get_line_prefix();
    begin_elements    = printer.get_begin_elements();
    end_elements      = printer.get_end_elements();
  `else
    name_enabled      = printer.knobs.identifier;
    type_name_enabled = printer.knobs.type_name;
    size_enabled      = printer.knobs.size;
    id_enabled        = printer.knobs.reference;
    radix_enabled     = printer.knobs.show_radix;
    dec_radix         = printer.knobs.dec_radix;
    bin_radix         = printer.knobs.bin_radix;
    oct_radix         = printer.knobs.oct_radix;
    hex_radix         = printer.knobs.hex_radix;
    unsigned_radix    = printer.knobs.unsigned_radix;
    default_radix     = printer.knobs.default_radix;
    root_enabled      = printer.knobs.show_root;
    policy            = UVM_DEFAULT_POLICY; //Apparently no knob with this value, setting to UVM_DEFAULT_POLICY instead
    max_depth         = printer.knobs.depth;
    file              = printer.knobs.mcd;
    line_prefix       = printer.knobs.prefix;
    begin_elements    = printer.knobs.begin_elements;
    end_elements      = printer.knobs.end_elements;
  `endif

  //To correctly pack the printer, we must also know the type of the printer
  //This must be packed before all fields
  ptype = get_printer_type(printer);
  packer.pack_field_int(ptype, $bits(ptype));
  packer.pack_field_int(name_enabled, $bits(name_enabled));
  packer.pack_field_int(type_name_enabled, $bits(type_name_enabled));
  packer.pack_field_int(size_enabled, $bits(size_enabled));
  packer.pack_field_int(id_enabled, $bits(id_enabled));
  packer.pack_field_int(radix_enabled, $bits(radix_enabled));
  packer.pack_string(dec_radix);
  packer.pack_string(bin_radix);
  packer.pack_string(oct_radix);
  packer.pack_string(hex_radix);
  packer.pack_string(unsigned_radix);
  packer.pack_field_int(default_radix, $bits(default_radix));
  packer.pack_field_int(root_enabled, $bits(root_enabled));
  packer.pack_field_int(policy, $bits(policy));
  packer.pack_field_int(max_depth, $bits(max_depth));
  packer.pack_field_int(file, $bits(file));
  packer.pack_string(line_prefix);
  packer.pack_field_int(begin_elements, $bits(begin_elements));
  packer.pack_field_int(end_elements, $bits(end_elements));
endfunction: do_help_pack

/// Unpacks printer configuration data and returns a printer with that configuration.
/// Since uvm_printer does not natively support pack/unpack operations, these helper methods can be used to
/// pack/unpack a printer.
/// \note The uvm_packer used must have the use_metadata flag set to 1'b1 for this to work correctly
///
/// \param packer The uvm_packer that was previously used to pack a uvm_printer
/// \return A uvm_printer with the packed configuration
function uvm_printer cl_syoscb_printer_config::do_help_unpack(uvm_packer packer);
  // This function is primarily used in cl_syoscb_cfg::do_unpack to unpack configuration data
  uvm_printer printer;
  bit name_enabled; //identifier
  bit type_name_enabled; //type_name
  bit size_enabled; //size
  bit id_enabled; //reference
  bit radix_enabled; //show_radix
  string dec_radix;
  string bin_radix;
  string oct_radix;
  string hex_radix;
  string unsigned_radix;
  uvm_radix_enum default_radix;
  bit root_enabled; //show_root
  uvm_recursion_policy_enum policy;
  int max_depth; //depth
  UVM_FILE file; //mcd
  string line_prefix; //prefix
  int begin_elements;
  int end_elements;

  int default_radix_value;
  int policy_value;
  t_printer_type ptype;
  int ptype_value;
  bit[3:0] is_null;

  is_null = packer.unpack_field_int($bits(is_null));
  if(is_null == 4'b0) begin
    return null;
  end

  ptype_value = packer.unpack_field_int($bits(ptype));
  name_enabled = packer.unpack_field_int($bits(name_enabled));
  type_name_enabled = packer.unpack_field_int($bits(type_name_enabled));
  size_enabled = packer.unpack_field_int($bits(size_enabled));
  id_enabled = packer.unpack_field_int($bits(id_enabled));
  radix_enabled = packer.unpack_field_int($bits(radix_enabled));
  dec_radix = packer.unpack_string();
  bin_radix = packer.unpack_string();
  oct_radix = packer.unpack_string();
  hex_radix = packer.unpack_string();
  unsigned_radix = packer.unpack_string();
  default_radix_value = packer.unpack_field_int($bits(default_radix));
  root_enabled = packer.unpack_field_int($bits(root_enabled));
  policy_value = packer.unpack_field_int($bits(policy));
  max_depth = packer.unpack_field_int($bits(max_depth));
  file = packer.unpack_field_int($bits(file));
  line_prefix = packer.unpack_string();
  begin_elements = packer.unpack_field_int($bits(begin_elements));
  end_elements = packer.unpack_field_int($bits(end_elements));

  //To conform to strong enum typing, we must use this workaround when assigning the value of policy, default_radix, printer_type
  //Iterate through all possible enumeration values, check if they match retrieved value.
  //If not, throw an error
  default_radix = default_radix.first();
  while(default_radix != default_radix_value && default_radix != default_radix.last()) begin
    default_radix = default_radix.next();
  end
  if(default_radix != default_radix_value) begin
    `uvm_error("ENUM_DECODE", $sformatf("Unable to interpret 'default_radix' enum. Unpacked value was %0d which is not valid", default_radix_value))
  end

  policy = policy.first();
  while(policy != policy_value && policy != policy.last()) begin
    policy = policy.next();
  end
  if(policy != policy_value) begin
    `uvm_error("ENUM_DECODE", $sformatf("Unable to interpret 'policy' enum. Unpacked value was %0d which is not valid", policy_value))
  end

  ptype = ptype.first();
  while(ptype != ptype_value && ptype != ptype.last()) begin
    ptype = ptype.next();
  end
  if(ptype != ptype_value) begin
    `uvm_error("ENUM_DECODE", $sformatf("Unable to interpret 'ptype' enum. Unpacked value was %0d which is not valid", ptype_value))
  end

  printer = get_printer_of_type(ptype);

  `ifdef UVM_VERSION
    printer.set_name_enabled(name_enabled);
    printer.set_type_name_enabled(type_name_enabled);
    printer.set_size_enabled(size_enabled);
    printer.set_id_enabled(id_enabled);
    printer.set_radix_enabled(radix_enabled);
    printer.set_radix_string(UVM_DEC, dec_radix);
    printer.set_radix_string(UVM_BIN, bin_radix);
    printer.set_radix_string(UVM_OCT, oct_radix);
    printer.set_radix_string(UVM_HEX, hex_radix);
    printer.set_radix_string(UVM_UNSIGNED, unsigned_radix);
    printer.set_default_radix(default_radix);
    printer.set_root_enabled(root_enabled);
    printer.set_recursion_policy(policy);
    printer.set_max_depth(max_depth);
    printer.set_file(file);
    printer.set_line_prefix(line_prefix);
    printer.set_begin_elements(begin_elements);
    printer.set_end_elements(end_elements);
  `else
    printer.knobs.identifier = name_enabled;
    printer.knobs.type_name = type_name_enabled;
    printer.knobs.size = size_enabled;
    printer.knobs.reference = id_enabled;
    printer.knobs.dec_radix = dec_radix;
    printer.knobs.bin_radix = bin_radix;
    printer.knobs.oct_radix = oct_radix;
    printer.knobs.hex_radix = hex_radix;
    printer.knobs.unsigned_radix = unsigned_radix;
    printer.knobs.default_radix = default_radix;
    printer.knobs.show_root = root_enabled;
    printer.knobs.depth = max_depth;
    printer.knobs.mcd = file;
    printer.knobs.prefix = line_prefix;
    printer.knobs.begin_elements = begin_elements;
    printer.knobs.end_elements = end_elements;
  `endif

  return printer;
endfunction: do_help_unpack

/// Sets the number of elements to print at the head of a list whenever the printer is used to print a tx item.
///
/// \param printer The printer to set the number of elements for
/// \param elements The number of elements to print
function void cl_syoscb_printer_config::set_printer_begin_elements(uvm_printer printer,
                                                                 int elements);
  `ifdef UVM_VERSION
    printer.set_begin_elements(elements);
  `else
    printer.knobs.begin_elements = elements;
  `endif
endfunction: set_printer_begin_elements

/// Sets the number of elements to print at the tail of a list whenever the printer is used to print a tx item.
///
/// \param printer The printer to set the number of elements for
/// \param elements The number of elements to print
function void cl_syoscb_printer_config::set_printer_end_elements(uvm_printer printer,
                                                               int elements);
  `ifdef UVM_VERSION
    printer.set_end_elements(elements);
  `else
    printer.knobs.end_elements = elements;
  `endif
endfunction: set_printer_end_elements