#!/usr/bin/env bash

set -euo pipefail

max_chars=18
sleep_interval=0.4
restart_delay=1
separator="  •  "
field_sep=$'\x1f'

player=""
status="stopped"
artist=""
title=""
offset=0
last_payload=""
coproc_pid=""
coproc_fd=""

json_escape() {
    local value="${1-}"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

player_icon() {
    case "${1,,}" in
        spotify)
            printf ' '
            ;;
        firefox)
            printf '󰈹 '
            ;;
        mpv)
            printf '󰐹 '
            ;;
        chromium|google-chrome|brave|brave-browser)
            printf ' '
            ;;
        *)
            printf '󰎇 '
            ;;
    esac
}

marquee_text() {
    local text="$1"
    local width="$2"

    if [ "${#text}" -le "$width" ]; then
        printf '%s' "$text"
        return
    fi

    local scroll_text="${text}${separator}"
    local scroll_len=${#scroll_text}
    local doubled_text="${scroll_text}${scroll_text}"
    local start=$((offset % scroll_len))

    printf '%s' "${doubled_text:start:width}"
}

print_state() {
    local display_title="$title"
    local short_title
    local tooltip="$title"
    local payload
    local status_class="${status,,}"

    if [ -z "$display_title" ]; then
        payload='{"text":"","tooltip":"","class":"stopped"}'
    else
        short_title="$(marquee_text "$display_title" "$max_chars")"
        if [ -n "$artist" ] && [ "$artist" != "$display_title" ]; then
            tooltip="${tooltip}\n${artist}"
        fi
        if [ -n "$player" ]; then
            tooltip="${tooltip}\n${player} (${status})"
        fi

        payload=$(printf '{"text":"%s %s","tooltip":"%s","class":"%s"}' \
            "$(json_escape "$(player_icon "$player")")" \
            "$(json_escape "$short_title")" \
            "$(json_escape "$tooltip")" \
            "$(json_escape "$status_class")")
    fi

    if [ "$payload" != "$last_payload" ]; then
        printf '%s\n' "$payload"
        last_payload="$payload"
    fi
}

update_state() {
    local new_player="$1"
    local new_status="$2"
    local new_artist="$3"
    local new_title="$4"
    local next_title

    next_title="$new_title"
    if [ -z "$next_title" ]; then
        next_title="${new_artist:-${new_player:-No media}}"
    fi

    if [ "$new_player" != "$player" ] || [ "$new_status" != "$status" ] || [ "$new_artist" != "$artist" ] || [ "$next_title" != "$title" ]; then
        player="$new_player"
        status="$new_status"
        artist="$new_artist"
        title="$next_title"
        offset=0
    fi
}

cleanup() {
    if [ -n "$coproc_pid" ] && kill -0 "$coproc_pid" 2>/dev/null; then
        kill "$coproc_pid" 2>/dev/null || true
        wait "$coproc_pid" 2>/dev/null || true
    fi
}

trap cleanup EXIT

while true; do
    cleanup
    coproc PLAYERCTL {
        exec playerctl --player=playerctld --follow metadata --format "{{playerName}}${field_sep}{{status}}${field_sep}{{artist}}${field_sep}{{title}}" 2>/dev/null
    }
    coproc_pid=$PLAYERCTL_PID
    coproc_fd=${PLAYERCTL[0]}
    print_state

    while true; do
        if [ -n "$title" ] && [ "${#title}" -gt "$max_chars" ]; then
            if IFS= read -r -t "$sleep_interval" line <&"$coproc_fd"; then
                IFS="$field_sep" read -r next_player next_status next_artist next_title <<<"$line"
                update_state "$next_player" "${next_status:-stopped}" "$next_artist" "$next_title"
                print_state
            else
                offset=$((offset + 1))
                print_state
            fi
            continue
        fi

        if ! IFS= read -r line <&"$coproc_fd"; then
            break
        fi

        IFS="$field_sep" read -r next_player next_status next_artist next_title <<<"$line"
        update_state "$next_player" "${next_status:-stopped}" "$next_artist" "$next_title"
        print_state
    done

    player=""
    status="stopped"
    artist=""
    title=""
    offset=0
    print_state
    sleep "$restart_delay"
done
