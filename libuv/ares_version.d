module deimos.libuv.ares.ares_version;

immutable ARES_COPYRIGHT = "2004 - 2010 Daniel Stenberg, <daniel@haxx.se>.";

enum ARES_VERSION_MAJOR = 1;
enum ARES_VERSION_MINOR = 7;
enum ARES_VERSION_PATCH = 5;
enum ARES_VERSION = (ARES_VERSION_MAJOR << 16) | (ARES_VERSION_MINOR << 8) | (ARES_VERSION_PATCH);

immutable ARES_VERSION_STR = "1.7.5-DEV";

static if (ARES_VERSION >= 0x010700) {
	version = CARES_HAVE_ARES_LIBRARY_INIT;
	version = CARES_HAVE_ARES_LIBRARY_CLEANUP;
}
