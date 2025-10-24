#!/bin/bash
# R Jesse Chaney
# rchaney@pdx.edu
#FILES=$(seq 1 3 12)
FILES="1 2 3 4 5 6 7 8 9 10 11 12"

PROG1=cae-xor
LAB=Lab1
CLASS=cs333
#JDIR=~rchaney/Classes/${CLASS}/Labs/src/caesar
JDIR=~rchaney/Classes/${CLASS}/Labs/${LAB}


SDIR=.
JPROG1=${JDIR}/${PROG1}
SPROG1=${SDIR}/${PROG1}

COWSAY=/usr/games/cowsay

VERBOSE=0
AVAIL_POINTS=300
TOTAL_POINTS=10
#VIEW_POINTS=0
CLEANUP=1
FILE_HOST=babbage
#BIG_TEST=1

#SLEEP_TIME=30
#TIME_OUT=5m
TIME_OUT=10s
TIME_OUT_KILL=15s
#MEM_THRESHOLD=4
#MEM_THRESHOLD=2

DIFF=diff
DIFF_OPTIONS=" "
#DIFF_OPTIONS=" -w"
NOLEAKS="All heap blocks were freed -- no leaks are possible"
LEAKS_FOUND=0
TIMEOUT_COUNT=0
DIFF_COUNT=0
FAIL_COUNT=0
FAIL_MAX=9

SCRIPT=$0

show_help()
{
    echo "${SCRIPT}"
    echo "    -C : do not delete all the various test files. Automatic if a test fails."
    echo "    -v : provide some verbose output. Currently, this does nothing...  :-("
    echo "    -x : see EVERYTHING that is going one. LOTS of output. Hard to understand. A wild ride."
    echo "    -h : print this AMAZING help text."
}

build()
{
    echo -e "\n********************************************"
    echo "Begin Build"
    make clean > /dev/null 2> /dev/null
    make clean all > /dev/null 2> /dev/null

    if [ ! -x ${PROG1} ]
    then
        echo "  **** Did not build!!!"
        echo "      Exiting with 0 points"
        exit 2
    fi
    echo "  Build success!"

    ln -sf ${JDIR}/data*.txt .
    echo "End Build"
    echo -e "********************************************\n"
}

test_caesar_e_spaces()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using a space as the caesar key"
    ${JPROG1} -D -c ' ' < ${DFILE} > j_ctest_${TEST_NUM}_SP1.out 2> j_ctest_${TEST_NUM}_SP1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ' '  < ${DFILE} > s_ctest_${TEST_NUM}_SP1.out 2> s_ctest_${TEST_NUM}_SP1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ' ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP1.out s_ctest_${TEST_NUM}_SP1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP1.out s_ctest_${TEST_NUM}_SP1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ' ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using a space as the caesar key"
    ${JPROG1} -D -d -c ' ' < j_ctest_${TEST_NUM}_SP1.out > j_ctest_${TEST_NUM}_SP1_d.out 2> j_ctest_${TEST_NUM}_SP1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ' ' < j_ctest_${TEST_NUM}_SP1.out > s_ctest_${TEST_NUM}_SP1_d.out 2> s_ctest_${TEST_NUM}_SP1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ' ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP1_d.out s_ctest_${TEST_NUM}_SP1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP1_d.out s_ctest_${TEST_NUM}_SP1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ' ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "Encryption Test Begin data-file=${DFILE} using 5 spaces as the caesar key"
    ${JPROG1} -D -c '     ' < ${DFILE} > j_ctest_${TEST_NUM}_SP5.out 2> j_ctest_${TEST_NUM}_SP5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c '     '  < ${DFILE} > s_ctest_${TEST_NUM}_SP5.out 2> s_ctest_${TEST_NUM}_SP5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c '     ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP5.out s_ctest_${TEST_NUM}_SP5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP5.out s_ctest_${TEST_NUM}_SP5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c '     ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 5 spaces as the caesar key"
    ${JPROG1} -D -d -c '     ' < j_ctest_${TEST_NUM}_SP5.out > j_ctest_${TEST_NUM}_SP5_d.out 2> j_ctest_${TEST_NUM}_SP5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c '     ' < j_ctest_${TEST_NUM}_SP5.out > s_ctest_${TEST_NUM}_SP5_d.out 2> s_ctest_${TEST_NUM}_SP5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1}  -d -c '     ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP5_d.out s_ctest_${TEST_NUM}_SP5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP5_d.out s_ctest_${TEST_NUM}_SP5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c '     ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "Encryption Test Begin data-file=${DFILE} using 10 spaces as the caesar key"
    ${JPROG1} -D -c '          ' < ${DFILE} > j_ctest_${TEST_NUM}_SP10.out 2> j_ctest_${TEST_NUM}_SP10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c '          '  < ${DFILE} > s_ctest_${TEST_NUM}_SP10.out 2> s_ctest_${TEST_NUM}_SP10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c '          ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP10.out s_ctest_${TEST_NUM}_SP10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP10.out s_ctest_${TEST_NUM}_SP10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c '          ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 10 spaces as the caesar key"
    ${JPROG1} -D -d -c '          ' < j_ctest_${TEST_NUM}_SP5.out > j_ctest_${TEST_NUM}_SP10_d.out 2> j_ctest_${TEST_NUM}_SP10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c '          ' < j_ctest_${TEST_NUM}_SP5.out > s_ctest_${TEST_NUM}_SP10_d.out 2> s_ctest_${TEST_NUM}_SP10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c '          ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP10_d.out s_ctest_${TEST_NUM}_SP10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_SP10_d.out s_ctest_${TEST_NUM}_SP10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c '          ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_caesar_e_numbers()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using '1' as the caesar key"
    ${JPROG1} -D -c '1' < ${DFILE} > j_ctest_${TEST_NUM}_NB1.out 2> j_ctest_${TEST_NUM}_NB1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c '1' < ${DFILE} > s_ctest_${TEST_NUM}_NB1.out 2> s_ctest_${TEST_NUM}_NB1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c '1' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB1.out s_ctest_${TEST_NUM}_NB1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB1.out s_ctest_${TEST_NUM}_NB1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c '1' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using '1' as the caesar key"
    ${JPROG1} -D -d -c '1' < j_ctest_${TEST_NUM}_NB1.out > j_ctest_${TEST_NUM}_NB1_d.out 2> j_ctest_${TEST_NUM}_NB1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c '1' < j_ctest_${TEST_NUM}_NB1.out > s_ctest_${TEST_NUM}_NB1_d.out 2> s_ctest_${TEST_NUM}_NB1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c '1' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB1_d.out s_ctest_${TEST_NUM}_NB1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB1_d.out s_ctest_${TEST_NUM}_NB1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c '1' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 12345 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_NB5.out 2> j_ctest_${TEST_NUM}_NB5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_NB5.out 2> s_ctest_${TEST_NUM}_NB5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB5.out s_ctest_${TEST_NUM}_NB5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB5.out s_ctest_${TEST_NUM}_NB5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_NB5.out > j_ctest_${TEST_NUM}_NB5_d.out 2> j_ctest_${TEST_NUM}_NB5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_NB5.out > s_ctest_${TEST_NUM}_NB5_d.out 2> s_ctest_${TEST_NUM}_NB5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB5_d.out s_ctest_${TEST_NUM}_NB5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB5_d.out s_ctest_${TEST_NUM}_NB5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 1234567890 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_NB10.out 2> j_ctest_${TEST_NUM}_NB10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_NB10.out 2> s_ctest_${TEST_NUM}_NB10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB10.out s_ctest_${TEST_NUM}_NB10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB10.out s_ctest_${TEST_NUM}_NB10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_NB10.out > j_ctest_${TEST_NUM}_NB10_d.out 2> j_ctest_${TEST_NUM}_NB10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_NB10.out > s_ctest_${TEST_NUM}_NB10_d.out 2> s_ctest_${TEST_NUM}_NB10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB10_d.out s_ctest_${TEST_NUM}_NB10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_NB10_d.out s_ctest_${TEST_NUM}_NB10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_caesar_e_letters()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using 'a' as the caesar key"
    ${JPROG1} -D -c 'a' < ${DFILE} > j_ctest_${TEST_NUM}_LT1.out 2> j_ctest_${TEST_NUM}_LT1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c 'a' < ${DFILE} > s_ctest_${TEST_NUM}_LT1.out 2> s_ctest_${TEST_NUM}_LT1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c 'a' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT1.out s_ctest_${TEST_NUM}_LT1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT1.out s_ctest_${TEST_NUM}_LT1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c 'a' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 'a' as the caesar key"
    ${JPROG1} -D -d -c 'a' < j_ctest_${TEST_NUM}_LT1.out > j_ctest_${TEST_NUM}_LT1_d.out 2> j_ctest_${TEST_NUM}_LT1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c 'a' < j_ctest_${TEST_NUM}_LT1.out > s_ctest_${TEST_NUM}_LT1_d.out 2> s_ctest_${TEST_NUM}_LT1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c 'a' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT1_d.out s_ctest_${TEST_NUM}_LT1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT1_d.out s_ctest_${TEST_NUM}_LT1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c 'a' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo aBcDe | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_LT5.out 2> j_ctest_${TEST_NUM}_LT5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_LT5.out 2> s_ctest_${TEST_NUM}_LT5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT5.out s_ctest_${TEST_NUM}_LT5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT5.out s_ctest_${TEST_NUM}_LT5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_LT5.out > j_ctest_${TEST_NUM}_LT5_d.out 2> j_ctest_${TEST_NUM}_LT5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_LT5.out > s_ctest_${TEST_NUM}_LT5_d.out 2> s_ctest_${TEST_NUM}_LT5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT5_d.out s_ctest_${TEST_NUM}_LT5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT5_d.out s_ctest_${TEST_NUM}_LT5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo AbCdEfgHiJLMNOPQRSTUVWXYZlmnopqrstuvwxyz0123456789 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_LT10.out 2> j_ctest_${TEST_NUM}_LT10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_LT10.out 2> s_ctest_${TEST_NUM}_LT10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT10.out s_ctest_${TEST_NUM}_LT10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT10.out s_ctest_${TEST_NUM}_LT10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_LT10.out > j_ctest_${TEST_NUM}_LT10_d.out 2> j_ctest_${TEST_NUM}_LT10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_LT10.out > s_ctest_${TEST_NUM}_LT10_d.out 2> s_ctest_${TEST_NUM}_LT10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT10_d.out s_ctest_${TEST_NUM}_LT10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_LT10_d.out s_ctest_${TEST_NUM}_LT10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_caesar_e_end()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using '~' as the caesar key"

    #set -x
    ${JPROG1} -D -c '~' < ${DFILE} > j_ctest_${TEST_NUM}_EN1.out 2> j_ctest_${TEST_NUM}_EN1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c '~' < ${DFILE} > s_ctest_${TEST_NUM}_EN1.out 2> s_ctest_${TEST_NUM}_EN1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1}  -c '~' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN1.out s_ctest_${TEST_NUM}_EN1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN1.out s_ctest_${TEST_NUM}_EN1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c '~' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using '~' as the caesar key"
    #echo "    j_ctest_${TEST_NUM}_EN1.out"
    ${JPROG1} -D -d -c '~' < j_ctest_${TEST_NUM}_EN1.out > j_ctest_${TEST_NUM}_EN1_d.out 2> j_ctest_${TEST_NUM}_EN1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c '~' < j_ctest_${TEST_NUM}_EN1.out > s_ctest_${TEST_NUM}_EN1_d.out 2> s_ctest_${TEST_NUM}_EN1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d  -c '~' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN1_d.out s_ctest_${TEST_NUM}_EN1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN1_d.out s_ctest_${TEST_NUM}_EN1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c '~' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 'z{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_EN5.out 2> j_ctest_${TEST_NUM}_EN5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_EN5.out 2> s_ctest_${TEST_NUM}_EN5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN5.out s_ctest_${TEST_NUM}_EN5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN5.out s_ctest_${TEST_NUM}_EN5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_EN5.out > j_ctest_${TEST_NUM}_EN5_d.out 2> j_ctest_${TEST_NUM}_EN5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_EN5.out > s_ctest_${TEST_NUM}_EN5_d.out 2> s_ctest_${TEST_NUM}_EN5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN5_d.out s_ctest_${TEST_NUM}_EN5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN5_d.out s_ctest_${TEST_NUM}_EN5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 'uvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -c ${ENC} < ${DFILE} > j_ctest_${TEST_NUM}_EN10.out 2> j_ctest_${TEST_NUM}_EN10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC}  < ${DFILE} > s_ctest_${TEST_NUM}_EN10.out 2> s_ctest_${TEST_NUM}_EN10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN10.out s_ctest_${TEST_NUM}_EN10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN10.out s_ctest_${TEST_NUM}_EN10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the caesar key"
    ${JPROG1} -D -d -c ${ENC} < j_ctest_${TEST_NUM}_EN10.out > j_ctest_${TEST_NUM}_EN10_d.out 2> j_ctest_${TEST_NUM}_EN10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c ${ENC} < j_ctest_${TEST_NUM}_EN10.out > s_ctest_${TEST_NUM}_EN10_d.out 2> s_ctest_${TEST_NUM}_EN10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN10_d.out s_ctest_${TEST_NUM}_EN10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_ctest_${TEST_NUM}_EN10_d.out s_ctest_${TEST_NUM}_EN10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


# XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR
# XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR
# XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR
# XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR XOR

test_xor_e_spaces()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using a space as the xor key"
    ${JPROG1} -D -x ' ' < ${DFILE} > j_xtest_${TEST_NUM}_SP1.out 2> j_xtest_${TEST_NUM}_SP1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ' '  < ${DFILE} > s_xtest_${TEST_NUM}_SP1.out 2> s_xtest_${TEST_NUM}_SP1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ' ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi

    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP1.out s_xtest_${TEST_NUM}_SP1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP1.out s_xtest_${TEST_NUM}_SP1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ' ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using a space as the xor key"
    ${JPROG1} -D -d -x ' ' < j_xtest_${TEST_NUM}_SP1.out > j_xtest_${TEST_NUM}_SP1_d.out 2> j_xtest_${TEST_NUM}_SP1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x ' ' < j_xtest_${TEST_NUM}_SP1.out > s_xtest_${TEST_NUM}_SP1_d.out 2> s_xtest_${TEST_NUM}_SP1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x ' ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP1_d.out s_xtest_${TEST_NUM}_SP1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP1_d.out s_xtest_${TEST_NUM}_SP1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x ' ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "Encryption Test Begin data-file=${DFILE} using 5 spaces as the xor key"
    ${JPROG1} -D -x '     ' < ${DFILE} > j_xtest_${TEST_NUM}_SP5.out 2> j_xtest_${TEST_NUM}_SP5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x '     '  < ${DFILE} > s_xtest_${TEST_NUM}_SP5.out 2> s_xtest_${TEST_NUM}_SP5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x '     ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP5.out s_xtest_${TEST_NUM}_SP5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP5.out s_xtest_${TEST_NUM}_SP5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x '     ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 5 spaces as the xor key"
    ${JPROG1} -D -d -x '     ' < j_xtest_${TEST_NUM}_SP5.out > j_xtest_${TEST_NUM}_SP5_d.out 2> j_xtest_${TEST_NUM}_SP5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x '     ' < j_xtest_${TEST_NUM}_SP5.out > s_xtest_${TEST_NUM}_SP5_d.out 2> s_xtest_${TEST_NUM}_SP5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x '     ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP5_d.out s_xtest_${TEST_NUM}_SP5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP5_d.out s_xtest_${TEST_NUM}_SP5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x '     ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "Encryption Test Begin data-file=${DFILE} using 10 spaces as the xor key"
    ${JPROG1} -D -x '          ' < ${DFILE} > j_xtest_${TEST_NUM}_SP10.out 2> j_xtest_${TEST_NUM}_SP10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x '          '  < ${DFILE} > s_xtest_${TEST_NUM}_SP10.out 2> s_xtest_${TEST_NUM}_SP10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x '          ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP10.out s_xtest_${TEST_NUM}_SP10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP10.out s_xtest_${TEST_NUM}_SP10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x '          ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 10 spaces as the xor key"
    ${JPROG1} -D -d -x '          ' < j_xtest_${TEST_NUM}_SP5.out > j_xtest_${TEST_NUM}_SP10_d.out 2> j_xtest_${TEST_NUM}_SP10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x '          ' < j_xtest_${TEST_NUM}_SP5.out > s_xtest_${TEST_NUM}_SP10_d.out 2> s_xtest_${TEST_NUM}_SP10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x '          ' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP10_d.out s_xtest_${TEST_NUM}_SP10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_SP10_d.out s_xtest_${TEST_NUM}_SP10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x '          ' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_xor_e_numbers()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using '1' as the xor key"
    ${JPROG1} -D -x '1' < ${DFILE} > j_xtest_${TEST_NUM}_NB1.out 2> j_xtest_${TEST_NUM}_NB1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x '1' < ${DFILE} > s_xtest_${TEST_NUM}_NB1.out 2> s_xtest_${TEST_NUM}_NB1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x '1' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB1.out s_xtest_${TEST_NUM}_NB1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB1.out s_xtest_${TEST_NUM}_NB1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x '1' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using '1' as the xor key"
    ${JPROG1} -D -d -x '1' < j_xtest_${TEST_NUM}_NB1.out > j_xtest_${TEST_NUM}_NB1_d.out 2> j_xtest_${TEST_NUM}_NB1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x '1' < j_xtest_${TEST_NUM}_NB1.out > s_xtest_${TEST_NUM}_NB1_d.out 2> s_xtest_${TEST_NUM}_NB1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x '1' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB1_d.out s_xtest_${TEST_NUM}_NB1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB1_d.out s_xtest_${TEST_NUM}_NB1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x '1' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 12345 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_NB5.out 2> j_xtest_${TEST_NUM}_NB5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC}  < ${DFILE} > s_xtest_${TEST_NUM}_NB5.out 2> s_xtest_${TEST_NUM}_NB5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        #        ((TOTAL_POINTS+=5))
        #        echo "  That's 5 points for a non-error exit TOTAL_POINTS=${TOTAL_POINTS}"
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB5.out s_xtest_${TEST_NUM}_NB5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB5.out s_xtest_${TEST_NUM}_NB5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_NB5.out > j_xtest_${TEST_NUM}_NB5_d.out 2> j_xtest_${TEST_NUM}_NB5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x ${ENC} < j_xtest_${TEST_NUM}_NB5.out > s_xtest_${TEST_NUM}_NB5_d.out 2> s_xtest_${TEST_NUM}_NB5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB5_d.out s_xtest_${TEST_NUM}_NB5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB5_d.out s_xtest_${TEST_NUM}_NB5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 1234567890 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_NB10.out 2> j_xtest_${TEST_NUM}_NB10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC}  < ${DFILE} > s_xtest_${TEST_NUM}_NB10.out 2> s_xtest_${TEST_NUM}_NB10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB10.out s_xtest_${TEST_NUM}_NB10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB10.out s_xtest_${TEST_NUM}_NB10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_NB10.out > j_xtest_${TEST_NUM}_NB10_d.out 2> j_xtest_${TEST_NUM}_NB10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x ${ENC} < j_xtest_${TEST_NUM}_NB10.out > s_xtest_${TEST_NUM}_NB10_d.out 2> s_xtest_${TEST_NUM}_NB10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB10_d.out s_xtest_${TEST_NUM}_NB10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_NB10_d.out s_xtest_${TEST_NUM}_NB10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_xor_e_letters()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using 'a' as the xor key"
    ${JPROG1} -D -x 'a' < ${DFILE} > j_xtest_${TEST_NUM}_LT1.out 2> j_xtest_${TEST_NUM}_LT1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x 'a' < ${DFILE} > s_xtest_${TEST_NUM}_LT1.out 2> s_xtest_${TEST_NUM}_LT1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x 'a' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT1.out s_xtest_${TEST_NUM}_LT1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT1.out s_xtest_${TEST_NUM}_LT1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x 'a' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using 'a' as the xor key"
    ${JPROG1} -D -d -x 'a' < j_xtest_${TEST_NUM}_LT1.out > j_xtest_${TEST_NUM}_LT1_d.out 2> j_xtest_${TEST_NUM}_LT1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x 'a' < j_xtest_${TEST_NUM}_LT1.out > s_xtest_${TEST_NUM}_LT1_d.out 2> s_xtest_${TEST_NUM}_LT1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x 'a' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT1_d.out s_xtest_${TEST_NUM}_LT1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT1_d.out s_xtest_${TEST_NUM}_LT1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x 'a' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo aBcDe | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_LT5.out 2> j_xtest_${TEST_NUM}_LT5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC}  < ${DFILE} > s_xtest_${TEST_NUM}_LT5.out 2> s_xtest_${TEST_NUM}_LT5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT5.out s_xtest_${TEST_NUM}_LT5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT5.out s_xtest_${TEST_NUM}_LT5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_LT5.out > j_xtest_${TEST_NUM}_LT5_d.out 2> j_xtest_${TEST_NUM}_LT5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x ${ENC} < j_xtest_${TEST_NUM}_LT5.out > s_xtest_${TEST_NUM}_LT5_d.out 2> s_xtest_${TEST_NUM}_LT5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT5_d.out s_xtest_${TEST_NUM}_LT5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT5_d.out s_xtest_${TEST_NUM}_LT5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo AbCdEfgHiJLMNOPQRSTUVWXYZlmnopqrstuvwxyz0123456789 | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_LT10.out 2> j_xtest_${TEST_NUM}_LT10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC}  < ${DFILE} > s_xtest_${TEST_NUM}_LT10.out 2> s_xtest_${TEST_NUM}_LT10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT10.out s_xtest_${TEST_NUM}_LT10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT10.out s_xtest_${TEST_NUM}_LT10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_LT10.out > j_xtest_${TEST_NUM}_LT10_d.out 2> j_xtest_${TEST_NUM}_LT10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -x ${ENC} < j_xtest_${TEST_NUM}_LT10.out > s_xtest_${TEST_NUM}_LT10_d.out 2> s_xtest_${TEST_NUM}_LT10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT10_d.out s_xtest_${TEST_NUM}_LT10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_LT10_d.out s_xtest_${TEST_NUM}_LT10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_xor_e_end()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using '~' as the xor key"

    #set -x
    ${JPROG1} -D -x '~' < ${DFILE} > j_xtest_${TEST_NUM}_EN1.out 2> j_xtest_${TEST_NUM}_EN1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -ex '~' < ${DFILE} > s_xtest_${TEST_NUM}_EN1.out 2> s_xtest_${TEST_NUM}_EN1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -ex '~' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN1.out s_xtest_${TEST_NUM}_EN1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN1.out s_xtest_${TEST_NUM}_EN1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x '~' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using '~' as the xor key"
    ${JPROG1} -D -d -x '~' < j_xtest_${TEST_NUM}_EN1.out > j_xtest_${TEST_NUM}_EN1_d.out 2> j_xtest_${TEST_NUM}_EN1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -dx '~' < j_xtest_${TEST_NUM}_EN1.out > s_xtest_${TEST_NUM}_EN1_d.out 2> s_xtest_${TEST_NUM}_EN1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -dx '~' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN1_d.out s_xtest_${TEST_NUM}_EN1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN1_d.out s_xtest_${TEST_NUM}_EN1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -x '~' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 'z{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_EN5.out 2> j_xtest_${TEST_NUM}_EN5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -ddddeeeede -x ${ENC} < ${DFILE} > s_xtest_${TEST_NUM}_EN5.out 2> s_xtest_${TEST_NUM}_EN5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -ddddeeeede -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN5.out s_xtest_${TEST_NUM}_EN5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN5.out s_xtest_${TEST_NUM}_EN5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -ddddeeeede -x ${ENC} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_EN5.out > j_xtest_${TEST_NUM}_EN5_d.out 2> j_xtest_${TEST_NUM}_EN5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -dedededededededede -x ${ENC} -d < j_xtest_${TEST_NUM}_EN5.out > s_xtest_${TEST_NUM}_EN5_d.out 2> s_xtest_${TEST_NUM}_EN5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -dedededededededede -x ${ENC} -d < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN5_d.out s_xtest_${TEST_NUM}_EN5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN5_d.out s_xtest_${TEST_NUM}_EN5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -dedededededededede -x ${ENC} -d < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo 'uvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo "Encryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_EN10.out 2> j_xtest_${TEST_NUM}_EN10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -eeeeeee -x ${ENC} -dedededed -d -e -d -e -de < ${DFILE} > s_xtest_${TEST_NUM}_EN10.out 2> s_xtest_${TEST_NUM}_EN10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -eeeeeee -x ${ENC} -dedededed -d -e -d -e -de < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10.out s_xtest_${TEST_NUM}_EN10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10.out s_xtest_${TEST_NUM}_EN10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -eeeeeee -x ${ENC} -dedededede < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using ${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_EN10.out > j_xtest_${TEST_NUM}_EN10_d.out 2> j_xtest_${TEST_NUM}_EN10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -d -e -d -e -e -x ${ENC} -d < j_xtest_${TEST_NUM}_EN10.out > s_xtest_${TEST_NUM}_EN10_d.out 2> s_xtest_${TEST_NUM}_EN10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -d -e -d -e -e -x ${ENC} -d < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10_d.out s_xtest_${TEST_NUM}_EN10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10_d.out s_xtest_${TEST_NUM}_EN10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -d -e -d -e -e -x ${ENC} -d < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC=$(echo '0123456789;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the xor key"
    ${JPROG1} -D -x ${ENC} < ${DFILE} > j_xtest_${TEST_NUM}_EN10.out 2> j_xtest_${TEST_NUM}_EN10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -dddddddddddddddddddddddd -x ${ENC} -dddddddddddddddddddddddde < ${DFILE} > s_xtest_${TEST_NUM}_EN10.out 2> s_xtest_${TEST_NUM}_EN10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -dddddddddddddddddddddddd -x ${ENC} -dddddddddddddddddddddddde < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10.out s_xtest_${TEST_NUM}_EN10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10.out s_xtest_${TEST_NUM}_EN10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -dddddddddddddddddddddddd -x ${ENC} -dddddddddddddddddddddddde < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using \n\t\t${ENC} as the xor key"
    ${JPROG1} -D -d -x ${ENC} < j_xtest_${TEST_NUM}_EN10.out > j_xtest_${TEST_NUM}_EN10_d.out 2> j_xtest_${TEST_NUM}_EN10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -dddddddddddddddddddddddded -x ${ENC} -dddddddddddddddddddddddded < j_xtest_${TEST_NUM}_EN10.out > s_xtest_${TEST_NUM}_EN10_d.out 2> s_xtest_${TEST_NUM}_EN10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -dddddddddddddddddddddddded -x ${ENC} -dddddddddddddddddddddddded < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10_d.out s_xtest_${TEST_NUM}_EN10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_xtest_${TEST_NUM}_EN10_d.out s_xtest_${TEST_NUM}_EN10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -dddddddddddddddddddddddded -x ${ENC} -dddddddddddddddddddddddded < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


test_cae_xor()
{
    local DFILE=$1
    local TEST_NUM=$2

    echo "Encryption Test Begin data-file=${DFILE} using '~' as the caesar and 'a' as the xor key"
    ${JPROG1} -D -x 'a' -c '~' < ${DFILE} > j_cxtest_${TEST_NUM}_EN1.out 2> j_cxtest_${TEST_NUM}_EN1.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x 'a' -e -c '~' -d -e < ${DFILE} > s_cxtest_${TEST_NUM}_EN1.out 2> s_cxtest_${TEST_NUM}_EN1.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x 'a' -e -c '~' -d -e < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN1.out s_cxtest_${TEST_NUM}_EN1.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN1.out s_cxtest_${TEST_NUM}_EN1.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x 'a' -e -c '~' -d -e < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo "  Decryption Test Begin data-file=${DFILE} using '~' as the caesar key and 'a' as the xor key"
    ${JPROG1} -D -d -c '~' -x 'a' < j_cxtest_${TEST_NUM}_EN1.out > j_cxtest_${TEST_NUM}_EN1_d.out 2> j_cxtest_${TEST_NUM}_EN1_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -d -c '~' -x 'a' < j_cxtest_${TEST_NUM}_EN1.out > s_cxtest_${TEST_NUM}_EN1_d.out 2> s_cxtest_${TEST_NUM}_EN1_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -d -c '~' -x 'a' < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN1_d.out s_cxtest_${TEST_NUM}_EN1_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN1_d.out s_cxtest_${TEST_NUM}_EN1_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -d -c '~' -x 'a' < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC_c=$(echo 'z{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    ENC_x=$(echo 'z{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t\t${ENC_c} as the caesar key \n\t\t\tand ${ENC_c} as the xor key"
    ${JPROG1} -D -x ${ENC_x} -c ${ENC_c} < ${DFILE} > j_cxtest_${TEST_NUM}_EN5.out 2> j_cxtest_${TEST_NUM}_EN5.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} > s_cxtest_${TEST_NUM}_EN5.out 2> s_cxtest_${TEST_NUM}_EN5.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN5.out s_cxtest_${TEST_NUM}_EN5.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN5.out s_cxtest_${TEST_NUM}_EN5.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using ${ENC_c} as the caesar key \n\t\tand ${ENC_c} as the xor key"
    ${JPROG1} -D -d -c ${ENC_c} -x ${ENC_x} < j_cxtest_${TEST_NUM}_EN5.out > j_cxtest_${TEST_NUM}_EN5_d.out 2> j_cxtest_${TEST_NUM}_EN5_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -dc ${ENC_c} -x ${ENC_x} < j_cxtest_${TEST_NUM}_EN5.out > s_cxtest_${TEST_NUM}_EN5_d.out 2> s_cxtest_${TEST_NUM}_EN5_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -dc ${ENC_c} -x ${ENC_x} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN5_d.out s_cxtest_${TEST_NUM}_EN5_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN5_d.out s_cxtest_${TEST_NUM}_EN5_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -dc ${ENC_c} -x ${ENC_x} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC_c=$(echo 'uvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    ENC_x=$(echo 'uvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t\t${ENC_c} as the caesar key \n\t\t\tand ${ENC_c} as the xor key"
    ${JPROG1} -D -x ${ENC_x} -c ${ENC_c} < ${DFILE} > j_cxtest_${TEST_NUM}_EN10.out 2> j_cxtest_${TEST_NUM}_EN10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} > s_cxtest_${TEST_NUM}_EN10.out 2> s_cxtest_${TEST_NUM}_EN10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10.out s_cxtest_${TEST_NUM}_EN10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10.out s_cxtest_${TEST_NUM}_EN10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using \n\t\t\t${ENC_c} as the caesar key \n\t\t\tand ${ENC_c} as the xor key"
    ${JPROG1} -D -d -c ${ENC_c} -x ${ENC_x} < j_cxtest_${TEST_NUM}_EN10.out > j_cxtest_${TEST_NUM}_EN10_d.out 2> j_cxtest_${TEST_NUM}_EN10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC_c} -dx ${ENC_x} < j_cxtest_${TEST_NUM}_EN10.out > s_cxtest_${TEST_NUM}_EN10_d.out 2> s_cxtest_${TEST_NUM}_EN10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC_c} -dx ${ENC_x} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10_d.out s_cxtest_${TEST_NUM}_EN10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10_d.out s_cxtest_${TEST_NUM}_EN10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC_c} -dx ${ENC_x} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    ENC_c=$(echo '0123456789;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    ENC_x=$(echo '0123456789;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
    echo -e "Encryption Test Begin data-file=${DFILE} using \n\t\t\tcaesar key is   ${ENC_c} \n\t\t\tand xor key is  ${ENC_x}"
    ${JPROG1} -D -x ${ENC_x} -c ${ENC_c} < ${DFILE} > j_cxtest_${TEST_NUM}_EN10.out 2> j_cxtest_${TEST_NUM}_EN10.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} > s_cxtest_${TEST_NUM}_EN10.out 2> s_cxtest_${TEST_NUM}_EN10.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10.out s_cxtest_${TEST_NUM}_EN10.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "  Encryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10.out s_cxtest_${TEST_NUM}_EN10.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -x ${ENC_x} -c ${ENC_c} < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    echo -e "  Decryption Test Begin data-file=${DFILE} using \n\t\t\tcaesar key is   ${ENC_c} \n\t\t\tand xor key is  ${ENC_x}"
    ${JPROG1} -D -d -c ${ENC_c} -x ${ENC_x} < j_cxtest_${TEST_NUM}_EN10.out > j_cxtest_${TEST_NUM}_EN10_d.out 2> j_cxtest_${TEST_NUM}_EN10_d.err
    timeout -k ${TIME_OUT_KILL} ${TIME_OUT} ${SPROG1} -c ${ENC_c} -x ${ENC_x} -d < j_cxtest_${TEST_NUM}_EN10.out > s_cxtest_${TEST_NUM}_EN10_d.out 2> s_cxtest_${TEST_NUM}_EN10_d.err
    local EV=$?

    if [ ${EV} -ge 124 ]
    then
        echo "  **** Ohhh... A timeout on ${SPROG1} -c ${ENC_c} -x ${ENC_x} -d < ${DFILE} That is not good. ****"
        echo "       It waited ${TIME_OUT}."
        echo "       No points for timeout: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
        ((TIMEOUT_COUNT++))
        if [ ${TIMEOUT_COUNT} -gt 2 ]
        then
            echo "  **** Too many timouts. You need to fix this! ****"
            echo "       Exiting tests"
            ${COWSAY} -f vader "Too Many timeouts! The force is weak."
            exit 3
        fi
        return
    fi
    if [ ${EV} -eq 0 ]
    then
        ${DIFF} -q ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10_d.out s_cxtest_${TEST_NUM}_EN10_d.out > /dev/null 2> /dev/null
        local DIFF_EXIT=$?
        if [ ${DIFF_EXIT} -eq 0 ]
        then
            ((TOTAL_POINTS+=1))
            echo "    Decryption success with data file ${DFILE} : TOTAL_POINTS=${TOTAL_POINTS}"
        else
            ((DIFF_COUNT+=1))
            echo "  **** Ooopsie... Output files differ. diff_count=${DIFF_COUNT}"
            echo "       No points for output difference: TOTAL_POINTS=${TOTAL_POINTS}"
            echo "       Try the following command to see the differences"
            echo "       ${DIFF} ${DIFF_OPTIONS} j_cxtest_${TEST_NUM}_EN10_d.out s_cxtest_${TEST_NUM}_EN10_d.out"
            echo "       data file=${DFILE} key=' ' encoding"
            CLEANUP=0
        fi
    else
        ((FAIL_COUNT+=1))
        echo "  **** Ouch... An exit value of non-zero indicates an error "
        echo "       Command: ./${SPROG1} -c ${ENC_c} -x ${ENC_x} -d < ${DFILE} That is not good. ****"
        echo "       No points for error exits: TOTAL_POINTS=${TOTAL_POINTS}"
        CLEANUP=0
    fi

    #####################################################################################
    #####################################################################################
    #####################################################################################

    check_diff_count
}


check_diff_count()
{
    if [ ${DIFF_COUNT} -gt ${FAIL_MAX} ]
    then
        echo -e "\n\n*********************************************"
        echo "Toooooooooooo many failed tests. Exiting."
        echo "    Failed test count ${DIFF_COUNT}"
        exit 1
    fi
}


valgrind_check()
{
    local LOG=$1
    shift
    local ARGS=$*

    #echo "valgrid log file ${LOG}"
    #echo "valgrid args ${ARGS}"

    local LEAKS=$(grep "${NOLEAKS}" ${LOG} | wc -l)
    if [ ${LEAKS} -eq 1 ]
    then
        echo -e "    No leaks found! : ${ARGS} "
        echo    "    Excellent!!!"
    else
        if [ ${LEAKS_FOUND} -eq 0 ]
        then
            echo "    *** Leaks found : ${ARGS}"
            echo "        That is a 20% deduction."
            echo "        Check for not freeing allocated memory."
            echo "        Check for not closing opened files."
            ${COWSAY} -d "Moooo Leaks"
            LEAKS_FOUND=1
            CLEANUP=0
        else
            echo "    *** Leaks found : ${ARGS}"
        fi
    fi
}

valgrind_test()
{

    local FILES=$(shuf -e 1 5 7 12)

    echo -e "\n********************************************"
    echo "Begin valgrind test"
    for F in ${FILES}
    do
        ENC_c=$(echo '0123456789;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
        ENC_x=$(echo '0123456789;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{|}~' | grep -o . | shuf | paste -s -d' ' | sed -e 's/ //g' )
        echo -e "  Valgrind test: Encryption File=data${F}.txt \n\t\t\tcaesar key is ${ENC_c} \n\t\t\txor key is    ${ENC_x}"
        valgrind ${SPROG1} -c ${ENC_c} -x ${ENC_x} < data${F}.txt > v_test${F}_E.out 2> v_test${F}_E.err
        valgrind_check v_test${F}_E.err data${F}_E.txt encrypt

        echo -e "                 Decryption File=v_test${F}_E.out \n\t\t\tcaesar key is ${ENC_c} \n\t\t\txor key is    ${ENC_x}"
        valgrind ${SPROG1} -d -c ${ENC_c} -x ${ENC_x} < v_test${F}_E.out > v_test${F}_D.out 2> v_test${F}_D.err
        valgrind_check v_test${F}_D.err v_test${F}_E.out v_test${F}_D.out decrypt
    done

    if [ ${LEAKS_FOUND} -eq 0 ]
    then
        ${COWSAY} -f vader -d "No leaks! Obi-Wan has taught you well."
    fi
    echo "End valgrind test"
    echo -e "********************************************\n"
}

while getopts "xvCh" opt
do
    case $opt in
	    C)
	        # Skip removal of data files
	        CLEANUP=0
	        ;;
	    v)
	        # Print extra messages.
	        VERBOSE=1
	        ;;
	    x)
	        # If you really, really, REALLY want to watch what is going on.
	        echo "Hang on for a wild ride."
	        set -x
	        ;;
        h)
            show_help
            exit 0
            ;;
	    \?)
	        echo "Invalid option" >&2
	        echo ""
	        show_help
	        exit 1
	        ;;
	    :)
	        echo "Option -$OPTARG requires an argument." >&2
            show_help
	        exit 1
	        ;;
    esac
done

BDATE=$(date)

#echo "################################################################"
#echo "################################################################"
#echo "    Begun at     ${BDATE}"
#echo "################################################################"
#echo "################################################################"
#echo -e "\n"

trap "kill 0" EXIT
trap "exit" INT TERM ERR

HOST=$(hostname -s)
if [ ${HOST} != ${FILE_HOST} ]
then
    echo "This script MUST be run on ${FILE_HOST}"
    exit 1
fi

G_NAME=$(finger ${LOGNAME} | head -1 | awk -e '{print $4;}')

${COWSAY} -f luke-koala "Cae-xor! Cae-xor! Cae-xor!  Go ${G_NAME}!"
sleep 1.5

build


echo -e "\n********************************************"
for F in ${FILES}
do
    test_caesar_e_spaces   data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_caesar_e_numbers  data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_caesar_e_letters  data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_caesar_e_end      data${F}.txt ${F}
done


################################################################
################################################################
################################################################


echo -e "\n********************************************"
for F in ${FILES}
do
    test_xor_e_spaces   data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_xor_e_numbers  data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_xor_e_letters  data${F}.txt ${F}
done


echo -e "\n********************************************"
for F in ${FILES}
do
    test_xor_e_end      data${F}.txt ${F}
done


################################################################
################################################################
################################################################
################################################################


echo -e "\n********************************************"
for F in ${FILES}
do
    test_cae_xor        data${F}.txt ${F}
done
echo -e "********************************************\n"


################################################################
################################################################
################################################################
################################################################


valgrind_test

if [ ${CLEANUP} -eq 1 ]
then
    echo -e "\nCleaning up"
    rm -f [js]_[cx]test_*.{out,err}
    rm -f [js]_cxtest_*.{out,err}
    rm -f data*.txt
    rm -f v_test*_[DE].{out,err}
fi

EDATE=$(date)

if [ ${LEAKS_FOUND} -ne 0 ]
then
    POINTS=$(echo ${TOTAL_POINTS} | awk '{printf "%d", $1 * 0.2;}')
    echo -e "\n"
    echo "################################################################"
    echo "  Your code has memory leaks, a 20% deduction!"
    echo "  Points lost to memory leaks: ${POINTS}"
    echo "################################################################"
    echo -e "\n"
    ((TOTAL_POINTS-=${POINTS}))
fi

if [ -e .HAS_WARNINGS ]
then
    POINTS=$(echo ${TOTAL_POINTS} | awk '{printf "%d", $1 * 0.2;}')
    echo -e "\n"
    echo "################################################################"
    echo "  Your code has compiler warnings, a 20% deduction!"
    echo "  Points lost to compiler warnings: ${POINTS}"
    echo "################################################################"
    echo -e "\n"
    ((TOTAL_POINTS-=${POINTS}))
fi

echo -e "\n"
echo "Test begun at     ${BDATE}"
echo "Test completed at ${EDATE}"
echo -e "\n"

echo "+++ FAILED TEST COUNT  = ${DIFF_COUNT}"
echo "+++ TOTAL POINTS       = ${TOTAL_POINTS} ***"
echo "+++ OUT OF             = ${AVAIL_POINTS} ***"

if [ ${TOTAL_POINTS} -gt 285 ]
then
    ${COWSAY} -f vader-koala -d "Impressive ${G_NAME}. Most impressive."
fi
