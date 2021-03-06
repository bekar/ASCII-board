#!/bin/bash

# for colorizing numbers

FONT_SH=1

font_c0="\e[m"
font_c1="\e[31m"
font_c2="\e[38;5;22m"
font_c3="\e[32m"
font_c4="\e[38;5;226m"
font_c5="\e[34m"
font_c6="\e[35m"


function font_map { # $1: val
    case $1 in
        0) zero;;
        1) one;;
        2) two;;
        3) three;;
        4) four;;
        6) six;;
        8) eight;;
        10) ten;;
        11) eleven;;
        12) twelve;;
        16) sixteen;;
        32) thirtytwo;;
        64) sixtyfour;;
        128) onetwoeight;;
        256) twofivesix;;
        512) fiveonetwo;;
        1024) onezerotwofour;;
        2048) twozerofoureight;;
        *) return 0;;
    esac
    return 1
}

function printer { # $1: value
    for ((i=0; i<4; i++)); do
        echo "${word[$i]}"
    done
}

function zero {
    word[0]="   ▗▄▄▄▖   "
    word[1]="   █   █   "
    word[2]="   █   █   "
    word[3]="    ▀▀▀    "
}

function one {
    word[0]="    ▗▄     "
    word[1]="     █     "
    word[2]="     █     "
    word[3]="     ▀     "
}

function two {
    word[0]="    ▃▄▄▃   "
    word[1]="   ▝▘  ▄▀  "
    word[2]="    ▄▀▀    "
    word[3]="   ▀▀▀▀▀▀  "
}

function three {
    word[0]="   ▗▄▄▄▖   "
    word[1]="     ▄▀    "
    word[2]="   ▗▖ ▜▖   "
    word[3]="    ▝▀▀    "
}

function four {
    word[0]="      ▄▆   "
    word[1]="    ▄▀ █   "
    word[2]="   ▀▀▀▀█▀  "
    word[3]="       ▀   "
}

function six {
    word[0]="   ▗▄▄▄▖   "
    word[1]="   █▄▄▄    "
    word[2]="   █   █   "
    word[3]="    ▀▀▀    "
}

function eight {
    word[0]="    ▄▄▄▄   "
    word[1]="   █ ▂▃▄▀  "
    word[2]="   ▄▀▔  █  "
    word[3]="    ▀▀▀▀   "
}

function ten {
    word[0]="  ▗▄ ▗▄▄▖  "
    word[1]="   █ █  █  "
    word[2]="   █ █  █  "
    word[3]="   ▀  ▀▀   "
}

function eleven {
    word[0]="  ▗▄  ▗▄   "
    word[1]="   █   █   "
    word[2]="   █   █   "
    word[3]="   ▀   ▀   "
}

function twelve {
    word[0]=" ▗▄  ▂▄▄   "
    word[1]="  █  ▔ ▄█  "
    word[2]="  █  ▃█▀   "
    word[3]="  ▀  ▀▀▀▀  "
}

function sixteen {
    word[0]="  ▗▄ ▗▄▄▖  "
    word[1]="   █ █▄▄   "
    word[2]="   █ █  █  "
    word[3]="   ▀  ▀▀   "
}

function thirtytwo {
    word[0]=" ▗▄▄▄▖▂▄▄  "
    word[1]="   ▄▀ ▔ ▄█ "
    word[2]=" ▗▖ ▜▖▃█▀  "
    word[3]="  ▝▀▀ ▀▀▀▀ "
}

function sixtyfour {
    word[0]=" ▗▄▄▖   ▄▄ "
    word[1]=" █▄▄  ▄▀ █ "
    word[2]=" █  █▝▀▀▀█▘"
    word[3]="  ▀▀     ▀ "
}

function onetwoeight {
    word[0]="           "
    word[1]="▝▌▀▀▀▖▗▀▀▀▖"
    word[2]=" ▌▄▀▀ ▗▀▀▀▖"
    word[3]=" ▘▀▀▀▘▝▀▀▀ "
}

function twofivesix {
    word[0]="           "
    word[1]=" ▀▀▖▐▀▀▗▀▀ "
    word[2]=" ▄▀  ▀▚▐▀▀▖"
    word[3]=" ▀▀▘▝▀▘ ▀▀ "
}

function fiveonetwo {
    word[0]="           "
    word[1]="▐▀▀▀▝█ ▀▀▀▖"
    word[2]=" ▀▀▄ █ ▄▀▀ "
    word[3]="▝▀▀  ▀ ▀▀▀▘"
}

function onezerotwofour {
    word[0]="           "
    word[1]="${font_c2}▝▌${font_c1}▛▜${font_c5}▝▀▚${font_c6} ▞▌ "
    word[2]="${font_c2} ▌${font_c1}▙▟${font_c5}▗▟▙${font_c6}▝▀▛ "
    word[3]="           "
}

function twozerofoureight {
    word[0]="        ${font_c3}▁▁ "
    word[1]="${font_c1}▝▀▚${font_c4}▛▜${font_c5} ▞▌${font_c3}▙▟ "
    word[2]="${font_c1}▗▟▙${font_c4}▙▟${font_c5}▝▀▛${font_c3}▙▟ "
    word[3]="           "
}

if [ `basename $0` == "font.sh" ]; then
    two; printer
    #four; printer
    eight; printer
    #sixteen; printer
    thirtytwo; printer
    sixtyfour; printer
    onetwoeight; printer
    twofivesix; printer
    fiveonetwo; printer
    twozerofoureight; printer
fi
