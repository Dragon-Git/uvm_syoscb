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
/// IO comparison test to ensure that the SYOSIL TLM GP comparison workaround works as expected.
/// See cl_syoscb_item for a description as to why this workaround is necessary
class cl_scb_test_io_std_tlm_gp_test extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------


  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_io_std_tlm_gp_test)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_io_std_tlm_gp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();
  extern task                  run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);

endclass: cl_scb_test_io_std_tlm_gp_test

function void cl_scb_test_io_std_tlm_gp_test::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_max_print_orphans(-1);

  //If defined, an error should occur. Demoting that error and orphan error to make the test pass
  `ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
    uvm_root::get().set_report_severity_id_override(UVM_ERROR, "COMPARE_ERROR", UVM_INFO);
  `endif //Otherwise, no error should pop up

endfunction: pre_build

task cl_scb_test_io_std_tlm_gp_test::run_phase(uvm_phase phase);
  uvm_tlm_generic_payload gp1, gp2;

  phase.raise_objection(this);
  super.run_phase(phase);

  //Very simple test of the GP workaround.
  //Create two randomized GP items which do not match, prompting a miscompare
  gp1 = uvm_tlm_generic_payload::type_id::create("gp1");
  gp2 = uvm_tlm_generic_payload::type_id::create("gp2");

  //If we do not randomize with fixed lengths, the test stalls on both cadence and mentor...
  //Reason is unknown
  if(!gp1.randomize() with { this.m_length == 5; }) begin
    `uvm_fatal("RAND", "Unable to randomize gp1");
  end
  if(!gp2.randomize() with { this.m_length == 6; }) begin
    `uvm_fatal("RAND", "Unable to randomize gp2");
  end

  scb_env.syoscb[0].add_item("Q1", "P1", gp1);
  scb_env.syoscb[0].add_item("Q2", "P1", gp2);

  this.scb_env.syoscb[0].flush_queues_all(); //Flush queues to avoid re-comparing due to greed

  phase.drop_objection(this);
endtask: run_phase

function void cl_scb_test_io_std_tlm_gp_test::check_phase(uvm_phase phase);
  super.check_phase(phase);

  //If defined, we expect one COMPARE_ERROR to have popped up
  `ifdef SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND
    begin
      uvm_report_server rs = uvm_report_server::get_server();
      int num_cmp_err = rs.get_id_count("COMPARE_ERROR");

      if(num_cmp_err != 1) begin
        `uvm_error("TEST", $sformatf("Number of COMPARE_ERRORs was not 1 as expected. Got %0d COMPARE_ERROR instead", num_cmp_err))
      end
    end
  `endif
    //If not defined, no errors are expected
endfunction: check_phase
