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

my @appNames = (
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

my %appPath = (
    "PowerPoint" => "/Applications/Microsoft Office 2011/Microsoft PowerPoint.app/Contents/MacOS/Microsoft PowerPoint", 
    "Word" => "/Applications/Microsoft Office 2011/Microsoft Word.app/Contents/MacOS/Microsoft Word",
    "Excel" => "/Applications/Microsoft Office 2011/Microsoft Excel.app/Contents/MacOS/Microsoft Excel",
    "Chrome" => "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "Skype" => "/Applications/Skype.app/Contents/MacOS/Skype",
    "QuickTimePlayer" => "/Applications/QuickTime Player.app/Contents/MacOS/QuickTime Player"
);


my %appCount = (
    "PowerPoint" => 0,
    "Word" => 0,
    "Excel" => 0,
    "Chrome" => 0,
    "Skype" => 0,
    "QuickTimePlayer" => 0

);

my $openItvl = 6;
my $closeItvl = 2;
my $fileItvl = 2;
my $std_time = [Time::HiRes::gettimeofday()];


#############
# Variables
#############
my $cmd;


#############
# Functions
#############
sub open_app {
    #Argument: appName, fileName, sensorIP, sensorPort 
    my $app_name = $_[0];
    my $file_name = $_[1];
    my $sensor_ip = $_[2];
    my $sensor_port = $_[3]; 

    my $app_path = $appPath{$app_name};
    my $cmd = "$app_path";
    $cmd =~ s/ /\\ /g;
    $cmd .= "&";

    #receive the sensorlog data
    my $app_count = $appCount{$app_name}+1;
    $appCount{$app_name} = $app_count;

    if ($SocketOpen){
        if ($app_count == 1){
            # open a new file and write from the begining
            system("nc $ARGV[2] $ARGV[3] > $output_dir/${file_name}_${app_name}.mag.txt &");
        } 
        else {
            system("nc $ARGV[2] $ARGV[3] >> $output_dir/${file_name}_${app_name}.mag.txt &");
        }
    }


    #run the application
    system($cmd);

    #sleep for a while
    sleep($openItvl);

    #stop logging to the file 
    if ($SocketOpen){
        system("killall -9 nc");
    }

    ## kill the application

    $cmd = "ps | grep \"$app_path\"";
    print "    $cmd\n";
    my $ret = `$cmd`;
    print "$ret\n";
    my @tmp = split(/\s+/, $ret);
    print "> ".$tmp[0]."\n";
    $cmd = "kill -9 ".$tmp[0];
    print "    $cmd\n";
    `$cmd`;

    #tag the count number and label to the file
    $cmd = "echo \"Count,$app_count,Label,$app_name\" >> $output_dir/${file_name}_${app_name}.mag.txt";
    system($cmd);

    #sleep for a while
    sleep($closeItvl);
}



#############
# check input
#############
if(@ARGV != 4) {
    print "Usage:   ./gen_app_cpu_loads.pl <FileName> <Num Loop> <MobileIP> <MobilePort>", "\n";
    print "Example: ./gen_app_cpu_loads.pl file01 10 192.168.1.102 12345\n";
    exit;
}
my $filename = $ARGV[0];
my $num_loop = $ARGV[1];
my $sensorIp = $ARGV[2];
my $sensorPort = $ARGV[3];


#############
# Main starts
#############

open FH, "> $output_dir/$filename.app_time.txt" or die $!;

foreach my $pi (0..@appNames-1){
    my $appName = $appNames[$pi];

    ## open the app. Parameters: appName, fileName, sensorIP, sensorPort 
    my $loop = $num_loop;
    while ($loop --){
        ## request time
        my $curr_time = Time::HiRes::tv_interval($std_time);
        print FH "$curr_time,".$appName."\n";
        print "$curr_time,".$appName."\n";
    
        open_app($appName, $filename, $sensorIp, $sensorPort);
    }
}

close FH;
