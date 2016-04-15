#!/bin/perl

##########################################
## Author: Yi-Chao Chen
##
## - input:
##
## - output:
##
## - e.g.
##   
##
##########################################

use strict;
use POSIX;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use Time::HiRes qw(gettimeofday tv_interval);


#############
# Debug
#############
my $DEBUG0 = 0;
my $DEBUG1 = 1;
my $DEBUG2 = 1; ## print progress
my $DEBUG3 = 1; ## print output


#############
# Constants
#############
my $input_dir  = "";
my $output_dir = "./gen";

my @webs = ("http://www.cs.utexas.edu/", 
            "http://www.amazon.com", 
            "http://www.apple.com",
            "http://www.cnn.com",
            # "http://www.nytimes.com",
            "https://www.facebook.com",
            "https://www.wikipedia.org",
            "https://www.yahoo.com",
            "http://www.ebay.com",
            "http://www.bing.com",
            "https://twitter.com", 
            "http://www.msn.com", 
            "https://www.linkedin.com/",
            "https://www.pinterest.com/",
            "https://wordpress.com/",
            "https://www.google.com", 
            "https://www.youtube.com/");

my $num_loop = 10;
my $itvl = 5;

#############
# Variables
#############
my $cmd;


#############
# check input
#############
if(@ARGV != 1) {
    print "wrong number of input: ".@ARGV."\n";
    exit;
}
my $filename = $ARGV[0];


#############
# Main starts
#############

open FH, "> $output_dir/$filename" or die $!;
my $std_time = [Time::HiRes::gettimeofday()];

my $loop = $num_loop;
while($loop --) {
    foreach my $web (@webs) {
        my $curl = "curl";
        if($web =~ /https/) {
            $curl .= " -k";
        }

        ## request time
        my $curr_time = Time::HiRes::tv_interval($std_time);
        print FH "$curr_time,$web\n";

        ## send request
        $cmd = "$curl $web";
        print "$loop/$num_loop: $cmd\n";
        my $rcv = `$cmd`;
        print "  rcv bytes=".length($cmd)."\n";

        ## sleep
        # my $wait = $itvl;
        # while($wait--) {
        #     print "    sleep $wait\n";
        #     sleep(1);
        # }
        sleep($itvl);
    }
}

close FH;
