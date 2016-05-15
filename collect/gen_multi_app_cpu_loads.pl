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
    "/Applications/Firefox.app/Contents/MacOS/firefox",
    "/Applications/Safari.app/Contents/MacOS/Safari",
    "/Applications/Skype.app/Contents/MacOS/Skype",
    "/Applications/iTunes.app/Contents/MacOS/iTunes",
    "/Applications/VLC.app/Contents/MacOS/VLC",
    "/Applications/MPlayerX.app/Contents/MacOS/MPlayerX"
    );
my @program_names = (
    "PowerPoint",
    "Word",
    "Excel",
    "Chrome",
    "Firefox",
    "Safari",
    "Skype",
    "iTunes",
    "VLC",
    "MPlayer"
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
    print "Usage:   ./gen_multi_app_cpu_loads.pl <FileName> <Num Loop> <MobileIP> <MobilePort>", "\n";
    print "Example: ./gen_multi_app_cpu_loads.pl file01 10 192.168.1.102 12345\n";
    exit;
}
my $filename = $ARGV[0];
my $num_loop = $ARGV[1];


#############
# Main starts
#############

open(my $fh1, ">", "$output_dir/$filename.multi_app_time.txt")
    or die "cannot open $output_dir/$filename.multi_app_time.txt";

open(my $fh2, ">", "$output_dir/$filename.multi_app_close_time.txt")
    or die "cannot open $output_dir/$filename.multi_app_close_time.txt";

if ($SocketOpen){
    system("nc $ARGV[2] $ARGV[3] > $output_dir/$filename.multi_mag.txt &");
}

my $std_time = [Time::HiRes::gettimeofday()];
my $loop = $num_loop;
while($loop --) {
    foreach my $pi (0..@programs-2){
        #open two programs at the same time
        my $program = $programs[$pi];
        my $next_program = $programs[$pi+1];


        ## run the program
        my $cmd1 = "$program";
        $cmd1 =~ s/ /\\ /g;
        $cmd1 .= "&";
        print "  $loop/$num_loop: $cmd1\n";
        system($cmd1);


        my $cmd2 = "$next_program";
        $cmd2 =~ s/ /\\ /g;
        $cmd2 .= "&";
        print "  $loop/$num_loop: $cmd2\n";
        system($cmd2);

        ## request time
        my $curr_time = Time::HiRes::tv_interval($std_time);
        print $fh1 "$curr_time,".$program_names[$pi].",".$program_names[$pi+1]."\n";
        print "$curr_time,".$program_names[$pi].",".$program_names[$pi+1]."\n";


        sleep($openItvl);

        ## kill the program
        my $cmd = "ps | grep \"$program\"";
        print "    $cmd\n";
        my $ret = `$cmd`;
        print "$ret\n";

        my @tmp = split(/\s+/, $ret);
        if ($tmp[0] == ''){
            #print "tmp[0]>>>".$tmp[0].">>>"."\n";
            $cmd = "kill -9 ".$tmp[1];
        }
        else{
            $cmd = "kill -9 ".$tmp[0];
        }

        print "    $cmd\n";
        `$cmd`;


        $cmd = "ps | grep \"$next_program\"";
        print "    $cmd\n";
        my $ret = `$cmd`;
        print "$ret\n";

        my @tmp = split(/\s+/, $ret);


        if ($tmp[0] == ''){
            $cmd = "kill -9 ".$tmp[1];
        }
        else{
            $cmd = "kill -9 ".$tmp[0];
        }


        my $curr_time = Time::HiRes::tv_interval($std_time);
        print $fh2 "$curr_time,".$program_names[$pi].",".$program_names[$pi+1]."\n";
        print "$curr_time,".$program_names[$pi].",".$program_names[$pi+1]."\n";
        print "    $cmd\n";

        `$cmd`;

        sleep($closeItvl);
    }
}

close $fh1;
close $fh2;
if ($SocketOpen){
    system("killall -9 nc");
}
