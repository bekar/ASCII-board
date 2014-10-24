#!/bin/bash

source "$WD_BOARD/font.sh"

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

function box_board_print { # $1: size
    #print_x "\n" $offset_y
    tput cup 2 0
    line_printer $1 0
    for ((r=1; r <= $1; r++ )); do
        let field=(r == $1)?2:1
        for ((i=1; i <= $b_height; i++)); do
            line_printer $1 3
        done
        line_printer $1 $field
    done
}

function block_update { # $1: x_position, $2: y_position, $3: val
    if [[ $FONT_SH != "1" ]]; then
        block_update2 $1 $2 $3;
        return
    fi

    font_map $3 && {
        block_update2 $1 $2 $3;
        return
    }

    printf "${_colors[$3]}"
    for ((i=0; i < $b_height; i++)); do
        tput cup $(($1+i+1)) $2
        printf "${word[i]}"
    done
    printf "${_colors[0]}"
}

function box_board_block_update { # $1: row, $2: column, $3: val
    local r=$1
    local c=$2

    local x=$((2+r*b_height+$r))
    local y=$((1+offset_x+b_width*c+c))

    block_update $x $y $3
}

function block_update2 { # $1: x_position, $2: y_position, $3: val
    val=$3
    if [[ "$val" == 0 ]]; then
        val=" "
    fi

    for ((i=1; i <= $b_height; i++)); do
        tput cup $(($1+i)) $2
        printf "${_colors[$val]}"
        if (( i == mid_y )); then
            printf "%${mid_x}s" $val
            print_x " " $mid_xr
        else
            print_x "${lines[3]}" b_width
        fi
        printf "${_colors[0]}"
    done
}

function box_board_update {
    local index=0
    for ((r=0; r < $size; r++)); do
        for ((c=0; c < $size; c++)); do
            if [[ ${old_board[index]} != ${board[index]} ]]; then
                box_board_block_update $r $c ${board[index]}
            fi
            old_board[$index]=${board[index]}
            let index++
        done
    done
}

function box_board_init { # $1: size
    size=$1
    LINES=$(tput lines)
    COLUMNS=$(tput cols)
    b_height=$((LINES/size))

    if ((b_height*size > LINE-5)); then
        b_height=$(((LINES-4-size)/size))
    fi

    let b_width=b_height*2+3
    let mid_x=b_width/2+1
    let mid_y=b_height/2+1
    let mid_xr=b_width-mid_x

    let screen_mid=LINES/2
    let offset_x=COLUMNS/2-b_width*size/2-3
    let offset_y=screen_mid-b_height*size/2
    let offset_figlet_y=screen_mid-3

    screen_x=$((2+(b_height+1)*size))

    tput civis # hide cursor
    stty -echo # disable output
}

function box_board_terminate {
    tput cnorm # show cursor
    stty echo # enable output
    tput cup $screen_x $COLUMNS
}

if [ `basename $0` == "board.sh" ]; then
    source font.sh
    s=4
    if [[ $# -eq 1 ]] && (( "$1" > -1 )); then
        s=$1
    fi

    trap "box_board_terminate; exit" INT

    box_board_init $s

    clear
    box_board_print $s
    tput cup 0 0
    echo -n "block_size(hxw):${b_height}x$b_width "
    echo -n "mid(x,y):($mid_x,$mid_y) "
    echo -n "offset(x,y):($offset_x,$offset_y) "
    echo -n "size:${COLUMNS}x$LINES"

    let N=s*s-1

    for ((i=N; i>= 0; i--)); do
        board[$i]=$(echo 2^$i | bc)
    done

    box_board_update
    box_board_terminate
fi
