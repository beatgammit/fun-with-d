import deimos.ev;
import std.stdio;
import std.datetime;

ev_io stdin_watcher;
ev_timer timeout_watcher;

// all watcher callbacks have a similar signature
// this callback is called when data is readable on stdin
extern (C) void stdin_cb (ev_loop_t* loop, ev_io *w, int revents) {
	// for one-shot events, one must manually stop the watcher
	// with its corresponding stop function.
	ev_io_stop(loop, w);

	char[] buf;
	readln(buf);
	writef("You wrote: %s", buf);

	// this causes all nested ev_run's to stop iterating
	ev_break(loop, EVBREAK_ALL);
}

// another callback, this time for a time-out
extern (C) void timeout_cb (ev_loop_t* loop, ev_timer *w, int revents) {
	writefln("You weren't fast enough. The timeout got you.");
	// this causes the innermost ev_run to stop iterating
	ev_break(loop, EVBREAK_ONE);
}

void main() {
	StopWatch sw;
	sw.start();

	// use the default event loop unless you have special needs
	auto loop = ev_default_loop(0);

	// initialise an io watcher, then start it
	// this one will watch for stdin to become readable
	ev_io_init(&stdin_watcher, &stdin_cb, 0, EV_READ);
	ev_io_start(loop, &stdin_watcher);

	// initialise a timer watcher, then start it
	// simple non-repeating 5.5 second timeout
	ev_timer_init(&timeout_watcher, &timeout_cb, 5.5, 0);
	ev_timer_start(loop, &timeout_watcher);

	// now wait for events to arrive
	ev_run(loop, 0);

	sw.stop();

	writefln("Total run time: %f", sw.peek().msecs / 1000F);
}
