import deimos.ev;
import std.stdio;
import std.conv;
import std.socket;

Socket[socket_t] sockets;

extern (C) void sigintCb (ev_loop_t* loop, ev_signal *w, int revents) {
	ev_break(loop, EVBREAK_ALL);
}

// another callback, this time for a time-out
extern (C) void socket_watcher_cb(ev_loop_t* loop, ev_io *w, int revents) {
	writeln("Socket ready");

	// grab our socket and then remove it from the array
	auto req = sockets[cast(socket_t)w.fd];
	sockets.remove(req.handle);

	char[1024] buf;
	auto received = req.receive(buf);

	writefln("%d bytes read. Data:\n%s", received, buf[0..received]);

	req.send("You said: " ~ buf[0..received] ~ "\nHello!!\n");
	req.close();

	ev_io_stop(loop, w);
}

extern (C) void connection_cb(ev_loop_t* loop, ev_io* w, int revents) {
	auto server = cast(TcpSocket*)(*w).data;
	auto req = server.accept();

	// allocate on the heap; I'll release it later, I swear =D
	ev_io* watcher = new ev_io;

	// stick out Socket object somewhere where we can get it later
	// we can't use watcher.data because the GC doesn't check data
	// allocated by C (unless asked really nicely)
	sockets[req.handle] = req;

	ev_io_init(watcher, &socket_watcher_cb, req.handle, EV_READ);
	ev_io_start(loop, watcher);
}

void startServer(ushort port) {
	auto serverSock = new TcpSocket();
	serverSock.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
	serverSock.bind(new InternetAddress(port));
	serverSock.listen(100);

	ev_io server_watcher;
	server_watcher.data = &serverSock;

	// use the default event loop unless you have special needs
	auto mainLoop = ev_default_loop(0);

	ev_io_init(&server_watcher, &connection_cb, serverSock.handle, EV_READ);
	ev_io_start(mainLoop, &server_watcher);

	// set up our signal watchers
	ev_signal signal_watcher;
	ev_signal_init(&signal_watcher, &sigintCb, /*SIGINT*/2);
	ev_signal_start(mainLoop, &signal_watcher);

	// now wait for events to arrive
	ev_run(mainLoop, 0);

	ev_loop_destroy(mainLoop);
}

void main(char[][] args) {
	if (args.length != 2) {
		writeln("Usage: tcp_server <port>\n\tport: 0-65535");
		return;
	}

	ushort port;
	try {
		port = to!ushort(args[1]);
	} catch (Exception e) {
		writeln("Could not parse port.");
		return;
	}

	startServer(port);
}
