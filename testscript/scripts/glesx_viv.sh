#!/bin/sh
###############################################################################
# Copyright (C) 2011-2013 Freescale Semiconductor, Inc. All Rights Reserved.
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
#    @file   glesx_test.sh
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
#Shelly Cheng                 09/02/2013       N/A      add more test demo and restructure the sceipt
#Shelly Cheng                 11/01/2013       N/A      add PowerVR sdk demo test
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
    dmesg -c > /dev/null
    #    trap "cleanup" 0 3
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
    #TODO add cleanup code here
    RC=$1
    RET=0
    if [ -n "$trip_hot_old" ]; then
        echo $trip_hot_old > /sys/devices/virtual/thermal/thermal_zone0/trip_point_1_temp
    fi
    if [ -n "$trip_act_old" ]; then
        echo $trip_act_old > /sys/devices/virtual/thermal/thermal_zone0/trip_point_2_temp
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
    ./egl_2 "width=800,height=600"|| RC=$(echo $RC egl_test)

    echo "ES1.1 Test case"
    echo "==========================="
    echo simple_draw
    echo "==========================="
    cd eglx_es1_1
    ./eglx_es1_1 "width=800,height=600, subcase=0, loop=300" || RC=$(echo $RC simple_draw)

    echo "==========================="
    echo texture fence
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./eglx_es1_2 "width=800,height=600, subcase=0, loop=10,texwidth=1024,texheight=1024"|| RC=$(echo $RC eglx_es1_2_test)
    ./eglx_es1_2 "width=400,height=600, subcase=0, loop=20,texwidth=32,texheight=32"|| RC=$(echo $RC eglx_es1_2_test)

    echo "==========================="
    echo shared context
    echo "==========================="
    ./eglx_es1_3 "width=800,height=600, loop=300"|| RC=$(echo $RC eglx_es1_3_test)

    echo "==========================="
    echo gpubench
    echo "==========================="
    cd gpubench
    ./gpuBench || RC=$(echo $RC gpuBench)

    echo "ES2.0 Test case"
    echo "==========================="
    echo simple draw vertex color
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./eglx_es2_1 "width=800,height=600,subcase=0,loop=300" || RC=$(echo $RC simple_draw_vertex__test)

    echo "==========================="
    echo test synchronization of eglSwapbuffers
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=0,loop=10,eglsynctest=20" || RC=$(echo $RC sync_eglswap_test)
    echo "==========================="
    echo rgb texture
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=2,loop=30,texwidth=1024,texheight=1024" || RC=$(echo $RC rgb_testure_es2_1_test)

    echo "==========================="
    echo pure eglSwapBuffers
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=3,loop=30" || RC=$(echo $RC pure_eglswapbuffer_test)

    echo "==========================="
    echo test texture fence
    echo "==========================="
    ./eglx_es2_2 "width=800,height=600,subcase=0,loop=30,texwidth=1024,texheight=1024" || RC=$(echo $RC test_texture_fence_test)

    echo "==========================="
    echo sample_test ES2.0
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./sample_test 1000 || RC=$(echo $RC sample_test)

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo mcube stencil test
    echo "==========================="
    ./mcube 1000 || RC=$(echo $RC mcube)

    echo "==========================="
    echo mcube_es20 stencil test
    echo "==========================="
    ./mcube_es2 1000 || RC=$(echo $RC mcube_es20)

    #echo "==========================="
    #echo quake3a
    #echo "==========================="
    #cd ${TEST_DIR}/${APP_SUB_DIR}
    #cd  quake3a
    #./quake3D || RC=$(echo $RCquake3a)

    echo "==========================="
    echo model3d
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    cd model3dbin || RC=$(echo $RC model3d)

    echo "==========================="
    echo sceneFO
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./scene_FBO&
    pid=$!
    sleep 60
    kill -l $pid || RC=$(echo $RC sceneFBO)

    echo "==========================="
    echo glTexDirectViv
    echo "==========================="
    ./RenderToTexture || RC=$(echo $RC RenderToTexture)

    echo "==========================="
    echo google_glperf
    echo "==========================="
    ./google_glperf || RC=$(echo $RC google_glperf)

    echo "==========================="
    echo googletextures
    echo "==========================="
    ./googletextures || RC=$(echo $RC googletextures)

    echo "==========================="
    echo fillrate
    echo "==========================="
    ./fillrate || RC=$(echo $RC fillrate)


    echo "==========================="
    echo filter
    echo "==========================="
    ./filter || RC=$(echo $RC filter)

    echo "==========================="
    echo finish
    echo "==========================="
    ./finish || RC=$(echo $RC finish)

    echo "==========================="
    echo tritex
    echo "==========================="
    ./tritex || RC=$(echo $RC tritex)

    echo "==========================="
    echo angeles
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./angeles || RC=$(echo $RC angeles)

    echo "==========================="
    echo glx demo
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    if [ -e GLXS ]; then
        cd GLXS/
        ./glxs || RC=$(echo $RC glxs)
        cd ..
    else
        echo "Folder GLXS missed"
        RC=1
    fi

    glxgears &
    sleep 30
    ./xdotool key Escape

    glxgears -fullscreen&
    sleep 30
    ./xdotool key Escape

    #glxgears_pixmap &
    #       pid=$!
    #      sleep 30
    #     kill -l $pid
    glxcontexts &
    sleep 30
    ./xdotool key Escape

    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo mesa demos
    echo "==========================="
    ./es2gears &
    sleep 30
    ./xdotool key Escape

    ./manywin -s 10 &
    sleep 30
    ./xdotool key Escape

    ./glxpixmap &
    pid=$!
    sleep 30
    kill -l $pid
    ./glxdemo &
    pid=$!
    sleep 30
    kill -l $pid

    ./glxswapcontrol&
    sleep 30
    ./xdotool key Escape

    ./multictx &
    sleep 30
    ./xdotool key Escape

    ./offset &
    sleep 30
    ./xdotool key Escape

    ./pbinfo || RC=$(echo $RC pbinfo)

    ./shape &
    sleep 30
    ./xdotool key Escape

    ./wincopy&
    sleep 30
    ./xdotool key Escape

    ./xfont &
    sleep 30
    ./xdotool key Escape

    ./xrotfontdemo&
    sleep 30
    ./xdotool key Escape

    ./glxheads&
    sleep 30
    ./xdotool key Escape

    ./glxinfo|| RC=$(echo $RC glxinfo)
    ./mesa_copytex ||  RC=$(echo $RC mesa_copytex)
    ./mesa_drawoverhead || RC=$(echo $RC mesa_drawoverhead)
    ./mesa_fbobind ||  RC=$(echo $RC mesa_fbobind)
    #./mesa_genmipmap ||RC=$(echo $RC mesa_genmipmap)
    ./mesa_readpixels || RC=$(echo $RC mesa_readpixels)
    ./mesa_swapbuffers || RC=$(echo $RC mesa_swapbuffers)
    ./mesa_teximage || RC=$(echo $RC mesa_teximage)
    ./mesa_vbo || RC=$(echo $RC mesa_vbo)
    ./mesa_vertexrate || RC=$(echo $RC mesa_vertexrate)
    #RC=$(echo $RC)
    #echo "==========================="
    #echo draw quad
    #echo "==========================="
    #./glx_quad_1 "width=800,height=600" || RC=$(echo $RC draw_quad_test)
    wait
    RC=$?
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
    ./egl_2 "width=800,height=600"|| RC=$(echo $RC egl_test) &
    pid_egl=$!

    echo "ES1.1 Test case"
    echo "==========================="
    echo simple_draw
    echo "==========================="
    cd eglx_es1_1
    ./eglx_es1_1 "width=800,height=600, subcase=0, loop=300" || RC=$(echo $RC simple_draw) &
    pid_es1_simdra=$!

    echo "==========================="
    echo texture fence
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./eglx_es1_2 "width=800,height=600, subcase=0, loop=10,texwidth=1024,texheight=1024"|| RC=$(echo $RC eglx_es1_2_test) &
    pid_es1_texfen_1=$!

    echo "==========================="
    echo shared context
    echo "==========================="
    #./eglx_es1_3 "width=800,height=600, loop=300"|| RC=$(echo $RC eglx_es1_3_test) &
    #pid_es1_shacon=$!


    echo "ES2.0 Test case"
    echo "==========================="
    echo simple draw vertex color
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=0,loop=300" || RC=$(echo $RC simple_draw_vertex__test) &
    pid_es2_simvercol=$!

    echo "==========================="
    echo test synchronization of eglSwapbuffers
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=0,loop=10,eglsynctest=20" || RC=$(echo $RC sync_eglswap_test) &
    pid_es2_synswapbuf=$!

    echo "==========================="
    echo rgb texture
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=2,loop=30,texwidth=1024,texheight=1024" || RC=$(echo $RC rgb_testure_es2_1_test) &
    pid_es2_rgbtex=$!

    echo "==========================="
    echo pure eglSwapBuffers
    echo "==========================="
    ./eglx_es2_1 "width=800,height=600,subcase=3,loop=30" || RC=$(echo $RC pure_eglswapbuffer_test) &
    pid_es2_purswapbuf=$!

    echo "==========================="
    echo test texture fence
    echo "==========================="
    ./eglx_es2_2 "width=800,height=600,subcase=0,loop=30,texwidth=1024,texheight=1024" || RC=$(echo $RC test_texture_fence_test) &
    pid_es2_texfen=$!

    echo "==========================="
    echo sample_test ES2.0
    echo "==========================="
    ./sample_test 1000 &
    pid_sample_test=$!

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo glx test
    echo "==========================="
    ./glxgears&
    ./glxgears&

    echo "==========================="
    echo three eglgears
    echo "==========================="
    ./es2gears &
    ./es2gears &
    ./es2gears &

    #./glx_quad_1 "width=800,height=random600" || RC=$(echo $RC draw_quad_test) &
    #pid_quad_1=$!
    sleep 100
    #five processes need to end
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape

    wait $pid_egl&&wait $pid_es1_texfen_1&&wait $pid_es2_simvercol&&wait $pid_es2_synswapbuf&&wait $pid_es2_rgbtex&&wait $pid_es2_purswapbuf&&wait $pid_es2_texfen&&wait $pid_sample_test
    RC=$?
    wait
    RC=$?
    return $RC
}

# Function:     test_case_03
# Description   - Test if gles conformance ok
#
test_case_03()
{
    #TODO give TCID
    TCID="gles_conform_test"
    #TODO give TST_COUNT
    TST_COUNT=3
    RC=0

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo es11 conformance
    echo "==========================="
    cd es11_conform/conform
    conform/conform -r 32555 -l conform/TESTLIST && \
        conform/conform -r 32556 -l conform/TESTLIST -p 1 && \
        conform/conform -r 32557 -l conform/TESTLIST -p 2 && \
        conform/conform -r 32558 -l conform/TESTLIST -p 3 \
        || RC=es11_conformance

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo es20 conformance
    echo "==========================="
    RC=$(echo $RC es20_conformance)
    if [ -e es20_conform/GTF_ES/glsl/GTF/GTF ]; then
        cd es20_conform/GTF_ES/glsl
        ./GTF/GTF -width=64 -height=64 -noimagefileio \
            -l=/home/root/es20_conformance_mustpass_64x64 -run="$(pwd)/GTF/mustpass.run" \
            && ./GTF/GTF -width=113 -height=47 -noimagefileio \
            -l=/home/root/es20_conformance_mustpass_113x47 -run="$(pwd)/GTF/mustpass.run" \
            && ./GTF/GTF -width=640 -height=480 -noimagefileio \
            -l=/home/root/es20_conformance_mustpass_640x480 -run="$(pwd)/GTF/mustpass.run" \
            || RC=$(echo $RC es20_conformance)
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
    ./eglx_es2_1 "width=800,height=600,subcase=0,loop=1000" &
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

    return $RC
}

test_case_05()
{
    #TODO give TCID
    TCID="gles_pm_test"
    #TODO give TST_COUNT
    TST_COUNT=4
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    echo "======================================"
    echo "please record the performance log!!!"
    echo "======================================"
    sleep 5
    cpufreq-set -g performance
    echo "==========================="
    echo "tutorial6_es20 test"
    echo "==========================="
    cd /opt/viv_samples/vdk
    ./tutorial6_es20

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "glxgears fullscreen test"
    echo "==========================="
    glxgears -fullscreen&
    sleep 30
    ./xdotool key Escape

    echo "==========================="
    echo "es2gears test"
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./es2gears &
    sleep 30
    ./xdotool key Escape


    echo "==========================="
    echo "glmark2 test"
    echo "==========================="
    glmark2 || RC=$(echo $RC glmark2)

    echo "==========================="
    echo "glmark2 test"
    echo "==========================="
    glmark2-es2 || RC=$(echo $RC glmark2-es2)

    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3DMark mm06 NOAA test"
    echo "==========================="

    if [ -e mm06/bin/fsl_imx_linux ]; then
        cd mm06/bin/fsl_imx_linux
        ./fm_oes_player || RC=$(echo $RC mm06)
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "3Dmark20 mm07 FSAA test"
    echo "==========================="
    if [ -e basemark_es2.0 ]; then
        cd basemark_es2.0
        ./fm_oes2_mobile_player || RC=$(echo $RC mm07)
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "basemark_v2 test"
    echo "==========================="
    if [ -e 3dmarkmobile_es2_gold ]; then
        cd 3dmarkmobile_es2_gold
       #./fm_oes2_player || RC=$(echo $RC 3Dmark22)
       ./fm_oes2_player_HighQuality || RC=$(echo $RC 3Dmark22)
       ./fm_oes2_player_NormalQuality || RC=$(echo $RC 3Dmark22)
    fi
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo "Mirada NOAA test"
    echo "==========================="
    if [ -e mirada ]; then
        cd mirada
        ./Mirada || RC=$(echo $RC Mirada)
    fi
    echo "==========================="
    echo "gtkperf test"
    echo "==========================="
    gtkperf -a || RC=$(echo $RC gtkperf)

    if [ "$RC" = "0" ];then
        RC=0
    else
        echo "Fail apps are listed as below, please check!"
        echo $RC
        RC=1
    fi

    cpufreq-set -g ondemand
    return $RC
}

test_case_06()
{
    #TODO give TCID
    TCID="PowerVR SDK opengles1.1 2.0 3.0 test"
    #TODO give TST_COUNT
    TST_COUNT=1
    RC=0
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo PowerVR3 test
    echo "==========================="
    chip=$(platfm.sh)
    platfm=$?
    cd PowerVR3.1

    cd Advanced
    if [ "$platfm"  = "63" -o "$platfm" = "61" ]
    then
        if [ -e ShaderBinary ]; then
            rm ShaderBinary
        fi
        for i in `ls OGLES*`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    else
        for i in `ls OGLES* | grep -v "OGLES3"`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    fi

    cd ../Beginner
    if [ "$platfm"  = "63" -o "$platfm" = "61" ]
    then
        for i in `ls OGLES*`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    else
        for i in `ls OGLES* | grep -v "OGLES3"`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    fi

    cd ../Intermediate
    if [ "$platfm"  = "63" -o "$platfm" = "61" ]
    then
        for i in `ls OGLES*`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    else
        for i in `ls OGLES* | grep -v "OGLES3"`
        do
            echo $i
            ./$i &
            sleep 15
            ../../xdotool key Escape
        done
    fi

    RC=$?
    return $RC
}
test_case_07()
{
    #TODO give TCID
    TCID="STRESS_OVERNIGHT_TEST"
    TST_COUNT=7
    RC=0
    echo "==========================="
    echo overnight multi-instance test
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    echo "==========================="
    echo 3 eglgears  es2.0 instances
    echo "==========================="
    ./es2gears &
    sleep 5
    ./es2gears &
    sleep 5
    ./es2gears &
    sleep 5
    echo "==========================="
    echo 2 glxgears glx instances
    echo "==========================="
    glxgears &
    sleep 5
    glxgears &
    sleep 5
    echo "==========================="
    echo 2 tiger_3D vg instances
    echo "==========================="
    if [ -z "$GPU_DRIVER_PATH" ];then
        export GPU_DRIVER_PATH=/usr/lib
    fi
    if [ -e $GPU_DRIVER_PATH/libOpenVG.so ]; then
        mv $GPU_DRIVER_PATH/libOpenVG.so $GPU_DRIVER_PATH/libOpenVG.so.bak
    fi
    if [ -e $GPU_DRIVER_PATH/libOpenVG.3d.so ]; then
        ln -s $GPU_DRIVER_PATH/libOpenVG.3d.so $GPU_DRIVER_PATH/libOpenVG.so
    else
        ln -s $GPU_DRIVER_PATH/libOpenVG_3D.so $GPU_DRIVER_PATH/libOpenVG.so
    fi
    echo ====== Using 3D VG library =======
    while true;
    do
        ./tiger -frameCount 1000&
        sleep 5
        ./tiger -frameCount 1000
        sleep 5
    done
    rm $GPU_DRIVER_PATH/libOpenVG.so
    mv $GPU_DRIVER_PATH/libOpenVG.so.bak $GPU_DRIVER_PATH/libOpenVG.so
    #five processes need to end
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape;
    sleep 1
    ./xdotool key Escape
    RC=$?

    return $RC

}

test_case_08()
{
    #TODO give TCID
    TCID="fsl-gpu-sdk_test"
    #TODO give TST_COUNT
    TST_COUNT=8
    RC=0
    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    echo "==========================="
    echo fsl-gpu-sdk test
    echo "==========================="
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
                    elif [ $app == InputEvents* ];then
                        ./$app  --ExitAfterFrame 800 || RC=$(echo $RC "InputEvent")
                    else
                        ./$app  --Window [0,0,1024,768]  --ExitAfterFrame 800 || RC=$(echo $RC "$i"/"$j")
                        if [ "$app" = "S05_PrecompiledShader_X11" ];then
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

test_case_09()
{
    #TODO give TCID
    TCID="X11_2D+3D_Helloworld_stress_test"
    #TODO give TST_COUNT
    TST_COUNT=9
    ret=""
    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID "

    #TODO add function test scripte here
    echo "==========================="      
    echo Helloworldx stress test                                      
    echo "==========================="                                
    cd ${TEST_DIR}/${APP_SUB_DIR}                                  
    cd HelloWorldX-hfp-x             
    ./HelloWorldX &
    pid_Helloworld=$!
    sleep 20   
    echo "==========================="
    echo X11 2D and 3D stress test
    echo "==========================="
    cd ${TEST_DIR}/${APP_SUB_DIR}
    ./fsl_stress_test & 
    pid_2d3d=$!

    echo "==============================================================="
    echo "This is 2d_3d and Helloworldx overnight stress test, \
        after more than 24 hours stress test, \
        you can exit it by press any key"
    echo "==============================================================="
    while true
    do
        if read -n 1;then
            echo "do you want end the test?if true press any key"
            read -p "please any key"  answer
            case "$answer" in
                *) echo "killing the apps ......"
                    kill -l $pid_Helloworld || ret=$(echo $ret "Helloworldx")
                    kill -l $pid_2d3d  || ret=$(echo $ret "2d_3d_stress")
                    break
                    ;;
            esac
        fi
    done
    if [ "$ret" = "" ];then
        echo "PASS"
        RC=0
    else
        echo "Fail: some apps failed"
        echo "$ret"
        RC=1
    fi
    return $RC
}
test_case_10()
{
    #TODO give TCID
    TCID="VDK_TEST"
    #TODO give TST_COUNT
    TST_COUNT=10
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

test_case_11()
{
    TCID="FSL-GPU-CTRL-C-STRESS-TEST"
    TST_COUNT=11

    #print test info
    tst_resm TINFO "test $TST_COUNT: $TCID"
    echo "================================================"
    echo "fsl-gpu-sdk: ctrl c stress test"
    echo "================================================"
    RC=0
    #delay mode test
    local gpusdk_dir=/opt/imx-gpu-sdk
    if [ ! -d "$gpusdk_dir" ]; then
        gpusdk_dir=/opt/fsl-gpu-sdk
        if [ ! -d "$gpusdk_dir" ]; then
            echo "/opt/imx-gpu-sdk or /opt/fsl-gpu-sdk does not exist"
            return 1;
        fi
    fi
    cd ${gpusdk_dir}/GLES2/S01_SimpleTriangle
    i=0
    APP=S01_SimpleTriangle_X11
    while [ $i -lt 5 ]
    do
        echo "delay mode test $i times"
        ctrlc_test 120 $APP &
        ./$APP --Window [0,0,1024,768] --ExitAfterFrame 200000 
        ret=$?
        if [ $ret -ne 0 ];then
            RC=$(echo $RC delay)
            break
        fi
        let "i++"
    done

    #fast mode test
    cd /opt/viv_samples/vdk/
    APP=tutorial7_es20
    i=0
    while [ $i -lt 500 ]
    do
        echo "fast mode test $i times"
        ctrlc_test 3 $APP &
        ./$APP
        ret=$?
        if [ $ret -ne 0 ];then
            RC=$(echo $RC fast)
            break
        fi
        let "i++"
    done
    if [ "$RC" = "0" ];then
        echo "TEST PASS"
    else
        echo "TEST FAIL in $RC mode test"
        RC=1
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
    echo "6: PowerVR sdk demo test"
    echo "7: stress overnight test"
    echo "8: fsl-gpu-sdk test"
    echo "9: X11 2D and 3D stress test"
    echo "10: vdk test"
    echo "11: FSL-GPU-CTRL-C-STRESS-TEST"
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
rt="Yocto"
platfm.sh
platfm=$?
if [ -e /etc/X11 ];then
        if [ "$platfm" = "80" ];then
	    APP_SUB_DIR="yocto_imx8_x/bin"
            export LD_LIBRARY_PATH="$TEST_DIR/yocto_imx8_x/lib"
        else
            APP_SUB_DIR="yocto_1.6_x/bin"
            export LD_LIBRARY_PATH="$TEST_DIR/yocto_1.6_x/lib"
        fi

    	export DISPLAY=:0.0

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
        61)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        62)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        63)
            APP_SUB_DIR="imx61_rootfs/test"
            ;;
        *)
            exit 0
            ;;
    esac
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
