#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 12;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use CheatEngine::Trainer::Packer;
use CheatEngine::Trainer::Unpacker;

# Create a temporary directory for test files
my $temp_dir = tempdir(CLEANUP => 1);

# Read the sample fixture
my $fixture_file = 't/fixtures/sample.xml';
ok(-f $fixture_file, 'Sample fixture file exists');

open my $fh, '<:raw', $fixture_file or die "Cannot read fixture: $!";
my $original_xml = do { local $/; <$fh> };
close $fh;

ok(length($original_xml) > 0, 'Fixture has content');
like($original_xml, qr/^<\?xml/, 'Fixture is XML');

# Test 1: Write encrypted file (old method)
my $encrypted_file_old = File::Spec->catfile($temp_dir, 'test_old.CETRAINER');
my $encrypted_data_old = CheatEngine::Trainer::Packer::encrypt($original_xml, 0);

open my $out_fh, '>:raw', $encrypted_file_old or die "Cannot write: $!";
print $out_fh $encrypted_data_old;
close $out_fh;

ok(-f $encrypted_file_old, 'Encrypted file (old method) was created');

# Test 2: Read and decrypt the file (old method)
open my $in_fh, '<:raw', $encrypted_file_old or die "Cannot read: $!";
my $read_encrypted_old = do { local $/; <$in_fh> };
close $in_fh;

my $decrypted_old = CheatEngine::Trainer::Unpacker::decrypt($read_encrypted_old);
is($decrypted_old, $original_xml, 'File round-trip works (old method)');

# Test 3: Write encrypted file (new method)
my $encrypted_file_new = File::Spec->catfile($temp_dir, 'test_new.CETRAINER');
my $encrypted_data_new = CheatEngine::Trainer::Packer::encrypt($original_xml, 1);

open $out_fh, '>:raw', $encrypted_file_new or die "Cannot write: $!";
print $out_fh $encrypted_data_new;
close $out_fh;

ok(-f $encrypted_file_new, 'Encrypted file (new method) was created');

# Test 4: Read and decrypt the file (new method)
open $in_fh, '<:raw', $encrypted_file_new or die "Cannot read: $!";
my $read_encrypted_new = do { local $/; <$in_fh> };
close $in_fh;

my $decrypted_new = CheatEngine::Trainer::Unpacker::decrypt($read_encrypted_new);
is($decrypted_new, $original_xml, 'File round-trip works (new method)');

# Test 5: Verify file sizes (encrypted should be smaller due to compression for this data)
my $original_size = length($original_xml);
my $encrypted_size_old = -s $encrypted_file_old;
my $encrypted_size_new = -s $encrypted_file_new;

ok($encrypted_size_old < $original_size, 'Old method compression reduces file size');
ok($encrypted_size_new < $original_size, 'New method compression reduces file size');

# Test 6: Write plain XML and verify decrypt is idempotent
my $plain_file = File::Spec->catfile($temp_dir, 'plain.xml');
open $out_fh, '>:raw', $plain_file or die "Cannot write: $!";
print $out_fh $original_xml;
close $out_fh;

open $in_fh, '<:raw', $plain_file or die "Cannot read: $!";
my $read_plain = do { local $/; <$in_fh> };
close $in_fh;

my $decrypted_plain = CheatEngine::Trainer::Unpacker::decrypt($read_plain);
is($decrypted_plain, $original_xml, 'Plain XML file passes through decrypt unchanged');

# Test 7: Binary safety - ensure no data corruption
my $binary_test = CheatEngine::Trainer::Packer::encrypt($original_xml, 0);
ok(length($binary_test) > 0, 'Encrypted data is not empty');

my $binary_round_trip = CheatEngine::Trainer::Unpacker::decrypt($binary_test);
is($binary_round_trip, $original_xml, 'Binary data remains intact through round-trip');

done_testing();
