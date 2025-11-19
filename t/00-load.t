#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

# Test that modules can be loaded
BEGIN {
    use_ok('CheatEngine::Trainer::Packer') || print "Bail out!\n";
    use_ok('CheatEngine::Trainer::Unpacker') || print "Bail out!\n";
}

diag("Testing CheatEngine::Trainer modules");
