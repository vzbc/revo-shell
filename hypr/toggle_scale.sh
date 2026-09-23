#!/bin/bash

MONITOR="DP-1"

# Get current scale value
CURRENT_SCALE=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .scale")

if [[ "$CURRENT_SCALE" == "2.00" ]]; then
    # Switch to 1.5
    hyprctl keyword monitor "$MONITOR,2560x1440@180,auto,1,transform,0"
else
    # Switch to 2
    hyprctl keyword monitor "$MONITOR,2560x1440@180,auto,1,transform,0"
fi

