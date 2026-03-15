#!/usr/bin/bash

#
# Input data
#
export CONTROLLER_IP=172.16.0.19
export ANALYTICS_PORT=8081
export COMPUTE_IP=172.16.0.54
export VMI_FQ_NAME=default-domain:a-lab:port-1
export WAIT_TIME=1
export SHOW_ONLY=N
export R_REF=10240 # B/s
#export R_REF=1048576 # B/s
export K_P=0.5
export T_I=10000000
export T_D=0.01


#
# Operative data
#
export T_C=
export T_O=
export B_C=
export B_O=
export R_C=0
export R_O=0
export DELTA_B=0
export E_C=0
export E_O=0
export E_I=0
export E_D=0
export BW=0

function tap_interface() {
    iface_mac=$(curl -s http://$CONTROLLER_IP:$ANALYTICS_PORT/analytics/uves/virtual-machine-interface/$VMI_FQ_NAME?flat | jq -r '.UveVMInterfaceAgent.mac_address')
    iface_tap="${iface_mac:3:14}"
    iface_tap=tap`echo $iface_tap | rev | sed "s/:/-/" | rev | sed "s/://g"`
    echo $iface_tap
}

function read_bytescount() {
    local intf_state=`curl -s http://$CONTROLLER_IP:$ANALYTICS_PORT/analytics/uves/virtual-machine-interface/$VMI_FQ_NAME?flat`
    local c_tput=`echo $intf_state | jq '.VMIStats.raw_if_stats.in_bytes'`
    local c_time=`echo $intf_state | jq '.VMIStats.__T'`
    local c_time_sec=`expr $c_time / 1000000`
    local c_time_us=` expr $c_time % 1000000`
    echo "$c_time_sec $c_time_us $c_tput"
}

function set_bandwidth() {
    local tap=$1
    local bw_bps=$2
    local bw_kbitps=`expr $bw_bps \* 8 / 1024`
    echo "$1 $2"
    ssh root@$COMPUTE_IP "/root/wondershaper/wondershaper -m -a $tap -u $bw_kbitps -d $bw_kbitps"
}

TAP_NAME=`tap_interface`
values=(`read_bytescount`)
T_C=${values[0]}
B_C=${values[2]}

if [ -z "$T_O" ]
then
    T_O=$T_C
    B_O=$B_C
    sleep 1
fi

while [ true ]
do
    values=(`read_bytescount`)
    T_C=${values[0]}
    B_C=${values[2]}
    if [ $T_C -eq $T_O ]
    then
        echo "T_C eq T_O, waiting"
        sleep $WAIT_TIME
        continue
    fi
    R_O=$R_C
    R_C=`expr \( $B_C - $B_O \) / \( $T_C - $T_O \)`
    E_O=$E_C
    E_C=`expr \( $R_REF - $R_C \)`
    E_I1=`expr \( $E_C + $E_O \) \* \( $T_C - $T_O \) / 2`
    E_I=`expr $E_I + $E_I1`
    E_D=`expr \( $E_C - $E_O \) / \( $T_C - $T_O \)`
    DELTA_B=`echo "$K_P * ( $E_C + $E_I / $T_I + $E_D * $T_D )" | bc`
    DELTA_B=`echo ${DELTA_B%%.*}`
    BW=`expr $R_C + $DELTA_B`
    if [ $BW -lt 0 ]
    then
        BW=0
    fi

    T_O_FORMAT=`date -d @$T_C`
    echo "T=$T_O_FORMAT, B=$B_C, R=$R_C, E(R)=$E_C, Ei=$E_I, Ed=$E_D, dE=$DELTA_B, new BW=$BW"
    if [ "$SHOW_ONLY" != "Y" ]
    then
        set_bandwidth $TAP_NAME $BW
    fi
    T_O=$T_C
    B_O=$B_C
done
