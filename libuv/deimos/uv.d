/* Copyright Joyent, Inc. and other Node contributors. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

module deimos.uv.uv;

// private stuffs
private import deimos.uv.ares;
private import deimos.ev;

version (Posix) {
	private import core.sys.posix.sys.types;
	private import core.sys.posix.termios;

	mixin template UV_HANDLE_PRIVATE_FIELDS() {
		int fd;
		int flags;
		ev_idle next_watcher;
	}
	mixin template UV_ARES_TASK_PRIVATE_FIELDS() {
		int sock;
		ev_io read_watcher;
		ev_io write_watcher;
	}
	mixin template UV_REQ_PRIVATE_FIELDS() {
	}

	struct uv_buf_t {
		char* base;
		size_t len;
	};

	alias ngx_queue_s ngx_queue_t;

	struct ngx_queue_s {
		ngx_queue_t* prev;
		ngx_queue_t* next;
	}

	mixin template UV_STREAM_PRIVATE_FIELDS() {
		uv_connect_t *connect_req;
		uv_shutdown_t *shutdown_req;
		ev_io read_watcher;
		ev_io write_watcher;
		ngx_queue_t write_queue;
		ngx_queue_t write_completed_queue;
		int delayed_error;
		uv_connection_cb connection_cb;
		int accepted_fd;
		int blocking;
	}

	mixin template UV_SHUTDOWN_PRIVATE_FIELDS() {}

	enum UV_REQ_BUFSML_SIZE = 4;

	mixin template UV_WRITE_PRIVATE_FIELDS() {
		ngx_queue_t queue;
		int write_index;
		uv_buf_t* bufs;
		int bufcnt;
		int error;
		uv_buf_t bufsml[UV_REQ_BUFSML_SIZE];
	}

	mixin template UV_CONNECT_PRIVATE_FIELDS() {
		ngx_queue_t queue;
	}

	mixin template UV_PIPE_PRIVATE_FIELDS() {
		const char* pipe_fname; /* strdup'ed */
	}

	mixin template UV_TCP_PRIVATE_FIELDS() {}

	mixin template UV_PREPARE_PRIVATE_FIELDS() {
		ev_prepare prepare_watcher;
		uv_prepare_cb prepare_cb;
	}

	mixin template UV_CHECK_PRIVATE_FIELDS() {
		ev_check check_watcher;
		uv_check_cb check_cb;
	}

	mixin template UV_IDLE_PRIVATE_FIELDS() {
		ev_idle idle_watcher;
		uv_idle_cb idle_cb;
	}

	mixin template UV_ASYNC_PRIVATE_FIELDS() {
		ev_async async_watcher;
		uv_async_cb async_cb;
	}

	mixin template UV_TIMER_PRIVATE_FIELDS() {
		ev_timer timer_watcher;
		uv_timer_cb timer_cb;
	}

	mixin template UV_GETADDRINFO_PRIVATE_FIELDS() {
		uv_getaddrinfo_cb cb;
		addrinfo* hints;
		char* hostname;
		char* service;
		addrinfo* res;
		int retcode;
	}

	alias ptrdiff_t eio_ssize_t;
	alias long off_t;
	alias double eio_tstamp;
	alias eio_req ETP_REQ;

	enum EIO_PRI_MIN     = -4;
	enum EIO_PRI_MAX     =  4;
	enum EIO_PRI_DEFAULT =  0;
	enum ETP_NUM_PRI = (EIO_PRI_MAX - EIO_PRI_MIN + 1);

	struct etp_reqq {
		ETP_REQ *qs[ETP_NUM_PRI];
		ETP_REQ *qe[ETP_NUM_PRI];
		int size;
	}

	struct eio_channel {
		etp_reqq res_queue;
		void *data;
	}

	// from libuv/include/uv-private/eio.h
	/* eio request structure */
	/* this structure is mostly read-only */
	/* when initialising it, all members must be zero-initialised */
	struct eio_req
	{
		eio_req /*volatile*/ *next; /* private ETP */

		eio_ssize_t result;  /* result of syscall, e.g. result = read (... */
		off_t offs;      /* read, write, truncate, readahead, sync_file_range, fallocate: file offset, mknod: dev_t */
		size_t size;     /* read, write, readahead, sendfile, msync, mlock, sync_file_range, fallocate: length */
		void *ptr1;      /* all applicable requests: pathname, old name; readdir: optional eio_dirents */
		void *ptr2;      /* all applicable requests: new name or memory buffer; readdir: name strings */
		eio_tstamp nv1;  /* utime, futime: atime; busy: sleep time */
		eio_tstamp nv2;  /* utime, futime: mtime */

		int type;        /* EIO_xxx constant ETP */
		int int1;        /* all applicable requests: file descriptor; sendfile: output fd; open, msync, mlockall, readdir: flags */
		long int2;       /* chown, fchown: uid; sendfile: input fd; open, chmod, mkdir, mknod: file mode, sync_file_range, fallocate: flags */
		long int3;       /* chown, fchown: gid */
		int errorno;     /* errno value on syscall return */

		eio_channel *channel; /* data used to direct poll callbacks arising from this req */

		version (X86) {
			char cancelled;
		} else {
			version (X86_64) {
				char cancelled;
			} else {
				sig_atomic_t cancelled;
			}
		}

		char flags; /* private */
		byte pri;     /* the priority */

		void* data;
		int function (eio_req*) finish;
		void function (eio_req*) destroy; /* called when request no longer needed */
		void function (eio_req*) feed;    /* only used for group requests */

		//EIO_REQ_MEMBERS

		/* private */
		eio_req* grp;
		eio_req* grp_prev;
		eio_req* grp_next;
		eio_req* grp_first;
	};

	mixin template UV_FS_PRIVATE_FIELDS() {
		stat.stat_t statbuf;
		eio_req* eio;
	}

	mixin template UV_WORK_PRIVATE_FIELDS() {
		eio_req* eio;
	}

	version (linux) {
		mixin template UV_FS_EVENT_PRIVATE_FIELDS() {
			struct node {
				uv_fs_event_t* rbe_left;
				uv_fs_event_t* rbe_right;
				uv_fs_event_t* rbe_parent;
				int rbe_color;
			}
			ev_io read_watcher;
			uv_fs_event_cb cb;
		}
	}
	version (BSD) {
		mixin template UV_FS_EVENT_PRIVATE_FIELDS() {
			ev_io event_watcher;
			uv_fs_event_cb cb;
			int fflags;
		}
	}
	version (Solaris) {
		static assert(false, "Solaris not supported");
	}

	mixin template UV_PROCESS_PRIVATE_FIELDS() {
		ev_child child_watcher;
	}

	mixin template UV_UDP_SEND_PRIVATE_FIELDS() {
		ngx_queue_t queue;
		sockaddr_storage addr;
		socklen_t addrlen;
		uv_buf_t* bufs;
		int bufcnt;
		ssize_t status;
		uv_udp_send_cb send_cb;
		uv_buf_t bufsml[UV_REQ_BUFSML_SIZE];
	}

	mixin template UV_UDP_PRIVATE_FIELDS() {
		uv_alloc_cb alloc_cb;
		uv_udp_recv_cb recv_cb;
		ev_io read_watcher;
		ev_io write_watcher;
		ngx_queue_t write_queue;
		ngx_queue_t write_completed_queue;
	}

	alias void* uv_lib_t;
	alias pthread_mutex_t uv_mutex_t;
	alias pthread_rwlock_t uv_rwlock_t;

	mixin template UV_PRIVATE_REQ_TYPES() {}

	mixin template UV_TTY_PRIVATE_FIELDS() {
		termios orig_termios;
		int mode;
	}

	alias int uv_file;

	alias pthread_once_t uv_once_t;
	alias pthread_t uv_thread_t;
}

version (Windows) {
	mixin template UV_HANDLE_PRIVATE_FIELDS() {
		uv_handle_t* endgame_next;
		uint flags;
	}
	mixin template UV_ARES_TASK_PRIVATE_FIELDS() {
		uv_req_s ares_req;
		SOCKET sock;
		HANDLE h_wait;
		WSAEVENT h_event;
		HANDLE h_close_event;
	}
	mixin template UV_REQ_PRIVATE_FIELDS() {
		union {
			/* Used by I/O operations */
			struct {
				OVERLAPPED overlapped;
				size_t queued_bytes;
			};
		};
		uv_req_s* next_req;
	}

	struct uv_buf_t {
		ULONG len;
		char* base;
	};

	mixin template UV_STREAM_PRIVATE_FIELDS() {
		uint reqs_pending;
		uv_read_t read_req;
		union {
			struct {
				uint write_reqs_pending;
				uv_shutdown_t* shutdown_req;
			};
			struct {
				uv_connection_cb connection_cb;
			};
		};
	}

	mixin template UV_SHUTDOWN_PRIVATE_FIELDS() {}

	mixin template UV_WRITE_PRIVATE_FIELDS() {
		int ipc_header;
		uv_buf_t write_buffer;
		HANDLE event_handle;
		HANDLE wait_handle;
	}

	mixin template UV_CONNECT_PRIVATE_FIELDS() {}

	mixin template UV_PIPE_PRIVATE_FIELDS() {
		HANDLE handle;
		wchar_t* name;
		union {
			struct {
				int pending_instances;
				uv_pipe_accept_t* accept_reqs;
				uv_pipe_accept_t* pending_accepts;
			};
			struct {
				uv_timer_t* eof_timer;
				uv_write_t ipc_header_write_req;
				int ipc_pid;
				uint64_t remaining_ipc_rawdata_bytes;
				WSAPROTOCOL_INFOW* pending_socket_info;
				uv_write_t* non_overlapped_writes_tail;
			};
		};
	}

	mixin template UV_TCP_PRIVATE_FIELDS() {
		SOCKET socket;
		int bind_error;
		union {
			struct {
				uv_tcp_accept_t* accept_reqs;
				uint processed_accepts;
				uv_tcp_accept_t* pending_accepts;
				LPFN_ACCEPTEX func_acceptex;
			};
			struct {
				uv_buf_t read_buffer;
				LPFN_CONNECTEX func_connectex;
			};
		};
	}

	mixin template UV_PREPARE_PRIVATE_FIELDS() {
		uv_prepare_t* prepare_prev;
		uv_prepare_t* prepare_next;
		uv_prepare_cb prepare_cb;
	}

	mixin template UV_CHECK_PRIVATE_FIELDS() {
		uv_check_t* check_prev;
		uv_check_t* check_next;
		uv_check_cb check_cb;
	}

	mixin template UV_IDLE_PRIVATE_FIELDS() {
		uv_idle_t* idle_prev;
		uv_idle_t* idle_next;
		uv_idle_cb idle_cb;
	}

	mixin template UV_ASYNC_PRIVATE_FIELDS() {
		uv_req_s async_req;
		uv_async_cb async_cb;
		/* char to avoid alignment issues */
		char /*volatile*/ async_sent;
	}

	mixin template RB_ENTRY(T) {
		struct {
			T* rbe_left;        /* left element */
			T* rbe_right;       /* right element */
			T* rbe_parent;      /* parent element */
			int rbe_color;                /* node color */
		};
	}

	mixin template UV_TIMER_PRIVATE_FIELDS() {
		mixin RB_ENTRY!(uv_timer_s) tree_entry;
		int64_t due;
		int64_t repeat;
		uv_timer_cb timer_cb;
	}

	mixin template UV_GETADDRINFO_PRIVATE_FIELDS() {
		uv_req_s getadddrinfo_req;
		uv_getaddrinfo_cb getaddrinfo_cb;
		void* alloc;
		wchar_t* node;
		wchar_t* service;
		addrinfoW* hints;
		addrinfoW* res;
		int retcode;
	}

	mixin template UV_FS_PRIVATE_FIELDS() {
		wchar_t* pathw;
		int flags;
		DWORD sys_errno_;
		_stati64 stat;
		void* arg0;
		union {
			struct {
				void* arg1;
				void* arg2;
				void* arg3;
			}
			struct {
				void* arg4;
				void* arg5;
			}
		}
	}

	mixin template UV_WORK_PRIVATE_FIELDS() {}

	mixin template UV_FS_EVENT_PRIVATE_FIELDS() {
		struct req {
			mixin UV_REQ_FIELDS;
		}
		HANDLE dir_handle;
		int req_pending;
		uv_fs_event_cb cb;
		wchar_t* filew;
		wchar_t* short_filew;
		wchar_t* dirw;
		char* buffer;
	}

	mixin template UV_PROCESS_PRIVATE_FIELDS() {
		struct exit_req {
			mixin UV_REQ_FIELDS;
		}
		struct close_req {
			mixin UV_REQ_FIELDS;
		}
		HANDLE child_stdio[3];
		int exit_signal;
		DWORD spawn_errno;
		HANDLE wait_handle;
		HANDLE process_handle;
		HANDLE close_handle;
	}

	mixin template UV_UDP_SEND_PRIVATE_FIELDS() {}

	alias HMODULE uv_lib_t;
	alias CRITICAL_SECTION uv_mutex_t;
	union uv_rwlock_t {
		SRWLOCK srwlock_;
		struct {
			uv_mutex_t read_mutex_;
			uv_mutex_t write_mutex_;
			uint num_readers_;
		}
	}

	mixin template UV_PRIVATE_REQ_TYPES() {
		struct uv_pipe_accept_t {
			mixin UV_REQ_FIELDS;
			HANDLE pipeHandle;
			uv_pipe_accept_t* next_pending;
		}
		struct uv_tcp_accept_t {
			mixin UV_REQ_FIELDS;
			SOCKET accept_socket;
			char accept_buffer[sizeof(sockaddr_storage) * 2 + 32];
			HANDLE event_handle;
			HANDLE wait_handle;
			uv_tcp_accept_t* next_pending;
		}
		struct uv_read_t {
			mixin UV_REQ_FIELDS;
			HANDLE event_handle;
			HANDLE wait_handle;
		}
	}

	mixin template UV_TTY_PRIVATE_FIELDS() {
		HANDLE handle;
		HANDLE read_line_handle;
		uv_buf_t read_line_buffer;
		HANDLE read_raw_wait;
		DWORD original_console_mode;
		/* Fields used for translating win */
		/* keystrokes into vt100 characters */
		char last_key[8];
		char last_key_offset;
		char last_key_len;
		INPUT_RECORD last_input_record;
		WCHAR last_utf16_high_surrogate;
		/* utf8-to-utf16 conversion state */
		char utf8_bytes_left;
		uint utf8_codepoint;
		/* eol conversion state */
		char previous_eol;
		/* ansi parser state */
		char ansi_parser_state;
		char ansi_csi_argc;
		ushort ansi_csi_argv[4];
		COORD saved_position;
		WORD saved_attributes;
	}

	alias int uv_file;

	struct uv_once_t {
		char ran;
		HANDLE event;
		HANDLE padding;
	}

	alias HANDLE uv_thread_t;
}

extern (C):

/* See uv_loop_new for an introduction. */

/+
#ifdef _WIN32
  /* Windows - set up dll import/export decorators. */
# if defined(BUILDING_UV_SHARED)
    /* Building shared library. Export everything from c-ares as well. */
#   define UV_EXTERN __declspec(dllexport)
#   define CARES_BUILDING_LIBRARY 1
# elif defined(USING_UV_SHARED)
    /* Using shared library. Use shared c-ares as well. */
#   define UV_EXTERN __declspec(dllimport)
# else
    /* Building static library. Build c-ares statically as well. */
#   define UV_EXTERN /* nothing */
#   define CARES_STATICLIB 1
# endif
#elif __GNUC__ >= 4
# define UV_EXTERN __attribute__((visibility("default")))
#else
# define UV_EXTERN /* nothing */
#endif
+/


enum UV_VERSION_MAJOR = 0;
enum UV_VERSION_MINOR = 6;

import std.stdint;
version (linux) {
	import std.c.linux.socket;
}
version (FreeBSD) {
	import std.c.freebsd.socket;
}
version (OSX) {
	import std.c.osx.socket;
}

alias ptrdiff_t ssize_t;

/* Expand this list if necessary. */
mixin template UV_ERRNO_GEN(alias val, alias name, string s) {
	mixin("UV_" ~ name ~ " = " ~ val ~ ",");
}

enum uv_err_code {
  UV_UNKNOWN = -1, // "unknown error"
  UV_OK = 0, // "success"
  UV_EOF = 1, // "end of file"
  UV_EADDRINFO = 2, // "getaddrinfo error"
  UV_EACCES = 3, // "permission denied"
  UV_EAGAIN = 4, // "no more processes"
  UV_EADDRINUSE = 5, // "address already in use"
  UV_EADDRNOTAVAIL = 6,//, "");
  UV_EAFNOSUPPORT = 7,//, "");
  UV_EALREADY = 8,//, "");
  UV_EBADF = 9, // "bad file descriptor"
  UV_EBUSY = 10, // "mount device busy"
  UV_ECONNABORTED = 11, // "software caused connection abort"
  UV_ECONNREFUSED = 12, // "connection refused"
  UV_ECONNRESET = 13, // "connection reset by peer"
  UV_EDESTADDRREQ = 14, // "destination address required"
  UV_EFAULT = 15, // "bad address in system call argument"
  UV_EHOSTUNREACH = 16, // "host is unreachable"
  UV_EINTR = 17, // "interrupted system call"
  UV_EINVAL = 18, // "invalid argument"
  UV_EISCONN = 19, // "socket is already connected"
  UV_EMFILE = 20, // "too many open files"
  UV_EMSGSIZE = 21, // "message too long"
  UV_ENETDOWN = 22, // "network is down"
  UV_ENETUNREACH = 23, // "network is unreachable"
  UV_ENFILE = 24, // "file table overflow"
  UV_ENOBUFS = 25, // "no buffer space available"
  UV_ENOMEM = 26, // "not enough memory"
  UV_ENOTDIR = 27, // "not a directory"
  UV_EISDIR = 28, // "illegal operation on a directory"
  UV_ENONET = 29, // "machine is not on the network"
  UV_ENOTCONN = 31, // "socket is not connected"
  UV_ENOTSOCK = 32, // "socket operation on non-socket"
  UV_ENOTSUP = 33, // "operation not supported on socket"
  UV_ENOENT = 34, // "no such file or directory"
  UV_ENOSYS = 35, // "function not implemented"
  UV_EPIPE = 36, // "broken pipe"
  UV_EPROTO = 37, // "protocol error"
  UV_EPROTONOSUPPORT = 38, // "protocol not supported"
  UV_EPROTOTYPE = 39, // "protocol wrong type for socket"
  UV_ETIMEDOUT = 40, // "connection timed out"
  UV_ECHARSET = 41, // ""
  UV_EAIFAMNOSUPPORT = 42, // ""
  UV_EAISERVICE = 44, // ""
  UV_EAISOCKTYPE = 45, // ""
  UV_ESHUTDOWN = 46, // ""
  UV_EEXIST = 47, // "file already exists"
  UV_ESRCH = 48, // "no such process"
  UV_ENAMETOOLONG = 49, // "name too long"
  UV_EPERM = 50, // "operation not permitted"
  UV_ELOOP = 51, // "too many symbolic links encountered"
  UV_EXDEV = 52, // "cross-device link not permitted"
  UV_MAX_ERRORS
}

enum uv_handle_type {
  UV_UNKNOWN_HANDLE = 0,
  UV_TCP,
  UV_UDP,
  UV_NAMED_PIPE,
  UV_TTY,
  UV_FILE,
  UV_TIMER,
  UV_PREPARE,
  UV_CHECK,
  UV_IDLE,
  UV_ASYNC,
  UV_ARES_TASK,
  UV_ARES_EVENT,
  UV_PROCESS,
  UV_FS_EVENT
};

enum uv_req_type {
  UV_UNKNOWN_REQ = 0,
  UV_CONNECT,
  UV_ACCEPT,
  UV_READ,
  UV_WRITE,
  UV_SHUTDOWN,
  UV_WAKEUP,
  UV_UDP_SEND,
  UV_FS,
  UV_WORK,
  UV_GETADDRINFO,
  UV_REQ_TYPE_PRIVATE
};


// from uv-common.h
struct uv_ares_task_s {
	mixin UV_HANDLE_FIELDS;
	mixin UV_ARES_TASK_PRIVATE_FIELDS;
	uv_ares_task_t* ares_prev;
	uv_ares_task_t* ares_next;
};


alias uv_loop_s uv_loop_t;
alias uv_ares_task_s uv_ares_task_t;
alias uv_err_s uv_err_t;
alias uv_handle_s uv_handle_t;
alias uv_stream_s uv_stream_t;
alias uv_tcp_s uv_tcp_t;
alias uv_udp_s uv_udp_t;
alias uv_pipe_s uv_pipe_t;
alias uv_tty_s uv_tty_t;
alias uv_timer_s uv_timer_t;
alias uv_prepare_s uv_prepare_t;
alias uv_check_s uv_check_t;
alias uv_idle_s uv_idle_t;
alias uv_async_s uv_async_t;
alias uv_getaddrinfo_s uv_getaddrinfo_t;
alias uv_process_s uv_process_t;
alias uv_counters_s uv_counters_t;
alias uv_cpu_info_s uv_cpu_info_t;
alias uv_interface_address_s uv_interface_address_t;
/* Request types */
alias uv_req_s uv_req_t;
alias uv_shutdown_s uv_shutdown_t;
alias uv_write_s uv_write_t;
alias uv_connect_s uv_connect_t;
alias uv_udp_send_s uv_udp_send_t;
alias uv_fs_s uv_fs_t;
/* uv_fs_event_t is a subclass of uv_handle_t. */
alias uv_fs_event_s uv_fs_event_t;
alias uv_work_s uv_work_t;


/*
 * This function must be called before any other functions in libuv.
 *
 * All functions besides uv_run() are non-blocking.
 *
 * All callbacks in libuv are made asynchronously. That is they are never
 * made by the function that takes them as a parameter.
 */
uv_loop_t* uv_loop_new();
void uv_loop_delete(uv_loop_t*);

/* This is a debugging tool. It's NOT part of the official API. */
int uv_loop_refcount(const uv_loop_t*);


/*
 * Returns the default loop.
 */
uv_loop_t* uv_default_loop();

/*
 * This function starts the event loop. It blocks until the reference count
 * of the loop drops to zero.
 */
int uv_run (uv_loop_t*);

/*
 * This function polls for new events without blocking.
 */
int uv_run_once (uv_loop_t*);

/*
 * Manually modify the event loop's reference count. Useful if the user wants
 * to have a handle or timeout that doesn't keep the loop alive.
 */
void uv_ref(uv_loop_t*);
void uv_unref(uv_loop_t*);

void uv_update_time(uv_loop_t*);
int64_t uv_now(uv_loop_t*);


/*
 * Should return a buffer that libuv can use to read data into.
 *
 * `suggested_size` is a hint. Returning a buffer that is smaller is perfectly
 * okay as long as `buf.len > 0`.
 */
alias uv_buf_t function (uv_handle_t*, size_t) uv_alloc_cb;

/*
 * `nread` is > 0 if there is data available, 0 if libuv is done reading for now
 * or -1 on error.
 *
 * Error details can be obtained by calling uv_last_error(). UV_EOF indicates
 * that the stream has been closed.
 *
 * The callee is responsible for closing the stream when an error happens.
 * Trying to read from the stream again is undefined.
 *
 * The callee is responsible for freeing the buffer, libuv does not reuse it.
 */
alias void function (uv_stream_t*, ssize_t, uv_buf_t) uv_read_cb;

/*
 * Just like the uv_read_cb except that if the pending parameter is true
 * then you can use uv_accept() to pull the new handle into the process.
 * If no handle is pending then pending will be UV_UNKNOWN_HANDLE.
 */
alias void function (uv_pipe_t*, ssize_t, uv_buf_t, uv_handle_type) uv_read2_cb;
alias void function (uv_write_t*, int) uv_write_cb;
alias void function (uv_connect_t*, int) uv_connect_cb;
alias void function (uv_shutdown_t*, int) uv_shutdown_cb;
alias void function (uv_stream_t*, int) uv_connection_cb;
alias void function (uv_handle_t*) uv_close_cb;
alias void function (uv_timer_t*, int) uv_timer_cb;
alias void function (uv_async_t*, int) uv_async_cb;
alias void function (uv_prepare_t*, int) uv_prepare_cb;
alias void function (uv_check_t*, int) uv_check_cb;
alias void function (uv_idle_t*, int) uv_idle_cb;
alias void function (uv_getaddrinfo_t*, int) uv_getaddrinfo_cb;
alias void function (uv_process_t*, int, int) uv_exit_cb;
alias void function (uv_fs_t*) uv_fs_cb;
alias void function (uv_work_t*) uv_work_cb;
alias void function (uv_work_t*) uv_after_work_cb;

/*
* This will be called repeatedly after the uv_fs_event_t is initialized.
* If uv_fs_event_t was initialized with a directory the filename parameter
* will be a relative path to a file contained in the directory.
* The events parameter is an ORed mask of enum uv_fs_event elements.
*/
alias void function (uv_fs_event_t*, const char*, int, int) uv_fs_event_cb;
enum uv_membership {
  UV_LEAVE_GROUP = 0,
  UV_JOIN_GROUP
};

struct uv_err_s {
  /* read-only */
  uv_err_code code;
  /* private */
  int sys_errno_;
};

/*
 * Most functions return boolean: 0 for success and -1 for failure.
 * On error the user should then call uv_last_error() to determine
 * the error code.
 */
uv_err_t uv_last_error(uv_loop_t*);
string uv_strerror(uv_err_t err);
string uv_err_name(uv_err_t err);

mixin template UV_REQ_FIELDS() {
  /* read-only */
  uv_req_type type;
  /* public */
  void* data;
  /* private */
  mixin UV_REQ_PRIVATE_FIELDS;
}

/* Abstract base class of all requests. */
struct uv_req_s {
  mixin UV_REQ_FIELDS;
};

/* Platform-specific request types */
mixin UV_PRIVATE_REQ_TYPES;


/*
 * uv_shutdown_t is a subclass of uv_req_t
 *
 * Shutdown the outgoing (write) side of a duplex stream. It waits for
 * pending write requests to complete. The handle should refer to a
 * initialized stream. req should be an uninitialized shutdown request
 * struct. The cb is called after shutdown is complete.
 */
int uv_shutdown(uv_shutdown_t* req, uv_stream_t* handle, uv_shutdown_cb cb);

struct uv_shutdown_s {
  mixin UV_REQ_FIELDS;
  uv_stream_t* handle;
  uv_shutdown_cb cb;
  mixin UV_SHUTDOWN_PRIVATE_FIELDS;
};

mixin template UV_HANDLE_FIELDS() {
  /* read-only */
  uv_loop_t* loop;
  uv_handle_type type;
  /* public */
  uv_close_cb close_cb;
  void* data;
  /* private */
  mixin UV_HANDLE_PRIVATE_FIELDS;
}

/* The abstract base class of all handles.  */
struct uv_handle_s {
  mixin UV_HANDLE_FIELDS;
};


/*
 * Returns 1 if the prepare/check/idle/timer handle has been started, 0
 * otherwise. For other handle types this always returns 1.
 */
int uv_is_active(uv_handle_t* handle);

/*
 * Request handle to be closed. close_cb will be called asynchronously after
 * this call. This MUST be called on each handle before memory is released.
 *
 * Note that handles that wrap file descriptors are closed immediately but
 * close_cb will still be deferred to the next iteration of the event loop.
 * It gives you a chance to free up any resources associated with the handle.
 */
void uv_close(uv_handle_t* handle, uv_close_cb close_cb);


/*
 * Constructor for uv_buf_t.
 * Due to platform differences the user cannot rely on the ordering of the
 * base and len members of the uv_buf_t struct. The user is responsible for
 * freeing base after the uv_buf_t is done. Return struct passed by value.
 */
uv_buf_t uv_buf_init(char* base, size_t len);


/*
 * Utility function. Copies up to `size` characters from `src` to `dst`
 * and ensures that `dst` is properly NUL terminated unless `size` is zero.
 */
size_t uv_strlcpy(char* dst, const char* src, size_t size);

/*
 * Utility function. Appends `src` to `dst` and ensures that `dst` is
 * properly NUL terminated unless `size` is zero or `dst` does not
 * contain a NUL byte. `size` is the total length of `dst` so at most
 * `size - strlen(dst) - 1` characters will be copied from `src`.
 */
size_t uv_strlcat(char* dst, const char* src, size_t size);

mixin template UV_STREAM_FIELDS() {
  /* number of bytes queued for writing */
  size_t write_queue_size;
  uv_alloc_cb alloc_cb;
  uv_read_cb read_cb;
  uv_read2_cb read2_cb;
  /* private */
  mixin UV_STREAM_PRIVATE_FIELDS;
};

/*
 * uv_stream_t is a subclass of uv_handle_t
 *
 * uv_stream is an abstract class.
 *
 * uv_stream_t is the parent class of uv_tcp_t, uv_pipe_t, uv_tty_t, and
 * soon uv_file_t.
 */
struct uv_stream_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_STREAM_FIELDS;
};

int uv_listen(uv_stream_t* stream, int backlog, uv_connection_cb cb);

/*
 * This call is used in conjunction with uv_listen() to accept incoming
 * connections. Call uv_accept after receiving a uv_connection_cb to accept
 * the connection. Before calling uv_accept use uv_*_init() must be
 * called on the client. Non-zero return value indicates an error.
 *
 * When the uv_connection_cb is called it is guaranteed that uv_accept will
 * complete successfully the first time. If you attempt to use it more than
 * once, it may fail. It is suggested to only call uv_accept once per
 * uv_connection_cb call.
 */
int uv_accept(uv_stream_t* server, uv_stream_t* client);

/*
 * Read data from an incoming stream. The callback will be made several
 * several times until there is no more data to read or uv_read_stop is
 * called. When we've reached EOF nread will be set to -1 and the error is
 * set to UV_EOF. When nread == -1 the buf parameter might not point to a
 * valid buffer; in that case buf.len and buf.base are both set to 0.
 * Note that nread might also be 0, which does *not* indicate an error or
 * eof; it happens when libuv requested a buffer through the alloc callback
 * but then decided that it didn't need that buffer.
 */
int uv_read_start(uv_stream_t*, uv_alloc_cb alloc_cb, uv_read_cb read_cb);

int uv_read_stop(uv_stream_t*);

/*
 * Extended read methods for receiving handles over a pipe. The pipe must be
 * initialized with ipc == 1.
 */
int uv_read2_start(uv_stream_t*, uv_alloc_cb alloc_cb, uv_read2_cb read_cb);


/*
 * Write data to stream. Buffers are written in order. Example:
 *
 *   uv_buf_t a[] = {
 *     { .base = "1", .len = 1 },
 *     { .base = "2", .len = 1 }
 *   };
 *
 *   uv_buf_t b[] = {
 *     { .base = "3", .len = 1 },
 *     { .base = "4", .len = 1 }
 *   };
 *
 *   // writes "1234"
 *   uv_write(req, stream, a, 2);
 *   uv_write(req, stream, b, 2);
 *
 */
int uv_write(uv_write_t* req, uv_stream_t* handle, uv_buf_t bufs[], int bufcnt, uv_write_cb cb);

int uv_write2(uv_write_t* req, uv_stream_t* handle, uv_buf_t bufs[], int bufcnt, uv_stream_t* send_handle, uv_write_cb cb);

/* uv_write_t is a subclass of uv_req_t */
struct uv_write_s {
  mixin UV_REQ_FIELDS;
  uv_write_cb cb;
  uv_stream_t* send_handle;
  uv_stream_t* handle;
  mixin UV_WRITE_PRIVATE_FIELDS;
};

/*
 * Used to determine whether a stream is readable or writable.
 * TODO: export in v0.8.
 */
/* UV_EXTERN */ int uv_is_readable(uv_stream_t* handle);
/* UV_EXTERN */ int uv_is_writable(uv_stream_t* handle);

/*
 * uv_tcp_t is a subclass of uv_stream_t
 *
 * Represents a TCP stream or TCP server.
 */
struct uv_tcp_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_STREAM_FIELDS;
  mixin UV_TCP_PRIVATE_FIELDS;
};

int uv_tcp_init(uv_loop_t*, uv_tcp_t* handle);

/* Enable/disable Nagle's algorithm. */
int uv_tcp_nodelay(uv_tcp_t* handle, int enable);

/* Enable/disable TCP keep-alive.
 *
 * `ms` is the initial delay in seconds, ignored when `enable` is zero.
 */
int uv_tcp_keepalive(uv_tcp_t* handle, int enable, uint delay);

/*
 * This setting applies to Windows only.
 * Enable/disable simultaneous asynchronous accept requests that are
 * queued by the operating system when listening for new tcp connections.
 * This setting is used to tune a tcp server for the desired performance.
 * Having simultaneous accepts can significantly improve the rate of
 * accepting connections (which is why it is enabled by default).
 */
int uv_tcp_simultaneous_accepts(uv_tcp_t* handle, int enable);

int uv_tcp_bind(uv_tcp_t* handle, sockaddr_in);
int uv_tcp_bind6(uv_tcp_t* handle, sockaddr_in6);
int uv_tcp_getsockname(uv_tcp_t* handle, sockaddr* name, int* namelen);
int uv_tcp_getpeername(uv_tcp_t* handle, sockaddr* name, int* namelen);

/*
 * uv_tcp_connect, uv_tcp_connect6
 * These functions establish IPv4 and IPv6 TCP connections. Provide an
 * initialized TCP handle and an uninitialized uv_connect_t*. The callback
 * will be made when the connection is established.
 */
int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, sockaddr_in address, uv_connect_cb cb);
int uv_tcp_connect6(uv_connect_t* req, uv_tcp_t* handle, sockaddr_in6 address, uv_connect_cb cb);

/* uv_connect_t is a subclass of uv_req_t */
struct uv_connect_s {
  mixin UV_REQ_FIELDS;
  uv_connect_cb cb;
  uv_stream_t* handle;
  mixin UV_CONNECT_PRIVATE_FIELDS;
};

/*
 * UDP support.
 */

enum uv_udp_flags {
  /* Disables dual stack mode. Used with uv_udp_bind6(). */
  UV_UDP_IPV6ONLY = 1,
  /*
   * Indicates message was truncated because read buffer was too small. The
   * remainder was discarded by the OS. Used in uv_udp_recv_cb.
   */
  UV_UDP_PARTIAL = 2
};

/*
 * Called after a uv_udp_send() or uv_udp_send6(). status 0 indicates
 * success otherwise error.
 */
alias void function (uv_udp_send_t*, int) uv_udp_send_cb;

/*
 * Callback that is invoked when a new UDP datagram is received.
 *
 *  handle  UDP handle.
 *  nread   Number of bytes that have been received.
 *          0 if there is no more data to read. You may
 *          discard or repurpose the read buffer.
 *          -1 if a transmission error was detected.
 *  buf     uv_buf_t with the received data.
 *  addr    struct sockaddr_in or struct sockaddr_in6.
 *          Valid for the duration of the callback only.
 *  flags   One or more OR'ed UV_UDP_* constants.
 *          Right now only UV_UDP_PARTIAL is used.
 */
alias void function (uv_udp_t*, ssize_t, uv_buf_t, sockaddr*, uint flags) uv_udp_recv_cb;

/* uv_udp_t is a subclass of uv_handle_t */
struct uv_udp_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_UDP_PRIVATE_FIELDS;
};

/* uv_udp_send_t is a subclass of uv_req_t */
struct uv_udp_send_s {
  mixin UV_REQ_FIELDS;
  uv_udp_t* handle;
  uv_udp_send_cb cb;
  mixin UV_UDP_SEND_PRIVATE_FIELDS;
};

/*
 * Initialize a new UDP handle. The actual socket is created lazily.
 * Returns 0 on success.
 */
int uv_udp_init(uv_loop_t*, uv_udp_t* handle);

/*
 * Bind to a IPv4 address and port.
 *
 * Arguments:
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *  addr      struct sockaddr_in with the address and port to bind to.
 *  flags     Unused.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_bind(uv_udp_t* handle, sockaddr_in addr, uint flags);

/*
 * Bind to a IPv6 address and port.
 *
 * Arguments:
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *  addr      struct sockaddr_in with the address and port to bind to.
 *  flags     Should be 0 or UV_UDP_IPV6ONLY.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_bind6(uv_udp_t* handle, sockaddr_in6 addr, uint flags);
int uv_udp_getsockname(uv_udp_t* handle, sockaddr* name, int* namelen);

/*
 * Set membership for a multicast address
 *
 * Arguments:
 *  handle              UDP handle. Should have been initialized with
 *                      `uv_udp_init`.
 *  multicast_addr      multicast address to set membership for
 *  interface_addr      interface address
 *  membership          Should be UV_JOIN_GROUP or UV_LEAVE_GROUP
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_set_membership(uv_udp_t* handle, const char* multicast_addr, const char* interface_addr, uv_membership membership);

/*
 * Set IP multicast loop flag. Makes multicast packets loop back to
 * local sockets.
 *
 * Arguments:
 *  handle              UDP handle. Should have been initialized with
 *                      `uv_udp_init`.
 *  on                  1 for on, 0 for off
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_set_multicast_loop(uv_udp_t* handle, int on);

/*
 * Set the multicast ttl
 *
 * Arguments:
 *  handle              UDP handle. Should have been initialized with
 *                      `uv_udp_init`.
 *  ttl                 1 through 255
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_set_multicast_ttl(uv_udp_t* handle, int ttl);

/*
 * Set broadcast on or off
 *
 * Arguments:
 *  handle              UDP handle. Should have been initialized with
 *                      `uv_udp_init`.
 *  on                  1 for on, 0 for off
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_set_broadcast(uv_udp_t* handle, int on);

/*
 * Set the time to live
 *
 * Arguments:
 *  handle              UDP handle. Should have been initialized with
 *                      `uv_udp_init`.
 *  ttl                 1 through 255
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_set_ttl(uv_udp_t* handle, int ttl);

/*
 * Send data. If the socket has not previously been bound with `uv_udp_bind`
 * or `uv_udp_bind6`, it is bound to 0.0.0.0 (the "all interfaces" address)
 * and a random port number.
 *
 * Arguments:
 *  req       UDP request handle. Need not be initialized.
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *  bufs      List of buffers to send.
 *  bufcnt    Number of buffers in `bufs`.
 *  addr      Address of the remote peer. See `uv_ip4_addr`.
 *  send_cb   Callback to invoke when the data has been sent out.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_send(uv_udp_send_t* req, uv_udp_t* handle,
    uv_buf_t bufs[], int bufcnt, sockaddr_in addr,
    uv_udp_send_cb send_cb);

/*
 * Send data. If the socket has not previously been bound with `uv_udp_bind6`,
 * it is bound to ::0 (the "all interfaces" address) and a random port number.
 *
 * Arguments:
 *  req       UDP request handle. Need not be initialized.
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *  bufs      List of buffers to send.
 *  bufcnt    Number of buffers in `bufs`.
 *  addr      Address of the remote peer. See `uv_ip6_addr`.
 *  send_cb   Callback to invoke when the data has been sent out.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_send6(uv_udp_send_t* req, uv_udp_t* handle,
    uv_buf_t bufs[], int bufcnt, sockaddr_in6 addr,
    uv_udp_send_cb send_cb);

/*
 * Receive data. If the socket has not previously been bound with `uv_udp_bind`
 * or `uv_udp_bind6`, it is bound to 0.0.0.0 (the "all interfaces" address)
 * and a random port number.
 *
 * Arguments:
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *  alloc_cb  Callback to invoke when temporary storage is needed.
 *  recv_cb   Callback to invoke with received data.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_recv_start(uv_udp_t* handle, uv_alloc_cb alloc_cb,
    uv_udp_recv_cb recv_cb);

/*
 * Stop listening for incoming datagrams.
 *
 * Arguments:
 *  handle    UDP handle. Should have been initialized with `uv_udp_init`.
 *
 * Returns:
 *  0 on success, -1 on error.
 */
int uv_udp_recv_stop(uv_udp_t* handle);


/*
 * uv_tty_t is a subclass of uv_stream_t
 *
 * Representing a stream for the console.
 */
struct uv_tty_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_STREAM_FIELDS;
  mixin UV_TTY_PRIVATE_FIELDS;
};

/*
 * Initialize a new TTY stream with the given file descriptor. Usually the
 * file descriptor will be
 *   0 = stdin
 *   1 = stdout
 *   2 = stderr
 * The last argument, readable, specifies if you plan on calling
 * uv_read_start with this stream. stdin is readable, stdout is not.
 *
 * TTY streams which are not readable have blocking writes.
 */
int uv_tty_init(uv_loop_t*, uv_tty_t*, uv_file fd, int readable);

/*
 * Set mode. 0 for normal, 1 for raw.
 */
int uv_tty_set_mode(uv_tty_t*, int mode);

/*
 * To be called when the program exits. Resets TTY settings to default
 * values for the next process to take over.
 */
void uv_tty_reset_mode();

/*
 * Gets the current Window size. On success zero is returned.
 */
int uv_tty_get_winsize(uv_tty_t*, int* width, int* height);

/*
 * Used to detect what type of stream should be used with a given file
 * descriptor. Usually this will be used during initialization to guess the
 * type of the stdio streams.
 * For isatty() functionality use this function and test for UV_TTY.
 */
uv_handle_type uv_guess_handle(uv_file file);


/*
 * uv_pipe_t is a subclass of uv_stream_t
 *
 * Representing a pipe stream or pipe server. On Windows this is a Named
 * Pipe. On Unix this is a UNIX domain socket.
 */
struct uv_pipe_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_STREAM_FIELDS;
  mixin UV_PIPE_PRIVATE_FIELDS;
  int ipc; /* non-zero if this pipe is used for passing handles */
};

/*
 * Initialize a pipe. The last argument is a boolean to indicate if
 * this pipe will be used for handle passing between processes.
 */
int uv_pipe_init(uv_loop_t*, uv_pipe_t* handle, int ipc);

/*
 * Opens an existing file descriptor or HANDLE as a pipe.
 */
void uv_pipe_open(uv_pipe_t*, uv_file file);

int uv_pipe_bind(uv_pipe_t* handle, const char* name);

void uv_pipe_connect(uv_connect_t* req, uv_pipe_t* handle,
    const char* name, uv_connect_cb cb);

/*
 * This setting applies to Windows only.
 * Set the number of pending pipe instance handles when the pipe server
 * is waiting for connections.
 */
void uv_pipe_pending_instances(uv_pipe_t* handle, int count);

/*
 * uv_prepare_t is a subclass of uv_handle_t.
 *
 * libev wrapper. Every active prepare handle gets its callback called
 * exactly once per loop iteration, just before the system blocks to wait
 * for completed i/o.
 */
struct uv_prepare_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_PREPARE_PRIVATE_FIELDS;
};

int uv_prepare_init(uv_loop_t*, uv_prepare_t* prepare);

int uv_prepare_start(uv_prepare_t* prepare, uv_prepare_cb cb);

int uv_prepare_stop(uv_prepare_t* prepare);

/*
 * uv_check_t is a subclass of uv_handle_t.
 *
 * libev wrapper. Every active check handle gets its callback called exactly
 * once per loop iteration, just after the system returns from blocking.
 */
struct uv_check_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_CHECK_PRIVATE_FIELDS;
};

int uv_check_init(uv_loop_t*, uv_check_t* check);

int uv_check_start(uv_check_t* check, uv_check_cb cb);

int uv_check_stop(uv_check_t* check);

/*
 * uv_idle_t is a subclass of uv_handle_t.
 *
 * libev wrapper. Every active idle handle gets its callback called
 * repeatedly until it is stopped. This happens after all other types of
 * callbacks are processed.  When there are multiple "idle" handles active,
 * their callbacks are called in turn.
 */
struct uv_idle_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_IDLE_PRIVATE_FIELDS;
};

int uv_idle_init(uv_loop_t*, uv_idle_t* idle);

int uv_idle_start(uv_idle_t* idle, uv_idle_cb cb);

int uv_idle_stop(uv_idle_t* idle);

/*
 * uv_async_t is a subclass of uv_handle_t.
 *
 * libev wrapper. uv_async_send wakes up the event
 * loop and calls the async handle's callback There is no guarantee that
 * every uv_async_send call leads to exactly one invocation of the callback;
 * The only guarantee is that the callback function is  called at least once
 * after the call to async_send. Unlike all other libuv functions,
 * uv_async_send can be called from another thread.
 */
struct uv_async_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_ASYNC_PRIVATE_FIELDS;
};

int uv_async_init(uv_loop_t*, uv_async_t* async,
    uv_async_cb async_cb);

/*
 * This can be called from other threads to wake up a libuv thread.
 *
 * libuv is single threaded at the moment.
 */
int uv_async_send(uv_async_t* async);

/*
 * uv_timer_t is a subclass of uv_handle_t.
 *
 * Wraps libev's ev_timer watcher. Used to get woken up at a specified time
 * in the future.
 */
struct uv_timer_s {
  mixin UV_HANDLE_FIELDS;
  mixin UV_TIMER_PRIVATE_FIELDS;
};

int uv_timer_init(uv_loop_t*, uv_timer_t* timer);

int uv_timer_start(uv_timer_t* timer, uv_timer_cb cb,
    int64_t timeout, int64_t repeat);

int uv_timer_stop(uv_timer_t* timer);

/*
 * Stop the timer, and if it is repeating restart it using the repeat value
 * as the timeout. If the timer has never been started before it returns -1 and
 * sets the error to UV_EINVAL.
 */
int uv_timer_again(uv_timer_t* timer);

/*
 * Set the repeat value. Note that if the repeat value is set from a timer
 * callback it does not immediately take effect. If the timer was non-repeating
 * before, it will have been stopped. If it was repeating, then the old repeat
 * value will have been used to schedule the next timeout.
 */
void uv_timer_set_repeat(uv_timer_t* timer, int64_t repeat);

int64_t uv_timer_get_repeat(uv_timer_t* timer);


/* c-ares integration initialize and terminate */
int uv_ares_init_options(uv_loop_t*,
    ares_channel *channelptr, ares_options *options, int optmask);

/* TODO remove the loop argument from this function? */
void uv_ares_destroy(uv_loop_t*, ares_channel channel);

/*
 * uv_getaddrinfo_t is a subclass of uv_req_t
 *
 * Request object for uv_getaddrinfo.
 */
struct uv_getaddrinfo_s {
  mixin UV_REQ_FIELDS;
  /* read-only */
  uv_loop_t* loop;
  mixin UV_GETADDRINFO_PRIVATE_FIELDS;
};

/*
 * Asynchronous getaddrinfo(3).
 *
 * Return code 0 means that request is accepted and callback will be called
 * with result. Other return codes mean that there will not be a callback.
 * Input arguments may be released after return from this call.
 *
 * uv_freeaddrinfo() must be called after completion to free the addrinfo
 * structure.
 *
 * On error NXDOMAIN the status code will be non-zero and UV_ENOENT returned.
 */
int uv_getaddrinfo(uv_loop_t*, uv_getaddrinfo_t* handle,
    uv_getaddrinfo_cb getaddrinfo_cb, const char* node, const char* service,
    const addrinfo* hints);

void uv_freeaddrinfo(addrinfo* ai);

/* uv_spawn() options */
struct uv_process_options_t {
  uv_exit_cb exit_cb; /* Called after the process exits. */
  const char* file; /* Path to program to execute. */
  /*
   * Command line arguments. args[0] should be the path to the program. On
   * Windows this uses CreateProcess which concatenates the arguments into a
   * string this can cause some strange errors. See the note at
   * windows_verbatim_arguments.
   */
  char** args;
  /*
   * This will be set as the environ variable in the subprocess. If this is
   * NULL then the parents environ will be used.
   */
  char** env;
  /*
   * If non-null this represents a directory the subprocess should execute
   * in. Stands for current working directory.
   */
  char* cwd;

  /*
   * TODO describe how this works.
   */
  int windows_verbatim_arguments;

  /*
   * The user should supply pointers to initialized uv_pipe_t structs for
   * stdio. This is used to to send or receive input from the subprocess.
   * The user is responsible for calling uv_close on them.
   */
  uv_pipe_t* stdin_stream;
  uv_pipe_t* stdout_stream;
  uv_pipe_t* stderr_stream;
};

/*
 * uv_process_t is a subclass of uv_handle_t
 */
struct uv_process_s {
  mixin UV_HANDLE_FIELDS;
  uv_exit_cb exit_cb;
  int pid;
  mixin UV_PROCESS_PRIVATE_FIELDS;
};

/* Initializes uv_process_t and starts the process. */
int uv_spawn(uv_loop_t*, uv_process_t*,
    uv_process_options_t options);

/*
 * Kills the process with the specified signal. The user must still
 * call uv_close on the process.
 */
int uv_process_kill(uv_process_t*, int signum);


/* Kills the process with the specified signal. */
uv_err_t uv_kill(int pid, int signum);

/*
 * uv_work_t is a subclass of uv_req_t
 */
struct uv_work_s {
  mixin UV_REQ_FIELDS;
  uv_loop_t* loop;
  uv_work_cb work_cb;
  uv_after_work_cb after_work_cb;
  mixin UV_WORK_PRIVATE_FIELDS;
};

/* Queues a work request to execute asynchronously on the thread pool. */
int uv_queue_work(uv_loop_t* loop, uv_work_t* req,
    uv_work_cb work_cb, uv_after_work_cb after_work_cb);


struct uv_cpu_info_s {
  char* model;
  int speed;
  struct uv_cpu_times_s {
    uint64_t user;
    uint64_t nice;
    uint64_t sys;
    uint64_t idle;
    uint64_t irq;
  };
};

struct uv_interface_address_s {
  char* name;
  int is_internal;
  union address {
    sockaddr_in address4;
    sockaddr_in6 address6;
  };
};

char** uv_setup_args(int argc, char** argv);
uv_err_t uv_get_process_title(char* buffer, size_t size);
uv_err_t uv_set_process_title(const char* title);
uv_err_t uv_resident_set_memory(size_t* rss);
uv_err_t uv_uptime(double* uptime);

/*
 * This allocates cpu_infos array, and sets count.  The array
 * is freed using uv_free_cpu_info().
 */
uv_err_t uv_cpu_info(uv_cpu_info_t** cpu_infos, int* count);
void uv_free_cpu_info(uv_cpu_info_t* cpu_infos, int count);

/*
 * This allocates addresses array, and sets count.  The array
 * is freed using uv_free_interface_addresses().
 */
uv_err_t uv_interface_addresses(uv_interface_address_t** addresses,
  int* count);
void uv_free_interface_addresses(uv_interface_address_t* addresses,
  int count);

/*
 * File System Methods.
 *
 * The uv_fs_* functions execute a blocking system call asynchronously (in a
 * thread pool) and call the specified callback in the specified loop after
 * completion. If the user gives NULL as the callback the blocking system
 * call will be called synchronously. req should be a pointer to an
 * uninitialized uv_fs_t object.
 *
 * uv_fs_req_cleanup() must be called after completion of the uv_fs_
 * function to free any internal memory allocations associated with the
 * request.
 */

enum uv_fs_type {
  UV_FS_UNKNOWN = -1,
  UV_FS_CUSTOM,
  UV_FS_OPEN,
  UV_FS_CLOSE,
  UV_FS_READ,
  UV_FS_WRITE,
  UV_FS_SENDFILE,
  UV_FS_STAT,
  UV_FS_LSTAT,
  UV_FS_FSTAT,
  UV_FS_FTRUNCATE,
  UV_FS_UTIME,
  UV_FS_FUTIME,
  UV_FS_CHMOD,
  UV_FS_FCHMOD,
  UV_FS_FSYNC,
  UV_FS_FDATASYNC,
  UV_FS_UNLINK,
  UV_FS_RMDIR,
  UV_FS_MKDIR,
  UV_FS_RENAME,
  UV_FS_READDIR,
  UV_FS_LINK,
  UV_FS_SYMLINK,
  UV_FS_READLINK,
  UV_FS_CHOWN,
  UV_FS_FCHOWN
};

/* uv_fs_t is a subclass of uv_req_t */
struct uv_fs_s {
  mixin UV_REQ_FIELDS;
  uv_loop_t* loop;
  uv_fs_type fs_type;
  uv_fs_cb cb;
  ssize_t result;
  void* ptr;
  char* path;
  int errorno;
  mixin UV_FS_PRIVATE_FIELDS;
};

void uv_fs_req_cleanup(uv_fs_t* req);

int uv_fs_close(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

int uv_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int flags, int mode, uv_fs_cb cb);

int uv_fs_read(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    void* buf, size_t length, off_t offset, uv_fs_cb cb);

int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

int uv_fs_write(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    void* buf, size_t length, off_t offset, uv_fs_cb cb);

int uv_fs_mkdir(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int mode, uv_fs_cb cb);

int uv_fs_rmdir(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

int uv_fs_readdir(uv_loop_t* loop, uv_fs_t* req,
    const char* path, int flags, uv_fs_cb cb);

int uv_fs_stat(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

int uv_fs_fstat(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

int uv_fs_rename(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, uv_fs_cb cb);

int uv_fs_fsync(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

int uv_fs_fdatasync(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    uv_fs_cb cb);

int uv_fs_ftruncate(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    off_t offset, uv_fs_cb cb);

int uv_fs_sendfile(uv_loop_t* loop, uv_fs_t* req, uv_file out_fd,
    uv_file in_fd, off_t in_offset, size_t length, uv_fs_cb cb);

int uv_fs_chmod(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int mode, uv_fs_cb cb);

int uv_fs_utime(uv_loop_t* loop, uv_fs_t* req, const char* path,
    double atime, double mtime, uv_fs_cb cb);

int uv_fs_futime(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    double atime, double mtime, uv_fs_cb cb);

int uv_fs_lstat(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

int uv_fs_link(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, uv_fs_cb cb);

/*
 * This flag can be used with uv_fs_symlink on Windows
 * to specify whether path argument points to a directory.
 */
enum UV_FS_SYMLINK_DIR = 0x0001;

int uv_fs_symlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    const char* new_path, int flags, uv_fs_cb cb);

int uv_fs_readlink(uv_loop_t* loop, uv_fs_t* req, const char* path,
    uv_fs_cb cb);

int uv_fs_fchmod(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    int mode, uv_fs_cb cb);

int uv_fs_chown(uv_loop_t* loop, uv_fs_t* req, const char* path,
    int uid, int gid, uv_fs_cb cb);

int uv_fs_fchown(uv_loop_t* loop, uv_fs_t* req, uv_file file,
    int uid, int gid, uv_fs_cb cb);

enum uv_fs_event {
  UV_RENAME = 1,
  UV_CHANGE = 2
};


struct uv_fs_event_s {
  mixin UV_HANDLE_FIELDS;
  char* filename;
  mixin UV_FS_EVENT_PRIVATE_FIELDS;
};

/*
 * Gets load avg
 * See: http://en.wikipedia.org/wiki/Load_(computing)
 * (Returns [0,0,0] for windows and cygwin)
 */
void uv_loadavg(double avg[3]);


/*
 * Flags to be passed to uv_fs_event_init.
 */
enum uv_fs_event_flags {
  /*
   * By default, if the fs event watcher is given a directory name, we will
   * watch for all events in that directory. This flags overrides this behavior
   * and makes fs_event report only changes to the directory entry itself. This
   * flag does not affect individual files watched.
   * This flag is currently not implemented yet on any backend.
   */
 UV_FS_EVENT_WATCH_ENTRY = 1,

  /*
   * By default uv_fs_event will try to use a kernel interface such as inotify
   * or kqueue to detect events. This may not work on remote filesystems such
   * as NFS mounts. This flag makes fs_event fall back to calling stat() on a
   * regular interval.
   * This flag is currently not implemented yet on any backend.
   */
  UV_FS_EVENT_STAT = 2
};


int uv_fs_event_init(uv_loop_t* loop, uv_fs_event_t* handle, const char* filename, uv_fs_event_cb cb, int flags);

/* Utility */

/* Convert string ip addresses to binary structures */
sockaddr_in uv_ip4_addr(const char* ip, int port);
sockaddr_in6 uv_ip6_addr(const char* ip, int port);

/* Convert binary addresses to strings */
int uv_ip4_name(sockaddr_in* src, char* dst, size_t size);
int uv_ip6_name(sockaddr_in6* src, char* dst, size_t size);

/* Gets the executable path */
int uv_exepath(char* buffer, size_t* size);

/* Gets the current working directory */
uv_err_t uv_cwd(char* buffer, size_t size);

/* Changes the current working directory */
uv_err_t uv_chdir(const char* dir);

/* Gets memory info in bytes */
uint64_t uv_get_free_memory();
uint64_t uv_get_total_memory();

/*
 * Returns the current high-resolution real time. This is expressed in
 * nanoseconds. It is relative to an arbitrary time in the past. It is not
 * related to the time of day and therefore not subject to clock drift. The
 * primary use is for measuring performance between intervals.
 *
 * Note not every platform can support nanosecond resolution; however, this
 * value will always be in nanoseconds.
 */
uint64_t uv_hrtime();


/*
 * Opens a shared library. The filename is in utf-8. On success, -1 is returned
 * and the variable pointed by library receives a handle to the library.
 */
uv_err_t uv_dlopen(const char* filename, uv_lib_t* library);
uv_err_t uv_dlclose(uv_lib_t library);

/*
 * Retrieves a data pointer from a dynamic library. It is legal for a symbol to
 * map to NULL.
 */
uv_err_t uv_dlsym(uv_lib_t library, const char* name, void** ptr);

/*
 * Retrieves and frees an error message of dynamic linking loaders.
 */
string uv_dlerror(uv_lib_t library);
void uv_dlerror_free(uv_lib_t library, const char *msg);

/*
 * The mutex functions return 0 on success, -1 on error
 * (unless the return type is void, of course).
 */
int uv_mutex_init(uv_mutex_t* handle);
void uv_mutex_destroy(uv_mutex_t* handle);
void uv_mutex_lock(uv_mutex_t* handle);
int uv_mutex_trylock(uv_mutex_t* handle);
void uv_mutex_unlock(uv_mutex_t* handle);

/*
 * Same goes for the read/write lock functions.
 */
int uv_rwlock_init(uv_rwlock_t* rwlock);
void uv_rwlock_destroy(uv_rwlock_t* rwlock);
void uv_rwlock_rdlock(uv_rwlock_t* rwlock);
int uv_rwlock_tryrdlock(uv_rwlock_t* rwlock);
void uv_rwlock_rdunlock(uv_rwlock_t* rwlock);
void uv_rwlock_wrlock(uv_rwlock_t* rwlock);
int uv_rwlock_trywrlock(uv_rwlock_t* rwlock);
void uv_rwlock_wrunlock(uv_rwlock_t* rwlock);

/* Runs a function once and only once. Concurrent calls to uv_once() with the
 * same guard will block all callers except one (it's unspecified which one).
 * The guard should be initialized statically with the UV_ONCE_INIT macro.
 */
void uv_once(uv_once_t* guard, void function () callback);

int uv_thread_create(uv_thread_t *tid, void function (void*) entry, void *arg);
int uv_thread_join(uv_thread_t *tid);

/* the presence of these unions force similar struct layout */
union uv_any_handle {
  uv_tcp_t tcp;
  uv_pipe_t pipe;
  uv_prepare_t prepare;
  uv_check_t check;
  uv_idle_t idle;
  uv_async_t async;
  uv_timer_t timer;
  uv_getaddrinfo_t getaddrinfo;
  uv_fs_event_t fs_event;
};

union uv_any_req {
  uv_req_t req;
  uv_write_t write;
  uv_connect_t connect;
  uv_shutdown_t shutdown;
  uv_fs_t fs_req;
  uv_work_t work_req;
};


struct uv_counters_s {
  uint64_t eio_init;
  uint64_t req_init;
  uint64_t handle_init;
  uint64_t stream_init;
  uint64_t tcp_init;
  uint64_t udp_init;
  uint64_t pipe_init;
  uint64_t tty_init;
  uint64_t prepare_init;
  uint64_t check_init;
  uint64_t idle_init;
  uint64_t async_init;
  uint64_t timer_init;
  uint64_t process_init;
  uint64_t fs_event_init;
};


struct uv_loop_s {
	// from uv-private/uv-unix.h
	version (Posix) {
		private ares_channel channel;
		private ev_timer timer;
		private eio_channel uv_eio_channel;
		private ev_loop_t* ev;
		version (linux) {
			struct uv__inotify_watchers {
				uv_fs_event_s* rbh_root;
			};
			ev_io inotify_read_watcher;
			int inotify_fd;
		}
	}
	// from uv-private/uv-win.h
	version (Windows) {
		HANDLE iocp;
		int refs;
		int64_t time;
		uv_req_t* pending_reqs_tail;
		uv_handle_t* endgame_handles;
		uv_timer_tree_s timers;
		uv_prepare_t* prepare_handles;
		uv_check_t* check_handles;
		uv_idle_t* idle_handles;
		uv_prepare_t* next_prepare_handle;
		uv_check_t* next_check_handle;
		uv_idle_t* next_idle_handle;
		ares_channel ares_chan;
		int ares_active_sockets;
		uv_timer_t ares_polling_timer;
		uint active_tcp_streams;
		uint active_udp_streams;
	}
  /* list used for ares task handles */
  uv_ares_task_t* uv_ares_handles_;
  /* Various thing for libeio. */
  uv_async_t uv_eio_want_poll_notifier;
  uv_async_t uv_eio_done_poll_notifier;
  uv_idle_t uv_eio_poller;
  /* Diagnostic counters */
  uv_counters_t counters;
  /* The last error */
  uv_err_t last_err;
  /* User data - use this for whatever. */
  void* data;
};
