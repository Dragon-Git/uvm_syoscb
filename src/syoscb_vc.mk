#######################################################################
#   Copyright 2005-2022 SyoSil ApS
#   All Rights Reserved Worldwide
#
#   Licensed under the Apache License, Version 2.0 (the
#   "License"); you may not use this file except in
#   compliance with the License.  You may obtain a copy of
#   the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in
#   writing, software distributed under the License is
#   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied.  See
#   the License for the specific language governing
#   permissions and limitations under the License.
#######################################################################
syoscb_DEPS :=

syoscb_SRC := $(UVMLIB_DIR)/pk_utils_uvm.sv \
              $(VC_DIR)/pk_syoscb.sv

syoscb_INC_DIR := $(VC_DIR)

syoscb_VLOG_OPTS :=

# Simple rule to capture the package dependency on the included files
$(VC_DIR)/pk_syoscb.sv : $(VC_DIR)/syoscb_common.svh \
                         $(VC_DIR)/cl_syoscb_cfg_pl.svh \
                         $(VC_DIR)/cl_syoscb_cfg.svh \
                         $(VC_DIR)/cl_syoscbs_cfg.svh \
                         $(VC_DIR)/cl_syoscb_compare_base.svh \
                         $(VC_DIR)/cl_syoscb_compare.svh \
                         $(VC_DIR)/cl_syoscb_compare_ooo.svh \
                         $(VC_DIR)/cl_syoscb_compare_io.svh \
                         $(VC_DIR)/cl_syoscb_item.svh \
                         $(VC_DIR)/cl_syoscb_queue_base.svh \
                         $(VC_DIR)/cl_syoscb_queue_std.svh \
                         $(VC_DIR)/cl_syoscb_queue_iterator_base.svh \
                         $(VC_DIR)/cl_syoscb_queue_iterator_std.svh \
                         $(VC_DIR)/cl_syoscb.svh \
                         $(VC_DIR)/cl_syoscbs.svh

	@touch $(VC_DIR)/pk_syoscb.sv

#############################################################################
# Common targets
#############################################################################
.PHONY: help_syoscb_vc_common
help_syoscb_vc_common:
	@echo "########## VC: syoscb_vc targets ############"
	@echo ""

#############################################################################
# Mentor targets
#############################################################################
ifeq ($(VENDOR),MENTOR)
.PHONY : compile_syoscb_vc
compile_syoscb_vc : $(COMPILE_DIR)/syoscb_vc/compiled_vc

$(COMPILE_DIR)/syoscb_vc/compiled_vc: $(syoscb_SRC) $(foreach dep,$(syoscb_DEPS),$(dep)/compiled_vc) \
                                    | $(COMPILE_DIR)/syoscb_vc
	$(VLOG) -work $(COMPILE_DIR)/syoscb_vc  $(VLOG_OPTS) $(syoscb_VLOG_OPTS) \
          $(foreach lib,$(syoscb_DEPS), -L $(lib)) \
          $(foreach inc_dir,$(syoscb_INC_DIR),+incdir+$(inc_dir)) \
          $(syoscb_SRC)
	@touch $@

$(COMPILE_DIR)/syoscb_vc : | $(COMPILE_DIR)
	$(VLIB) $(COMPILE_DIR)/syoscb_vc

.PHONY: help_syoscb_vc
help_syoscb_vc: help_syoscb_vc_common
	@echo "  TARGET: compile_syoscb_vc"
	@echo "  Shortcut to compile SyoSCB VC"
	@echo ""
	@echo "  TARGET: $(COMPILE_DIR)/syoscb_vc"
	@echo "  Create vlib"
	@echo ""
	@echo "  TARGET: $(COMPILE_DIR)/syoscb_vc/compiled_vc"
	@echo "  Compile SyoSCB VC"
	@echo ""
endif

#############################################################################
# Cadence targets
#############################################################################
ifeq ($(VENDOR),CADENCE)
.PHONY: help_syoscb_vc
help_syoscb_vc: help_syoscb_vc_common
	@echo "  No targets available"
	@echo ""
endif

#############################################################################
# Synopsys targets
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
.PHONY : compile_syoscb_vc
compile_syoscb_vc: $(syoscb_SRC) synopsys_uvm
	vlogan -ntb_opts uvm-$(UVM_VERSION) -sverilog $(VLOG_OPTS) \
	  $(foreach inc_dir,$(syoscb_INC_DIR),+incdir+$(inc_dir)) \
          $(syoscb_SRC)

.PHONY: help_syoscb_vc
help_syoscb_vc: help_syoscb_vc_common
	@echo "  TARGET: compile_syoscb_vc"
	@echo "  Compile SyoSCB VC"
	@echo ""
endif
