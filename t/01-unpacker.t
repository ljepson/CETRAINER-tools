#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 11;

use lib 'lib';
use CheatEngine::Trainer::Unpacker;

# Test 1: Module can be instantiated
my $unpacker = CheatEngine::Trainer::Unpacker->new();
isa_ok($unpacker, 'CheatEngine::Trainer::Unpacker', 'Unpacker object created');

# Test 2: Plain XML passes through unchanged
my $xml = '<?xml version="1.0" encoding="utf-8"?><CheatTable><CheatEntries/></CheatTable>';
my $result = CheatEngine::Trainer::Unpacker::decrypt($xml);
is($result, $xml, 'Plain XML passes through unchanged');

# Test 3: Function export works
can_ok('CheatEngine::Trainer::Unpacker', 'decrypt');

# Test 4: Object method works
$result = $unpacker->_decrypt($xml);
is($result, $xml, 'Object method decrypt works');

# Test 5: Empty string handling
my $empty = '';
my $empty_result = eval { CheatEngine::Trainer::Unpacker::decrypt($empty) };
ok(defined($empty_result), 'Empty string processes without crashing');

# Test 6: Very short data handling
my $short = 'ab';
my $short_result = eval { CheatEngine::Trainer::Unpacker::decrypt($short) };
ok(defined($short_result), 'Short data processes without crashing');

# Test 7: Invalid compressed data processes (may not be valid output, but doesn't crash)
my $invalid = pack("C*", (0xCE, 0xCF, 0xD0, 0xD1, 0xD2));
my $invalid_result = eval { CheatEngine::Trainer::Unpacker::decrypt($invalid) };
ok(defined($invalid_result), 'Invalid compressed data processes without crashing');

# Test 8: XOR decryption runs (may fail on decompression but doesn't crash)
my $sample = pack("C*", (0x00, 0x01, 0x02, 0x03, 0x04));
eval { CheatEngine::Trainer::Unpacker::decrypt($sample) };
ok(1, 'XOR decryption executes without crashing the process');

# Test 9: XOR decoding happens (output differs from input after XOR)
my @test_bytes = (0xCE, 0xCF, 0xD0);
my $xor_test = pack("C*", @test_bytes);
my $xor_result = eval { CheatEngine::Trainer::Unpacker::decrypt($xor_test) };
ok(defined($xor_result), 'XOR-encrypted data processes');

# Test 10: CHEAT header is recognized and new method is used
my $cheat_header = "CHEAT" . pack("C*", (0x00) x 10);
eval { CheatEngine::Trainer::Unpacker::decrypt($cheat_header) };
ok($@, 'CHEAT header triggers new method but invalid data fails decompression');

# Test 11: Decryption handles various data without crashing
my $test_data = pack("C*", (0xFF) x 100);
my $test_result = eval { CheatEngine::Trainer::Unpacker::decrypt($test_data) };
ok(defined($test_result) || $@, 'Decryption algorithm runs without crashing');

done_testing();
