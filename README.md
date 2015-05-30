# perl hang

I've experienced a hang with my perl program.
Can you tell me why?

## Scenario

1. Assume your program call fork(2) many times.
2. Set Sys::SigAction::timeout_call with your heavy work:

        Sys::SigAction::timeout_call $sec, sub {
            do_heavy_work();
        };

3. Then timeout occurs, and call `Perl_sighandler` with signal 14 (SIGALRM).
4. In `Perl_sighandler`, the followings are called in the order:
  1. `Perl_safesysmalloc`
  1. `malloc`
  1. `_L_lock_9503`
  1. `__lll_lock_wait_private`
5. Sometimes, hang up!

## How to reproduce

Assume you have:

* Linux (Centos6 or Ubuntu14.04)
* gdb
* perl 5.20.2 with `-DDEBUGING=-g`
* Parallel::Prefork, Sys::SigAction

Then

    > perl hang.pl

Please wait for a while (maybe 1hour or more), and check `ps auxwwf`:

```
skaji     3930  0.0  0.2 133096  5200 pts/1    S+   11:19   0:03  |   \_ perl hang.pl
skaji     8916  0.0  0.2 133096  4228 pts/1    S+   11:55   0:00  |       \_ worker (2015-05-30 11:55:17)
skaji    14191 11.4  0.2 133096  4212 pts/1    R+   12:33   0:02  |       \_ worker (2015-05-30 12:33:14)
skaji    14209 10.5  0.2 133096  4212 pts/1    R+   12:33   0:01  |       \_ worker (2015-05-30 12:33:20)
skaji    14210 10.6  0.2 133096  4212 pts/1    R+   12:33   0:01  |       \_ worker (2015-05-30 12:33:20)
```

Then you'll see some workers are alive for a long term.
(In the above case of `ps auxwwf`, the process which have pid 8916)

Normally, a worker must alive only for a few seconds,
so they are in hang!

The back trace of that process is:

```
#0  0x00007fb96b78e05e in __lll_lock_wait_private () from /lib64/libc.so.6
#1  0x00007fb96b71316b in _L_lock_9503 () from /lib64/libc.so.6
#2  0x00007fb96b7106a6 in malloc () from /lib64/libc.so.6
#3  0x000000000048a675 in Perl_safesysmalloc (size=<value optimized out>) at util.c:130
#4  0x00000000004b7a28 in Perl_sv_grow (sv=0x16347b0, newlen=10) at sv.c:1593
#5  0x00000000004b4968 in Perl_sv_setsv_flags (dstr=0x16347b0, sstr=0x1410100, flags=<value optimized out>) at sv.c:4524
#6  0x00000000004b56bd in Perl_newSVsv (old=<value optimized out>) at sv.c:9325
#7  0x0000000000494ff2 in Perl_sighandler (sig=14, sip=0x7fff073c97b0, uap=0x7fff073c9680) at mg.c:3216
#8  <signal handler called>
#9  0x00007fb96b70f17d in _int_malloc () from /lib64/libc.so.6
#10 0x00007fb96b7106b1 in malloc () from /lib64/libc.so.6
#11 0x000000000048a675 in Perl_safesysmalloc (size=<value optimized out>) at util.c:130
#12 0x00000000004a2650 in Perl_av_extend_guts (av=0x1634780, key=6, maxp=0x16cb400, allocp=0x16cb408, arrayp=<value optimized out>) at av.c:176
#13 0x00000000004a2bb8 in Perl_av_store (av=0x1634780, key=6, val=0x1634798) at av.c:345
#14 0x0000000000465abf in Perl_pad_push (padlist=0x16229d0, depth=36) at pad.c:2352
#15 0x00000000004a54aa in Perl_pp_entersub () at pp_hot.c:2671
#16 0x00000000004a36f3 in Perl_runops_standard () at run.c:42
#17 0x0000000000437fbe in S_run_body (my_perl=<value optimized out>) at perl.c:2451
#18 perl_run (my_perl=<value optimized out>) at perl.c:2372
#19 0x000000000041ce5c in main (argc=2, argv=0x7fff073ca0b8, env=0x7fff073ca0d0) at perlmain.c:114
```

Please see [bt-centos.txt](bt-centos.txt) and [bt-ubuntu.txt](bt-ubuntu.txt) for details.

