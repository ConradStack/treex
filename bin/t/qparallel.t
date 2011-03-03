#!/usr/bin/perl

use strict;
use warnings;

use Treex::Core::Config;

use Treex::Core::Run;

use Test::More tests => 1;
use Test::Output;

SKIP: {

    skip "because not running on an SGE cluster",1
        if not defined $ENV{SGE_CLUSTER_NAME};

    my $number_of_files = 11;
    my $number_of_jobs = 3;

    foreach my $i (map {sprintf "%02d",$_} (1..$number_of_files)) {
        my $doc = Treex::Core::Document->new();
        $doc->set_attr('description',$i);
        $doc->save("paratest$i.treex");
    }

    my $cmdline_arguments = "-q -p --jobs=$number_of_jobs --cleanup"
        . " Eval document='print \$document->get_attr(q(description))'"
        . " -g 'paratest*.treex'";

    stdout_is( sub { treex $cmdline_arguments },
               (join '',map {sprintf "%02d",$_} (1..$number_of_files)),
               "running parallelized treex on SGE cluster");

    unlink glob "paratest*";
}
