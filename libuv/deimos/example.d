import deimos.uv.uv;
import std.stdio;
import std.conv;

extern (C) void mkdir_cb (uv_fs_t* req) {
	int* msg = cast(int*)req.data;
	writefln("send(%d)\n", *msg);
}

void main() {
	uv_loop_t* loop = uv_loop_new();

	uv_fs_t req;
	int msg = 432;
	req.data = &msg;

	uv_fs_mkdir(loop, &req, "test", octal!777, &mkdir_cb);
	uv_run(loop);
}
