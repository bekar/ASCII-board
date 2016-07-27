#!/bin/bash

declare board_LCORN=("╔" "╟" "╚" "║")
declare board_RCORN=("╗" "╢" "╝" "║")
declare board_CROSS=("╤" "┼" "╧" "│")
declare board_LINES=("═" "─" "═" " ")

declare board_vt100_tile="\e[1;33;48m"
declare board_vt100_select="\e[34m"
declare board_vt100_normal="\e[m"

trap "board_terminate" EXIT

function _print_x { # $1: char, $2:repeate
    for ((l=0; l<$2; l++)); do
        echo -en "$1";
    done
}


function _line_printer { # $1: total_columns, $2: field
    printf "%${offset_x}s" " "
    printf "${board_LCORN[$2]}";
    for ((j=1; j < $1; j++)); do
        _print_x "${board_LINES[$2]}" $_tile_width
        printf "${board_CROSS[$2]}";
    done
    _print_x "${board_LINES[$2]}" $_tile_width
    echo "${board_RCORN[$2]}"
}


function board_get_current_cursor {
    printf "\E[6n"
    read -sdR CURPOS
    local IFS=";"
    CURPOS=($(echo "${CURPOS#*[}"))
    echo board_current_cursor = ${CURPOS[@]} >&3
}


function board_select_tile_ij { # $1: row, $2: col, $3: select
    # only for board size 2
    local r=$1 c=$2
    (( $r >= $board_size )) && return
    (( $c >= $board_size )) && return

    let _r="board_size - r"
    let x="offset_x + _tile_width * c + c"
    let y="board_max_y - (_r * _tile_height + _r)"

    if test -z "$3"; then
        printf "${board_vt100_select}"
        local vl=┃ vr=┃ ht=━ hb=━ tl=┏ tr=┓ bl=┗ br=┛
    else
        local end=$((board_size-1))
        >&3 echo "$r×$c"
        case "$r×$c" in
            0×0)             local vl=║ vr=│ ht=═ hb=─ tl=╔ tr=╤ bl=╟ br=┼;;
            0×${end})        local vl=│ vr=║ ht=═ hb=─ tl=╤ tr=╗ bl=┼ br=╢;;
            ${end}×0)        local vl=║ vr=│ ht=─ hb=═ tl=╟ tr=┼ bl=╚ br=╧;;
            ${end}×${end})   local vl=│ vr=║ ht=─ hb=═ tl=┼ tr=╢ bl=╧ br=╝;;

            0×[1-$end])      local vl=│ vr=│ ht=═ hb=─ tl=╤ tr=╤ bl=┼ br=┼;;
            [1-$end]×${end}) local vl=│ vr=║ ht=─ hb=─ tl=┼ tr=╢ bl=┼ br=╢;;
            ${end}×[1-$end]) local vl=│ vr=│ ht=─ hb=═ tl=┼ tr=┼ bl=╧ br=╧;;
            [1-$end]×0)      local vl=║ vr=│ ht=─ hb=─ tl=╟ tr=┼ bl=╟ br=┼;;

            *)               local vl=│ vr=│ ht=─ hb=─ tl=┼ tr=┼ bl=┼ br=┼;;
        esac
        [[ 0 == $end ]] && local vr=║ bl=╚
        [[ 0 == $end ]] && local hb=═ br=╝ tr=╗
    fi

    tput cup $y $x
    printf $tl;
    _print_x $ht $_tile_width
    printf $tr
    for ((i=1; i <= $_tile_height; i++)); do
        tput cup $((y+i)) $x; printf $vl
        tput cup $((y+i)) $((x+_tile_width+1)); printf $vr
    done
    tput cup $((y+i)) $x
    printf $bl
    _print_x $hb $_tile_width
    printf $br
    printf "${board_vt100_normal}"
}


function board_print { # $1: board_size
    _line_printer $1 0
    for ((r=1; r <= $1; r++ )); do
        let field=(r == $1)?2:1
        for ((i=1; i <= $_tile_height; i++)); do
            _line_printer $1 3
        done
        _line_printer $1 $field
    done
    echo "board_print_border" >&3
    board_get_current_cursor
    # tput cup $((CURPOS[0]-2)) 0
    let board_max_y=$((CURPOS[0]-2))
}


function _tile_px_update { # $1: x_position, $2: y_position, $3: val
    local x=$1 y=$2 val=$3
    if [[ $FONT_SH != "1" ]] || (( $_tile_height < 4 )); then
        board_tile_update_1px $1 $2 $3;
        return
    fi

    font_map $3 && {
        board_tile_update_1px $1 $2 $3;
        return
    }

    # 4px font
    printf "${board_vt100_tile}"
    for ((i=0; i < $_tile_height; i++)); do
        tput cup $(($2+i+1)) $1
        _print_x " " $_tile_width
        tput cup $(($2+i+1)) $1
        printf "${word[i]}"
    done
    printf "${board_vt100_normal}"
}


function board_tile_update_1px { # $1: x_position, $2: y_position, $3: val
    local x=$1 y=$2 val=$3
    printf "${board_vt100_tile}"
    for ((i=1; i <= _tile_height; i++)); do
        tput cup $(($y+i)) $x
        if (( i == b_mid_y )); then
            printf "%${b_mid_x}s" $val
            _print_x " " $b_mid_xr
        else
            _print_x " " $_tile_width
        fi
    done
    printf "${board_vt100_normal}"
}


function board_tile_update_ij { # $1: row, $2: column, $3: val
    local r c x y
    r=$1 c=$2

    let _r="board_size - r"
    let x="1 + offset_x + _tile_width * c + c"
    let y="board_max_y - (_r * _tile_height + _r)"
    printf "b[$r][$c]=%-6d" $3 >&3
    printf "x:%-2d y:%-3d" $x $y >&3
    echo >&3
    _tile_px_update $x $y $3
}


function board_update {
    local new_lines=$(tput lines)
    if (( $new_lines != $LINES )); then # TEMP FIX: for reading input
        board_get_current_cursor
        let board_max_y=$((CURPOS[0]-1))
        LINES=$new_lines
    fi

    local index=0
    for ((r=0; r < $board_size; r++)); do
        for ((c=0; c < $board_size; c++)); do
            local val=${board[index]}
            board_vt100_tile=${colors[val]}
            if [[ ${board_old[index]} != ${board[index]} ]]; then
                board_tile_update_ij $r $c ${board[index]}
                board_old[$index]=${board[index]}
            fi
            let index++ && : # ':' is do nothing
        done
    done

    tput cup $board_max_y 0
}


function board_tput_status {
    tput cup $((board_max_y - board_size * _tile_height - board_size - 1)) 0
}


function board_init { # $1: board_size
    board_size=$1
    echo board_size = $board_size >&3
    LINES=$(tput lines) COLUMNS=$(tput cols)
    echo term = $LINES × $COLUMNS >&3

    offset_y=2 # header and status

    local height=$((LINES - offset_y - board_size + 1))
    >&3 echo max height: $height
    let _tile_height="(height / board_size)" && :
    >&3 echo tile height: $_tile_height
    let diff_height="height - (board_size * _tile_height)" && :
    >&3 echo diff_height: $diff_height

    let _tile_width="_tile_height * 2 + 3"

    let b_mid_x="_tile_width / 2 + 1"
    let b_mid_y="_tile_height / 2 + 1"
    let b_mid_xr="_tile_width - b_mid_x"

    let offset_x=COLUMNS/2-_tile_width*board_size/2-3

    tput civis # hide cursor
    stty -echo # disable output
}


function board_terminate {
    tput cnorm # show cursor
    stty echo # enable output
    tput cup $board_max_y $COLUMNS
    echo
}


if [ `basename $0` == "board.sh" ]; then
    WD="$(dirname $(readlink $0 || echo $0))"
    source $WD/font.sh
    exec 3> /tmp/board
    exec 2>&3 # redirecting errors
    set -e

    s=5
    if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
        s=$1
    fi

    trap "board_terminate; exit" INT
    board_init $s
    echo -n "tile_size(h×w):${_tile_height}×$_tile_width "
    echo -n "tile_mid(x,y):($b_mid_x,$b_mid_y) "
    echo -n "offset(x,y):($offset_x,$offset_y) "
    echo "size:${COLUMNS}x${LINES}"
    board_print $s


    board_select_tile_ij 2 2

    >&3 echo -e "\ncorners"
    board_select_tile_ij 0 0 1
    board_select_tile_ij 0 4 1
    board_select_tile_ij 4 0 1
    board_select_tile_ij 4 4 1

    >&3 echo -e "\nother pts"
    board_select_tile_ij 0 2 1
    board_select_tile_ij 2 4 1
    board_select_tile_ij 4 2 1
    board_select_tile_ij 2 0 1

    let N="s*s"
    for ((i=0; i < N; i++)); do
        declare board[$i]=$i
    done

    board_update
    echo end_point_y: $board_max_y >&3
else
    source $WD_BOARD/font.sh
fi
