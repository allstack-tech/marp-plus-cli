#!/bin/sh

# Extract theme from markdown file's YAML front matter
get_theme_from_file() {
    local file="$1"
    awk '
    FNR==1 && /^---/ { in_frontmatter=1; next }
    in_frontmatter && /^---/ { in_frontmatter=0; exit }
    in_frontmatter && /^theme:/ {
        # Extract the theme value after "theme:"
        sub(/^theme:[ \t]*/, "")
        sub(/[ \t]*$/, "")
        # Remove surrounding quotes if present
        gsub(/^["'"'"']/, "")
        gsub(/["'"'"']$/, "")
        print
        exit
    }
    ' "$file"
}

# Normalize theme for comparison (handles paths, URLs, and built-in themes)
normalize_theme() {
    local theme="$1"
    # If it's a path, normalize by removing leading ./
    if [ -n "$(echo "$theme" | grep -E '(^\.?\/|\.css$)')" ]; then
        # Path-based theme - normalize
        theme=$(echo "$theme" | sed 's|^\./||')
        echo "$theme"
    else
        # Built-in theme or URL - keep as is
        echo "$theme"
    fi
}

# Check if two themes match (after normalization)
themes_match() {
    local file_theme="$1"
    local filter_theme="$2"
    
    local normalized_file=$(normalize_theme "$file_theme")
    local normalized_filter=$(normalize_theme "$filter_theme")
    
    if [ "$normalized_file" = "$normalized_filter" ]; then
        return 0
    fi
    # Allow alias matching for themes like atech-marp <-> tech-marp
    if [ "$normalized_file" = "a$normalized_filter" ] || [ "$normalized_filter" = "a$normalized_file" ]; then
        return 0
    fi
    return 1
}

is_remote_url() {
    case "$1" in
        http://*|https://*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

download_remote_theme() {
    local url="$1"
    local cache_dir="/tmp/marp-theme-cache"
    mkdir -p "$cache_dir"
    local hash
    hash=$(printf '%s' "$url" | node -e 'const crypto = require("crypto"); const s = process.argv[1]; process.stdout.write(crypto.createHash("sha256").update(s).digest("hex"));' "$url")
    local out="$cache_dir/$hash.css"
    if [ ! -f "$out" ]; then
        node -e 'const fs = require("fs"); const url = process.argv[1]; const out = process.argv[2]; globalThis.fetch(url).then(res => { if (!res.ok) throw new Error(`HTTP ${res.status}`); return res.arrayBuffer(); }).then(buf => fs.writeFileSync(out, Buffer.from(buf))).catch(err => { console.error(err.message); process.exit(1); });' "$url" "$out"
    fi
    echo "$out"
}

# Get the first argument (should be file or directory)
TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Error: No file or directory specified"
    exit 1
fi

# Quote a single argument for safe eval reconstruction
quote_arg() {
    local s="$1"
    printf "'%s'" "$(printf '%s' "$s" | sed "s/'/'\\\"'\\\"'/g")"
}

# Parse remaining arguments for --theme-filter, --theme, --theme-set, and --output
THEME_FILTER=""
OUTPUT_PATH=""
REMAINING_ARGS=""
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --theme-filter)
            shift
            THEME_FILTER="$1"
            ;;
        --theme)
            shift
            if is_remote_url "$1"; then
                THEME_PATH=$(download_remote_theme "$1")
                REMAINING_ARGS="$REMAINING_ARGS --theme $THEME_PATH"
            else
                REMAINING_ARGS="$REMAINING_ARGS --theme $1"
            fi
            ;;
        --theme-set)
            shift
            if is_remote_url "$1"; then
                THEME_PATH=$(download_remote_theme "$1")
                REMAINING_ARGS="$REMAINING_ARGS --theme-set $THEME_PATH"
            else
                REMAINING_ARGS="$REMAINING_ARGS --theme-set $1"
            fi
            ;;
        -o|--output)
            shift
            OUTPUT_PATH="$1"
            ;;
        *)
            REMAINING_ARGS="$REMAINING_ARGS $1"
            ;;
    esac
    shift
done

# Create positional args for the remaining Marp options
if [ -n "$REMAINING_ARGS" ]; then
    set -- $REMAINING_ARGS
else
    set --
fi

# Determine whether the output path is a directory
OUTPUT_DIR=""
if [ -n "$OUTPUT_PATH" ]; then
    case "$OUTPUT_PATH" in
        */)
            OUTPUT_DIR="${OUTPUT_PATH%/}"
            ;;
        *)
            if [ -d "$OUTPUT_PATH" ]; then
                OUTPUT_DIR="$OUTPUT_PATH"
            fi
            ;;
    esac
fi

if [ -n "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Check if target is a directory
if [ -d "$TARGET" ]; then
    # It's a directory
    if [ -n "$THEME_FILTER" ]; then
        # Theme filter provided - find and process only matching files
        MATCHING_FILES=""
        
        # Find all markdown files recursively
        while IFS= read -r md_file; do
            file_theme=$(get_theme_from_file "$md_file")
            
            # Skip files without a theme directive
            if [ -z "$file_theme" ]; then
                continue
            fi
            
            # Check if theme matches
            if themes_match "$file_theme" "$THEME_FILTER"; then
                MATCHING_FILES="$MATCHING_FILES $md_file"
            fi
        done <<EOF
$(find "$TARGET" -name "*.md" -type f)
EOF
        
        if [ -z "$MATCHING_FILES" ]; then
            echo "No markdown files found matching theme filter: $THEME_FILTER"
            exit 0
        fi
        
        # Process only matching files, one by one so output directory can be specified.
        for md_file in $MATCHING_FILES; do
            if [ -n "$OUTPUT_DIR" ]; then
                file_name=$(basename "$md_file" .md)
                marp --engine "$ENGINE_FILE" "$md_file" $REMAINING_ARGS -o "$OUTPUT_DIR/$file_name.html" || exit $?
            else
                marp --engine "$ENGINE_FILE" "$md_file" $REMAINING_ARGS || exit $?
            fi
        done
        exit 0
    else
        # No theme filter - process all markdown files in directory
        exec marp --engine "$ENGINE_FILE" "$TARGET" $REMAINING_ARGS
    fi
elif [ -f "$TARGET" ]; then
    # It's a file - process normally (ignore theme filter for single files)
    exec marp --engine "$ENGINE_FILE" "$TARGET" $REMAINING_ARGS
else
    echo "Error: '$TARGET' is neither a file nor a directory"
    exit 1
fi