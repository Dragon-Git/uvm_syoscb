#############################################################################
# Global Common Options
#############################################################################
# Internal config
.DEFAULT_GOAL := help

include Makefile.vendor

# Directories
BASE_DIR           := $(CURDIR)
OUTPUT_DIR         := $(BASE_DIR)/output
COMPILE_DIR        := $(OUTPUT_DIR)/compile
RTL_DIR            := $(BASE_DIR)/rtl
TB_DIR             := $(BASE_DIR)/tb
VC_DIR             := $(BASE_DIR)/src
EXTERN_LIB_SRC_DIR := $(BASE_DIR)/extern
LIB_DIR            := $(OUTPUT_DIR)/lib

# Misc variables
VERIFICATION_COMPS   := syoscb
TB                   := scbtest

#############################################################################
# Global UVM Options
#############################################################################
UVM_TESTNAME ?= cl_scbtest_test_simple1

#############################################################################
# Global Mentor Options
#############################################################################
ifeq ($(VENDOR),MENTOR)
VLIB := vlib
VMAP := vmap
VLOG := vlog
VSIM := vsim
GCC  := gcc
VLOG_OPTS := -64 -timescale "1ps / 100fs" +define+ASSERTIONS +define+CLOCKING +acc -sv -novopt
VSIM_OPTS := -classdebug -novopt -64 -c
VSIM_WAVE ?= 0
VSIM_DO_CMD ?= run -all
ifeq ($(VSIM_WAVE), 1)
  VSIM_DO_CMD := log -r /*; $(VSIM_DO_CMD)
endif
endif

#############################################################################
# Global Cadence Options
#############################################################################
# Currently none

#############################################################################
# Global Synopsys Options
#############################################################################
# Currently none

#############################################################################
# Include make targets for each VC
#############################################################################
include $(foreach vc, $(VERIFICATION_COMPS), $(VC_DIR)/$(vc)_vc.mk)

#############################################################################
# Include make target for the testbench
#############################################################################
include $(TB_DIR)/$(TB).mk

#############################################################################
# Rules for directory creation
#############################################################################
$(OUTPUT_DIR) :
	mkdir -p $@

$(COMPILE_DIR) :
	mkdir -p $@

#############################################################################
# Common targets
#############################################################################
# Currently none

#############################################################################
# Mentor targets
#############################################################################
ifeq ($(VENDOR),MENTOR)
.PHONY: compile_vc
compile_vc: $(foreach vc,$(VERIFICATION_COMPS), $(COMPILE_DIR)/$(vc)_vc/compiled_vc)

.PHONY: sim
sim: $(COMPILE_DIR)/work/compiled_tb
	$(VSIM) $(VSIM_OPTS) -lib $(COMPILE_DIR)/work \
        +UVM_MAX_QUIT_COUNT=1,0 +UVM_TESTNAME=$(UVM_TESTNAME) \
	$(foreach vc,$(VERIFICATION_COMPS), -L $(COMPILE_DIR)/$(vc)_vc)\
        -do "$(VSIM_DO_CMD)" \
	scbtest_top

.PHONY: mentor_clean
mentor_clean:
	rm -rf transcript

.PHONY: help_vendor
help_vendor:
	@echo "Targets:"
	@echo "  TARGET: compile_vc"
	@echo "  Compile all VCs"
	@echo ""
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
else
.PHONY: mentor_clean
mentor_clean:
endif

#############################################################################
# Cadence targets
#############################################################################
ifeq ($(VENDOR),CADENCE)
.PHONY: sim
sim:
	irun \
	-makelib \
	worklib \
	-endlib	\
	-uvm \
	-sv \
	-64bit \
	+incdir+./src \
	+incdir+./tb \
	+incdir+./tb/test \
	-top scbtest_top \
	+UVM_MAX_QUIT_COUNT=1,0 \
	+UVM_TESTNAME=$(UVM_TESTNAME) \
	./src/pk_syoscb.sv \
	./tb/pk_scbtest.sv \
	./tb/scbtest_top.sv

.PHONY: cadence_clean
cadence_clean:
	rm -rf INCA_libs irun.log

.PHONY: help_vendor
help_vendor:
	@echo "Targets:"
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
else
.PHONY: cadence_clean
cadence_clean:
endif

#############################################################################
# Synopsys targets
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
.PHONY: synopsys_uvm
synopsys_uvm:
	vlogan -ntb_opts uvm-1.1

.PHONY: sim
sim: elaborate_tb
	./simv +UVM_TESTNAME=$(UVM_TESTNAME)

.PHONY: synsopsys_clean
synsopsys_clean:
	rm -rf DVEfiles AN.DB csrc simv* ucli.key vc_hdrs.h .vlogansetup.args .vlogansetup.env

.PHONY: help_vendor
help_vendor:
	@echo "Targets:"
	@echo "  TARGET: synopsys_uvm"
	@echo "  Compile UVM"
	@echo ""
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
else
.PHONY: synsopsys_clean
synsopsys_clean:
endif

#############################################################################
# Clean target
#############################################################################
clean: cadence_clean mentor_clean synsopsys_clean
	rm -rf output

#############################################################################
# Help target
#############################################################################
.PHONY: help_top
help_top:
	@echo "#############################################"
	@echo "#          SyoSil UVM SCB targets           #"
	@echo "#############################################"
	@echo ""
	@echo "Variables:"
	@echo "  VENDOR=MENTOR | CADENCE | SYNOPSYS"
	@echo "  Current value: $(VENDOR)"
	@echo ""
	@echo "  UVM_TESTNAME=cl_scbtest_test_base |"
	@echo "               cl_scbtest_test_simple1 |"
	@echo "               cl_scbtest_test_ooo_heavy"
	@echo "  Current value: $(UVM_TESTNAME)"
	@echo ""

.PHONY: help
help: help_top help_vendor help_tb $(foreach vc,$(VERIFICATION_COMPS), help_$(vc)_vc)

