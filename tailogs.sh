#!/usr/bin/env bash

###################
# Define commands #
###################

_tailogs_display_usage() {
    echo -e "Usage: $0 [arguments] \n
Arguments: \n
 -g, --logfile=<file.log> \t Log filename
 -l, --limit \t\t\t Limit to terminal screensize 
in progress..."
    exit 0
}

_tailogs_getoptions() {
    # --(l)imit-terminal-size
    for i in "$@"; do
        case $i in
            --grep=*)
                GREP_PATTERN="${i#*=}"
            ;;
            --logfile=*)
                FILEPATH="${i#*=}"
            ;;
            --help)
                _tailogs_display_usage
                exit 0
            ;;
            *)
                _tailogs_display_usage
                exit 0
            ;;
        esac
    done
}

### INPUT ###

_dev_config() {
    FILEPATH=/var/log/apt/history.log
    PATTERN="txton-txtwo: date  time"
    NEW_PATTERN="txton-txtwo: time date?"
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

# use NEW_PATTERN, PATTERN_ITEMS
# return INDEXED_NEWPATTERN
_tailogs_replace_newpattern_by_indexes() {
    INDEXED_NEWPATTERN=$NEW_PATTERN
    for i in "${!PATTERN_ITEMS[@]}"; do
        local item="${PATTERN_ITEMS[$i]}"
        _tailogs_getindex_from_item $item INDEX
        INDEXED_NEWPATTERN=$(sed "s/$item/\\\\$INDEX/g" <<< $INDEXED_NEWPATTERN)
    done
}

_tailogs_process_pattern() {
    _tailogs_pattern_to_stars #STAR_PATTERN=(.*)\-(.*)\: (.*) (.*)
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

# use FILEPATH, SIZE_TERM, GREP_PATTERN, TYPE
_tailogs_run_tail() {
    tail $FILEPATH | \
    cut -c -$SIZE_TERM | \
    grep --color "$GREP_PATTERN" | \
    sed -E "s/${TYPE[0]}/${TYPE[1]}/"
    # ccze -A
}

########
# MAIN #
########
main() {
    RES=
    _dev_config
    #PATTERN="txton-txtwo: date  time"
    #NEW_PATTERN="txton-txtwo: time date?"

    _tailogs_process_pattern #STAR_PATTERN, INDEXED_NEWPATTERN
    APACHE=("$STAR_PATTERN" "$INDEXED_NEWPATTERN")

    _tailogs_getoptions "$@"
    _tailogs_set_size_term #SIZE_TERM

    # RUN #
    TYPE=("${APACHE[@]}")
    _tailogs_run_tail
}
main "$@"


#@todo
# _tailogs_longparams() {
#     for param in "$@"; do
#         shift
#         case "$param" in
#             "--file") set -- "$@" "-f" ;;
#             "--help") set -- "$@" "-h" ;;
#             *) set -- "$@" "$param" ;;
#         esac
#     done
# }

#@todo
# _tailogs_shortparams() {
#     OPTIND=1
#     while getopts "fh" opt; do
#         case "$opt" in
#             "h")
#                 _tailogs_display_usage
#                 exit 0
#                 ;;
#             "f") file=1 ;;
#             "?")
#                 _tailogs_display_usage >&2
#                 exit 1
#                 ;;
#         esac
#     done

#     shift $((OPTIND - 1))
# }
