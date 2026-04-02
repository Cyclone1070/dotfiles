#!/usr/bin/perl -w

use strict;
use lib "./modules";
use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;
use Term::ReadKey;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
                      clock_gettime clock_getres clock_nanosleep clock
                      stat lstat utime);
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
 
our ($width, $height) = GetTerminalSize ();

our @buf1; our @buf2;
our @chars; our @cols;
our $maxchars=8;
our $maxdots=20;

my $key; # pressed key

# buffer&color init
sub clearbufs { 
  my $x; my $y;
  for ($y=0; $y<=$height; $y++) {
    for ($x=0; $x<=$width; $x++) {
      $buf1[$x][$y]=0;
      $buf2[$x][$y]=0;
    }
  }
  $chars[0]=" "; $cols[0]="black";
  $chars[1]=" "; $cols[1]="black";
  $chars[2]="+"; $cols[2]="bold yellow";
  $chars[3]="+"; $cols[3]="yellow";
  $chars[4]="O"; $cols[4]="red";
  $chars[5]="0"; $cols[5]="red";
  $chars[6]="X"; $cols[6]="bold red";
  $chars[7]="X"; $cols[7]="red";
  $chars[8]="@"; $cols[8]="white";
}

sub copybuf2to1 { @buf1=@buf2; }

# calc buf1 -> buf2
sub calctobuf2 {
  my $y; my $x;
  for ($y=1; $y<$height-1; $y++) {
    for ($x=1; $x<$width-1; $x++) {
      $buf2[$x][$y-1]=int(($buf1[$x][$y]+$buf1[$x+1][$y]+$buf1[$x-1][$y]+$buf1[$x][$y+1]+$buf1[$x][$y-1])/5 + rand()*0.35 ) ;
    }
  }   
}

# put the whole shit to screen
sub buf2toscr {
  my $y; my $x;
  for ($y=1; $y<$height; $y++) {
    for ($x=1; $x<$width; $x++) {
      locate $y,$x; 
      print color ($cols[$buf2[$x][$y]]), $chars[$buf2[$x][$y]], color("reset");
    }
  }   
}

# bottom random pixel line
sub putbottom {
  my $x;
  for ($x=0; $x<$width; $x++) {
    $buf1[$x][$height-2]=int(rand($maxchars)+1);
  }
}

# random bright flying dots
sub putrnddots {
  $buf1[int(rand($width))][$height-2-int(rand(10))]=$maxchars;
}

# main loop

&clearbufs;

while (not defined ($key = ReadKey(-1))) {
  &putbottom;
  &putrnddots;
  &calctobuf2;
  &copybuf2to1;
  &buf2toscr;
  usleep(20000);
}

# perec!
