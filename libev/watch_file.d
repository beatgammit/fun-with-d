import deimos.ev;
import std.stdio;
import std.datetime;
import std.conv;
import std.file;

// another callback, this time for a time-out
extern (C) void file_watcher_cb(ev_loop_t* loop, ev_stat *w, int revents) {
	writefln("File changed");
	// this causes the innermost ev_run to stop iterating
	ev_break(loop, EVBREAK_ONE);
}

void main(char[][] args) {
	if (args.length != 2) {
		writeln("Usage: watch_file path/to/file");
		return;
	}

	if (!exists(args[1])) {
		writefln("File does not exist: %s", args[1]);
		return;
	}

	StopWatch sw;
	sw.start();

	// use the default event loop unless you have special needs
	auto loop = ev_default_loop(0);

	ev_stat file_watcher;
	// watch the file the user passed in
	ev_stat_init(&file_watcher, &file_watcher_cb, cast(char*)args[1], 0);
	ev_stat_start(loop, &file_watcher);

	// now wait for events to arrive
	ev_run(loop, 0);

	sw.stop();

	writefln("Total run time: %f", sw.peek().msecs / 1000F);
}
