#!/usr/bin/env bash

ACTION=$1
TYPE=$2
ID=$3
VAL=$4

case $ACTION in
    set-volume)
        # Type should be 'sink', 'source', or 'sink-input'
        pactl set-$TYPE-volume "$ID" "$VAL%"
        ;;
    toggle-mute)
        pactl set-$TYPE-mute "$ID" toggle
        ;;
    set-default)
        # For setting defaults, we need to use the name rather than the index
        pactl set-default-$TYPE "$ID"
        ;;
esac
