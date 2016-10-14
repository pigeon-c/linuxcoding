#!/bin/bash -x

AdhocSSID=TestAdhoc1
export ServerIP=192.168.1.100

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
    export TST_TOTAL=4

    export TCID="SETUP"
    export TST_COUNT=0
    RC=0
    trap "cleanup" 0

    if [ -z "${SSID}" ] || [ -z "${Passphrase}" ]; then
        SSID=LinuxBSPtest_5G
        Passphrase=Happy123
    fi
    if [ -z "${ServerIP}" ]; then
        ServerIP=192.168.1.100
    fi

    sleep 1
    current_time=$(date +%s)
    # Configure the passphrase, save the first 3 lines of original configuration
    head -n 4 /etc/wpa_supplicant.conf > /etc/wpa_supplicant_${current_time}.conf
    # Generate a WPA PSK from an ASCII passphrase for a SSID. such as SSID: LinuxBSPtest_5G passphrase: Happy123
    wpa_passphrase ${SSID} ${Passphrase} >> /etc/wpa_supplicant_${current_time}.conf
    # Backup the original configuration.
    #mv /etc/wpa_supplicant.conf /etc/wpa_supplicant.conf.bak
    # Use the current configration:
    #mv /etc/wpa_supplicant_${current_time}.conf.tmp /etc/wpa_supplicant_${current_time}.conf
    # Load the Broadcom WIFI module.
    if [ -z "${Firmware}" ]; then
        Firmware=/lib/firmware/bcm/ZP_BCM4339/fw_bcmdhd.bin
    fi
    if [ -z "${Nvram}" ]; then
        Nvram=/lib/firmware/bcm/ZP_BCM4339/bcmdhd.ZP.SDIO.cal
    fi
    # Check if the WiFi driver is built-in or modulable.
    MorY=`cat /proc/config.gz|gunzip|grep "CONFIG_BCMDHD="|awk -F "=" '{print $2}'`
    if [ "${MorY}" = "m" ];then
        modprobe bcmdhd firmware_path=${Firmware} nvram_path=${Nvram} || RC=$(expr $RC + 1)
    fi
    # Need kill wpa_supplicant first and then do WiFi test, otherwise WiFi will auto connect to a open AP.
    killall wpa_supplicant
    sleep 3

    return $RC
}

# Function:     connect_ap
#
# Description   - Connect to an AP basic test with WPA2 security.
#
connect_ap()
{
    RC=0

    # Connect the WiFi AP with before configuration.
    wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant_${current_time}.conf -D nl80211 || RC=$(expr $RC + 1)
    if [ $RC -ne 0 ]; then
        rm -rf /var/run/wpa_supplicant/wlan0
        wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant_${current_time}.conf -D nl80211 || RC=$(expr $RC + 1)
    fi
    sleep 10
    # Check if connect to WiFi AP.
    if iw wlan0 link | grep Connected; then
        # Get the IP address.
        { sleep 120; killall udhcpc; } &
        udhcpc -i wlan0 || RC=$(expr $RC + 1)
        # Get the local wlan IP adress.
        export LocalIP=$(ifconfig wlan0 | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
    else
        tst_resm TFAIL "Cannot connect to AP, please check if AP powered on and SSID/Passphrase."
        RC=$(expr $RC + 1)
    fi
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

    #mv /etc/wpa_supplicant.conf.bak /etc/wpa_supplicant.conf
    rm -rf /etc/wpa_supplicant_${current_time}.conf
    rm -rf iperf.log
    return $RC
}

# Function:     uninstall
# Description   - uninstall WiFi module
#
unload()
{
    # Disconnect the link then unload the WiFi module.
    ifconfig wlan0 down || RC=$(expr $RC + 1)
    if [ "${MorY}" = "m" ];then
        modprobe -r bcmdhd || RC=$(expr $RC + 1)
    fi
}

# Function:     test_case_01
# Description   - Basic data transfer test with host via an AP.
#
test_case_01()
{
    TCID="WIFI_BASIC_TEST"
    TST_COUNT=1
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    connect_ap || RC=$(expr $RC + 1)
    tst_resm TINFO "Local IP is ${LocalIP}."
    # Run the iperf test.
    iperf -c ${ServerIP} -B ${LocalIP} -t 100 -i 5 > iperf.log || RC=$(expr $RC + 1)
    cat iperf.log
    if [ $RC -ne 0 ] || ! grep 'Interval' iperf.log; then
        tst_resm TFAIL "iperf test fail, please check if server side have ran 'iperf -s'."
        unload || RC=$(expr $RC + 1)
        return $RC
    fi
    sleep 1
    # Additional uncommon test, uninstall module with WiFi connected.
    if [ "${MorY}" = "m" ];then
        unload || RC=$(expr $RC + 1)
        setup || RC=$(expr $RC + 1)
        connect_ap || RC=$(expr $RC + 1)
        modprobe -r bcmdhd || RC=$(expr $RC + 1)
        setup || RC=$(expr $RC + 1)
        connect_ap || RC=$(expr $RC + 1)
        unload || RC=$(expr $RC + 1)
    fi
    return $RC
}

# Function:     test_case_02
# Description   - No-busy state with suspend and resume test.
#
test_case_02()
{
    TCID="SUSPEND_RESUME_TEST"
    TST_COUNT=2
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    connect_ap || RC=$(expr $RC + 1)
    tst_resm TINFO "Local IP is ${LocalIP}."
    rtc_testapp_6 -T 50 -m mem
    rtc_testapp_6 -T 50 -m standby
    # Check if connect to WiFi AP.
    if iw wlan0 link | grep Connected; then
        tst_resm TINFO "WiFi link is ok after suspend/resume."
    else
        tst_resm TFAIL "WiFi link drops after suspend/resume."
        RC=$(expr $RC + 1)
    fi
    sleep 1
    unload || RC=$(expr $RC + 1)
    sleep 1
    # Additional test: suspend/resume first, to validate if WiFi can connect to AP.
    rtc_testapp_6 -T 50 -m mem
    rtc_testapp_6 -T 50 -m standby
    setup || RC=$(expr $RC + 1)
    connect_ap || RC=$(expr $RC + 1)
    unload || RC=$(expr $RC + 1)
    return $RC
}

# Function:     test_case_03
# Description   - Data transfer overnight stress test.
#
test_case_03()
{
    TCID="DATA_TRANSFER_STRESS"
    TST_COUNT=3
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    connect_ap || RC=$(expr $RC + 1)
    tst_resm TINFO "Local IP is ${LocalIP}."
    export LOCALIP=${LocalIP}
    # Check if the remote server run netserver already.
    if ping ${ServerIP} -I ${LocalIP} -c 5; then
        if netperf -t REM_CPU -H ${ServerIP}; then
            # Run the netperf test.
            tst_resm TINFO "Remote server ran netserver already, go on test."
            loops=20
            i=0
            while [ $i -lt $loops ]; do
                Fail_flag=0
                tcp_stream_2nd_script ${ServerIP} CPU || Fail_flag=1
                sleep 1
                udp_stream_2nd_script ${ServerIP} CPU || Fail_flag=1
                sleep 1
                let i++
                if [ ${Fail_flag} -eq 1 ]; then
                    RC=$(expr $RC + 1)
                    tst_resm TINFO  "==========Test fail at No.$i time data transfer.=========="
                fi
            done
        else
            RC=$(expr $RC + 1)
            tst_resm TINFO "Remote server has not run netserver, please check."
        fi
    else
        RC=$(expr $RC + 1)
        tst_resm TINFO "Ping fail between local wlan and remote server, please check."
    fi

    return $RC
}

# Function:     test_case_04
# Description   -  WiFi module load/unload or wlan up/down stress test.
#
test_case_04()
{
    TCID="LOAD_UNLOAD_STRESS"
    TST_COUNT=4
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    # WiFi module load/unload or wlan up/down stress test with AP disconnected.
    loops=200
    i=0
    while [ $i -lt $loops ]; do
        Fail_flag=0
        setup || Fail_flag=1
        ifconfig wlan0 up || Fail_flag=1
        sleep 3
        unload || Fail_flag=1
        let i++
        if [ ${Fail_flag} -eq 1 ]; then
            RC=$(expr $RC + 1)
            tst_resm TINFO  "==========Test fail at No.$i time disconnected load/unload.=========="
        fi
    done
    # WiFi module load/unload or wlan up/down stress test with AP connected.
    loops=200
    i=0
    while [ $i -lt $loops ]; do
        Fail_flag=0
        setup || Fail_flag=1
        ifconfig wlan0 up || Fail_flag=1
        connect_ap || Fail_flag=1
        # kill the udhcpc process as there's a known issue: udhcpc cannot exit, which blocks test.
        cnt_udhcpc=`ps -aux |grep -i 'udhcpc -i wlan0'|wc -l`
        if [ ${cnt_udhcpc} -gt 1 ]; then
            killall udhcpc
        fi
        tst_resm TINFO "Local IP is ${LocalIP}."
        ping ${ServerIP} -I ${LocalIP} -c 5 || Fail_flag=1
        unload || Fail_flag=1
        let i++
        if [ ${Fail_flag} -eq 1 ]; then
            RC=$(expr $RC + 1)
            tst_resm TINFO  "==========Test fail at No.$i time disconnected load/unload.=========="
        fi
    done

    tst_resm TINFO "Local IP is ${LocalIP}."

    return $RC
}

# Function:     test_case_05
# Description   - Ad-Hoc test environment setup.
#
test_case_05()
{
    TCID="AD_HOC_ENV_SETUP"
    TST_COUNT=5
    RC=0

    tst_resm TINFO "test $TST_COUNT: $TCID "
    if [ -z "${AdhocSSID}" ]; then
        AdhocSSID=TestAdhoc1
    fi
    ifconfig wlan0 192.168.1.55 up || RC=$(expr $RC + 1)
    iw wlan0 scan | grep -i IBSS || RC=$(expr $RC + 1)
    iw wlan0 set type ibss || RC=$(expr $RC + 1)
    iw wlan0 ibss join ${AdhocSSID} 2412 || RC=$(expr $RC + 1)
    tst_resm TINFO "Check if network is connected, if you can not ping success, please disconnect the laptop side, then re-connect the laptop side."
    return $RC
}

usage()
{
cat <<-EOF
    $0 [case ID]
    1: Basic data transfer test with host via an AP.
    2: No-busy state with suspend and resume test.
    3: Data transfer overnight stress test.
    4: WiFi module load/unload or wlan up/down stress test.
    5: Ad-Hoc test environment setup.
EOF
    exit 1
}

# main function

RC=0

if [ $# -ne 1 ]
then
    usage
fi

setup || exit $RC

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
    5)
        test_case_05 || exit $RC
        ;;
    setup)
        ;;
    unload)
        unload || exit $RC
        ;;
    connect)
        connect_ap || exit $RC
        ;;
    *)
        usage
        ;;
esac
