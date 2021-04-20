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
APACHE=("(\])" ".")

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
