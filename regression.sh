#!/usr/bin/env bash

# If Makefile creates am error on ./regression.sh, first of all make the
# regression script executabile using chmod +x regression.sh

RNUM=$1; shift
TESTS_LIST=( "$@" )
last_idx=$(( ${#TESTS_LIST[@]} - 1 ))
COV_EN=${TESTS_LIST[$last_idx]}
unset TESTS_LIST[$last_idx]

echo "Regression starts."
echo "Iterations per test: $RNUM"
echo "Coverage status: ... $COV_EN "
echo "List of test:"
printf "%s\n" "${TESTS_LIST[@]}"
echo ""
echo ""


set -e; \
for test in ${TESTS_LIST[@]}
do
    for((iter =1; iter <= $RNUM; iter++))
    do
        CUR_TEST_LOG=$test.log.$iter ; \
	make UVM_TESTNAME=$test sim COV=$COV_EN > $CUR_TEST_LOG 2>&1 ; \
	if [ ! -f ./$CUR_TEST_LOG ]; then
            echo "File $CUR_TEST_LOG not found!" ; \
	    exit 1
	fi
	echo -n "Analyzing: $CUR_TEST_LOG for UVM_WARNINGS ... " ; \
        perl -ne 'if(/^[#]*\s*UVM_WARNING\s\:\s+(\d+)/) { print "UVM_WARNINGS: $1\n";}' $CUR_TEST_LOG ; \
	echo -n "Analyzing: $CUR_TEST_LOG for UVM_ERRORS ..... " ; \
        perl -ne 'if(/^[#]*\s*UVM_ERROR\s\:\s+(\d+)/) { print "UVM_ERRORS: $1\n"; exit($1) if($1 ne "0");}' $CUR_TEST_LOG || exit 1 ; \
        echo -n "Analyzing: $CUR_TEST_LOG for UVM_FATALS ..... " ; \
        perl -ne 'if(/^[#]*\s*UVM_FATAL\s\:\s+(\d+)/) { print "UVM_FATALS: $1\n"; exit($1) if($1 ne "0");}' $CUR_TEST_LOG || exit 1 ; \
        echo "" ; \
    done
done
