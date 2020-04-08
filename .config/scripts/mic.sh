#!/bin/bash

[[ -z "${WAYLAND_DISPLAY}" ]] && display='xorg' || display='wayland'
icon_low="notification-audio-volume-low.svg"
icon_med="notification-audio-volume-medium.svg"
icon_high="notification-audio-volume-high.svg"
icon_over="notification-audio-volume-high.svg"
icon_mute="notification-audio-volume-muted.svg"
content_file=/tmp/mic-$display

function update_source {
    source=$(pactl list short sources | grep input | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,')
}

function volume_up {
    update_source
    pactl set-source-volume $source +5%
    volume_print
}

function volume_down {
    update_source
    pactl set-source-volume $source -5%
    volume_print
}

function volume_mute {
    update_source
    pactl set-source-mute $source toggle
    volume_print
}

function get_volume {
    pactl list sources | grep '^[[:space:]]Volume:' | tail -n 1 | head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
}

function volume_print {
    update_source

    mute=$(pactl list sources | grep '^[[:space:]]Mute:' | tail -n 1 | awk '{ print $2 }')
    if [ "$mute" = "yes" ]; then
        echo " muted" > $content_file
    else
        echo " `get_volume`%" > $content_file
    fi
}
function listen {
    if [ ! -f $content_file ]; then
        volume_print
    fi

    echo "$(cat $content_file)"

    pactl subscribe | while read -r event; do
        if echo "$event" | grep -qv "Client" &>/dev/null; then
            echo "$(cat $content_file)"
        fi
    done
}
case "$1" in
    up)
        volume_up
        ;;
    down)
        volume_down
        ;;
    mute)
        volume_mute
        ;;
    *)
        listen
        ;;
esac

# case $1 in
#     up)
#         pactl set-source-volume $source +5%
#         volume_print
#         ;;
#     down)
#         pactl set-source-volume $source -5%
#         volume_print
# 	    ;;
#     mute)
#         pactl set-source-mute $source toggle
#         volume_print
#         ;;
#     *)
#         volume_print
#         ;;
# esac

