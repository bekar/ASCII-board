run:
	./board.sh

tmux:
	tmux send-keys "${PWD}/board.sh ${SIZE}" Enter
