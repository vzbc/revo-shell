#!/bin/bash
# Reads notification counts from window titles using hyprctl
# Output format: appId|count per line
# Apps like Discord put "(17761)" or "17,761" in their window title

hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json, re

try:
    clients = json.load(sys.stdin)
except:
    sys.exit(0)

for c in clients:
    title = c.get('title', '')
    class_name = c.get('class', '')
    initial_title = c.get('initialTitle', '')
    
    # Try to find a number in the title (notification count)
    # Patterns: (123), [123], 123, 1,234
    numbers = re.findall(r'[\(\[]?(\d[\d,\.]*)[\)\]]?', title)
    
    count = 0
    for n in numbers:
        clean = n.replace(',', '').replace('.', '')
        if clean.isdigit() and int(clean) > 0:
            count = int(clean)
            break
    
    if count > 0:
        print(f'{class_name}|{count}')
" 2>/dev/null
