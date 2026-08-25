#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Time::HiRes qw(time usleep);
use Term::ReadKey;

$| = 1;
binmode STDOUT, ":encoding(UTF-8)";

my $TARGET_FPS = 30;
my $FRAME_INTERVAL = 1.0 / $TARGET_FPS;

my @CHARS = (" ", " ", "+", "+", "O", "0", "X", "X", "@");
my @COLOR_ID = (0, 0, 1, 2, 3, 3, 4, 3, 5);
my @COLOR_CODE = (
    "\e[0m",      # 0: reset
    "\e[1;33m",   # 1: bold yellow
    "\e[0;33m",   # 2: yellow
    "\e[0;31m",   # 3: red
    "\e[1;31m",   # 4: bold red
    "\e[1;37m",   # 5: white
);

my $maxchars = 8;
my ($width, $height);
my (@buf1, @buf2);
my ($cur_buf, $next_buf);

sub get_size {
    my ($w, $h);
    {
        local $SIG{__WARN__} = sub {};
        eval { ($w, $h) = GetTerminalSize(*STDOUT); };
        if (!$w || !$h) {
            eval { ($w, $h) = GetTerminalSize(*STDIN); };
        }
    }
    $w ||= $ENV{COLUMNS} || 80;
    $h ||= $ENV{LINES}   || 24;
    return ($w, $h);
}

sub init_buffers {
    ($width, $height) = get_size();

    @buf1 = ();
    @buf2 = ();
    for my $x (0 .. $width) {
        $buf1[$x] = [ (0) x ($height + 1) ];
        $buf2[$x] = [ (0) x ($height + 1) ];
    }
    $cur_buf  = \@buf1;
    $next_buf = \@buf2;
}

sub resize_handler {
    init_buffers();
    print "\e[2J\e[H";
}

$SIG{WINCH} = \&resize_handler;

sub cleanup {
    print "\e[?25h\e[0m";
    eval { local $SIG{__WARN__} = sub {}; ReadMode('normal'); };
}

$SIG{INT}  = sub { cleanup(); exit(0); };
$SIG{TERM} = sub { cleanup(); exit(0); };
END { cleanup(); }

print "\e[?25l";
eval { local $SIG{__WARN__} = sub {}; ReadMode('cbreak'); };

init_buffers();

while (1) {
    my $t_start = time();

    my $key;
    eval {
        local $SIG{__WARN__} = sub {};
        $key = ReadKey(-1);
    };
    last if defined $key and ($key eq 'q' or $key eq 'Q' or ord($key) == 27 or ord($key) == 3);

    my $bottom_y = $height - 2;
    if ($bottom_y > 0) {
        for my $x (0 .. $width - 1) {
            $cur_buf->[$x][$bottom_y] = int(rand($maxchars) + 1);
        }
        $cur_buf->[int(rand($width))][max(0, $bottom_y - int(rand(10)))] = $maxchars;
    }

    for (my $y = 1; $y < $height - 1; $y++) {
        my $target_y = $y - 1;
        for (my $x = 1; $x < $width - 1; $x++) {
            my $sum = $cur_buf->[$x][$y]
                    + $cur_buf->[$x + 1][$y]
                    + $cur_buf->[$x - 1][$y]
                    + $cur_buf->[$x][$y + 1]
                    + $cur_buf->[$x][$y - 1];
            $next_buf->[$x][$target_y] = int($sum / 5 + rand() * 0.35);
        }
    }

    ($cur_buf, $next_buf) = ($next_buf, $cur_buf);

    # State-tracked ANSI rendering (only emits color code on transition)
    my $frame = "\e[H";
    my $last_color = 0;
    for (my $y = 1; $y < $height; $y++) {
        for (my $x = 1; $x < $width; $x++) {
            my $val = $cur_buf->[$x][$y] || 0;
            $val = 8 if $val > 8;
            my $cid = $COLOR_ID[$val];
            if ($cid != $last_color) {
                $frame .= $COLOR_CODE[$cid];
                $last_color = $cid;
            }
            $frame .= $CHARS[$val];
        }
        $frame .= "\n" if $y < $height - 1;
    }
    $frame .= "\e[0m" if $last_color != 0;
    print $frame;

    my $elapsed = time() - $t_start;
    my $sleep_time = $FRAME_INTERVAL - $elapsed;
    if ($sleep_time > 0) {
        usleep($sleep_time * 1_000_000);
    }
}

sub max { $_[0] > $_[1] ? $_[0] : $_[1] }
