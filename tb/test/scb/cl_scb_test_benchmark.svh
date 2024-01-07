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
/// Benchmark to compare performance of STD and Hash queues when executing OOO compare
// Additional classes defined below which actually implement the test
class cl_scb_test_benchmark extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  int Nvals[] = {100, 200, 500, 1000, 5000, 10000, 20000, 50000, 100000};
  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_benchmark)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_benchmark", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern function void test(int N, string fname);
  extern function void log_time(string fname);
  extern function real get_time_diff(string file1, string file2);
  extern function void pre_build();
endclass: cl_scb_test_benchmark

function void cl_scb_test_benchmark::pre_build();
  super.pre_build();
  this.syoscb_cfgs.syoscb_cfg[0].set_compare_type(pk_syoscb::SYOSCB_COMPARE_OOO);
  this.syoscb_cfgs.syoscb_cfg[0].set_disable_clone(1'b0);
  void'(this.syoscb_cfgs.syoscb_cfg[0].set_primary_queue("Q2"));
endfunction: pre_build

//Perform the test, generating N items and randomly inserting them in Q1 and Q2
//N: Number of items to generate
//name: File name to write results to
function void cl_scb_test_benchmark::test(int N, string fname);
  cl_tb_seq_item items[];
  real time_diff;
  int fd;

  //Generate items
  items = new [N];
  foreach(items[i]) begin
    items[i] = cl_tb_seq_item::type_id::create($sformatf("items[%0d]", i));
    if(!items[i].randomize()) begin
      `uvm_fatal("RAND", $sformatf("Unable to randomize items[%0d]", i))
    end
  end

  foreach(items[i]) begin
    this.scb_env.syoscb[0].add_item("Q1", "P1", items[i]);
  end
  items.shuffle();

  this.log_time("t0");
  foreach(items[i]) begin
    this.scb_env.syoscb[0].add_item("Q2", "P1", items[i]);
  end
  this.log_time("t1");
  time_diff = get_time_diff("t0", "t1");
  if(this.scb_env.syoscb[0].get_total_queue_size() != 0) begin
    `uvm_fatal("ERR", $sformatf("Total queue size was not 0, is %0d", this.scb_env.syoscb[0].get_total_queue_size()))
  end

  fd = $fopen(fname, "a");
  $fwrite(fd, $sformatf("%0d, %0f\n", N, time_diff));
  $display("N: %0d, time: %0f", N, time_diff);
  $fclose(fd);
endfunction: test

//Gets current time, stores it in the file named "fname"
function void cl_scb_test_benchmark::log_time(string fname);
  $system($sformatf("date -Ins > %0s.time", fname));
endfunction: log_time

//Gets time difference in seconds between two timestamps
function real cl_scb_test_benchmark::get_time_diff(string file1, string file2);
  int f1, f2;
  string t1, t2, s1, s2, m1, m2, h1, h2;
  real S1, S2, M1, M2, H1, H2;
  real a;

  f1 = $fopen($sformatf("%0s.time", file1), "r");
  f2 = $fopen($sformatf("%0s.time", file2), "r");

  void'($fgets(t1, f1));
  void'($fgets(t2, f2));
  //date -Ins returns a string of the type
  //2022-01-24T08:48:50,131570320+0100
  //We wish to extract hours, minutes and seconds, replace the ',' with a '.'
  h1 = t1.substr(11, 12);
  h2 = t2.substr(11, 12);
  m1 = t1.substr(14, 15);
  m2 = t2.substr(14, 15);
  s1 = t1.substr(17, 28);
  s2 = t2.substr(17, 28);

  s1.putc(2, ".");
  s2.putc(2, ".");

  H1 = h1.atoreal();
  H2 = h2.atoreal();
  M1 = m1.atoreal();
  M2 = m2.atoreal();
  S1 = s1.atoreal();
  S2 = s2.atoreal();

  a = (H2-H1)*3600 + (M2-M1)*60 + S2-S1;

  $fclose(f1);
  $fclose(f2);

  return a;
endfunction: get_time_diff


// Track execution time of std queue
class cl_scb_test_benchmark_std extends cl_scb_test_benchmark;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_benchmark_std)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_benchmark_std", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------

  function void pre_build();
    super.pre_build();
    this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_STD);
  endfunction: pre_build

  task main_phase(uvm_phase phase);
    int fd;
    phase.raise_objection(this);
    super.main_phase(phase);

    $fclose($fopen("std_log.txt", "w")); //this clears the file

    foreach(this.Nvals[i]) begin
      this.test(this.Nvals[i], "std_log.txt");
    end

    phase.drop_objection(this);
  endtask: main_phase
endclass: cl_scb_test_benchmark_std


// Track execution time of md5 queue with ordered_next=0
class cl_scb_test_benchmark_md5 extends cl_scb_test_benchmark;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_benchmark_md5)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_benchmark_md5", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  function void pre_build();
    super.pre_build();
    this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b0);
    this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  endfunction: pre_build

  task main_phase(uvm_phase phase);
    int fd;
    phase.raise_objection(this);
    super.main_phase(phase);

    $fclose($fopen("md5_log.txt", "w")); //this clears the file
    foreach(this.Nvals[i]) begin
      this.test(this.Nvals[i], "md5_log.txt");
    end

    phase.drop_objection(this);
  endtask: main_phase
endclass: cl_scb_test_benchmark_md5

// Track execution time of md5 queue with ordered_next=1
class cl_scb_test_benchmark_md5_on extends cl_scb_test_benchmark;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_benchmark_md5_on)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_benchmark_md5", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  function void pre_build();
    super.pre_build();
    this.syoscb_cfgs.syoscb_cfg[0].set_ordered_next(1'b1);
    this.syoscb_cfgs.syoscb_cfg[0].set_queue_type(pk_syoscb::SYOSCB_QUEUE_MD5);
  endfunction: pre_build

  task main_phase(uvm_phase phase);
    int fd;
    phase.raise_objection(this);
    super.main_phase(phase);

    $fclose($fopen("md5_on_log.txt", "w")); //this clears the file
    foreach(this.Nvals[i]) begin
      this.test(this.Nvals[i], "md5_on_log.txt");
    end

    phase.drop_objection(this);
  endtask: main_phase
endclass: cl_scb_test_benchmark_md5_on