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
VERIFICATION_COMPS     := syoscb
TB                     := scbtest
SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND ?= 0

#############################################################################
# Global UVM Options
#############################################################################
UVM_VERBOSITY ?= UVM_MEDIUM
UVM_TESTNAME  ?= cl_scbtest_test_ooo_simple
UVM_VERSION   ?= 1.2

#############################################################################
# Global Mentor Options
#############################################################################
ifeq ($(VENDOR),MENTOR)
VLIB := vlib
VMAP := vmap
VLOG := vlog
VSIM := vsim
GCC  := gcc
ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),1)
VLOG_OPTS := -64 -timescale "1ps / 100fs" +define+ASSERTIONS +define+CLOCKING +acc -sv -novopt -L $(MTI_HOME)/uvm-$(UVM_VERSION)
else
VLOG_OPTS := -64 -timescale "1ps / 100fs" +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND +define+ASSERTIONS +define+CLOCKING +acc -sv -novopt -L $(MTI_HOME)/uvm-$(UVM_VERSION)
endif
VSIM_OPTS := -classdebug -novopt -64 -c -L $(MTI_HOME)/uvm-$(UVM_VERSION)
VSIM_WAVE ?= 0
VSIM_DO_CMD ?= run -all
ifeq ($(VSIM_WAVE), 1)
  VSIM_DO_CMD := log -r /*; $(VSIM_DO_CMD)
endif
endif

#############################################################################
# Global Cadence Options
#############################################################################
ifeq ($(VENDOR),CADENCE)
ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),1)
IRUN_OPTS :=
else
IRUN_OPTS := +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND=1
endif
endif

#############################################################################
# Global Synopsys Options
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),1)
VLOG_OPTS :=
else
VLOG_OPTS := +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND=1
endif
endif

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
.PHONY: regression
regression:
	make UVM_TESTNAME=cl_scbtest_test_ooo_simple sim
	make UVM_TESTNAME=cl_scbtest_test_io_simple sim
	make UVM_TESTNAME=cl_scbtest_test_iop_simple sim
	make UVM_TESTNAME=cl_scbtest_test_ooo_tlm sim

#############################################################################
# Mentor targets
#############################################################################
ifeq ($(VENDOR),MENTOR)
.PHONY: compile_vc
compile_vc: $(foreach vc,$(VERIFICATION_COMPS), $(COMPILE_DIR)/$(vc)_vc/compiled_vc)

.PHONY: sim
sim: $(COMPILE_DIR)/work/compiled_tb
	$(VSIM) $(VSIM_OPTS) -lib $(COMPILE_DIR)/work \
        +UVM_MAX_QUIT_COUNT=1,0 +UVM_TESTNAME=$(UVM_TESTNAME) +UVM_VERBOSITY=$(UVM_VERBOSITY) \
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
	-uvmhome $(IFV_ROOT)/tools/methodology/UVM/CDNS-$(UVM_VERSION) \
	-sv \
	-64bit \
	+incdir+./src \
	+incdir+./tb \
	+incdir+./tb/test \
	-top scbtest_top \
	+UVM_MAX_QUIT_COUNT=1,0 \
	+UVM_TESTNAME=$(UVM_TESTNAME) \
	+UVM_VERBOSITY=$(UVM_VERBOSITY) \
	$(IRUN_OPTS) \
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
	vlogan -ntb_opts uvm-$(UVM_VERSION)

.PHONY: sim
sim: elaborate_tb
	./simv +UVM_TESTNAME=$(UVM_TESTNAME) +UVM_VERBOSITY=$(UVM_VERBOSITY)

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
	@echo "  UVM_TESTNAME = cl_scbtest_test_base       |"
	@echo "                 cl_scbtest_test_ooo_simple |"
	@echo "                 cl_scbtest_test_ooo_tlm    |"
	@echo "                 cl_scbtest_test_ooo_heavy  |"
	@echo "                 cl_scbtest_test_io_simple  |"
	@echo "                 cl_scbtest_test_iop_simple |"
	@echo "                 cl_scbtest_test_gp         "
	@echo "  Current value: $(UVM_TESTNAME)"
	@echo ""
	@echo "  UVM_VERBOSITY = UVM_FULL   |"
	@echo "                = UVM_HIGH   |"
	@echo "                = UVM_MEDIUM |"
	@echo "                = UVM_LOW    |"
	@echo "                = UVM_NONE"
	@echo "  Current value: $(UVM_VERBOSITY)"
	@echo ""
ifeq ($(VENDOR), SYNOPSYS)
	@echo "  UVM_VERSION = 1.1 |"
else
	@echo "  UVM_VERSION = 1.1d |"
endif
	@echo "              = 1.2"
	@echo "  Current value: $(UVM_VERSION)"
	@echo ""
	@echo "  SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND = 0 |"
	@echo "                                       = 1"
	@echo "  Current value: $(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND)"
	@echo ""

.PHONY: help
help: help_top help_vendor help_tb $(foreach vc,$(VERIFICATION_COMPS), help_$(vc)_vc)

