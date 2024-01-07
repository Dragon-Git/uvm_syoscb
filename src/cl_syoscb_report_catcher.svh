//----------------------------------------------------------------------
//   Copyright 2014-2015 SyoSil ApS
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
class cl_syoscb_report_catcher extends uvm_report_catcher;
   int max_num_scb_errors = 10;  	// allow that many SCB errors before stopping the simulation
   int num_scb_errors = 0;
   extern virtual function action_e catch();
endclass: cl_syoscb_report_catcher


function cl_syoscb_report_catcher::action_e cl_syoscb_report_catcher::catch();
   if (get_severity()==UVM_INFO) begin
      if (get_id()=="MISCMP") begin     
         return CAUGHT;       // Avoid the OOO compare to report lots of mismatches for the compare method
      end
   end else if (get_severity()==UVM_ERROR) begin
      if (get_id() == "SYOSCB") begin
         if (num_scb_errors < max_num_scb_errors) begin
            set_severity(UVM_WARNING);
         end
         num_scb_errors++;
      end
    end
   return THROW;
endfunction

