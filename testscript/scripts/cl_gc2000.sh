#!/bin/sh
#
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
#Shelly Cheng                 20130517     N/A          add more unittest
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
RC=0
trap "cleanup" 0
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
RC=0

#TODO add cleanup code here
return $RC
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
cd /opt/viv_samples/
echo "==========================="
echo unit tests
echo "==========================="
if [ -e cl11/UnitTest ]; then
  cd cl11/UnitTest/
  for i in $unit_list
	  do
     ./$i || RC=$(echo $RC $i)
   done
fi

cd /opt/viv_samples/
echo "==========================="
echo fft
echo "==========================="
if [ -e cl11/fft ]; then
  cd cl11/fft/
  ./fft 1024 || ./fft 8192 || RC=$(echo $RC $fft)
fi
if [ "$RC" = "0" ]; then
        RC=0
else
        RC=1
fi
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

cd /opt/viv_samples/
echo "==========================="
echo unit tests
echo "==========================="
if [ -e cl11/UnitTest ]; then
  cd cl11/UnitTest/
  for i in $unit_list
	  do
     ./$i &
   done
fi

RC=$(wait)
return $RC
}

test_case_03()
{
#TODO give TCID 
TCID="gles_conform_test"
#TODO give TST_COUNT
TST_COUNT=3
RC=0

#print test info
tst_resm TINFO "test $TST_COUNT: $TCID "

tempfile=$(mktemp)
#TODO add function test scripte here
cd ${TEST_DIR}/${APP_SUB_DIR}
echo "==========================="
echo cl11 conformance
echo "==========================="
if [ -e ~/cl11_con ]; then
    rm ~/cl11_con
fi
touch ~/cl11_con
if [ $? -ne 0 ]; then
    echo "Create cl11_con fail, please check."
    RC=1
    return $RC
fi

cd cl11/conform
platf=`cat /sys/devices/soc0/soc_id`
echo "The platform is $platf"
# MX6Q paltform
find=`echo $platf|grep ".*MX6Q$"|wc -l`
if [ $find -eq 1 ];then
    cp opencl_conformance_tests_quick.csv_gc2000 opencl_conformance_tests_quick.csv || RC=1
else
    cp opencl_conformance_tests_quick.csv_gc3000 opencl_conformance_tests_quick.csv || RC=1
fi
if [ $RC -eq 0 ];then
python run_conformance.py opencl_conformance_tests_quick.csv > ~/cl11_con
fi

# add auto analysis for opencl conformance
echo "******************** OPENCL CONFORMANCE ANALYSIS ********************"
if [ -e ~/cl11_con ]; then
    fail_value=`grep 'Testing complete.' ~/cl11_con | awk -F'.' '{print $2}' | awk '{print $1}'`
    len=`grep 'Testing complete.' ~/cl11_con | awk -F'.' '{print $2}' | awk '{print $4}'`
    echo "Total Run: $len"
    echo "Failed Num: $fail_value"
    if [ $fail_value -ne 0 ]; then
        RC=2
    fi
else
    echo "Error: ~/cl11_con not found, cannot use conformance analysis."
fi

if [ $RC -eq 0 ]; then
    echo "Opencl Conformance Final Result: TEST PASS"
else
    echo "Opencl Conformance Final Result: TEST FAIL"
fi

return $RC
}
test_case_04()
{
#TODO give TCID
TCID="opencl_perf_test"
#TODO give TST_COUNT
TST_COUNT=4
RC=0
echo "You can use anny key to quit the testapp, such as blank key."


    cd ${TEST_DIR}/${APP_SUB_DIR}
    cd fslcl_sdk
    echo "==========================="
    echo "OpenCL Test"
    echo "==========================="

    echo "==========================="
    echo "colorseg_demo"
    echo "==========================="
    ./colorseg_demo || RC=$(echo $RC colorseg_demo)

    echo "==========================="
    echo "gaussianfilter_test gray"
    echo "==========================="
    ./gaussianfilter_test data/image.bmp test.bmp gray || RC=$(echo $RC gaussianfilter_test_gray)

    echo "==========================="
    echo "gaussianfilter_test rgb"
    echo "==========================="
    ./gaussianfilter_test data/image.bmp test.bmp rgb || RC=$(echo $RC gaussianfilter_test_rgb)

    echo "==========================="
    echo "gray2rgb_test"
    echo "==========================="
    ./gray2rgb_test data/image.bmp test.bmp || RC=$(echo $RC gray2rgb_test)

    echo "==========================="
    echo "medianfilter_test"
    echo "==========================="
     ./medianfilter_test data/image.bmp test.bmp || RC=$(echo $RC medianfilter_test)

    echo "==========================="
    echo "morphodilate_test"
    echo "==========================="
    ./morphodilate_test data/image.bmp test.bmp || RC=$(echo $RC morphodilate_test)

    echo "==========================="
    echo "morphoerode_test"
    echo "==========================="
    ./morphoerode_test data/image.bmp test.bmp || RC=$(echo $RC morphoerode_test)

    echo "==========================="
    echo "rgb2gray_test"
    echo "==========================="
    ./rgb2gray_test data/image.bmp test.bmp || RC=$(echo $RC rgb2gray_test)

    echo "==========================="
    echo "rgb2hsv_test"
    echo "==========================="
    ./rgb2hsv_test data/image.bmp test.bmp || RC=$(echo $RC rgb2hsv_test)

    echo "==========================="
    echo "rgb888torgb565_test"
    echo "==========================="
    ./rgb888torgb565_test data/image.bmp test.bmp || RC=$(echo $RC rgb888torgb565_test)

    echo "==========================="
    echo "rgb888toUYVY_test"
    echo "==========================="
    ./rgb888toUYVY_test data/image.bmp test.bmp || RC=$(echo $RC rgb888toUYVY_test)

    echo "==========================="
    echo "sobelhfilter_test"
    echo "==========================="
    ./sobelhfilter_test data/image.bmp test.bmp || RC=$(echo $RC sobelhfilter_test)

    echo "==========================="
    echo "sobelvfilter_test"
 echo "==========================="
    ./sobelvhfilter_test data/image.bmp test.bmp || RC=$(echo $RC sobelvhfilter_test)

    echo "==========================="
    echo "vivante_fft"
    echo "==========================="
    ./vivante_fft 1024 || RC=$(echo $RC vivante_fft)

    if [ "$RC" -eq "0" ]; then
        RC=0
    else
        echo "Fail apps are listed as below, please check!"
        echo $RC
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
echo "4: perf test"
}

# main function

RC=0

#TODO check parameter
if [ $# -ne 1 ]
then
usage
exit 1 
fi

unit_list="loadstore math threadwalker"
unit_list="$unit_list  test_vivante/functions_and_kernels"
unit_list="$unit_list  test_vivante/illegal_vector_sizes"
unit_list="$unit_list  test_vivante/initializers"
unit_list="$unit_list  test_vivante/multi_dimensional_arrays"
unit_list="$unit_list  test_vivante/reserved_data_types"
unit_list="$unit_list  test_vivante/structs_and_enums"
unit_list="$unit_list  test_vivante/unions"
unit_list="$unit_list  test_vivante/unsupported_extensions"

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
APP_SUB_DIR="ubuntu_10.10/test"
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
63)
  APP_SUB_DIR="imx61_rootfs/test"
  ;;
80)
  APP_SUB_DIR="yocto_imx8_fb/"
  ;;
*)
  exit 0
  ;;
esac
fi


case "$1" in
1)
  test_case_01 || exit $RC 
  ;;
2)
  test_case_02 || exit $RC
  ;;
3)
  test_case_03 || exit $RC
  ;;
4)
  test_case_04 || exit $RC
  ;;

*)
  usage
  ;;
esac

tst_resm TINFO "Test Finish"
