#!/bin/bash

SESSION_NAME="numbered-windows"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux attach -t "$SESSION_NAME"
    exit 0
fi

tmux new-session -d -s "$SESSION_NAME" -n "󰀶"

WINDOW_NAMES=("" "" "" "" "" "")
for name in "${WINDOW_NAMES[@]}"; do
    tmux new-window -t "$SESSION_NAME" -n "$name"
done

tmux select-window -t "$SESSION_NAME:󰀶"
tmux attach -t "$SESSION_NAME"
