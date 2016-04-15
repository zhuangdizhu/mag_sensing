#!/usr/bin/perl

##########################################
## Author: Yi-Chao Chen
##
## - e.g.
##   perl gen_app_cpu_loads.pl 20160328.exp1
##
##########################################

use strict;
use POSIX;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
# use lib "/u/yichao/utils/perl";
# use lib "../utils";
use Time::HiRes qw(gettimeofday tv_interval);


#############
# Debug
#############
my $DEBUG0 = 0;
my $DEBUG1 = 1;
my $DEBUG2 = 1;     ## print progress
my $DEBUG3 = 1;     ## print output
my $SocketOpen = 1; ## use nc to receive socket data


#############
# Constants
#############
my $input_dir  = "";
my $output_dir = "./gen";

my @programs = (
    "/Applications/Microsoft Office 2011/Microsoft PowerPoint.app/Contents/MacOS/Microsoft PowerPoint",
    "/Applications/Microsoft Office 2011/Microsoft Word.app/Contents/MacOS/Microsoft Word",
    "/Applications/Microsoft Office 2011/Microsoft Excel.app/Contents/MacOS/Microsoft Excel",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Skype.app/Contents/MacOS/Skype",
    "/Applications/QuickTime Player.app/Contents/MacOS/QuickTime Player",
    #"/Applications/Safari.app/Contents/MacOS/Safari",
    #"/Applications/iTunes.app/Contents/MacOS/iTunes",
    #"/Applications/OmniGraffle.app/Contents/MacOS/OmniGraffle",
    #"/Applications/TeX/TeXShop.app/Contents/MacOS/TeXShop"
    #"/Applications/VLC.app/Contents/MacOS/VLC",
    #"/Applications/MPlayerX.app/Contents/MacOS/MPlayerX",
    #"/Applications/Firefox.app/Contents/MacOS/firefox",
    );
my @program_names = (
    "PowerPoint",
    "Word",
    "Excel",
    "Chrome",
    "Skype",
    "QuickTimePlayer",
    #"Safari",
    #"iTunes",
    #"OmniGraffle",
    #"Texshop"
    #"MPlayerX"
    #"VLC",
    #"Firefox",
    );

my $openItvl = 8;
my $closeItvl = 2;


#############
# Variables
#############
my $cmd;


#############
# check input
#############
if(@ARGV != 4) {
    print "Usage:   ./gen_app_cpu_loads.pl <FileName> <Num Loop> <MobileIP> <MobilePort>", "\n";
    print "Example: ./gen_app_cpu_loads.pl file01 10 192.168.1.102 12345";
    exit;
}
my $filename = $ARGV[0];
my $num_loop = $ARGV[1];


#############
# Main starts
#############

open FH, "> $output_dir/$filename.app_time.txt" or die $!;

if ($SocketOpen){
    system("nc $ARGV[2] $ARGV[3] > $output_dir/$filename.mag.txt &");
}

my $std_time = [Time::HiRes::gettimeofday()];
my $loop = $num_loop;
while($loop --) {
    foreach my $pi (0..@programs-1){
        my $program = $programs[$pi];
        ## run the program
        $cmd = "$program";
        $cmd =~ s/ /\\ /g;
        $cmd .= "&";
        print "  $loop/$num_loop: $cmd\n";
        system($cmd);

        ## request time
        my $curr_time = Time::HiRes::tv_interval($std_time);
        print FH "$curr_time,".$program_names[$pi]."\n";
        print "$curr_time,".$program_names[$pi]."\n";


        sleep($openItvl);

        ## kill the program
        $cmd = "ps | grep \"$program\"";
        print "    $cmd\n";
        my $ret = `$cmd`;
        print "$ret\n";

        my @tmp = split(/\s+/, $ret);
        print "> ".$tmp[0]."\n";

        $cmd = "kill -9 ".$tmp[0];
        print "    $cmd\n";
        `$cmd`;

        sleep($closeItvl);
    }
}

close FH;
if ($SocketOpen){
    system("killall -9 nc");
}
