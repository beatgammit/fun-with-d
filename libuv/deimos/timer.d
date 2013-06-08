import deimos.uv.uv;
import std.stdio;

uv_loop_t* loop;

extern (C) void timer_cb1 (uv_timer_t* timer, int status) {
	writefln("1: %d", status);
	uv_timer_stop(timer);
	uv_unref(loop);
}

extern (C) void timer_cb2 (uv_timer_t* timer, int status) {
	writefln("2: %d", status);
	uv_timer_stop(timer);
	uv_unref(loop);
}

void main () {
	loop = uv_default_loop();

	uv_timer_t timer1;
	uv_timer_init(loop, &timer1);
	uv_timer_start(&timer1, &timer_cb1, 1000, 1000);

	uv_timer_t timer2;
	uv_timer_init(loop, &timer2);
	uv_timer_start(&timer2, &timer_cb2, 500, 1000);

	uv_run(loop);
}
