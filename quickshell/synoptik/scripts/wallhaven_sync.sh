#!/usr/bin/env bash

API_KEY="$1"
USERNAME="$2"
TARGET_DIR="${3:-$HOME/Pictures/Wallpapers}"

mkdir -p "$TARGET_DIR"

if [ -z "$API_KEY" ] || [ -z "$USERNAME" ]; then
    echo "STATUS:Missing API key or username"
    exit 1
fi

echo "STATUS:Connecting to Wallhaven..."

# 1. Fetch user collections list
COLLECTIONS_JSON=$(curl -s -H "X-API-Key: $API_KEY" "https://wallhaven.cc/api/v1/collections/$USERNAME?apikey=$API_KEY")

API_ERROR=$(echo "$COLLECTIONS_JSON" | jq -r '.error // empty')
if [ -n "$API_ERROR" ]; then
    echo "STATUS:Error: $API_ERROR"
    exit 1
fi

COLLECTION_IDS=$(echo "$COLLECTIONS_JSON" | jq -r '.data[].id // empty')

if [ -z "$COLLECTION_IDS" ]; then
    echo "STATUS:No collections found for $USERNAME"
    exit 0
fi

# 2. Iterate through all collections and all paginated pages
ALL_URLS=()

for cid in $COLLECTION_IDS; do
    PAGE=1
    while : ; do
        echo "STATUS:Querying collection #$cid (page $PAGE)..."
        # purity=111 fetches SFW, Sketchy, and NSFW (if account API key permits it)
        PAGE_DATA=$(curl -s -H "X-API-Key: $API_KEY" "https://wallhaven.cc/api/v1/collections/$USERNAME/$cid?apikey=$API_KEY&purity=111&page=$PAGE")
        
        URLS=$(echo "$PAGE_DATA" | jq -r '.data[].path // empty')
        
        # Stop looping if page is empty
        if [ -z "$URLS" ]; then
            break
        fi

        for u in $URLS; do
            [ -n "$u" ] && ALL_URLS+=("$u")
        done

        LAST_PAGE=$(echo "$PAGE_DATA" | jq -r '.meta.last_page // 1')
        if [ "$PAGE" -ge "$LAST_PAGE" ]; then
            break
        fi

        PAGE=$((PAGE + 1))
    done
done

TOTAL=${#ALL_URLS[@]}
if [ "$TOTAL" -eq 0 ]; then
    echo "STATUS:Collections are empty"
    exit 0
fi

echo "STATUS:Downloading $TOTAL wallpapers..."
CURRENT=0

# 3. Download files sequentially
for url in "${ALL_URLS[@]}"; do
    FILENAME=$(basename "$url")
    DEST="$TARGET_DIR/$FILENAME"
    
    if [ ! -f "$DEST" ]; then
        curl -s -L -o "$DEST" "$url"
    fi
    
    CURRENT=$((CURRENT + 1))
    echo "PROGRESS:$CURRENT:$TOTAL"
done

echo "STATUS:Complete ($TOTAL wallpapers synced)"
exit 0