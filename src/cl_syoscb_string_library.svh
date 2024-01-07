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
/// A utility class holding a number of static methods for performing string manipulation.
class cl_syoscb_string_library extends uvm_object;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_object_utils_begin(cl_syoscb_string_library)

  `uvm_object_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_syoscb_string_library");
    super.new(name);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern static function string pad_str(string str, int unsigned max_length, string expand = " ", bit side = 1'b0);
  extern static function string scb_separator_str(int unsigned pre_length);
  extern static function string scb_header_str(string hn, int unsigned pre_length, bit side,
                                           string col_names[] = '{"  Inserts " , "  Matches ", "  Flushed ", "  Orphans "});
  extern static function void   split_string(string in, byte delim[], output string out[]);
  extern static function int    merge_string_arrays(string inputs[$][], string concat = "|", output string result);
  extern static function string generate_cmp_table_header(int table_width, string header_text);
  extern static function int    generate_cmp_table_body(cl_syoscb_item items[], cl_syoscb_cfg cfg, output string result);
  extern static function string generate_cmp_table_footer(int table_width, uvm_comparer comparer);
  extern static function string sprint_item(cl_syoscb_item item, cl_syoscb_cfg cfg);

endclass: cl_syoscb_string_library

/// Pads the input string with another string until it reaches a given length.
/// \param str        The input string to pad
/// \param max_length The length to pad it to
/// \param expand     The character(s) to insert on the left/right of the original string until \c max_length is reached
/// \param side       Which side of the string to insert padding on. If 1, inserts on the right, if 0, inserts on the left
/// \return           The padded string
function string cl_syoscb_string_library::pad_str(string str, int unsigned max_length, string expand = " ", bit side = 1'b0);
  if(str.len() >= max_length) begin
    return str;
  end

  while(str.len() < max_length) begin
    str = (side == 1'b1) ? {str, expand} : {expand, str};
  end

  return str;
endfunction: pad_str

/// Creates a new separator string for scoreboard stat tables.
/// \param pre_length: The width of the first column of the table
/// \return The separator string
function string cl_syoscb_string_library::scb_separator_str(int unsigned pre_length);
  string str;

  str = { "\n",
  cl_syoscb_string_library::pad_str("", pre_length, "-"),
  "+----------+----------+----------+----------+"};

  return str;
endfunction: scb_separator_str

/// Creates a new header string for a scoreboard stat table.
/// \param hn         The name of the table
/// \param pre_length The width of the first column of the table
/// \param side       Whether to pad the table name with spaces on the right (1) or left (0)
/// \param col_names  The names of the columns in the table. Must have exactly 4 entries, each of which should be 10 characters wide
function string cl_syoscb_string_library::scb_header_str(string hn, int unsigned pre_length, bit side,
                                                     string col_names[] = '{"  Inserts " , "  Matches ", "  Flushed ", "  Orphans "});
  string str;

  if(col_names.size() != 4) begin
  `uvm_error("CFG_ERROR", $sformatf("col_names must have exactly 4 entries, found %0d", col_names.size()))
  end

  str = cl_syoscb_string_library::scb_separator_str(1+pre_length);
  str = {str, "\n",
    cl_syoscb_string_library::pad_str(hn, pre_length+1, " ", side),
    "|", col_names[0], "|", col_names[1], "|", col_names[2], "|", col_names[3], "|"};

  str = { str, cl_syoscb_string_library::scb_separator_str(1+pre_length)};

  return str;
endfunction: scb_header_str

/// Splits the string 'in' by any of the delimiter strings in 'delim',
/// returning the result in 'out'.
///
/// Example: in="Hello, world..", delim={",", " ", "."} => out={"Hello", "world"}
/// \param in: The input string to be split
/// \param delim: An array of possible delimiter characters to be used in splitting the string
/// \param out: A handle to an array in which the split strings will be placed.
function void cl_syoscb_string_library::split_string(string in, byte delim[], output string out[]);
  int start; //start  index of current substring
  string res[$]; //queue of result strings
  bit state; //Current state. 1'b0: Scan through delimiters. 1'b1: Scan through string
  bit is_delim; //Flag indicating if in[idx] is a delimiter

  start = 0;
  state = 1'b0;

  for(int idx=0; idx<in.len(); idx++) begin
    //Check if current char is a delimiter
    is_delim = 1'b0;
    foreach (delim[i]) begin
      if(in[idx] == delim[i]) begin
        is_delim = 1'b1;
        break;
      end
    end

    //Based on current state, handle delim value
    if(state == 1'b0) begin //Delimiter scan
      if(is_delim) begin
        //Do nothing
      end else begin
        start = idx;
        state = 1'b1;
      end
    end else begin //Scanning text
      if(is_delim) begin //End of word
        res.push_back(in.substr(start, idx-1));
        state = 1'b0;
      end //Else do nothing
    end
  end

  if(state == 1'b1) begin //Push in final string
    res.push_back(in.substr(start, in.len()-1));
  end
  out = res;
endfunction: split_string

/// Takes a queue of string arrays, merging these into a single string.
/// The output consists of the i'th lines of all entries concatenated together.
/// Each corresponding line is joined with a line break "\n".
/// Primarily intended to be used for merging item printouts previously split by split_string()
/// \param inputs  A queue of string arrays. inputs[x] is a string array, and inputs [x][y] is the y'th line of that string
/// \param concat  A concatenator to be used between strings. Defaults to "|"
/// \param result  A string handle where the result is returned
/// \return The width of the resulting table
function int cl_syoscb_string_library::merge_string_arrays(string inputs[$][], string concat = "|", output string result);
  int max_length; //Table with the most entries
  int total_width; //Total width of all entries, excluding spacers

  if(inputs.size() < 2) begin
    `uvm_error("STR_ERROR", "Must have at least two tables to merge")
  end

  //Find the length of the longest string array + the width of all arrays
  max_length = inputs[0].size();
  total_width = inputs[0][0].len();
  for(int i=1; i<inputs.size(); i++) begin
    total_width += inputs[i][0].len();
    if(inputs[i].size() > max_length) begin
      max_length = inputs[i].size();
    end
  end
  total_width = total_width + 3*(inputs.size()-1);

  //Add a top bar of '#'
  result = {" ", { (total_width){"#"} }, "\n"};

  for(int i=0; i<max_length-1; i++) begin
    result = {result, " "}; //Add leading " " to avoid questasim gobbling #'s
    for(int j=0; j<inputs.size(); j++) begin
      if(i >= inputs[j].size()-1) begin
        //If inputs[j].size < max_length, we insert spaces for the remaining rows
        result = {result, {(inputs[j][0].len()){" "}} };
      end else begin
        result = {result, inputs[j][i]};
      end
      //On all but the final column, add a concatenation symbol
      if(j != inputs.size()-1) begin
        result = {result, " ", concat, " "};
      end
    end
    result = {result, "\n"};
  end

  //Insert the final row of dashes
  result = {result, " "};
    for(int j=0; j<inputs.size(); j++) begin
    result = {result, inputs[j][inputs[j].size()-1]};
    if(j != inputs.size()-1) begin
      result = {result, " ", concat, " "};
    end
  end
  result = {result, "\n"};

  //Add a bottom bar of #
  result = {result, " ", {(total_width){"#"}}, "\n"};

  return total_width;
endfunction: merge_string_arrays


/// Generates the body of a comparison table. Primarily used for inspecting miscompares.
///
/// \param items  An array of all cl_syoscb_items that must be included in the table
/// \param cfg    The configuration object for the scoreboard
/// \param result Handle to a string in which the result is returned
/// \return       The width of the comparison table
function int cl_syoscb_string_library::generate_cmp_table_body(cl_syoscb_item items[], cl_syoscb_cfg cfg, output string result);
  string item_string;
  string item_tokens[$][];

  foreach(items[i]) begin
    string tokens[];
    item_string = sprint_item(items[i], cfg);
    split_string(item_string, '{"\n"}, tokens);
    item_tokens.push_back(tokens);
  end

  return merge_string_arrays(item_tokens, "|", result);
endfunction

/// Generates the header section of a comparison table.
///
/// \param table_width The width of the comparison table
/// \param header_text The text to be included in the header
/// \return A string containing the header
function string cl_syoscb_string_library::generate_cmp_table_header(int table_width, string header_text);
  string pounds;
  string header;
  string header_text_split[];

  pounds = {(table_width){"#"}};
  cl_syoscb_string_library::split_string(header_text, '{"\n"}, header_text_split);

  header = {" ", pounds, "\n"};
  foreach(header_text_split[i]) begin
    header = {header, " # ", pad_str(header_text_split[i], table_width-3, " ", 1'b1), "#\n"};
  end

  return header;
endfunction: generate_cmp_table_header

/// Generates the footer section of a comparison table.
///
/// \param table_width The width of the comparison table
/// \param comparer The UVM comparer used to compare seq. items
function string cl_syoscb_string_library::generate_cmp_table_footer(int table_width, uvm_comparer comparer);
  string comparer_miscompares;
  string comparer_miscompares_tokens[];
  string dashes, pounds, footer;
  int show_max;

  comparer_miscompares = cl_syoscb_comparer_config::get_miscompares_from_comparer(comparer);
  split_string(comparer_miscompares, '{"\n"}, comparer_miscompares_tokens);
  show_max = cl_syoscb_comparer_config::get_show_max(comparer);
  dashes = {table_width{"-"}};
  pounds = {table_width{"#"}};

  footer = {" ", dashes, "\n",
    $sformatf(" Results from uvm_comparer::get_miscompares() [show_max=%0d]\n", show_max),
    " ", dashes, "\n" };

  //Include miscompares found
  for(int i=0; i<show_max && i<comparer_miscompares_tokens.size(); i++) begin
    string miscmp;
    string tokens;

    tokens = comparer_miscompares_tokens[i];

    //Trim the "Miscompare for <item.field>" string away, preserving only "<item.field>: lhs=<lhs> : rhs=<rhs>"
    //Not necessary on UVM_IEEE
    `ifdef UVM_VERSION
      miscmp = tokens;
    `else
      for(int j=0; j<tokens.len(); j++) begin
        if(tokens[j] == ":") begin
          if(miscmp == "") begin //Nothing included yet: Include <item.field>
            miscmp = tokens.substr(0, j);
          end else begin //Already included <item.field>, included lhs/rhs information
            miscmp = {miscmp, tokens.substr(j+1, tokens.len()-1)};
          break;
          end
        end
      end
    `endif

    footer = {footer, " ", miscmp, "\n"};
  end

  footer = {footer, " ", pounds, "\n"};
  return footer;
endfunction: generate_cmp_table_footer

/// Utility function for printing sequence items using a table printer.
/// This function sprints the given seq. item. using the uvm_default_table_printer.
/// The value of the configuration object's default_printer_verbosity bit is used to control
/// how many array elements are included in long arrays. (See cl_syoscb_cfg#default_printer_verbosity)
///
/// \param item The sequence item to sprint
/// \param cfg  The configuration object for the current scoreboard
function string cl_syoscb_string_library::sprint_item(cl_syoscb_item item, cl_syoscb_cfg cfg);
  uvm_printer printer;
  bit         verbosity;

  `ifdef UVM_VERSION
    printer = uvm_table_printer::get_default();
  `else
    printer = uvm_default_table_printer;
  `endif
  verbosity = cfg.get_default_printer_verbosity();

  if(verbosity == 1'b1) begin
    cl_syoscb_printer_config::set_printer_begin_elements(printer, -1);
    cl_syoscb_printer_config::set_printer_end_elements(printer, -1);
  end else begin
    cl_syoscb_printer_config::set_printer_begin_elements(printer, 5);
    cl_syoscb_printer_config::set_printer_end_elements(printer, 5);
  end

  return item.sprint(printer);
endfunction: sprint_item
