#!/bin/bash

BASE_URL="https://link233on.github.io"
DEB_DIR="./debs"
OUT_DIR="./sileodepiction"
ASSETS="./assets"
DEFAULT_BANNER_URL="${BASE_URL}/assets/default_banner.png"

COMPATIBILITY_TEXT="iOS 15.0+"
TINT_COLOR="#1F6FB5"
IGNORE_WORDS="Rootless|rootless|ROOTLESS|Rootful|rootful|ROOTFUL|RootHide|roothide|ROOTHIDE"
SKIP_SECTIONS="Development|Localization|System"

[ ! -d "$DEB_DIR" ] && echo "ERR: debs dir not found" && exit 1
mkdir -p "$OUT_DIR" "$ASSETS"

for deb in "$DEB_DIR"/*.deb; do
    [ -e "$deb" ] || continue

    SEC=$(dpkg-deb -f "$deb" Section | tr -d '\r')
    if echo "$SEC" | grep -qE "^($SKIP_SECTIONS)$"; then
        echo "SKIP: $(basename "$deb") (section)"
        continue
    fi

    RAW_NAME=$(dpkg-deb -f "$deb" Name | tr -d '\r')
    CLEAN_NAME=$(echo "$RAW_NAME" | sed -E "s/[-_ ]*\(?($IGNORE_WORDS)\)?//g" | xargs)
    SAFE_NAME=$(echo "$CLEAN_NAME" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' | tr -d ' ')
    SAFE_NAME=$(echo "$SAFE_NAME" | sed 's/[\/]/_/g')
    
    TARGET="$OUT_DIR/$SAFE_NAME"
    JSON_FILE="$TARGET/SileoDepiction.json"
    mkdir -p "$TARGET"
    
    SHOULD_UPDATE=false

    if [ ! -f "$JSON_FILE" ]; then
        SHOULD_UPDATE=true
    elif [ "$deb" -nt "$JSON_FILE" ]; then
        SHOULD_UPDATE=true
    fi

    HAS_LOCAL_IMG=false
    [ -f "$TARGET/SileoBanner.png" ] && HAS_LOCAL_IMG=true

    if [ "$HAS_LOCAL_IMG" = true ]; then
        if [ "$TARGET/SileoBanner.png" -nt "$JSON_FILE" ]; then
            SHOULD_UPDATE=true
        elif ! grep -q "${BASE_URL}/sileodepiction/${SAFE_NAME}/SileoBanner.png" "$JSON_FILE"; then
            SHOULD_UPDATE=true
        fi
    elif [ "$HAS_LOCAL_IMG" = false ] && grep -q "${BASE_URL}/sileodepiction/${SAFE_NAME}/SileoBanner.png" "$JSON_FILE"; then
        SHOULD_UPDATE=true
    fi

    if [ "$SHOULD_UPDATE" = false ]; then
        echo "SKIP: $SAFE_NAME (no update)"
        continue
    fi

    NEW_VER=$(dpkg-deb -f "$deb" Version | tr -d '\r')
    echo "GEN: $SAFE_NAME v$NEW_VER"
    
    RAW_DESC=$(dpkg-deb -f "$deb" Description)
    DESC=$(echo "$RAW_DESC" | tr -d '\r' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\t/    /g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')

    DEV=$(dpkg-deb -f "$deb" Author | tr -d '\r')
    [ -z "$DEV" ] && DEV=$(dpkg-deb -f "$deb" Maintainer | tr -d '\r')
    
    DATE=$(date -r "$deb" "+%B %d, %Y")

    if [ -f "$TARGET/SileoBanner.png" ]; then
        FINAL_BANNER_URL="${BASE_URL}/sileodepiction/${SAFE_NAME}/SileoBanner.png"
    else
        FINAL_BANNER_URL="${DEFAULT_BANNER_URL}"
    fi

    SCREENSHOTS_ITEMS=""
    HAS_SCREENSHOTS=false
    FIRST_IMG=true

    for i in {1..10}; do
        IMG_NAME="screenshot${i}.png"
        if [ -f "$TARGET/$IMG_NAME" ]; then
            HAS_SCREENSHOTS=true
            IMG_URL="${BASE_URL}/sileodepiction/${SAFE_NAME}/${IMG_NAME}"
            
            ITEM_JSON="{
                            \"accessibilityText\": \"Screenshot ${i}\",
                            \"url\": \"${IMG_URL}\",
                            \"fullSizeURL\": \"${IMG_URL}\"
                        }"

            if [ "$FIRST_IMG" = false ]; then
                SCREENSHOTS_ITEMS="${SCREENSHOTS_ITEMS},"
            fi
            SCREENSHOTS_ITEMS="${SCREENSHOTS_ITEMS}${ITEM_JSON}"
            FIRST_IMG=false
        fi
    done

    SCREENSHOTS_VIEW_BLOCK=""
    if [ "$HAS_SCREENSHOTS" = true ]; then
        SCREENSHOTS_VIEW_BLOCK="{
                    \"class\": \"DepictionSeparatorView\"
                },
                {
                    \"class\": \"DepictionHeaderView\",
                    \"title\": \"Preview\"
                },
                {
                    \"class\": \"DepictionScreenshotsView\",
                    \"itemCornerRadius\": 8,
                    \"itemSize\": \"{160, 275}\",
                    \"screenshots\": [
                        $SCREENSHOTS_ITEMS
                    ],
                    \"ipad\": {
                        \"class\": \"DepictionScreenshotView\",
                        \"itemCornerRadius\": 12,
                        \"itemSize\": \"{320, 550}\",
                        \"screenshots\": [
                            $SCREENSHOTS_ITEMS
                        ]
                    }
                },
                {
                    \"class\": \"DepictionSpacerView\",
                    \"spacing\": 16
                },"
    fi

    cat > "$JSON_FILE" <<EOF
{
    "minVersion": "0.3",
    "class": "DepictionTabView",
    "headerImage": "${FINAL_BANNER_URL}",
    "tintColor": "${TINT_COLOR}",
    "tabs": [
        {
            "class": "DepictionStackView",
            "tabName": "Details",
            "views": [
                {
                    "class": "DepictionMarkdownView",
                    "markdown": "${DESC}",
                    "useRawMarkdown": true,
                    "useBottomMargin": false
                },
                {
                    "class": "DepictionSpacerView",
                    "spacing": 12
                },
                ${SCREENSHOTS_VIEW_BLOCK}
                {
                    "class": "DepictionSeparatorView"
                },
                {
                    "class": "DepictionHeaderView",
                    "title": "Information"
                },
                {
                    "class": "DepictionTableTextView",
                    "title": "Section",
                    "text": "${SEC}"
                },
                {
                    "class": "DepictionTableTextView",
                    "title": "Version",
                    "text": "${NEW_VER}"
                },
                {
                    "class": "DepictionTableTextView",
                    "title": "Updated",
                    "text": "${DATE}"
                },
                {
                    "class": "DepictionTableTextView",
                    "title": "Compatibility",
                    "text": "${COMPATIBILITY_TEXT}"
                },
                {
                    "class": "DepictionTableTextView",
                    "title": "Developer",
                    "text": "${DEV}"
                },
                {
                    "class": "DepictionSpacerView",
                    "spacing": 20
                }
            ]
        },
        {
            "class": "DepictionStackView",
            "tabName": "Changelog",
            "views": [
                {
                    "class": "DepictionTableTextView",
                    "title": "Version ${NEW_VER}",
                    "text": "${DATE}"
                },
                {
                    "class": "DepictionMarkdownView",
                    "markdown": "<ul><li>Update generated from deb file.</li><li>Check description for details.</li></ul>",
                    "useRawFormat": true
                },
                {
                    "class": "DepictionSeparatorView"
                }
            ]
        }
    ]
}
EOF
done

echo "DONE"