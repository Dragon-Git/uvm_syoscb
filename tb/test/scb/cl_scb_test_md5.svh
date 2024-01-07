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
/// Test which verifies that the md5 hash implementation works correctly
class cl_scb_test_md5 extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_md5)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_md5", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void pre_build();
  extern task          main_phase(uvm_phase phase);


endclass: cl_scb_test_md5

function void cl_scb_test_md5::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_enable_no_insert_check(1'b0);
endfunction: pre_build

task cl_scb_test_md5::main_phase(uvm_phase phase);
  cl_syoscb_hash_md5 md5;
  cl_syoscb_hash_md5::tp_hash_digest digest;
  string strings[$];
  string hashes[$];

  phase.raise_objection(this);
  super.main_phase(phase);

  strings.push_back("Hello, world");
  strings.push_back("This is a super duper long string that takes up a lot of space and exceeds the 512-byte boundary");
  strings.push_back("The quick brown fox jumps over the lazy dog");
  strings.push_back("1234567890");

  //Reference hashes generated with https://www.md5hashgenerator.com/
  hashes.push_back("bc6e6f16b8a077ef5fbc8d59d0b931b9");
  hashes.push_back("8eeaea9d3bac8c8b59aad5b9009129a3");
  hashes.push_back("9e107d9d372bb6826bd81d3542a419d6");
  hashes.push_back("e807f1fcf82d132f9bb018ca6738a19f");

  md5 = new;
  foreach(strings[i]) begin
    string hash;
    digest = md5.hash_str(strings[i]);
    hash = $sformatf("%0x", digest);
    if(hash != hashes[i]) begin
      `uvm_error("HASH_MD5", $sformatf(
        {"MD5 hash of string\n%0s\ndid not match expected value.\n",
         "Expected :%0s\b",
         "Got hash :%0s"}, strings[i], hashes[i], hash))
    end
  end

  phase.drop_objection(this);
endtask: main_phase