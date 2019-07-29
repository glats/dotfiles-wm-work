#!/bin/bash

# Volume notification: Pulseaudio and dunst
set -u

icon_path=/usr/share/icons/ePapirus/48x48/status/
notify_id=506
sink_nr=$(pactl list short sinks | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,' | head -n 1)   # use `pacmd list-sinks` to find out sink_nr
icon_low="notification-audio-volume-low.svg"
icon_med="notification-audio-volume-medium.svg"
icon_high="notification-audio-volume-high.svg"
icon_over="notification-audio-volume-high.svg"
icon_mute="notification-audio-volume-muted.svg"
notify=$HOME/.config/i3/notify-send.sh


function get_volume {
    pacmd list-sinks | awk '/\tvolume:/ { print $5 }'  | head -n1 | cut -d '%' -f 1
}

function get_volume_icon {
    if [ "$1" -lt 34 ]
    then
        echo -n $icon_low
    elif [ "$1" -lt 67 ]
    then
        echo -n $icon_med
    elif [ "$1" -le 100 ]
    then
        echo -n $icon_high
    else
        echo -n $icon_over
    fi
}

function get_bar {
    volume=`get_volume`
    seq -s "─" $(($volume / 5)) | sed 's/[0-9]//g'
}

function get_mute_bar {
    volume=`get_volume`
    seq -s "." $(($volume / 5)) | sed 's/[0-9]//g'
}

function volume_notification {
    volume=`get_volume`
    vol_icon=`get_volume_icon $volume`
    bar=`get_bar`
    exec $notify -r $notify_id -u low -i $icon_path$vol_icon $bar
}

function mute_notification {
    muted=$(pacmd list-sinks | awk '/muted/ { print $2 }' | head -n1)
    if [ $muted == 'yes' ]
    then
        exec $notify -r $notify_id -u low -i $icon_path$icon_mute `get_mute_bar`
    else
        exec $notify -r $notify_id -u low -i ${icon_path}`get_volume_icon $(get_volume)` `get_bar`
    fi
}

case $1 in
    up)
        pactl set-sink-volume $sink_nr +2%
        volume_notification
        ;;
    down)
        pactl set-sink-volume $sink_nr -2%
        volume_notification
	    ;;
    mute)
        pactl set-sink-mute $sink_nr toggle
        mute_notification
        ;;
    *)
        echo "Usage: $0 up | down | mute"
        ;;
esac
