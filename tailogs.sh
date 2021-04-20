#!/usr/bin/env bash

# var/logs/dev.log

display_usage() {
    echo -e "Usage: tailogs [OPTIONS]\n
 -f \t\t\t Follow
    --file=<file.log> \t Filename"
}

#PATTERN="[date time] name.type: message"
#NEW_PATTERN="\2"

#APACHE=("(snc_redis).(DEBUG)" "\2.\1")
PATTERN="[date time] name.type: message"
M_PATTERN=$(sed -E 's/([^a-z ])/\\\1/g' <<< "$PATTERN")
M_PATTERN=$(sed -E 's/(\w+)/(.*)/g' <<< "$M_PATTERN")
ARRAY=($(sed -E 's/[^a-z]+/ /g' <<< "$PATTERN"))

getindex() {
    for i in "${!ARRAY[@]}"; do
        if [[ $1 == "${ARRAY[$i]}" ]]; then RES=$i; fi
        RES=''
    done
}

#getindex 'dates' RES

getnames() {
    for i in "${!ARRAY[@]}"; do

    done
}



#APACHE=("\[(.*) (.*)\] (.*)\.(.*): (.*)" "\1.\5")
APACHE=("$M_PATTERN" "\1.\5")

getoptions() {
    # --(l)imit-terminal-size
    for i in "$@"; do
        case $i in
            -f)
                FOLLOW=1
            ;;
            --grep=*)
                GREP_PATTERN="${i#*=}"
            ;;
            --file=*)
                FILEPATH="${i#*=}"
            ;;
            --help)
                display_usage
                exit 0
            ;;
            *)
                exit 0
            ;;
        esac
    done
}

main() {
    getoptions "$@"
    TYPE=("${APACHE[@]}")
    export SIZE_TERM=$(stty size | cut -d ' ' -f 2)
    SIZE_TERM=$(($SIZE_TERM-1))

    # RUN
    tail $FILEPATH | cut -c -$SIZE_TERM | grep --color "$GREP_PATTERN" | \
        sed -E "s/${TYPE[0]}/${TYPE[1]}/"
    # ccze -A
}

main "$@"
