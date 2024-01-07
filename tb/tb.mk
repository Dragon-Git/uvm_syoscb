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
scbtest_DEPS := syoscb

scbtest_SRC  := $(TB_DIR)/pk_tb.sv $(TB_DIR)/top.sv

scbtest_INC_DIR := $(TB_DIR) $(TB_DIR)/test/scb $(TB_DIR)/test/scbs $(wildcard $(TB_DIR)/test/scb/*)

scbtest_VLOG_OPTS :=

# Simple rule to capture the package dependency on the included files
$(TB_DIR)/pk_tb.sv : $(wildcard $(TB_DIR)/*.svh) $(wildcard $(TB_DIR)/test/scb/*.svh) $(wildcard $(TB_DIR)/test/scbs/*.svh) $(wildcard $(TB_DIR)/test/scb/*/*.svh)
	@touch $(TB_DIR)/pk_tb.sv

#############################################################################
# Common targets
#############################################################################
.PHONY: help_tb_common
help_tb_common:
	@echo "############### TB targets ##################"
	@echo ""

#############################################################################
# Mentor targets
#############################################################################
ifeq ($(VENDOR),MENTOR)
$(COMPILE_DIR)/work/compiled_tb : $(scbtest_SRC) $(foreach dep,$(scbtest_DEPS),$(COMPILE_DIR)/$(dep)_vc/compiled_vc) \
                                  | $(COMPILE_DIR)/work
	$(VLOG) -work $(COMPILE_DIR)/work  $(VLOG_OPTS) $(scbtest_VLOG_OPTS) \
          $(foreach lib,$(scbtest_DEPS), -L $(COMPILE_DIR)/$(lib)_vc) \
          $(foreach inc_dir,$(scbtest_INC_DIR),+incdir+$(inc_dir)) \
          $(scbtest_SRC)
	@touch $@

$(COMPILE_DIR)/work : | $(COMPILE_DIR)
	$(VLIB) $(COMPILE_DIR)/work

.PHONY : compile_tb
compile_tb : $(COMPILE_DIR)/work/compiled_tb

.PHONY: help_tb
help_tb: help_tb_common
	@echo "  TARGET: compile_tb"
	@echo "  Shortcut to compile TB"
	@echo ""
	@echo "  TARGET: $(COMPILE_DIR)/work"
	@echo "  Create vlib"
	@echo ""
	@echo "  TARGET: $(COMPILE_DIR)/work/compiled_tb"
	@echo "  Compile TB"
	@echo ""
endif

#############################################################################
# Cadence targets
#############################################################################
ifeq ($(VENDOR),CADENCE)
.PHONY: help_tb
help_tb: help_tb_common
	@echo "  No targets available"
	@echo ""
endif

#############################################################################
# Synopsys targets
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
.PHONY : compile_tb
compile_tb: $(scbtest_SRC) synopsys_uvm $(foreach dep,$(scbtest_DEPS),compile_$(dep)_vc)
	vlogan $(VLOG_OPTS) \
          $(foreach inc_dir,$(scbtest_INC_DIR),+incdir+$(inc_dir)) \
          $(scbtest_SRC)

.PHONY: elaborate_tb
elaborate_tb: compile_tb
	vcs -full64 -sverilog -ntb_opts uvm-$(UVM_VERSION) top

.PHONY: help_tb
help_tb: help_tb_common
	@echo "  TARGET: compile_tb"
	@echo "  Compile TB"
	@echo ""
	@echo "  TARGET: elab_tb"
	@echo "  Elaborate TB"
	@echo ""
endif
