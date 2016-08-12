PKG_NAME = ASCII-board
SOURCES = board.sh
SUPPORT = README.org AUTHORS LICENCE font.sh

default:
	./board.sh
	echo "This was the DEMO, use make install"

tmux:
	tmux send-keys "${PWD}/board.sh ${SIZE}" Enter

uninstall:
	rm -rf ${DESTDIR}/opt/${PKG_NAME}

install: uninstall
	mkdir -p ${DESTDIR}/opt/${PKG_NAME}
	install -m 755 ${SOURCES} -t ${DESTDIR}/opt/${PKG_NAME}/
	cp -r ${SUPPORT} ${DESTDIR}/opt/${PKG_NAME}/
