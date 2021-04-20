#!/usr/bin/env bash

# var/logs/dev.log

display_usage() {
    echo -e "tailogs
    -f \t\t\t Follow
    --file=<file.log> \t Filename"
}

config() {
    
}

options() {
    for i in "$@"; do
        case $i in
            -f)
                FOLLOW=1
            ;;
            --file=*)
                FILEPATH="${i#*=}"
            ;;
            --help)
                display_usage
                exit 0
            ;;
            *)
                echo $i
            ;;
        esac
    done
}

main() {
    options "$@"
    tail $FILEPATH
}

main "$@"
