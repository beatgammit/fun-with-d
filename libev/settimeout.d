import deimos.ev;
import std.stdio;
import std.datetime;
import std.conv;

ev_timer timeout_watcher;

// another callback, this time for a time-out
extern (C) void timeout_cb (ev_loop_t* loop, ev_timer *w, int revents) {
	// this causes the innermost ev_run to stop iterating
	ev_break(loop, EVBREAK_ONE);
}

void main(char[][] args) {
	if (args.length != 2) {
		writeln("Usage: settimeout <timeout>\n\ttimeout: milliseconds");
		return;
	}

	long timeout;
	try {
		timeout = to!long(args[1]);
	} catch (Exception e) {
		writeln("Could not parse timeout. Must be a positive integer.");
		return;
	}

	StopWatch sw;

	// use the default event loop unless you have special needs
	auto loop = ev_default_loop(0);

	// initialise a timer watcher, then start it
	// simple non-repeating 5.5 second timeout
	ev_timer_init(&timeout_watcher, &timeout_cb, timeout / 1000F, 0);
	ev_timer_start(loop, &timeout_watcher);
	sw.start();

	// now wait for events to arrive
	ev_run(loop, 0);

	sw.stop();

	writefln("Total run time: %f", sw.peek().msecs / 1000F);
}
