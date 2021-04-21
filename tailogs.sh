#!/usr/bin/env bash

###################
# Define commands #
###################

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

_tailogs_display_usage() {
    echo -e "Usage: $0 [arguments] \n
Arguments: \n
 -g, --logfile=<file.log> \t Log filename
 -l, --limit \t\t\t Limit to terminal screensize 
in progress..."
    exit 0
}

_tailogs_getindex() {
    for i in "${!ARRAY[@]}"; do
        if [[ $1 == "${ARRAY[$i]}" ]]; then RES=$(($i+1)); return; fi
    done
}

_tailogs_replace_pattern_by_index() {
    for i in "${!ARRAY[@]}"; do
        local name="${ARRAY[$i]}"
        _tailogs_getindex $name RES
        index=$RES
        NEW_PAT=$(sed "s/$name/\\\\$index/g" <<< $NEW_PAT)
    done
}

_tailogs_run_tail() {
    tail $FILEPATH | \
    cut -c -$SIZE_TERM | \
    grep --color "$GREP_PATTERN" | \
    sed -E "s/${TYPE[0]}/${TYPE[1]}/"
    # ccze -A
}

_dev_config() {
    PATTERN="txton-txtwo: date  time"
    NEW_PATTERN="txton-txtwo: time date?"
}

########
# MAIN #
########

main() {

RES=''

_dev_config

#PATTERN="[date time] name.type: message"
#NEW_PATTERN="type:name date"

#APACHE=("(snc_redis).(DEBUG)" "\2.\1")
#PATTERN="[date time] name.type: message"


M_PATTERN=$(sed -E 's/([^a-z ])/\\\1/g' <<< "$PATTERN")
M_PATTERN=$(sed -E 's/(\w+)/(.*)/g' <<< "$M_PATTERN")
# date time name type message
ARRAY=($(sed -E 's/[^a-z]+/ /g' <<< "$PATTERN"))

NEW_PAT=$NEW_PATTERN


_tailogs_replace_pattern_by_index
#echo $NEW_PAT


#APACHE=("\[(.*) (.*)\] (.*)\.(.*): (.*)" "\1.\5")
APACHE=("$M_PATTERN" "$NEW_PAT")
#echo $M_PATTERN;

_tailogs_getoptions "$@"
TYPE=("${APACHE[@]}")

export SIZE_TERM=$(stty size | cut -d ' ' -f 2)
SIZE_TERM=$(($SIZE_TERM-1))

FILEPATH=/var/log/apt/history.log

# RUN
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
