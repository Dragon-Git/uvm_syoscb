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
/// This test is used to ensure that copying data from one cl_syoscb_cfg object to the next correctly moves over all information
class cl_scb_test_copy_cfg extends cl_scb_test_base;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  string            queues[] = '{"Q1", "Q2", "Q3"};
  string            producers[] = '{"P1", "P2"};

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils(cl_scb_test_copy_cfg)

  //-------------------------------------
  // Constructor
  //-------------------------------------
  extern function new(string name = "cl_scb_test_copy_cfg", uvm_component parent = null);

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task run_phase(uvm_phase phase);
endclass: cl_scb_test_copy_cfg

function cl_scb_test_copy_cfg::new(string name = "cl_scb_test_copy_cfg", uvm_component parent = null);
  super.new(name, parent);
endfunction: new

task cl_scb_test_copy_cfg::run_phase(uvm_phase phase);
  //Declarations
  cl_tb_cfg_rnd cfg_rnd;
  cl_syoscb_cfg cfg1, cfg2, cfg3;
  bit           pack1[];
  bit           pack2[];
  bit           pack3[];
  int           miscnt;
  uvm_printer   p[3];
  uvm_printer   default_printer;
  uvm_comparer  c[3];
  uvm_comparer  default_comparer;
  uvm_packer    packer;


  //Initialize objects
  cfg_rnd = this.config_create_and_randomize();
  cfg1 = new;
  cfg2 = new;
  cfg3 = new;
  default_comparer = new;
  packer = new;
  `ifndef UVM_VERSION
    packer.use_metadata = 1'b1;
  `endif

  //Set up cfg1
  cfg_rnd.set_rnd_fields(cfg1);
  cfg1.set_queues(queues);
  void'(cfg1.set_producer("P1", queues));
  void'(cfg1.set_producer("P2", queues));

  //Initialize printers in cfg1
  //Using different printer types to ensure all combinations are tested
  p[0] = cl_syoscb_printer_config::get_printer_of_type(pk_syoscb::SYOSCB_PRINTER_TABLE);
  p[1] = cl_syoscb_printer_config::get_printer_of_type(pk_syoscb::SYOSCB_PRINTER_TREE);
  p[2] = cl_syoscb_printer_config::get_printer_of_type(pk_syoscb::SYOSCB_PRINTER_LINE);
  default_printer = cl_syoscb_printer_config::get_printer_of_type(pk_syoscb::SYOSCB_PRINTER_XML);
  for(int i=0; i<3; i++) begin
    cl_syoscb_printer_config::set_file_descriptor(p[i], i);
    cfg1.set_printer(p[i], '{queues[i]}, '{"P1"});
  end
  cl_syoscb_printer_config::set_file_descriptor(default_printer, 10);
  cfg1.set_default_printer(default_printer);

  //Initialize comparers in cfg1
  foreach(c[i]) begin
    c[i] = new;
    cl_syoscb_comparer_config::set_verbosity(c[i], i*100);
    cfg1.set_comparer(c[i], '{queues[i]}, '{"P2"});
  end
  cl_syoscb_comparer_config::set_verbosity(default_comparer, 400);
  cfg1.set_default_comparer(default_comparer);

  //Copy to cfg2 and pack both cfg1 and cfg2. Packed data should be equal
  cfg2.copy(cfg1);
  $display("Packed %0d bits when packing cfg1", cfg1.pack(pack1, packer));
  $display("Packed %0d bits when packing cfg2", cfg2.pack(pack2, packer));

  foreach(pack1[i]) begin
    if(pack1[i] != pack2[i]) begin
    `uvm_error("CFG_COPY", $sformatf("Error when copying cfg1 to cfg2. Should be similar, but found a difference in pack @ %0d", i))
    end
  end

  //Unpack pack2 into cfg3. Repack that data into pack3, it should still
  //be the same as pack2.
  //This is really just a workaround since we cannot calls .compare on config objects
  //since the queues are included in the comparison
  $display("Unpacked %0d bits into cfg3 from cfg2's pack", cfg3.unpack(pack2));
  $display("Packed %0d bits when packing cfg3", cfg3.pack(pack3, packer));
  foreach(pack2[i]) begin
    if(pack2[i] != pack3[i]) begin
      `uvm_error("CFG_COPY", $sformatf("Error when comparing cfg2 and cfg3. Should be equal, but found a difference in pack @ %0d", i))
    end
  end

  //Introduce differences in cfg2, we now expect packed data to be different
  //beteen pack1 and pack2
  p[0] = cl_syoscb_printer_config::get_printer_of_type(pk_syoscb::SYOSCB_PRINTER_TREE);
  cl_syoscb_printer_config::set_file_descriptor(p[0], 9);
  cfg2.set_printer(p[0], '{"Q1"}, '{"P1"});

  c[0] = new;
  cl_syoscb_comparer_config::set_verbosity(c[0], 101);
  cfg2.set_comparer(c[0], '{"Q2"}, '{"P2"});

  void'(cfg2.pack(pack2, packer));

  miscnt = 0;
  foreach(pack1[i]) begin
    if(pack1[i] != pack2[i]) begin
      miscnt++;
    end
  end
  if(miscnt == 0) begin
    `uvm_error("CFG_COPY", "Error when copying cfg1 to cfg2. No packed difference found when introducing errors");
  end
endtask: run_phase