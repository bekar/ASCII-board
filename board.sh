#!/bin/bash

lcorn=("╔" "╟" "╚" "║")
rcorn=("╗" "╢" "╝" "║")
cross=("╤" "┼" "╧" "│")
lines=("═" "─" "═" " ")

function print_x { # $1: char, $2:repeate
    for ((l=0; l<$2; l++)); do
        echo -en "$1";
    done
}

function line_printer { # $1: total_columns, $2: field
    printf "%${offset_x}s" " "
    printf "${lcorn[$2]}";
    for ((j=1; j < $1; j++)); do
        print_x "${lines[$2]}" $b_width
        printf "${cross[$2]}";
    done
    print_x "${lines[$2]}" $b_width
    echo "${rcorn[$2]}"
}

function current_cursor_position {
    printf "\E[6n"
    read -sdR CURPOS
    local IFS=";"
    CURPOS=($(echo "${CURPOS#*[}"))
    echo current_y = $CURPOS >&3
}

function box_board_print { # $1: size
    line_printer $1 0
    for ((r=1; r <= $1; r++ )); do
        let field=(r == $1)?2:1
        for ((i=1; i <= $b_height; i++)); do
            line_printer $1 3
        done
        line_printer $1 $field
    done
    echo "board_print" >&3
    current_cursor_position
    # tput cup $((CURPOS[0]-2)) 0
    let board_max_y=$((CURPOS[0]-2))
}

function box_board_refresh_hook {
    # this function needs to be overrid
    box_board_init $s
    echo -n "block_size(hxw):${b_height}x$b_width "
    echo -n "block_mid(x,y):($b_mid_x,$b_mid_y) "
    echo -n "offset(x,y):($offset_x,$offset_y) "
    echo "size:${COLUMNS}x$LINES"
    box_board_print $s
}

function block_update { # $1: x_position, $2: y_position, $3: val
    if [[ $FONT_SH != "1" ]] || (( $b_height < 4 )); then
        block_update_1px $1 $2 $3;
        return
    fi

    font_map $3 && {
        block_update_1px $1 $2 $3;
        return
    }

    # 4px font
    printf "${_colors[$3]}"
    for ((i=0; i < $b_height; i++)); do
        tput cup $(($2+i+1)) $1 || { # Resize fixes
            echo ERROR: reloading board >&3
            printf "${_colors[0]}"
            clear
            box_board_refresh_hook
        }
        printf "${word[i]}"
    done
    printf "${_colors[0]}"
}

function block_update_ij { # $1: row, $2: column, $3: val
    local r c x y
    r=$1 c=$2

    let _r="size - r"
    let x="1 + offset_x + b_width * c + c"
    let y="board_max_y - (_r * b_height + _r)"
    printf "b[$r][$c]=%-6d" $3 >&3
    printf "x:%-2d y:%-3d" $x $y >&3
    echo >&3
    block_update $x $y $3
}

function block_update_1px { # $1: x_position, $2: y_position, $3: val
    local val=$3
    if [[ "$val" == 0 ]]; then
        val=" "
    fi

    printf "${_colors[$val]}"
    for ((i=1; i <= b_height; i++)); do
        tput cup $(($2+i)) $1
        if (( i == b_mid_y )); then
            printf "%${b_mid_x}s" $val
            print_x " " $b_mid_xr
        else
            print_x " " $b_width
        fi
    done
    printf "${_colors[0]}"
}

function box_board_update {
    local new_lines=$(tput lines)
    if (( $new_lines != $LINES )); then # TEMP FIX: for reading input
        current_cursor_position
        let board_max_y=$((CURPOS[0]-1))
        LINES=$new_lines
    fi

    echo moves: $moves >&3
    local index=0
    for ((r=0; r < $size; r++)); do
        for ((c=0; c < $size; c++)); do
            if [[ ${old_board[index]} != ${board[index]} ]]; then
                block_update_ij $r $c ${board[index]}
                old_board[$index]=${board[index]}
            fi
            let index++
        done
    done
    tput cup $board_max_y 0
}

function box_board_tput_status {
    tput cup $((board_max_y - size * b_height - 3 )) 0;
}

function box_board_init { # $1: size
    size=$1
    echo size = $size >&3
    LINES=$(tput lines) COLUMNS=$(tput cols)
    echo term = $LINES x $COLUMNS >&3

    let offset_y=2 # header and status

    let b_height="(LINES - offset_y) / size"
    let diff_height="LINE - b_height"
    if ((diff_height < 0)); then
        echo old b_height $b_height >&3
        let b_height="(LINES - offset_y + diff_height) / size" # diff is -ve
        echo new b_height $b_height >&3
    fi

    let b_width="b_height * 2 + 3"

    let b_mid_x="b_width / 2 + 1"
    let b_mid_y="b_height / 2 + 1"
    let b_mid_xr="b_width - b_mid_x"

    let offset_x=COLUMNS/2-b_width*size/2-3

    tput civis # hide cursor
    stty -echo # disable output
}

function box_board_terminate {
    tput cnorm # show cursor
    stty echo # enable output
    echo
}

if [ `basename $0` == "board.sh" ]; then
    WD="$(dirname $(readlink $0 || echo $0))"
    source $WD/font.sh
    exec 3> /tmp/gtmp

    s=4
    if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
        s=$1
    fi

    trap "box_board_terminate; exit" INT

    box_board_refresh_hook

    let N=s*s-1

    for ((i=N; i>= 0; i--)); do
        board[$i]=$(echo 2^$i | bc)
    done

    box_board_update
    echo end_point_y: $board_max_y >&3
    box_board_terminate
else
    source $WD_BOARD/font.sh
fi
