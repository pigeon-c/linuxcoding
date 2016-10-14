#!/bin/bash
###############################################################################
# Copyright (C) 2013 Freescale Semiconductor, Inc. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
###############################################################################
#
#    @file   gles_test.sh
#
#    @brief  shell script template for testcase design "gpu" is where to modify block.
#
################################################################################
#Revision History:
#                            Modification     Tracking
#Author                          Date          Number    Description of Changes
#------------------------   ------------    ----------  -----------------------
#Hake Huang/-----             20110817     N/A          Initial version
#Andy Tian                    05/15/2012       N/A      add wait for background
#Andy Tian                    12/14/2012       N/A      add GPU thermal test
#Shelly Cheng                 01/02/2013       N/A      add more test demo
#Shelly Cheng                 05/17/2013       N/A      add more demo
#Jane Liu                     06/25/2014       N/A      add fsl-gpu-sdk test
#
################################################################################

# Function:     setup
#
# Description:  - Check if required commands exits
#               - Export global variables
#               - Check if required config files exits
#               - Create temporary files and directories
#
# Return        - zero on success
#               - non zero on failure. return value from commands ($RC)
setup()
{
    #TODO Total test case
    export TST_TOTAL=6

    export TCID="setup"
    export TST_COUNT=0
    RC=0

    return $RC
}

# Function:     cleanup
#
# Description   - remove temporary files and directories.
#
# Return        - zero on success
#               - non zero on failure. return value from commands ($RC)
cleanup()
{
    RC=$1
    RET=`dmesg | grep -E '\[galcore\].*hang' | wc -l`
    if [ "$RC" = "0" -a "$RET" = "0" ]; then
        echo "TEST PASS"
    else
        if [ "$RC" = "0" ]; then
            #if RC=0 but RET is Non-zero, set RC=RET
            RC=$RET
        fi
        echo "TEST FAIL"
    fi
    return $RC
    #TODO add cleanup code here
}

#this function was created for the vdk app which would not stop by itself
close_app_vdk()
{
    APPName=$1
    i=0
    ret=0
    #set the limit time for the app which will not stop by itself
    time=20
    while [ $i -lt $time ]
    do
        sleep 1
        let "i++"
        #check the process per second to confirm whether app run fail or not
        if [ $(ps | grep $APPName | awk '{print $1}' | wc -l) -eq 0 ];then
            ret=1
            break
        fi
    done
    if [ $ret -eq 0 ];then
        pid=`ps | grep $APPName | awk '{print $1}'`
        kill -l $pid
        ret=$?
    fi
    return $ret
}

# Function:     test_case_01
# Description   - Test if gles applications sequence ok
#
test_case_01()
{
    #TODO give TCID
    TCID="gles_test"
    #TODO give TST_COUNT
    TST_COUNT=1
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    echo "egl Test case"

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo egl_test
    echo "==========================="
    ./egl_test || RC=egl_test

    echo "ES1.1 Test case"

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo cube
    echo "==========================="
    ./cube 2000 || RC=$(echo $RC cube)

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo mcube stencil test
    echo "==========================="
    ./mcube 2000 || RC=$(echo $RC mcube)

    echo "ES2.0 Test case"
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo simple draw ES2.0
    echo "==========================="
    ./simple_draw 2000 || RC=$(echo $RC simple draw)
    ./simple_draw 2000 -s || RC=$(echo $RC simple draw -s)

    echo "==========================="
    echo torusknot ES2.0
    echo "==========================="
    ./torusknot || RC=$(echo $RC torusknot)

    echo "==========================="
    echo model3d ES2.0
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./model3d 2000 2000 || RC=$(echo $RC model3d)

    echo "==========================="
    echo sample_test ES2.0
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./sample_test 2000 || RC=$(echo $RC sample_test)

    echo "==========================="
    echo mcube_es20 stencil test
    echo "==========================="
    ./mcube_es2 2000 || RC=$(echo $RC mcube_es20)

    if [ "$RC" = "0" ]; then
        RC=0
    else
        RC=1
    fi

    return $RC

}

# Function:     test_case_02
# Description   - Test if gles concurrent ok
#
test_case_02()
{
    #TODO give TCID
    TCID="gles_con_test"
    #TODO give TST_COUNT
    TST_COUNT=2
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here


    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo egl_test
    echo "==========================="
    ./egl_test &
    pid_egl=$!

    echo "==========================="
    echo fps triangle
    echo "==========================="
    ./fps_triangle 10000 &
    pid_tri=$!

    echo "==========================="
    echo simple draw
    echo "==========================="
    ./simple_draw 1000 &
    pid_s1=$!
    ./simple_draw 1000 -s &
    pid_s2=$!

    echo "==========================="
    echo simple triangle
    echo "==========================="
    ./simple_triangle &
    pid_sTri=$!

    echo "==========================="
    echo torusknot
    echo "==========================="
    ./torusknot &
    pid_tor=$!

    echo "==========================="
    echo model3d ES2.0
    echo "==========================="
    ./model3d 1000 1000 &
    pid_m3d=$!
    echo "==========================="
    echo sample_test ES2.0
    echo "==========================="
    ./sample_test 1000 &

    wait $pid_egl && wait $pid_tri && wait $pid_s1 && wait $pid_s2 && wait $pid_sTri && wait $pid_tor && wait $pid_m3d
    RC=$?
    wait

    if [ $RC -eq 0 ]; then
        echo "TEST PASS"
    else
        RC=1
        echo "TEST FAIL"
    fi
    return $RC
}

# Function:     test_case_03
# Description   - Test if gles conformance ok
#
test_case_03()
{
    #TODO give TCID
    TCID="gles_20_conform_test"
    #TODO give TST_COUNT
    TST_COUNT=3
    RC=0
    RC_1=0
    RC_2=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo es11 conformance
    echo "==========================="
    if [ -e ~/es11_con ]; then
        rm ~/es11_con
    fi
    touch ~/es11_con
    if [ $? -ne 0 ]; then
        echo "Create es11_con fail, please check."
        RC_1=1
        return $RC_1
    fi
    echo "es11 Conformance Log Saved in ~/es11_con."
    cd es11_conform/conform
    ( conform/conform -r 32555 -l conform/TESTLIST && \
    conform/conform -r 32556 -l conform/TESTLIST -p 1 && \
    conform/conform -r 32557 -l conform/TESTLIST -p 2 && \
    conform/conform -r 32558 -l conform/TESTLIST -p 3 ) > ~/es11_con \
    || RC_1=es11_conformance
    
    #add auto analysis for es11 conformance 
    echo "******************** ES11 CONFORMANCE ANALYSIS ********************"
    if [ -e ~/es11_con ]; then
        fail_value_1=(`grep "SUMMARY:"  ~/es11_con | grep "tests failed"  | awk '{print $2}'`)
        len_1=${#fail_value_1[*]}
        if [ $len_1 -gt 0 ]; then
            echo "Total Run: $len_1"
            for var_1 in ${fail_value_1[*]}
            do
                if [ "$var_1" != "NO" ]; then
                    RC_1=2
                    break
                fi
            done
        else
            echo "Error: pull data fail, cannot use conformance analysis."
        fi
    else
        echo "Error: ~/es11_con not found, cannot use conformance analysis."
    fi

    if [ "$RC_1" -eq "0" ]; then
        RC_1=0
        echo "es11 Conformance Final Result: TEST PASS"
    else
        RC_1=1
        echo "es11 Conformance Final Result: TEST FAIL"
    fi
    echo -e "\n"

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo es20 conformance
    echo "==========================="
    if [ -e ~/es20_con ]; then
        rm ~/es20_con
    fi
    touch ~/es20_con
    if [ $? -ne 0 ]; then
        echo "Create es20_con fail, please check."
        RC_2=1
        return $RC_2
    fi
    echo "es20 Conformance Log Saved in ~/es20_con."
    if [ -e es20_conform/cts ]; then
        cd es20_conform/cts
        ./cts-runner --type=es2 > ~/es20_con || RC_2=$(echo $RC cts-runner)
    else
        echo "Error: es20_conform folder not found"
        RC_2=1
    fi
    
    #add auto analysis for es20 conformance
    echo "******************** ES20 CONFORMANCE ANALYSIS ********************"
    if [ -e ~/es20_con ]; then 
        fail_value_2=(`grep "Failed" ~/es20_con | awk -F'[:/]' '{print $2}'`)
        len_2=${#fail_value_2[*]}
        if [ $len_2 -gt 0 ]; then
            echo "Total Run: $len_2"
            for var_2 in ${fail_value_2[*]}
            do
                if [ $var_2 -ne 0 ]; then
                    RC_2=2
                    break
                fi
            done
        else    
            echo "Error: pull data fail, cannot use conformance analysis."
        fi
    else
        echo "Error: ~/es20_con not found, cannot use conformance analysis."
    fi

    if [ "$RC_2" -eq "0" ]; then
        RC_2=0
        echo "es20 Conformance Final Result: TEST PASS"
    else
        RC_2=1
        echo "es20 Conformance Final Result: TEST FAIL"
    fi
    echo -e "\n"

    RC=$[ $RC_1||$RC_2 ]
 
    return $RC
}

test_case_04()
{
    #TODO give TCID
    TCID="gles_pm_test"
    #TODO give TST_COUNT
    TST_COUNT=4
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./simple_draw 10000 &
    pid=$!

    rtc_testapp_6 -T 50
    sleep 1
    rtc_testapp_6 -T 50
    sleep 1
    rtc_testapp_6 -T 50
    sleep 1
    rtc_testapp_6 -T 50
    sleep 1
    rtc_testapp_6 -T 50
    sleep 1

    wait $pid
    RC=$?

    if [ $RC = 0 ];then
        echo "TEST PASS"
    else
        echo "TEST FAIL"
    fi
    return $RC
}

test_case_05()
{
    #TODO give TCID
    TCID="gles_perf_test"
    #TODO give TST_COUNT
    TST_COUNT=4
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "
    echo "======================================"
    echo "please record the performance log!!!"
    echo "======================================"
    export FB_MULTI_BUFFER=1
    sleep 5

    cpufreq-set -g performance
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "icam perforamnce test with pixmap"
    echo "==========================="
    echo "iCam_PIX 1"
    ./iCam_PIX 1 || RC="iCam"
    echo "iCam_PIX 2"
    ./iCam_PIX 2 || RC=$(echo $RC iCam)
    echo "==========================="
    echo "icam perforamnce test without pixmap"
    echo "==========================="
    echo "iCam 1"
    ./iCam 1 || RC=$(echo $RC iCam)
    echo "iCam 2"
    ./iCam 2 || RC=$(echo $RC iCam)

    echo "==========================="
    echo " render performance test"
    echo "==========================="
    echo " First time run render"
    ./render || RC=$(echo $RC render)
    echo "second time run render"
    ./render || RC=$(echo $RC render)
    echo 3 > /proc/sys/vm/drop_caches
    echo "after drop cache and run render the 3rd time"
    ./render || RC=$(echo $RC render)
    echo "after drop cache and run render the 4th time"
    ./render || RC=$(echo $RC render)

    echo "==========================="
    echo "gpubench test"
    echo "==========================="
    cd gpubench
    ./gpuBench || RC=$(echo $RC gpuBench)

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3DMark mm06 NOAA test"
    echo "==========================="
    if [ -e 3DMarkMobile/fsl_imx_linux ]; then
        cd 3DMarkMobile/fsl_imx_linux/
        cp fm_config_noaa.txt fm_config.txt
        ./fm_oes_player || RC=$(echo $RC 3Dmark)
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3DMark mm06 FSAA test"
    echo "==========================="
    if [ -e 3DMarkMobile/fsl_imx_linux ]; then
        cd 3DMarkMobile/fsl_imx_linux/
        cp fm_config_fsaa.txt fm_config.txt
        ./fm_oes_player || RC=$(echo $RC 3Dmark)
    fi


    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3Dmark20 mm07 NOAA test"
    echo "==========================="
    if [ -e mm07_v21 ]; then
        cd mm07_v21
        cp script_noaa.lua script.lua
        ./fm_oes2_mobile_player || RC=$(echo $RC mm07)
    fi

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3Dmark20 mm07 FSAA test"
    echo "==========================="
    if [ -e mm07_v21 ]; then
        cd mm07_v21
        cp script_fsaa.lua script.lua
        ./fm_oes2_mobile_player || RC=$(echo $RC mm07)
    fi

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "Mirada NOAA test"
    echo "==========================="
    if [ -e Mirada ]; then
        cd Mirada
        ./Mirada || RC=$(echo $RC mirada)
    fi

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "basemark_v2 test"
    echo "==========================="
    if [ -e basemark_v2 ]; then
        cd basemark_v2
        ./fm_oes2_player || RC=$(echo $RC basemark)
    fi
    cpufreq-set -g ondemand
    return 0
}


# Function:     test_case_06
# Description   - Test if gpu works ok when changed thermal
#
test_case_06()
{
    #TODO give TCID
    TCID="gles_thermal_test"
    #TODO give TST_COUNT
    TST_COUNT=6
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "
    trippoint1_dir=$(find /sys/ -name trip_point_0_temp)
    thermal_dir=`dirname $trippoint1_dir`
    trip_hot_old=`cat $thermal_dir/trip_point_0_temp`
    cur_temp=`cat $thermal_dir/temp`
    cd ${TEST_DIR}/${APP_SUB_DIR}
    if [ $cur_temp -lt $trip_hot_old ]; then
        norm_fps=`./simple_draw 200 | grep FPS | cut -f3 -d:`
    else
        echo "Already in trip hot status"
        exit 6
    fi
    trip_hot_new=$(expr $cur_temp - 10000)
    # Set new trip hot value to trigger the trip_hot flag
    echo ${trip_hot_new} > $thermal_dir/trip_point_0_temp
    sleep 2
    if [ $cur_temp -gt $trip_hot_new ]; then
        low_fps=`./simple_draw 200 | grep FPS | cut -f3 -d: `
    else
        echo "Set trip hot flag failure"
        exit 6
    fi

    let drop_fps=norm_fps-low_fps
    let half_fps=norm_fps/2
    [ $drop_fps -gt $half_fps ] || RC=6
    if [ -n "$trip_hot_old" ]; then
        echo $trip_hot_old >  $thermal_dir/trip_point_0_temp
    fi
    if [ $RC -eq 0 ]; then
        echo "TEST PASS"
    else
        echo "TEST FAIL"
    fi

    return $RC
}
# Function:     test_case_07
# Description   - Test directviv_test
#
test_case_07()
{
    #TODO give TCID
    TCID="directviv_test"
    #TODO give TST_COUNT
    TST_COUNT=6
    RC=0

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo directviv_test
    echo "==========================="
    cd directviv_test
    echo "==========================="
    echo TexDirect_ES11
    echo "==========================="
    ./TexDirect_ES11 -f 5000 || RC=TexDirect_ES11
    echo "==========================="
    echo TexDirectMap_ES11
    echo "==========================="
    ./TexDirectMap_ES11 -f 5000 || RC=$(echo $RC TexDirectMap_ES11)
    echo "==========================="
    echo TexDirectTiledMap_ES11
    echo "==========================="
    ./TexDirectTiledMap_ES11 -f 5000 || RC=$(echo $RC TexDirectTiledMap_ES11)
    echo "==========================="
    echo TexDirect_ES20
    echo "==========================="
    ./TexDirect_ES20 -f 5000 || RC=TexDirect_ES20
    echo "==========================="
    echo TexDirectMap_ES20
    echo "==========================="
    ./TexDirectMap_ES20 -f 5000 || RC=$(echo $RC TexDirectMap_ES20)
    echo "==========================="
    echo TexDirectTiledMap_ES20
    echo "==========================="
    ./TexDirectTiledMap_ES20 -f 5000 || RC=$(echo $RC TexDirectTiledMap_ES20)
    echo "==========================="
    echo RenderToTexture
    echo "==========================="
    ./RenderToTexture || RC=$(echo $RC RenderToTexture)

    RC=$?
    if [ $RC -eq 0 ]; then
        echo "TEST PASS"
    else
        echo "TEST FAIL"
    fi
    return $RC
}
# Function:     test_case_08
# Description   - Test sample test
#
test_case_08()
{
    #TODO give TCID
    TCID="FB MULTIPLEBUFFER test"
    #TODO give TST_COUNT
    TST_COUNT=1
    RC=0
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo fb multiple buffer test
    echo "==========================="
    echo "===Please check the display to make sure no flip issue or other abnormal rendering issue==="
	sleep 1
    for (( loops=1;loops<=8;loops++ ))
    do
        if [ "$loops" -lt 4 ];then
            export FB_MULTI_BUFFER=${loops}
            loop=${loops}
        else
            export FB_MULTI_BUFFER=$[ 8 - ${loops} ]
            loop=$[ 8 - ${loops} ]
        fi
        echo "=============FB_MULTI_BUFFER=${loop}============="
		./cube 300 || RC=$(echo $RC $loops)
		./model3d 1000 300 ||  RC=$(echo $RC $loops)
		./imx_basic_usecase -F 300 || RC=$(echo $RC $loops)
	done
	echo "Abnormal buffer test"
	export FB_MULTI_BUFFER=40
	echo "FB_MULTI_BUFFER=40"
	./cube 300 || RC=$(echo $RC FB_MULTI_BUFFER=40)
	./model3d 1000 300 ||  RC=$(echo $RC FB_MULTI_BUFFER=40)
	./imx_basic_usecase -F 300 || RC=$(echo $RC FB_MULTI_BUFFER=40)
	echo "Buffer Recovery"
	if [ "$PLATFM" = "6QP" ];then
		export FB_MULTI_BUFFER=4
	else
	    export FB_MULTI_BUFFER=1
	fi
    echo "=========blank and unblank test========="
	export FB_MULTI_BUFFER=1
    echo 0 > /sys/class/graphics/fb0/blank
    ./imx_basic_usecase -F 3000  &
    pid=$!
	sleep 2
    for (( loops=1;loops<=4;loops++ ))
    do
        echo $loops
        echo 1 > /sys/class/graphics/fb0/blank
        sleep 1
        echo 0 > /sys/class/graphics/fb0/blank
        sleep 2
    done
    wait $pid
    echo "buffer recovery to initinal"
    if [ "$PLATFM" = "6QP" ];then
        export FB_MULTI_BUFFER=4
    else
        export FB_MULTI_BUFFER=1
    fi
    if [ "$RC" = "0" ]; then
        RC=0
    else
        echo "Failed, please check: $RC"
        RC=1
    fi
    return $RC
}

test_case_09()
{
    #TODO give TCID
    TCID="VDK_TEST"
    #TODO give TST_COUNT
    TST_COUNT=9
    RC=0
    echo "==========================="
    echo vdk test
    echo "==========================="
    cd /opt/viv_samples/vdk
    for i in `find -type f | grep -v '^\./.*\.'|sort`
    do
        echo "==========$(basename $i)=========="
        APP=$(basename $i)
        DIR=$(dirname $i)
        case $APP in
            vdksample8_es20)
                cd $DIR
                ./$APP 500 `fbset | grep geometry | awk '{print $2,$3}'` || RC=$(echo $RC $APP)
                ;;
            vdksample*)
                cd $DIR
                ./$APP 500 || RC=$(echo $RC $APP)
                ;;
            tutorial*)
                cd $DIR
                ./$APP -f 800 || RC=$(echo $RC $APP)
                ;;
            *)
                cd $DIR
                ./$APP &
                close_app_vdk $APP || RC=$(echo $RC $APP)
                ;;
        esac
        cd -
    done
    if [ "$RC" = "0" ]; then
        RC=0
    else
        echo "Fail apps are listed as below,please check!"
        echo $RC
        RC=1
    fi

    return $RC
}

# Function:     test_case_10
# Description   - Test if gpu works ok when change  minimum 3d clock
#
test_case_10()
{
    #TODO give TCID
    TCID="GLES_THERMAL_TEST"
    #TODO give TST_COUNT
    TST_COUNT=6
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    cd ${TEST_DIR}/${APP_SUB_DIR}
    trip_hot_old=`cat /sys/devices/virtual/thermal/thermal_zone0/trip_point_0_temp`
    cur_temp=`cat /sys/devices/virtual/thermal/thermal_zone0/temp`
    cd /opt/viv_samples/vdk
    ./tutorial4_es20 -f 500 &
    pid_egl=$!
    sleep 5
    trip_hot_new=$(expr $cur_temp - 10000)
    # Set new trip hot value to trigger the trip_hot flag
    old_gpu3DMinClock=`cat /sys/bus/platform/drivers/galcore/gpu3DMinClock`
    deta=$((64-$old_gpu3DMinClock))
    newMinClock=$(($RANDOM%$deta+$old_gpu3DMinClock))
    echo $newMinClock  > /sys/bus/platform/drivers/galcore/gpu3DMinClock
    echo ${trip_hot_new} > /sys/devices/virtual/thermal/thermal_zone0/trip_point_0_temp
    sleep 5
    wait $pid_egl
    echo ${trip_hot_old} > /sys/devices/virtual/thermal/thermal_zone0/trip_point_0_temp
    echo $old_gpu3DMinClock > /sys/bus/platform/drivers/galcore/gpu3DMinClock
    #add judgement for gpu auto test, if auto test, system will auto mount to dir /autotest/TestSuit
    if [ -d /autotest/TestSuit/ClientTools ];then
        local MAC_fullname=`cat /sys/class/net/eth0/address`
        MAC=${MAC_fullname//:/-}
        source /autotest/TestSuit/ClientTools/gettestmode.sh
        #get_test_id bad return value is -1
        local TESTID=$( get_test_id )
        local BOARD=$( get_boardtype )
        local ROOTFSTYPE=$( get_backend )
        local BATCHID=$( get_batch_id )
        if [ ${TESTID} -ne -1 ] && [ ${BOARD} != "na" ] && [ ${ROOTFSTYPE} != "na" ] && [ ${BATCHID} != "null" ];then
            logfile="${TESTID}_${MAC}_${BOARD}_${ROOTFSTYPE}_${BATCHID}.log.console"
            RET=`grep "System is too hot. GPU3D will work at $newMinClock/64 clock" /autotest/TestSuit/Results/${logfile} | wc -l`
        else
            echo "*ERROR* can't get log filename, please check gettestmode.sh"
            RET=0
        fi
    else
        #for the environment which not under auto test
        RET=`dmesg | grep "System is too hot. GPU3D will work at $newMinClock/64 clock" $logfile | wc -l`
    fi
    if [  "$RET" = "0" ]; then
        echo "TEST FAIL"
        RC=1
    else
        echo "TEST PASS"
    fi
    return $RC

}
# Function:     test_case_11
# Description   - Test if gles 3.0 applications sequence ok
#
test_case_11()
{
    #TODO give TCID
    TCID="GLES_3.0_TEST"
    #TODO give TST_COUNT
    TST_COUNT=11
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    echo "egl 3.0 Test case"

    cd ${TEST_DIR}/${APP_SUB_DIR}/es30_sequence
    echo "==========================="
    echo egl_3.0_sequence_test
    echo "==========================="
    echo fsl_sample_es3_mrt
    echo "==========================="
    ./sample_test_mrt 1000 || RC=$(echo $RC sample_test_mrt)
    echo "==========================="
    echo fsl_sample_es3_drawinstance
    echo "==========================="
    ./sample_test_di 1000 || RC=$(echo $RC sample_test_di)
    for i in `ls | grep -v "sample_test"`
    do
        echo ============================""
        echo $i
        echo ============================""
        cd $i
        ./OpenGL3.0_Exercise* 5000 || RC=$(echo $RC $i)
        cd ..
    done

    if [ "$RC" = "0" ]; then
        RC=0
    else
        echo "==================================================="
        echo "failed app are listed as below, please check!"
        echo $RC
        echo "==================================================="
        RC=1
    fi
    return $RC
}

# Function:     test_case_12
# Description   - FSL gpu sdk test
#
test_case_12()
{
    #TODO give TCID
    TCID="FSL-GPU-SDK_TEST"
    #TODO give TST_COUNT
    TST_COUNT=12
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "
    #TODO add function test scripte here
    echo "==========================="
    echo fsl-gpu-sdk test
    echo "==========================="
    local gpusdk_dir=/opt/imx-gpu-sdk
    if [ ! -d "${gpusdk_dir}" ];then
        gpusdk_dir=/opt/fsl-gpu-sdk
        if [ ! -d "${gpusdk_dir}" ];then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1
        fi
    fi
    cd ${gpusdk_dir}
    chip=$(platfm.sh)
    platfm=$?
    if [ "$platfm" = "63" -o "$platfm" = "62" -o "$platfm" = "61" ]
    then
        for i in `ls | grep "GLES*"`
        do
            echo "==========================="
            echo $i
            echo "==========================="
            if [ "$platfm" = "62" -a "$i" = "GLES3" ];then
                continue
            fi
            cd $i
            for j in `ls | grep [0-9]`
            do
                cd $j
                j=`ls| grep [0-9]`
                echo $j
                if [[ $j == *Stress* ]];then
                    ./$j  --Window [0,0,1024,768]  --ExitAfterFrame 200 || RC=$(echo $RC "$i"/"$j")
                    ./$j  --ExitAfterFrame 200 || RC=$(echo $RC "$i"/"$j")
                else
                    ./$j  --Window [0,0,1024,768]  --ExitAfterFrame 3000 || RC=$(echo $RC "$i"/"$j")
                    ./$j  --ExitAfterFrame 3000 || RC=$(echo $RC "$i"/"$j")
                    if [ "$j" = "S05_PrecompiledShader_FB" ];then
                        ./$j  --Window [0,0,1024,768]  --ExitAfterFrame 3000 --separateShader || RC=$(echo $RC "$i"/"$j")
                    fi
                fi
                cd ..
            done
            cd ..
        done
        echo " please plug in mouse or keyboard to useport then run follow case"
        echo "expect to see the mount/keyboard event on terminal"
        sleep 10
        cd GLES2/InputEvents
        j=`ls| grep ^InputEvents`
        ./$j  --ExitAfterFrame 2000 || RC=$(echo $RC "InputEvent")
    fi
    if [ "$RC" = "0" ];then
        RC=0
    else
        echo "Fail apps are listed as below, please check!"
        echo $RC
        RC=1
    fi

    return $RC
}

test_case_13()
{
    #TODO give TCID
    TCID="gles_30_conform_test"
    #TODO give TST_COUNT
    TST_COUNT=13
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo es30 conformance
    echo "==========================="
    if [ -e ~/es30_con ]; then
        rm ~/es30_con
    fi
    touch ~/es30_con
    if [ $? -ne 0 ]; then
        echo "Create es30_con fail, please check."
        RC=1
        return $RC
    fi
    echo "es30 Conformance Log Saved in ~/es30_con."
    if [ -e es30_conform/cts ];then
        cd es30_conform/cts
        ./cts-runner --type=es3 > ~/es30_con || RC=$(echo $RC cts-runner)
    else
        echo "Error: es30_conform folder not found"
        RC=1
    fi

    #add auto analysis for es30 conformance
    echo "******************** ES30 CONFORMANCE ANALYSIS ********************"
    if [ -e ~/es30_con ]; then
        fail_value=(`grep "Fail" ~/es30_con | awk -F'[:/]' '{print $2}'`)
        len=${#fail_value[*]}
        if [ $len -gt 0 ]; then
            echo "Total Run: $len"
            for var in ${fail_value[*]}
            do
                if [ $var -ne 0 ]; then
                    RC=2
                    break
                fi
            done
        else
            echo "Error: pull data fail, cannot use conformance analysis."
            RC=1
        fi
    else
        echo "Error: ~/es30_con not found, cannot use conformance analysis."
        RC=1
    fi
    
    if [ "$RC" -eq "0" ]; then
        RC=0
        echo "es30 Conformance Final Result: TEST PASS"
    else
        RC=1
        echo "es30 Conformance Final Result: TEST FAIL"
    fi 

    return $RC
}
function open_app
{
    cd /opt/viv_samples/vdk/
    ./tutorial7_es20 &
}

function close_app
{
    local pid=$1
    kill -2 $pid
    local ret=$?
    return $ret
}
test_case_14()
{
    #TODO give TCID
    TCID="gles_ctrl_c_stress_test"
    #TODO give TST_COUNT
    TST_COUNT=14
    RC=0

    times=0
    while [ $times -lt 500 ]; do
        echo $times
        open_app
        pid=$!
        echo "proc id: $pid"
        sleep 1
        close_app $pid
        ret=$?
        if [ $ret -ne 0 ];then
            RC=1
            return $RC
        fi
        #while ((ret != 0))
        #do
        #   echo "close pid $pid failed!"
        #   close_app $pid
        #   ret=$?
        #done
        #       sleep 1
        let times++
    done
    return $RC

}

test_case_15()
{
    echo "=========================================="
    echo "gpu_mem_leak_video_loopback_test start"
    echo "=========================================="
    RC=0
    i=0
    num=2400
    Ret=0
    if [ ! -e /mnt/nfs/test_stream/H264_HP41_1920x1088_30fps_55.8Mbps_shields_ter.mp4 ];then
        RC=1 && echo "*ERROR: videofile not exist,please check"
    fi
    echo -e "\033[9;0]" > /dev/tty0 
    touch ~/logfile || echo "Creat logfile fail,please check"
    /unit_tests/gpuinfo.sh > ~/logfile
    first=`grep cma ~/logfile`
    echo "Before gplay start, the CMA size is: $first"
    if ! echo $first | grep "0";then
        RC=1 && echo "*ERROR* cma info abnormal when first time start up!"
    else
        while true
        do
            sleep 15
            echo "----------------loop num is :" $i
            pidnum=`ps | grep "gplay-1.0" | awk '{print $1}' | wc -l`
            if [ $pidnum -eq 0 ] && [ $i -gt 2 ];then
                return 1
            fi
            if [ $i -eq $num ];then
                `ps -ef |grep "gplay-1.0" |awk '{print $2}'|xargs kill -l`
                 return 0
            fi
            let i++
            done &
            pid_sleep=$!
            gplay-1.0 /mnt/nfs/test_stream/H264_HP41_1920x1088_30fps_55.8Mbps_shields_ter.mp4 --video-sink=glimagesink --repeat
            sleep 1
            wait $pid_sleep
            RC=$?
            if [ $RC -eq 1 ];then
                echo "============================================="
                echo "*TEST FAIL, gplay quit abnormally"
                echo "============================================="
                return $RC
            fi
            /unit_tests/gpuinfo.sh > ~/logfile
            final=`grep cma ~/logfile`
            echo " After overnight stress gplay test, the CMA size change to: $final"
            if [ "$first" != "$final" ];then
                RC=1
                echo "============================================="
                echo "*ERROR* CMA is full, TEST FAIL"
                echo "============================================="
            else
                echo "=================Test Pass==================="
            fi
            fi
            return $RC

}


usage()
{
    echo "$0 [case ID]"
    echo "1: sequence test"
    echo "2: concurrent test"
    echo "3: conformance test"
    echo "4: pm test"
    echo "5: performance test"
    echo "6: Thermal control test"
    echo "7: TexDirect_viv"
    echo "8: FB MULTIBUFFER test"
    echo "9: VDK test"
    echo "10: minimum 3d clock export verify"
    echo "11: opengles3.0 sequence test"
    echo "12: fsl-gpu-sdk test"
    echo "13: gles_30 conformance"
    echo "14: ctrl_c stress test"
    echo "15: gpu memory leak stress test"
}

# main function

RC=0

#TODO check parameter
if [ $# -ne 1 ]
then
    usage
    exit 1
fi

if [ -d "/mnt/nfs/util/" ];then
    TEST_DIR=/mnt/nfs/util/Graphics
 else
    TEST_DIR=`pwd`
fi

APP_SUB_DIR=

setup || exit $RC
#judge rootfs type
rt="Ubuntu"
cat /etc/issue | grep Ubuntu || rt="others"

if [ $rt = "Ubuntu" ];then
    APP_SUB_DIR="ubuntu_11.10/test"
    export DISPLAY=:0.0
    #export XAUTHORITY=/home/linaro/.Xauthority
else
    #judge the rootfs
    platfm.sh
    case "$?" in
        41)
            APP_SUB_DIR="imx51_rootfs/test"
            ;;
        51)
            APP_SUB_DIR="imx51_rootfs/test"
            ;;
        53)
            APP_SUB_DIR="imx53_rootfs/test"
            ;;
        60)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        61)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        62)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        63)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
	80)
	   APP_SUB_DIR="yocto_imx8_fb"
	   ;;
        *)
            exit 0
            ;;
    esac
fi
PLATFM=""
IS6QP=`cat /sys/devices/soc0/soc_id | grep "6QP$" | wc -l`
if [ $IS6QP -gt 0 ];then
    PLATFM="6QP"
fi
case "$1" in
    1)
        test_case_01
        ;;
    2)
        test_case_02
        ;;
    3)
        test_case_03
        ;;
    4)
        test_case_04
        ;;
    5)
        test_case_05
        ;;
    6)
        test_case_06
        ;;
    7)
        test_case_07
        ;;
    8)
        test_case_08
        ;;
    9)
        test_case_09
        ;;
    10)
        test_case_10
        ;;
    11)
        test_case_11
        ;;
    12)
        test_case_12
        ;;
    13)
        test_case_13
        ;;
    14)
        test_case_14
        ;;
    15)
        test_case_15
        ;;
    *)
        usage
        ;;
esac
cleanup $RC || exit $RC
tst_resm TINFO "Test Finish"
