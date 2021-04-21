#!/usr/bin/env bash

###################
# Define commands #
###################

_tailogs_display_usage() {
    echo -e "\nUsage: $0 [arguments]
Arguments:
 -g, --logfile=<file.log> \t Log filename
 -l, --limit \t\t\t Limit to terminal screensize 
in progress...\n"
    exit 0
}

_tailogs_getoptions() {
    # @todo --(l)imit-terminal-size
    ARGS=()
    for param in "$@"; do
        case $param in
            --grep=*)
                GREP_PATTERN="${param#*=}"
            ;;
            --logfile=*)
                FILEPATH="${param#*=}"
            ;;
            --help)
                _tailogs_display_usage
                exit 0
            ;;
            *)
                # don't use set -- "$@" "$param" ;;
                # cause we keep every others params
                ARGS+=($param)
            ;;
        esac
    done
}

### INPUT ###

_dev_config() {
    FILEPATH=/var/log/apt/history.log
    ACTUAL_PATTERN="txton-txtwo: date  time"
    NEW_PATTERN="33txton0-32txtwo0: 33time0 31date0?"
    APACHE=("$ACTUAL_PATTERN" "$NEW_PATTERN")
    TYPE='APACHE'
}

_tailogs_get_patterns_from_config() {
    CONFIG_PATTERNS=("${APACHE[@]}")
    PATTERN="${CONFIG_PATTERNS[0]}"
    NEW_PATTERN="${CONFIG_PATTERNS[1]}"
}

### PROCESS ###

# use PATTERN
# return SLASHED_PATTERN
_tailogs_slash_nochars_pattern() {
    SLASHED_PATTERN=$(sed -E 's/([^a-z ])/\\\1/g' <<< "$PATTERN")
}

# return STAR_PATTERN
_tailogs_pattern_to_stars() {
    _tailogs_slash_nochars_pattern #SLASHED_PATTERN
    STAR_PATTERN=$(sed -E 's/(\w+)/(.*)/g' <<< "$SLASHED_PATTERN")
}

# use PATTERN
# return PATTERN_ITEMS
_tailogs_set_pattern_items() {
    PATTERN_ITEMS=($(sed -E 's/[^a-z]+/ /g' <<< "$PATTERN"))
}
 
# use PATTERN_ITEMS
# return INDEX
_tailogs_getindex_from_item() {
    for i in "${!PATTERN_ITEMS[@]}"; do
        if [[ $1 == "${PATTERN_ITEMS[$i]}" ]]; then INDEX=$(($i+1)); return; fi
    done
}

# use NEW_PATTERN
# return COLORED_NEWPATTERN
_tailogs_color_newpattern() {
    COLOR_PATTERN="\\e[\1m" #\033[0;32m | \e[32m
    RESET_PATTERN="\\e[0m"  #\033[0m \e[0m
    local _31="$(echo -e "\033[0;31m")"
    local _32="$(echo -e "\033[0;32m")"
    local _33="$(echo -e "\033[0;33m")"
    local _34="$(echo -e "\033[0;34m")"
    local _0="$(echo -e "\033[0m")"

    COLORED_NEWPATTERN=$(sed -E "s/0/$_0/g" <<< "$NEW_PATTERN")
    COLORED_NEWPATTERN=$(sed -E "s/(31)/$_31/g" <<< "$COLORED_NEWPATTERN")
    COLORED_NEWPATTERN=$(sed -E "s/(32)/$_32/g" <<< "$COLORED_NEWPATTERN")
    COLORED_NEWPATTERN=$(sed -E "s/(33)/$_33/g" <<< "$COLORED_NEWPATTERN")
    COLORED_NEWPATTERN=$(sed -E "s/(34)/$_34/g" <<< "$COLORED_NEWPATTERN")
}

# use COLORED_NEWPATTERN, PATTERN_ITEMS
# return INDEXED_NEWPATTERN
_tailogs_replace_newpattern_by_indexes() {
    INDEXED_NEWPATTERN=$COLORED_NEWPATTERN
    for i in "${!PATTERN_ITEMS[@]}"; do
        local item="${PATTERN_ITEMS[$i]}"
        _tailogs_getindex_from_item $item INDEX
        INDEXED_NEWPATTERN=$(sed "s/$item/\\\\$INDEX/g" <<< $INDEXED_NEWPATTERN)
    done
}

# use PATTERN, NEW_PATTERN
_tailogs_process_pattern() {
    _tailogs_pattern_to_stars #STAR_PATTERN=(.*)\-(.*)\: (.*) (.*)
    _tailogs_color_newpattern #COLORED_NEWPATTERN
    _tailogs_set_pattern_items #PATTERN_ITEMS=txton txtwo date time
    _tailogs_replace_newpattern_by_indexes #INDEXED_NEWPATTERN=\1-\2: \4 \3?
}

### OUTPUT ###

# return SIZE_TERM
_tailogs_set_size_term() {
    SIZE_TERM=$(stty size | cut -d ' ' -f 2)
    SIZE_TERM=$(($SIZE_TERM-1))
}

### RUN ###

# use FILEPATH, SIZE_TERM, GREP_PATTERN
# use STAR_PATTERN, INDEXED_NEWPATTERN
_tailogs_run_tail() {
    # echo "tail ${ARGS[@]} $FILEPATH | \
    # cut -c -$SIZE_TERM | \
    # grep --color $GREP_PATTERN | \
    # sed -E 's/$STAR_PATTERN/$INDEXED_NEWPATTERN/'"; exit
    
    
    tail "${ARGS[@]}" $FILEPATH | \
    cut -c -$SIZE_TERM | \
    grep --color "$GREP_PATTERN" | \
    sed --unbuffered -E "s/$STAR_PATTERN/$INDEXED_NEWPATTERN/"
    #sed --unbuffered -E -e "s/.*/$_33&dfgqg$_0/g"
    # grc tail, tail | ccze -A
}

########
# MAIN #
########
main() {
    RES=
    _dev_config
    #PATTERN="txton-txtwo: date  time"
    #NEW_PATTERN="txton-txtwo: time date?"

    # process
    _tailogs_get_patterns_from_config
    _tailogs_process_pattern #STAR_PATTERN, INDEXED_NEWPATTERN

    # options
    _tailogs_getoptions "$@"
    _tailogs_set_size_term #SIZE_TERM

    # RUN #
    _tailogs_run_tail 
}

main "$@"
