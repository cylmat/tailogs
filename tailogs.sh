#!/usr/bin/env bash

# var/logs/dev.log

main() {

RES=''

display_usage() {
    echo -e "Usage: tailogs [OPTIONS]\n
 -f \t\t\t Follow
    --file=<file.log> \t Filename"
}

#PATTERN="[date time] name.type: message"
#NEW_PATTERN="type:name date"

#APACHE=("(snc_redis).(DEBUG)" "\2.\1")
#PATTERN="[date time] name.type: message"
PATTERN="ni-no: datetruc  timetruc"
NEW_PATTERN="ni-no: timetruc datetruc?"
#\4:\3 \1


M_PATTERN=$(sed -E 's/([^a-z ])/\\\1/g' <<< "$PATTERN")
M_PATTERN=$(sed -E 's/(\w+)/(.*)/g' <<< "$M_PATTERN")
# date time name type message
ARRAY=($(sed -E 's/[^a-z]+/ /g' <<< "$PATTERN"))


getindex() {
    for i in "${!ARRAY[@]}"; do
        if [[ $1 == "${ARRAY[$i]}" ]]; then RES=$(($i+1)); return; fi
    done
}

#getindex 'name' RES

NEW_PAT=$NEW_PATTERN


replace_pattern_by_index() {
    for i in "${!ARRAY[@]}"; do
        local name="${ARRAY[$i]}"
        getindex $name RES
        index=$RES
        NEW_PAT=$(sed "s/$name/\\\\$index/g" <<< $NEW_PAT)
    done
}

replace_pattern_by_index
#echo $NEW_PAT


#APACHE=("\[(.*) (.*)\] (.*)\.(.*): (.*)" "\1.\5")
APACHE=("$M_PATTERN" "$NEW_PAT")
#echo $M_PATTERN;

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

getoptions "$@"
TYPE=("${APACHE[@]}")

export SIZE_TERM=$(stty size | cut -d ' ' -f 2)
SIZE_TERM=$(($SIZE_TERM-1))

FILEPATH=/var/log/apt/history.log

# RUN
tail $FILEPATH | cut -c -$SIZE_TERM | grep --color "$GREP_PATTERN" | \
    sed -E "s/${TYPE[0]}/${TYPE[1]}/"
# ccze -A

}

main "$@"
