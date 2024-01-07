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
UVMLIB_DIR         := $(BASE_DIR)/lib
XML_DIR            := $(BASE_DIR)/lib/xml
COVERAGE_DIR       := $(BASE_DIR)/coverage
REPORT_DIR         := $(BASE_DIR)/report

# Misc variables
VERIFICATION_COMPS := syoscb
TB                 := tb
TB_TOP             := top
SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND ?= 0

GUI               ?= 0
COV               ?= 0

PROF              ?= 0
# Report kind variables. Effective only if PROF=1
# Allowed report generation kind: STD_FILE, DB_CPU, DB_MEM
PROF_KIND         ?= STD_FILE

# Sim random seed. Allowed values: RND or any user defined number
SEED              ?= RND
# Iteration times of the same test inside a regression
RNUM              ?= 1

EVENTS            ?= 10
SIZE              ?= 0
SCENARIO          ?= 0
XML_FILE          ?= syoscb0.test_name.xml
HTML_OUT_FILE     ?= output.html
XSD_FILE          ?= $(XML_DIR)/dump.xsd
NUMBER_OF_COLUMNS ?= 8

#############################################################################
# Global UVM Options
#############################################################################
UVM_VERBOSITY ?= UVM_MEDIUM
UVM_TESTNAME  ?= cl_scb_test_ooo_std_simple
UVM_VERSION   ?= 1.2
UVM_OPTS := +uvm_set_config_int=uvm_test_top,events,$(EVENTS) +uvm_set_config_int=uvm_test_top,size,$(SIZE) +uvm_set_config_int=uvm_test_top,sc,$(SCENARIO)

#############################################################################
# Global Mentor Options
#############################################################################
ifeq ($(VENDOR),MENTOR)
VLIB := vlib
VMAP := vmap
VLOG := vlog
VSIM := vsim
GCC  := gcc

VLOG_OPTS := -64 -timescale "1ps / 100fs" +define+ASSERTIONS +define+CLOCKING +acc -sv -L $(MTI_HOME)/uvm-$(UVM_VERSION)

ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),0)
VLOG_OPTS := +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND $(VLOG_OPTS)
endif

VSIM_OPTS := -classdebug -64 -L $(MTI_HOME)/uvm-$(UVM_VERSION)
VSIM_WAVE ?= 0
VSIM_DO_CMD ?= run -all
ifeq ($(VSIM_WAVE), 1)
  VSIM_DO_CMD := log -r /*; $(VSIM_DO_CMD)
endif

ifeq ($(GUI), 1)
VSIM_OPTS := -gui $(VSIM_OPTS)
else
VSIM_OPTS := -c $(VSIM_OPTS)
endif

ifeq ($(COV), 1)
VSIM_DO_CMD := coverage save -onexit $(COVERAGE_DIR)/cov_$(UVM_TESTNAME).ucdb; $(VSIM_DO_CMD)
endif

ifeq ($(PROF),1)

ifeq ($(PROF_KIND), STD_FILE)
VSIM_DO_CMD := \
               write report -capacity -s -l std_report.out; \
               $(VSIM_DO_CMD)

VSIM_OPTS := -capacity $(VSIM_OPTS)
endif

ifeq ($(PROF_KIND), DB_CPU)
VSIM_DO_CMD := \
               profile on; \
               profile interval 2; \
               profile save -onexit vsim_cpu_report_db.pdb; \
               profile report -onexit -calltree -p -file vsim_cpu_report.out; \
               $(VSIM_DO_CMD)

VSIM_OPTS := -capacity $(VSIM_OPTS)
endif

ifeq ($(PROF_KIND), DB_MEM)
VSIM_DO_CMD := \
               capstats -du -decl -line -save vsim_mem_report_db.cdb; \
               capstats -du -decl -line -filename vsim_mem_report.out; \
               $(VSIM_DO_CMD)

VSIM_OPTS := -capacity=line $(VSIM_OPTS)
endif

endif
endif

ifeq ($(SEED), RND)
VSIM_OPTS := \
             -sv_seed random \
             $(VSIM_OPTS)
else
VSIM_OPTS := \
             -sv_seed $(SEED) \
             $(VSIM_OPTS)
endif

#############################################################################
# Global Cadence Options
#############################################################################
ifeq ($(VENDOR),CADENCE)
XRUN_OPTS := -licqueue                                                      \
             -makelib worklib                                               \
             -endlib	                                                      \
             -uvm                                                           \
             -uvmhome $(IFV_ROOT)/tools/methodology/UVM/CDNS-$(UVM_VERSION) \
             -sv                                                            \
             -64bit                                                         \
             +incdir+./src                                                  \
             +incdir+./tb                                                   \
             +incdir+./tb/test/scb                                          \
             +incdir+./tb/test/scb/cmp                                      \
             +incdir+./tb/test/scb/io                                       \
             +incdir+./tb/test/scb/ooo                                      \
             +incdir+./tb/test/scb/iop                                      \
             +incdir+./tb/test/scbs                                         \
             -top $(TB_TOP)

ifeq ($(GUI), 1)
XRUN_OPTS := -gui -linedebug $(XRUN_OPTS)
endif

ifeq ($(COV), 1)
XRUN_OPTS := $(XRUN_OPTS) -covworkdir $(COVERAGE_DIR) \
             -coverage all -covoverwrite -covdut $(TB_TOP)
endif

ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),0)
XRUN_OPTS := +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND=1 $(XRUN_OPTS)
endif

ifeq ($(PROF), 1)

ifeq ($(PROF_KIND), STD_FILE)
XRUN_OPTS := \
             $(XRUN_OPTS) \
             -perfstat \
             -perflog $(BASE_DIR)/xmstats_$(UVM_TESTNAME).out
endif

ifeq ($(PROF_KIND), DB_CPU)
XRUN_OPTS := \
             $(XRUN_OPTS) \
             -prof_work xprof_cpu_report \
             -prof_interval 1 \
             -xprof
endif

ifeq ($(PROF_KIND), DB_MEM)
XRUN_OPTS := \
             $(XRUN_OPTS) \
             -prof_work xprof_mem_report \
             -mem_xprof
endif

endif
endif

ifeq ($(SEED), RND)
XRUN_OPTS := \
             $(XRUN_OPTS) \
             -svseed random
else
XRUN_OPTS := \
             $(XRUN_OPTS) \
             -svseed $(SEED)
endif
#############################################################################
# Global Synopsys Options
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
VLOG_OPTS := -full64 -ntb_opts uvm-$(UVM_VERSION) -sverilog

VLOGAN_OPTS := -full64 -ntb_opts uvm-$(UVM_VERSION)

ifeq ($(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND),0)
VLOG_OPTS := +define+SYOSIL_APPLY_TLM_GP_CMP_WORKAROUND=1 $(VLOG_OPTS)
endif

ifeq ($(GUI), 1)
VLOGAN_OPTS := -gui $(VLOGAN_OPTS)
endif

ifeq ($(COV), 1)
VLOGAN_OPTS := -cm_dir $(COVERAGE_DIR)/cov_$(UVM_TESTNAME).vdb $(VLOGAN_OPTS)
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
#final
UVM_TESTS := cl_scb_test_io_2hp_std_simple         \
             cl_scb_test_io_2hp_md5_simple         \
             cl_scb_test_io_2hp_std_sbs_print      \
             cl_scb_test_io_md5_disable_compare    \
             cl_scb_test_io_md5_simple             \
             cl_scb_test_io_md5_dump_orphans       \
             cl_scb_test_iop_md5_simple            \
             cl_scb_test_iop_std_simple            \
             cl_scb_test_iop_std_sbs_print         \
             cl_scb_test_io_std_comparer_printer   \
             cl_scb_test_io_std_disable_compare    \
             cl_scb_test_io_std_comparer_report    \
             cl_scb_test_io_std_dump_simple        \
             cl_scb_test_io_std_dump_default       \
             cl_scb_test_io_std_dump_mixed         \
             cl_scb_test_io_std_dump_xml_split     \
             cl_scb_test_io_std_dump_xml_join      \
             cl_scb_test_io_std_dump_max_size_less \
             cl_scb_test_io_std_dump_max_size      \
             cl_scb_test_io_std_dump               \
             cl_scb_test_io_std_simple             \
             cl_scb_test_io_std_simple_mutexed     \
             cl_scb_test_io_std_tlm_mutexed        \
             cl_scb_test_io_std_tlm_gp_test        \
             cl_scb_test_io_std_simple_real        \
             cl_scb_test_io_std_intermediate_dump  \
             cl_scb_test_io_std_sbs_print          \
             cl_scb_test_io_std_insert_item        \
             cl_scb_test_io_std_insert_item_md5    \
             cl_scb_test_ooo_io_md5_simple         \
             cl_scb_test_ooo_io_std_simple         \
             cl_scb_test_ooo_md5_gp                \
             cl_scb_test_ooo_md5_heavy             \
             cl_scb_test_ooo_md5_simple            \
             cl_scb_test_ooo_md5_duplets           \
             cl_scb_test_ooo_md5_tlm               \
             cl_scb_test_ooo_std_max_search_window \
             cl_scb_test_ooo_std_gp                \
             cl_scb_test_ooo_std_heavy             \
             cl_scb_test_ooo_std_simple            \
             cl_scb_test_ooo_std_tlm               \
             cl_scb_test_ooo_std_dump_orphans      \
             cl_scb_test_ooo_std_dump_orphans_xml  \
             cl_scb_test_ooo_md5_validate          \
             cl_scb_test_ooo_std_primary_multiple  \
             cl_scb_test_ooo_std_trigger_greed     \
             cl_scbs_test_io_std_base              \
             cl_scbs_test_io_std_cc                \
             cl_scbs_test_iop_std_base             \
             cl_scbs_test_ooo_std_base             \
             cl_scbs_test_ooo_std_flush            \
             cl_scbs_test_filter_trfm_param        \
             cl_scb_test_cmp_io_ff                 \
             cl_scb_test_cmp_io_fd                 \
             cl_scb_test_cmp_io_fm                 \
             cl_scb_test_cmp_io_df                 \
             cl_scb_test_cmp_io_dd                 \
             cl_scb_test_cmp_io_dm                 \
             cl_scb_test_cmp_io_mf                 \
             cl_scb_test_cmp_io_md                 \
             cl_scb_test_cmp_io_mm                 \
             cl_scb_test_cmp_ooo_ff                \
             cl_scb_test_cmp_ooo_fd                \
             cl_scb_test_cmp_ooo_fm                \
             cl_scb_test_cmp_ooo_df                \
             cl_scb_test_cmp_ooo_dd                \
             cl_scb_test_cmp_ooo_dm                \
             cl_scb_test_cmp_ooo_mf                \
             cl_scb_test_cmp_ooo_md                \
             cl_scb_test_cmp_ooo_mm                \
             cl_scb_test_copy_cfg                  \
             cl_scb_test_uvm_xml_printer           \
             cl_scb_test_iterator_correctness      \
             cl_scb_test_iterator_unit_tests       \
             cl_scb_test_iterator_unit_tests_md5   \
             cl_scb_test_md5_hash_collisions       \
             cl_scb_test_md5

UVM_RND_TESTS:= cl_scb_test_rnd

UVM_CMP_TESTS :=  cl_scb_test_cmp_io_ff \
                  cl_scb_test_cmp_io_fd \
                  cl_scb_test_cmp_io_fm \
                  cl_scb_test_cmp_io_df \
                  cl_scb_test_cmp_io_dd \
                  cl_scb_test_cmp_io_dm \
                  cl_scb_test_cmp_io_mf \
                  cl_scb_test_cmp_io_md \
                  cl_scb_test_cmp_io_mm \
                  cl_scb_test_cmp_ooo_ff \
                  cl_scb_test_cmp_ooo_fd \
                  cl_scb_test_cmp_ooo_fm \
                  cl_scb_test_cmp_ooo_df \
                  cl_scb_test_cmp_ooo_dd \
                  cl_scb_test_cmp_ooo_dm \
                  cl_scb_test_cmp_ooo_mf \
                  cl_scb_test_cmp_ooo_md \
                  cl_scb_test_cmp_ooo_mm

UVM_TESTS_PRINT := $(foreach test,$(UVM_TESTS), $(test).print)

.PHONY: clean_regression
clean_regression: clean
	rm -rf *.log.*


.PHONY: regression
regression: clean_regression
	./regression.sh $(RNUM) $(UVM_TESTS) $(COV)

.PHONY: regression_rnd
regression_rnd: clean_regression
	./regression.sh $(RNUM) $(UVM_RND_TESTS) $(COV)

.PHONY: regression_cmp
regression_cmp: clean_regression
	./regression.sh $(RNUM) $(UVM_CMP_TESTS) $(COV)


print_uvm_tests: $(UVM_TESTS_PRINT)

.PHONY: %.print
%.print:
	@echo "    $(*F)"

#############################################################################
# Mentor targets
#############################################################################
ifeq ($(VENDOR),MENTOR)
.PHONY: compile_vc
compile_vc: $(foreach vc,$(VERIFICATION_COMPS), $(COMPILE_DIR)/$(vc)_vc/compiled_vc)

.PHONY: sim
sim: $(COMPILE_DIR)/work/compiled_tb
	$(VSIM) $(VSIM_OPTS) -lib $(COMPILE_DIR)/work \
        +UVM_MAX_QUIT_COUNT=1,0 +UVM_TESTNAME=$(UVM_TESTNAME) +UVM_VERBOSITY=$(UVM_VERBOSITY) $(UVM_OPTS) \
	$(foreach vc,$(VERIFICATION_COMPS), -L $(COMPILE_DIR)/$(vc)_vc) \
        -do "$(VSIM_DO_CMD)" \
	$(TB_TOP)

.PHONY: clean
clean: common_clean
	rm -rf transcript vish_stacktrace.vstf vsim.wlf transcript vlog.opt *.out *.log *.pdb *.cdb vsim_stacktrace.vstf


.PHONY : merge_coverage
merge_coverage:
	rm -rf $(COVERAGE_DIR)/globalCoverage.ucdb
	vcover merge $(COVERAGE_DIR)/*.ucdb -out $(COVERAGE_DIR)/globalCoverage.ucdb

.PHONY : generate_report
generate_report:
	vcover report -html -output $(REPORT_DIR)/ -details -verbose $(COVERAGE_DIR)/globalCoverage.ucdb

.PHONY: help_vendor
help_vendor:
	@echo "############# Vendor targets ################"
	@echo ""
	@echo "  TARGET: compile_vc"
	@echo "  Compile all VCs"
	@echo ""
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
endif

#############################################################################
# Cadence targets
#############################################################################
ifeq ($(VENDOR),CADENCE)
.PHONY: sim
sim:
	xrun                            \
	$(XRUN_OPTS)                    \
	+UVM_MAX_QUIT_COUNT=1,0         \
	+UVM_TESTNAME=$(UVM_TESTNAME)   \
	+UVM_VERBOSITY=$(UVM_VERBOSITY) \
	$(UVM_OPTS)                     \
	./lib/pk_utils_uvm.sv           \
	./src/pk_syoscb.sv              \
	./tb/pk_tb.sv                   \
	./tb/top.sv

.PHONY : merge_coverage
merge_coverage:
	rm -rf $(COVERAGE_DIR)/scope/all;
	imc -execcmd "merge $(COVERAGE_DIR)/scope/test_* -out $(COVERAGE_DIR)/scope/all -metrics all -initial_model union_all -message 1;"

.PHONY : generate_report
generate_report:
	mkdir -p $(REPORT_DIR)/report
        # Currenlty, report_metrics command is not working properly with generating html file, so instead report command will be
        # used for now, report_metrics command would be like :
        # report_metrics -detail -metrics all -out $(REPORT_DIR) -overwrite
	imc -execcmd "load  $(COVERAGE_DIR)/scope/all;report -html -metrics all -out $(REPORT_DIR) -overwrite"

.PHONY: clean
clean: common_clean
	rm -rf INCA_libs irun.log xrun.log xrun.history xcelium.d *.log *.out *.log* *.xml waves.shm

.PHONY: help_vendor
help_vendor:
	@echo "############# Vendor targets ################"
	@echo ""
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
endif

#############################################################################
# Synopsys targets
#############################################################################
ifeq ($(VENDOR),SYNOPSYS)
.PHONY: synopsys_uvm
synopsys_uvm:
	vlogan $(VLOGAN_OPTS)

.PHONY: sim
sim: elaborate_tb
	./simv +UVM_TESTNAME=$(UVM_TESTNAME) +UVM_VERBOSITY=$(UVM_VERBOSITY) $(UVM_OPTS)

.PHONY: clean
clean: common_clean
	rm -rf DVEfiles AN.DB csrc simv* ucli.key vc_hdrs.h .vlogansetup.args .vlogansetup.env

.PHONY: help_vendor
help_vendor:
	@echo "############# Vendor targets ################"
	@echo ""
	@echo "  TARGET: synopsys_uvm"
	@echo "  Compile UVM"
	@echo ""
	@echo "  TARGET: sim"
	@echo "  Run selected test"
	@echo ""
	@echo "  TARGET: clean"
	@echo "  Remove all temporary files"
	@echo ""
endif


#############################################################################
# SCB dump generation
#############################################################################
.PHONY: generate_html
generate_html:
	xsltproc --param numberofcolumns $(NUMBER_OF_COLUMNS) \
                  -o $(HTML_OUT_FILE) $(XML_DIR)/dump_html.xslt $(XML_FILE)

.PHONY: check_xml
check_xml:
	xmllint --schema $(XSD_FILE) $(XML_FILE) --noout

.PHONY: generate_dot
generate_dot:
	xsltproc -o output.dot $(XML_DIR)/dump_dot.xslt $(XML_FILE)

.PHONY: dot2svg
dot2svg: generate_dot
	 dot -Tsvg output.dot -o dot.svg

#############################################################################
# Clean target
#############################################################################
.PHONY: common_clean
common_clean:
	rm -rf output syoscb*.txt syoscb*.xml output.html *.time *log.txt

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
	@echo "  UVM_TESTNAME ="
	@make --no-print-directory print_uvm_tests
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
	@echo "  UVM_VERSION = 1.1  |"
else
	@echo "  UVM_VERSION = 1.1d |"
endif
	@echo "              = 1.2  |"
ifneq ($(VENDOR), MENTOR)
	@echo "              = IEEE"
endif
	@echo "  Current value: $(UVM_VERSION)"
	@echo ""
	@echo "  SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND = 0 |"
	@echo "                                       = 1"
	@echo "  Current value: $(SYOSIL_DISABLE_TLM_GP_CMP_WORKAROUND)"
	@echo ""
	@echo "############# Common targets ################"
	@echo ""
	@echo "  TARGET: regression"
	@echo "  Runs all tests"
	@echo ""
	@echo "  TARGET: clean_regression"
	@echo "  Removes regression results"
	@echo ""

.PHONY: help
help: help_top help_vendor help_tb $(foreach vc,$(VERIFICATION_COMPS), help_$(vc)_vc)
