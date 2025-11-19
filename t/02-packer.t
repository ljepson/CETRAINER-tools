#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;

use lib 'lib';
use CheatEngine::Trainer::Packer;

# Test 1: Module can be instantiated
my $packer = CheatEngine::Trainer::Packer->new();
isa_ok($packer, 'CheatEngine::Trainer::Packer', 'Packer object created');

# Test 2: Function export works
can_ok('CheatEngine::Trainer::Packer', 'encrypt');

# Test data
my $xml = '<?xml version="1.0" encoding="utf-8"?><CheatTable><CheatEntries/></CheatTable>';

# Test 3: Old method encryption produces output
my $encrypted_old;
eval { $encrypted_old = CheatEngine::Trainer::Packer::encrypt($xml, 0) };
ok(!$@ && defined($encrypted_old), 'Old method encryption succeeds');

# Test 4: Old method output is different from input
isnt($encrypted_old, $xml, 'Old method produces encrypted output');

# Test 5: Old method output doesn't start with <?xml
unlike($encrypted_old, qr/^<\?xml/, 'Old method output is not plain XML');

# Test 6: Old method output doesn't have plain CHEAT header (it's encrypted)
unlike($encrypted_old, qr/^CHEAT/, 'Old method does not include CHEAT header');

# Test 7: New method encryption produces output
my $encrypted_new;
eval { $encrypted_new = CheatEngine::Trainer::Packer::encrypt($xml, 1) };
ok(!$@ && defined($encrypted_new), 'New method encryption succeeds');

# Test 8: New method output is different from input
isnt($encrypted_new, $xml, 'New method produces encrypted output');

# Test 9: New method output doesn't start with <?xml
unlike($encrypted_new, qr/^<\?xml/, 'New method output is not plain XML');

# Test 10: Old and new methods produce different output
isnt($encrypted_old, $encrypted_new, 'Old and new methods produce different output');

# Test 11: Object method works
my $encrypted_obj;
eval { $encrypted_obj = $packer->_encrypt($xml, 0) };
ok(!$@ && defined($encrypted_obj), 'Object method encrypt works');

# Test 12: Non-XML data should pass through or be detected
my $non_xml = 'This is not XML';
my $result = CheatEngine::Trainer::Packer::encrypt($non_xml);
is($result, $non_xml, 'Non-XML data passes through unchanged');

# Test 13: Empty XML handling
my $empty_xml = '<?xml version="1.0"?><root/>';
my $empty_encrypted;
eval { $empty_encrypted = CheatEngine::Trainer::Packer::encrypt($empty_xml) };
ok(!$@ && defined($empty_encrypted), 'Empty XML element encrypts without error');

# Test 14: Default parameter (should use old method)
my $default_encrypted;
eval { $default_encrypted = CheatEngine::Trainer::Packer::encrypt($xml) };
ok(!$@ && defined($default_encrypted), 'Default method parameter works');

done_testing();
