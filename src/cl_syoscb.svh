//----------------------------------------------------------------------
//   Copyright 2014 SyoSil ApS
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
class cl_syoscb extends uvm_scoreboard;

   cl_syoscb_cfg cfg;
   cl_syoscb_queue queues[];
   cl_syoscb_compare compare_strategy;

   `uvm_component_utils_begin(cl_syoscb)
     `uvm_field_object(cfg, UVM_ALL_ON)
     `uvm_field_array_object(queues, UVM_ALL_ON)
     `uvm_field_object(compare_strategy, UVM_ALL_ON)
   `uvm_component_utils_end

   extern function new(string name, uvm_component parent);
   extern function void build_phase(uvm_phase phase);
   extern function void check_phase(uvm_phase phase);
   extern function void report_phase(uvm_phase phase);
   extern function bit compare();
   extern function void add_item(string queue_name, string producer, uvm_sequence_item item);
endclass: cl_syoscb

function cl_syoscb::new(string name, uvm_component parent);
   super.new(name, parent);
endfunction : new

function void cl_syoscb::build_phase(uvm_phase phase);
   // TBD: This contradicts the paper. It states that a default one is created
   // TBD push config further down?
   if (!uvm_config_db #(cl_syoscb_cfg)::get(this, "", "cfg", this.cfg))
     `uvm_fatal("CFG", "Configuration object not passed.")
   // TBD: This is snooping directly in the CFG - use get/set functions instead?
   this.queues = new[this.cfg.queues.size()];
   begin
     int unsigned idx = 0;
     foreach(this.cfg.queues[queue_name]) begin
     	this.queues[idx] = cl_syoscb_queue::type_id::create({"queue", $psprintf("%0d",idx)}, this);
         this.cfg.queues[queue_name] = this.queues[idx++];
      end
   end

   this.compare_strategy = cl_syoscb_compare::type_id::create(.name("compare_strategy"), .parent(this));

   // TBD: This should either be passed as args to constructor
   //      or the objects should query the CFG DB directly if possible
   //      The parent path is not available anymore after we changed to uvm_object
   this.compare_strategy.compare_algo.set_cfg(this.cfg);
      
   begin
      cl_syoscb_report_catcher catcher = new();
      uvm_report_cb::add(null, catcher);
   end
endfunction : build_phase

function bit cl_syoscb::compare();
   return(this.compare_strategy.compare());
endfunction: compare

///////////////////////////////////////
// Function based API
///////////////////////////////////////
function void cl_syoscb::add_item(string queue_name, string producer, uvm_sequence_item item);
   // TBD: Add checks of correct queue and producer
   if(!this.cfg.queues[queue_name].add_item(producer, item)) begin
     `uvm_fatal("QUEUE_ERROR", $sformatf("Unable to add item to queue: %s", queue_name));
   end

   // TBD: This should be revised according to how it was in the old SCB
   // TBD: Return value from compare() should also be handled
   void'(this.compare());
endfunction : add_item

///////////////////////////////////////
// Transaction based API
///////////////////////////////////////
// TBD

function void cl_syoscb::check_phase(uvm_phase phase);
	string queue_names[];
	cl_syoscb_queue_std queue;
	super.check_phase(phase);

	this.cfg.get_queues(queue_names);
	foreach (queue_names[i]) begin
		$cast(queue, this.cfg.queues[queue_names[i]]);
		if (queue.items.size()!=0) begin
			string firstitem = queue.items[0].sprint();
			`uvm_error("SYOSCB", $psprintf("Queue %s not empty, entries : %d, first element : \n%s", queue_names[i], queue.items.size(), firstitem));
			// TBD dump first parts of each queue !
			// will we use std UVM report mechanisms or a special channel we can redirect ?
		end
	end
endfunction : check_phase

function void cl_syoscb::report_phase(uvm_phase phase);
   super.report_phase(phase);
   // TBD this should NOT  call the report phase of the compare method !
   // as cl_syoscb_compare_base extends uvm_component the compare method should just perform its end of test checks in
   // uvm_check_phase, from the UVM 1.1 class ref manual:
   // uvm_build_phase      Create and configure of testbench structure
   // uvm_connect_phase      Establish cross-component connections.
   // uvm_end_of_elaboration_phase      Fine-tune the testbench.
   // uvm_start_of_simulation_phase      Get ready for DUT to be simulated.
   // uvm_run_phase      Stimulate the DUT.
   // uvm_extract_phase      Extract data from different points of the verficiation environment.
   // uvm_check_phase      Check for any unexpected conditions in the verification environment.
   // uvm_report_phase      Report results of the test.
   // uvm_final_phase      Tie up loose ends.
endfunction : report_phase
