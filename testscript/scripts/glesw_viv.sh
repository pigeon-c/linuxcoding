#!/bin/sh
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
#    @file   glesw_test.sh
#
#    @brief  shell script template for testcase design "gpu" is where to modify block.
#
################################################################################
#Revision History:
#                            Modification     Tracking
#Author                          Date          Number    Description of Changes
#------------------------   ------------    ----------  -----------------------
#Shelly Cheng              20131106     N/A          Initial version
#Jane Liu                  20140625     N/A          add fsl-gpu-sdk test
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
    export TST_TOTAL=4

    export TCID="setup"
    export TST_COUNT=0
    if [ -z "$GPU_DRIVER_PATH" ];then
        export GPU_DRIVER_PATH=/usr/lib
    fi
    platfm.sh
    chip=$?
    if [ "$chip" = "63" -o "$chip" = "62" -o "$chip" = "61" ];then
        dimen=3
    elif [ "$chip" = "60" ];then
        dimen=2
    fi

    if [ -e $GPU_DRIVER_PATH/libOpenVG.so ]; then
        mv $GPU_DRIVER_PATH/libOpenVG.so $GPU_DRIVER_PATH/libOpenVG.so.bak
    fi

    if [ -e $GPU_DRIVER_PATH/libOpenVG.${dimen}d.so ]; then
        ln -s $GPU_DRIVER_PATH/libOpenVG.${dimen}d.so $GPU_DRIVER_PATH/libOpenVG.so
    else
        ln -s $GPU_DRIVER_PATH/libOpenVG_${dimen}D.so $GPU_DRIVER_PATH/libOpenVG.so
    fi
    wayland_env.sh 3
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
    #TODO add cleanup code here
    if [ -e $GPU_DRIVER_PATH/libOpenVG.so ]; then
        rm $GPU_DRIVER_PATH/libOpenVG.so
    fi
    if [ -e $GPU_DRIVER_PATH/libOpenVG.so.bak ]; then
        mv $GPU_DRIVER_PATH/libOpenVG.so.bak $GPU_DRIVER_PATH/libOpenVG.so
    fi
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

ctrlc_test()
{
    j=0
    APPname=$2
    strcut=`echo ${APPname:0:10}`
    while true
    do
        sleep 1
        if [ $j -eq $1 ];then
            pid=$(ps | grep "${strcut}*" | awk '{print $1}')
            kill -2 $pid
            if [ $? -ne 0 ];then
                echo "kill app failed,please check the command"
            fi
            break
        fi
        let "j++"
    done
}

# Function:     test_case_01
# Description   - Test if egl applications sequence ok
#
test_case_01()
{
    #TODO give TCID
    TCID="GLES_TEST"
    #TODO give TST_COUNT
    TST_COUNT=1
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./RenderToTexture || RC=$(echo $RC RenderToTexture)
    #creat a data array for weston apps
    array_weston=(weston weston-image weston-simple-egl weston-calibrator weston-info \
        weston-simple-shm weston-clickdot weston-multi-resource weston-simple-touch weston-cliptest \
        weston-nested weston-smoke weston-dnd weston-stacking weston-editor \
        weston-presentation-shm weston-subsurfaces weston-eventdemo weston-resizor weston-terminal \
        weston-flower weston-scaler weston-transformed weston-fullscreen weston-simple-damage)
    for i in ${array_weston[@]}
    do
        case $i in
            weston-info | weston)
                $i
                sleep 5
                ;;
            weston-image)
                $i images.jpg &
                echo ---------------APP $i is running--------------
                pid_weston_image=$!
                sleep 5
                kill $pid_weston_image || RC=$(echo $RC $i)
                ;;
            #weston-nested call weston-nested-client
            weston-nested)
                cd /usr/bin
                $i &
                echo ---------------APP $i is running--------------
                pid_weston_nested=$!
                sleep 10
                if [ `ps | grep -c "weston-nested-c"` -eq 0 -o `ps | grep "weston-nested-c" | grep -c "defunct"` -eq 1 ]
                then
                    RC=$(echo $RC $i)
                fi
                kill $pid_weston_nested
                cd -
                ;;
            *)
                $i &
                echo ---------------APP $i is running--------------
                sleep 10
                ID=0
                APPName=$(echo $i|sed 's,.*/,,')
                APPName=$(echo $APPName|awk '{print substr($1,1,15)}')
                ID=`ps -ef|grep -E $APPName |grep -v grep|awk '{print $2}'`
                if [ "$ID" = "" ];then
                    RC=$( echo $RC,"$i")
                else
                    echo --------------- now killing $i---------------
                    kill -l $ID || RC=$( echo $RC,"$i")
                fi

                ;;
        esac
    done
    #these apps below list located in /usr/bin
    es2gears_wayland &
    echo ---------------APP $i is running--------------
    pid_es2gears=$!
    sleep 10
    kill $pid_es2gears || RC=$(echo $RC es2gears_wayland)

    glmark2-es2-wayland || RC=$(echo $RC glmark2-es2-wayland )

    if [ "$RC" = "0" ]; then
        RC=0
    else
        echo "Fail apps are listed as below,please check!"
        echo $RC
        RC=1
    fi
    return $RC
}

# Function:     test_case_02
# Description   - Test if egl and vg concurrent ok
#
test_case_02()
{
    #TODO give TCID
    TCID="GLES_CON_TEST"
    #TODO give TST_COUNT
    TST_COUNT=2
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    weston-info
    sleep 5

    echo "============================"

    echo start app: weston-clickdot
    weston-clickdot &
    pid_clickdot=$!

    echo start app: weston-cliptest
    weston-cliptest &
    pid_cliptest=$!

    echo start app: weston-dnd
    weston-dnd &
    pid_dnd=$!

    echo start app: weston-editor
    weston-editor &
    pid_editor=$!

    echo start app: weston-eventdemo
    weston-eventdemo &
    pid_eventdemo=$!

    echo start app: weston-flower
    weston-flower &
    pid_flower=$!

    echo start app: weston-fullscreen
    weston-fullscreen &
    pid_fullscreen=$!

    echo start app: weston-image
    weston-image images.jpg&
    pid_image=$!

    echo start app: weston-resizor
    weston-resizor &
    pid_resizor=$!

    echo start app: weston-simple-egl
    weston-simple-egl &
    pid_egl=$!

    echo start app: weston-simple-shm
    weston-simple-shm &
    pid_shm=$!

    echo start app: weston-simple-touch
    weston-simple-touch &
    pid_simple_touch=$!

    echo start app: weston-smoke
    weston-smoke &
    pid_smoke=$!

    echo start app: weston-subsurfaces
    weston-subsurfaces &
    pid_subsurfaces=$!

    echo start app: weston-terminal
    weston-terminal &
    pid_terminal=$!

    echo start app: weston-transformed
    weston-transformed &
    pid_transformed=$!

    echo start app: tiger
    cd /opt/viv_samples/tiger/
    ./tiger -frameCount 500 &

    wait $pid_tiger
    sleep 5
    kill $pid_egl
    kill $pid_shm
    kill $pid_clickdot
    kill $pid_cliptest
    kill $pid_dnd
    kill $pid_editor
    kill $pid_eventdemo
    kill $pid_flower
    kill $pid_fullscreen
    kill $pid_image
    kill $pid_resizor
    kill $pid_simple_touch
    kill $pid_smoke
    kill $pid_subsurfaces
    kill $pid_terminal
    kill $pid_transformed

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


test_case_03()
{
    #TODO give TCID
    TCID="WAYLAND_PM_TEST"
    #TODO give TST_COUNT
    TST_COUNT=3
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    cd /opt/viv_samples/tiger/
    ./tiger -frameCount 1000 &
    pid_tiger=$!

    if [ "$dimen" = "3" ];then
        weston-simple-egl &
    elif [ "$dimen" = "2" ];then
        weston-simple-shm &
    fi
    pid_weston=$!
    sleep 5

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
    wait $pid_tiger
    sleep 5
    kill $pid_weston
    RC=$?

    if [ $RC -eq 0 ];then
        echo "TEST PASS"
    else
        echo "TEST FAIL"
    fi
    return $RC
}

test_case_04()
{
    #TODO give TCID
    TCID="WAYLAND_PERF_TEST"
    #TODO give TST_COUNT
    TST_COUNT=4
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "
    echo "======================================"
    echo "please record the performance log!!!"
    echo "======================================"
    sleep 5

    cpufreq-set -g performance
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3DMark mm06 test"
    echo "==========================="

    if [ -e mm06/fsl_imx_linux ]; then
        cd mm06/fsl_imx_linux
        ./fm_oes_player
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3Dmark20 mm07 test"
    echo "==========================="
    if [ -e mm07 ]; then
        cd mm07
        ./fm_oes2_mobile_player
    fi
    cpufreq-set -g ondemand

    return 0
}

test_case_05()
{
    #TODO give TCID
    TCID="VDK_TEST"
    #TODO give TST_COUNT
    TST_COUNT=5
    RC=0
    ret=""
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
                ./$APP 500 `fbset | grep geometry | awk '{print $2,$3}'` || ret=$(echo $ret $APP)
                ;;
            vdksample*)
                cd $DIR
                ./$APP 500 || ret=$(echo $ret $APP)
                ;;
            tutorial*)
                cd $DIR
                ./$APP -f 800 || ret=$(echo $ret $APP)
                ;;
            *)
                cd $DIR
                ./$APP &
                close_app_vdk $APP || ret=$(echo $ret $APP)
                ;;
        esac
        cd -
    done
    #hal test
    cd /opt/viv_samples/hal/unit_test
    export LD_LIBRARY_PATH=/opt/viv_samples/hal/unit_test
    rm -rf result/*
    cp galTestCommon.ini galTestCommon.cfg
    ./runtest.sh || ret=$(echo $ret unittest)
    failnum=`ls result/* | grep err | wc -l |  awk '{print $1} '`
    tst_resm TINFO "!!! $failnum cases are failed,please check"
    if [ "$ret" = "0" -a $failnum -eq 0  ]; then
        RC=0
    else
        echo "Fail apps are listed as below,please check!"
        echo $ret
        echo "Fail unit_test cases are listed as below"
        echo `ls result/* | grep err`
        RC=1
    fi
    return $RC
}

# tiger stress test
tiger_stress()
{
    cd  /opt/viv_samples/tiger/
    num=0
    if [ -e $TIGERFILE ];then
        rm -rf $TIGERFILE
    else
        touch $TIGERFILE
    fi
    while true
    do
        num=$[num+1]
        ./tiger -frameCount 5000 || echo "tiger${num}," >> $TIGERFILE
    done
}

test_case_06()
{
    #TODO give TCID
    TCID="STRESS TEST"
    #TODO give TST_COUNT
    TST_COUNT=6
    RC=""
    TIGERFILE="/home/root/testfifo"
    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    apps=("tiger weston-flower weston-fullscreen weston-simple-egl \
        weston-simple-shm weston-simple-touch weston-smoke weston-transformed \
        test_wl_resice test_egl-swap destory_simple-egl2 simple-egl CoverFlow_Wayland es2gears")

    echo "start app: tiger"
    tiger_stress &
    TigerPID=$!

    echo "start app: weston-flower"
    weston-flower &

    echo "start app: weston-fullscreen"
    weston-fullscreen &

    echo "start app: simple-egl"
    weston-simple-egl &

    echo "start app: simple_shm"
    weston-simple-shm &

    echo "start app: weston-simple-touch"
    weston-simple-touch &

    echo "start app: weston-smoke"
    weston-smoke &

    echo "start app: weston-transformed"
    weston-transformed &

    echo "start app: test_wl_resice"
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./test_wl_resice &

    echo "start app:test_egl-swap"
    ./test_egl-swap &

    echo "start app:destory_simple-egl2"
    ./destory_simple-egl2 &

    echo "start app:simple-egl"
    ./simple-egl &

    echo "start app:coverflow for vg test"
    local gpusdk_dir=/opt/imx-gpu-sdk/
    if [ ! -d "${gpusdk_dir}" ];then
        gpusdk_dir=/opt/fsl-gpu-sdk/
        if [ ! -d "${gpusdk_dir}" ];then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1
        fi
    fi
    cd ${gpusdk_dir}/OpenVG/CoverFlow
    ./CoverFlow_Wayland &

#    echo "helloworldx test"
#    cd ${TEST_DIR}/${APP_SUB_DIR}
#    cd conti
#    ./HelloWorldX -platform wayland  &
#    sleep 15

    echo " 5 es2gears app"
    cd ${TEST_DIR}/${APP_SUB_DIR}
    if [ -d ./conti ];then
        cd conti
    else
        echo "the path of es2gears had been changed, please check"
    fi
    ./es2gears &
    ./es2gears &
    ./es2gears &
    ./es2gears &
    ./es2gears &

    echo "==============================================================="
    echo "This is wayland overnight stress test, \
        after more than 10 hours stress test, \
        you can exit it by press any key"
    echo "==============================================================="
    while true
    do
        if read -n 1
        then
            echo "do you want end the test? if true press any key"
            read -p "please any key"  answer
            case "$answer" in
                *) echo "killing the apps ......"
                    kill -15 ${TigerPID}
                    for i in ${apps}
                    do
                        ID=0
                        APPName=$(echo $i|sed 's,.*/,,')
                        APPName=$(echo $APPName|awk '{print substr($1,1,15)}')
                        ID=`ps -ef|grep -E $APPName |grep -v grep|awk '{print $2}'`
                        if [ "$ID" = "" ];then
                            RC=$( echo $RC,"$i")
                        else
                            for id in $ID
                            do
                                kill -l $id
                                echo "killed $id" || RC=$(echo $RC $id)
                            done
                        fi
                    done
                    break
                    ;;
            esac
        fi
    done
    if [ -s "$TIGERFILE" ];then
        TIGER=$( cat $TIGERFILE)
        RC=$( echo $RC,$TIGER )
        rm -rf $TIGERFILE
    fi
    if [ "$RC" = "" ];then
        echo "PASS"
        RC=0
    else
        echo "Fail: some apps failed"
        echo "$RC"
        RC=1
    fi
    return $RC
}

test_case_07()
{
    #TODO give TCID
    TCID="FSL-GP-SDK_test"
    #TODO give TST_COUNT
    TST_COUNT=7
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    local gpusdk_dir=/opt/imx-gpu-sdk
    if [ ! -d "$gpusdk_dir" ]; then
        gpusdk_dir=/opt/fsl-gpu-sdk
        if [ ! -d "$gpusdk_dir" ]; then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1;
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
            for j in `ls`
            do
                cd $j
                for app in `find -type f | grep -v '^\./.*\..'|sort`
                do
                    echo $app
                    if [[ $app == *Stress* ]];then
                        ./$app  --Window [0,0,1024,768]  --ExitAfterFrame 200 || RC=$(echo $RC "$i"/"$j")
                        ./$app  --ExitAfterFrame 200 || RC=$(echo $RC "$i"/"$j")
                    elif [ $app = InputEvents* ];then
                        ./$app  --ExitAfterFrame 800 || RC=$(echo $RC "InputEvent")
                    else
                        ./$app  --Window [0,0,1024,768]  --ExitAfterFrame 800 || RC=$(echo $RC "$i"/"$j")
                        ./$app  --ExitAfterFrame 800 || RC=$(echo $RC "$i"/"$j")
                        if [ "$app" = "S05_PrecompiledShader_Wayland" ];then
                            ./$app  --Window [0,0,1024,768]  --ExitAfterFrame 800 --separateShader || RC=$(echo $RC "$i"/"$j")
                        fi
                    fi
                done
                cd ..
            done
            cd ..
        done
        echo " please plug in mouse or keyboard to useport then run follow case"
        echo "expect to see the mount/keyboard event on terminal"
        sleep 10
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

test_case_08()
{
    #TODO give TCID
    TCID="FSL-GPU_G2D_compositor_test"
    #TODO give TST_COUNT
    TST_COUNT=8
    RC=0
    wayland_env.sh 1
    test_case_01
    RC=$?
    wayland_env.sh 3
    return $RC
}

test_case_09()
{
    echo "=========================================="
    echo "GPU_mem_leak_video_loopback_test start"
    echo "=========================================="
    RC=0
    i=0
    num=2400
    Ret=0
    if [ ! -e /mnt/nfs/test_stream/H264_HP41_1920x1088_30fps_55.8Mbps_shields_ter.mp4 ];then
        RC=1 && echo "*ERROR: videofile not exist,please check"
    fi
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
                #kill -l $pid
                `ps -ef |grep "gplay-1.0" |awk '{print $2}'|xargs kill -l`
                #break
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

test_case_10()
{
    #TODO give TCID
    TCID="WLD_MULTIPLEBUFFER_TEST"
    TST_COUNT=1
    RC=0
    VDK_APP="tutorial2"
    SDK_APP="S01_SimpleTriangle_Wayland"
    local gpusdk_dir=/opt/imx-gpu-sdk
    if [ ! -d "$gpusdk_dir" ]; then
        gpusdk_dir=/opt/fsl-gpu-sdk
        if [ ! -d "$gpusdk_dir" ]; then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1;
        fi
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo wld multiple buffer test
    echo "==========================="
    for (( loops=1;loops<=6;loops++ ))
    do
        /etc/init.d/weston stop
        sleep 2
        if [ $loops -lt 3 ];then
            export FB_MULTI_BUFFER=$loops
            loop=$loops
        else
            export FB_MULTI_BUFFER=$[ 6 - $loops ]
            loop=$[ 6 - $loops]
        fi
        echo "FB_MULTI_BUFFER=$loop"
        echo "Restart weston"
        /etc/init.d/weston start
        sleep 2
        /opt/viv_samples/vdk/$VDK_APP -f 500 || RC="$RC:FB_MULTI_BUFFER=$loop,$VDK_APP;"
        ${gpusdk_dir}/GLES2/S01_SimpleTriangle/$SDK_APP --Window [0,0,1024,768] --ExitAfterFrame 500 || RC="$RC:FB_MULTI_BUFFER=$loop,$SDK_APP;"
    done
    /etc/init.d/weston stop
    sleep 2
    export FB_MULTI_BUFFER=40
    echo " FB_MULTI_BUFFER=40"
    /etc/init.d/weston start
    sleep 2
    /opt/viv_samples/vdk/$VDK_APP -f 500 || RC="$RC:FB_MULTI_BUFFER=$loop,$VDK_APP;"
    ${gpusdk_dir}/GLES2/S01_SimpleTriangle/$SDK_APP --Window [0,0,1024,768] --ExitAfterFrame 500 || RC="$RC:FB_MULTI_BUFFER=$loop,$SDK_APP;"
    
    /etc/init.d/weston stop
    sleep 2
    export FB_MULTI_BUFFER=1
    /etc/init.d/weston start
    sleep 2

    if [ $RC -eq 0 ]; then
        echo "TEST PASS"
    else
        echo "TEST FAIL"
    fi
}

test_case_11()
{
    TCID="fsl-gpu-delay-ctrl-c-test"
    TST_COUNT=9
    wayland_env.sh 3
    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "
    echo "============================================="
    echo "fsl-gpu-sdk: ctrl c test"
    echo "============================================="
    RC=0
    ret=0
    local gpusdk_dir=/opt/imx-gpu-sdk
    if [ ! -d "$gpusdk_dir" ]; then
        gpusdk_dir=/opt/fsl-gpu-sdk
        if [ ! -d "$gpusdk_dir" ]; then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1;
        fi
    fi
    #delay mode test
    cd ${gpusdk_dir}/GLES2/T3DStressTest
    i=0
    APP=T3DStressTest_Wayland
    while [ $i -lt 5 ]
    do
        echo "delay mode test $i times"
        ctrlc_test 120 $APP &
        ./$APP --Window [0,0,1024,768] --ExitAfterFrame 2000 || ret=$?
        if [ $ret -ne 0 ];then
            RC=$(echo $i delay)
            break
        fi
        let "i++"
    done
    if [ "$RC" = 0 ];then
        echo "TEST PASS in delay mode ctrlc test"
    else
        echo "TEST FAIL in $RC mode test"
    fi
    #fast mode test
    cd /opt/viv_samples/vdk/
    APP=tutorial7_es20
    i=0
    while [ $i -lt 500 ]
    do
        echo "fast mode test $i times"
        ctrlc_test 3 $APP &
        ./$APP || ret=$?
        echo $ret
        if [ $ret -ne 130 ];then
            RC=$(echo $RC and $i fast)
            break
        fi
        let "i++"
        sleep 1
    done
    if [ "$RC" = 0 ];then
        echo "TEST PASS in fast mode ctrlc test"
    else
        echo "TEST FAIL in $RC mode test"
        RC=1
    fi
    return $RC
}

usage()
{
    echo "$0 [case ID]"
    echo "the script is for wayland test"
    echo "1: sequence test"
    echo "2: concurrent test"
    echo "3: pm test"
    echo "4: performance test"
    echo "5: vdk test"
    echo "6: stress test"
    echo "7: fsl-gpu-sdk test"
    echo "8: g2d compositor test"
    echo "9: gpu memory leak stress test"
    echo "10:mutibuffer test for wayland"
    echo "11: fsl-gpu-sdk-apps-ctrl-c-test"
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

setup || exit $RC
#judge rootfs type
platfm.sh
platfm=$?
if [ $platfm -eq 80 ];then
      APP_SUB_DIR="yocto_imx8_xwld"
else
      APP_SUB_DIR="wayland"
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
    *)
        usage
        ;;
esac
cleanup $RC || exit $RC
tst_resm TINFO "Test Finish"
