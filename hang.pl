#!/usr/bin/env perl
use 5.14.0;
use warnings;
use utf8;

package Worker {
    use Sys::SigAction 'timeout_call';
    sub new { bless {}, shift }
    sub work {
        my $self = shift;
        for (1..10) {
            my $sec = rand(3);
            timeout_call $sec, sub { fib(50) };
        }
    }
    sub fib {
        my $n = shift;
        if ($n == 0 || $n == 1) {
            return 1;
        } else {
            return fib($n-2) + fib($n-1);
        }
    }
}

use Parallel::Prefork;
use POSIX qw(strftime);

my $pm = Parallel::Prefork->new(
    max_workers => 30, trap_signals => {TERM => 'TERM'},
);

while ($pm->signal_received ne 'TERM') {
    $pm->start and next;
    $0 = strftime("worker (%F %T)", localtime);
    Worker->new->work;
    $pm->finish(0);
}

$pm->wait_all_children;
