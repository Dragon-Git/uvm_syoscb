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
/// Utility class used to perform manipulations of uvm_comparer objects.
/// Contains a number of functions that simplify uvm_comparer related code, as the comparer API
/// differs based on the UVM version used.
/// These functions encapsulate those differences, providing a unified API regardless of UVM version.
class cl_syoscb_comparer_config extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_comparer_config)

  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_syoscb_comparer_config");

  //-------------------------------------
  // Functions
  //-------------------------------------

  extern static function void         set_verbosity(uvm_comparer comparer, int unsigned cv = UVM_DEBUG);
  extern static function int unsigned get_verbosity(uvm_comparer comparer);
  extern static function void         copy_comparer(uvm_comparer from, uvm_comparer to);
  extern static function string       get_miscompares_from_comparer(uvm_comparer comparer);
  extern static function void         do_help_pack(uvm_comparer comparer, uvm_packer packer);
  extern static function uvm_comparer do_help_unpack(uvm_packer packer);
  extern static function void         set_show_max(uvm_comparer comparer, int unsigned sm);
  extern static function int unsigned get_show_max(uvm_comparer comparer);

endclass: cl_syoscb_comparer_config

function cl_syoscb_comparer_config::new(string name = "cl_syoscb_comparer_config");
  super.new(name);
endfunction: new

/// Sets the verbosity level of a given comparer
///
/// \param comparer The comparer object on which to set a new verbosity level
/// \param cv The new comparer verbosity level
function void cl_syoscb_comparer_config::set_verbosity(uvm_comparer comparer, int unsigned cv = UVM_DEBUG);
  `ifdef UVM_VERSION
    comparer.set_verbosity(cv);
  `else
    comparer.verbosity = cv;
  `endif
endfunction: set_verbosity

/// Gets the verbosity level for a given comparer
///
/// \param comparer The comparer object for which to get the verbosity level
/// \return That comparer's verbosity level
function int unsigned cl_syoscb_comparer_config::get_verbosity(uvm_comparer comparer);
  `ifdef UVM_VERSION
    return comparer.get_verbosity();
  `else
    return comparer.verbosity;
  `endif
endfunction: get_verbosity

/// Copies all config information from one comparer into another.
///
/// \param from Comparer containing the data to be copied
/// \param to Comparer to inherit configuration data in \c from
function void cl_syoscb_comparer_config::copy_comparer(uvm_comparer from, uvm_comparer to);
  `ifdef UVM_VERSION
    to.set_result(from.get_result());
    to.set_recursion_policy(from.get_recursion_policy());
    to.set_check_type(from.get_check_type());
    to.set_show_max(from.get_show_max());
    to.set_verbosity(from.get_verbosity());
    to.set_severity(from.get_severity());
    to.set_threshold(from.get_threshold());
  `else
    to.policy = from.policy;
    to.show_max = from.show_max;
    to.verbosity = from.verbosity;
    to.sev = from.sev;
    to.miscompares = from.miscompares;
    to.physical = from.physical;
    to.abstract = from.abstract;
    to.check_type = from.check_type;
    to.result = from.result;
  `endif
endfunction: copy_comparer

/// Packs all configuration data for the given uvm_comparer using the given uvm_packer.
/// Since uvm_comparer does not natively support pack/unpack operations,
/// these helper methods can be used to pack/unpack a comparer
///
/// \param comparer The uvm_comparer for which all configuration values should be packed
/// \param packer The uvm_packer to use when packing the item
function void cl_syoscb_comparer_config::do_help_pack(uvm_comparer comparer, uvm_packer packer);
  // This function is primarily meant to be used in cl_syoscb_cfg::do_pack to pack comparers
  int unsigned result;
  uvm_recursion_policy_enum policy;
  bit check_type;
  int unsigned show_max;
  uvm_severity sev;
  int unsigned verbosity;
  int unsigned threshold;

  //Pack 4 bits to indicate if the comparer is null or non-null
  if(comparer != null) begin
    packer.pack_field_int(1, 4);
  end else begin
    packer.pack_field_int(0, 4);
    return;
  end

  `ifdef UVM_VERSION
    result =     comparer.get_result();
    policy =     comparer.get_recursion_policy();
    check_type = comparer.get_check_type();
    show_max =   comparer.get_show_max();
    sev =        comparer.get_severity();
    verbosity =  comparer.get_verbosity();
    threshold =  comparer.get_threshold();
  `else
    result =     comparer.result;
    policy =     comparer.policy;
    check_type = comparer.check_type;
    show_max =   comparer.show_max;
    sev =        comparer.sev;
    verbosity =  comparer.verbosity;
    threshold =  1; //Threshold value is not readable if UVM_VERSION is not set, defaults to 1
  `endif

    packer.pack_field_int(result, $bits(result));
    packer.pack_field_int(policy, $bits(policy));
    packer.pack_field_int(check_type, $bits(check_type));
    packer.pack_field_int(show_max, $bits(show_max));
    packer.pack_field_int(sev, $bits(sev));
    packer.pack_field_int(verbosity, $bits(verbosity));
    packer.pack_field_int(threshold, $bits(threshold));

endfunction: do_help_pack

/// Unpacks comparer configuration data and returns a comparer with that configuration.
/// Since uvm_comparer does not natively support pack/unpack operations,
/// these helper methods can be used to pack/unpack a comparer
///
/// \param packer The uvm_packer that was previously used to pack a \c uvm_comparer
/// \return A uvm_comparer with the packed configuration
function uvm_comparer cl_syoscb_comparer_config::do_help_unpack(uvm_packer packer);
  // This function is primarily used in cl_syoscb_cfg::do_unpack to unpack configuration data
  uvm_comparer comparer;
  int unsigned result;
  uvm_recursion_policy_enum policy;
  bit check_type;
  int unsigned show_max;
  uvm_severity sev;
  int unsigned verbosity;
  int unsigned threshold;
  int policy_value;
  int sev_value;

  bit [3:0] is_null;

  is_null = packer.unpack_field_int($bits(is_null));

  if(is_null == 4'b0) begin
    return null;
  end

  result = packer.unpack_field_int($bits(result));
  policy_value = packer.unpack_field_int($bits(policy));
  check_type = packer.unpack_field_int($bits(check_type));
  show_max = packer.unpack_field_int($bits(show_max));
  sev_value = packer.unpack_field_int($bits(sev));
  verbosity = packer.unpack_field_int($bits(verbosity));
  threshold = packer.unpack_field_int($bits(threshold));

  //To conform to strong enum typing, we must use this workaround when assigning the value of policy
  //Iterate through all possible enumeration values, check if they match retrieved value.
  //If not, throw an error
  policy = policy.first();
  while(policy != policy_value && policy != policy.last()) begin
    policy = policy.next();
  end
  if(policy != policy_value) begin
    `uvm_error("ENUM_DECODE", $sformatf("Unable to interpret 'policy' enum. Unpacked value was %0d which is not valid", policy_value));
  end

  //In UVM 1.1d, sev is not an enum - instead we simply enumerate all possible values
  if(sev_value == UVM_INFO) begin
    sev = UVM_INFO;
  end else if (sev_value == UVM_WARNING) begin
    sev = UVM_WARNING;
  end else if (sev_value == UVM_ERROR) begin
    sev = UVM_ERROR;
  end else if (sev_value == UVM_FATAL) begin
    sev = UVM_FATAL;
  end else begin
    `uvm_error("ENUM_DECODE", $sformatf("Unable to interpret 'sev' enum. Unpacked value was %0d which is not valid", sev_value))
  end

  comparer = new;

  `ifdef UVM_VERSION
    comparer.set_result(result);
    comparer.set_recursion_policy(policy);
    comparer.set_check_type(check_type);
    comparer.set_show_max(show_max);
    comparer.set_severity(sev);
    comparer.set_verbosity(verbosity);
    comparer.set_threshold(threshold);
`else
    comparer.result = result;
    comparer.policy = policy;
    comparer.check_type = check_type;
    comparer.show_max = show_max;
    comparer.sev = sev;
    comparer.verbosity = verbosity;
    //Threshold value is not readable if UVM_VERSION is not set, defaults to 1
`endif

  return comparer;
endfunction: do_help_unpack

/// Returns a string containing all miscompares from the given comparer.
///
/// \param comparer The comparer from which to get all miscompares
/// \return A string containing information about the miscompares in the comparer
function string cl_syoscb_comparer_config::get_miscompares_from_comparer(uvm_comparer comparer);
  `ifdef UVM_VERSION
    return comparer.get_miscompares();
  `else
    return comparer.miscompares;
  `endif
endfunction: get_miscompares_from_comparer

/// Sets the value of the \c show_max knob in the given comparer.
///
/// \param comparer The comparer to set the show_max knob for
/// \param sm The new value of the show_max knob
function void cl_syoscb_comparer_config::set_show_max(uvm_comparer comparer, int unsigned sm);
  `ifdef UVM_VERSION
    comparer.set_show_max(sm);
  `else
    comparer.show_max = sm;
  `endif
endfunction: set_show_max

/// Gets the value of the \c show_max knob in the given comparer
///
/// \param comparer The comparer to get the show_max knob for
/// \return The value of show_max in the given comparer
function int unsigned cl_syoscb_comparer_config::get_show_max(uvm_comparer comparer);
  `ifdef UVM_VERSION
    return comparer.get_show_max();
  `else
    return comparer.show_max;
  `endif
endfunction: get_show_max