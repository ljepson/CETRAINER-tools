#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 'lib';
use CheatEngine::Trainer::Packer;
use CheatEngine::Trainer::Unpacker;

# Simple XML test data
my $simple_xml = '<?xml version="1.0" encoding="utf-8"?><CheatTable><CheatEntries/></CheatTable>';

# Test 1-2: Old method round-trip
my $encrypted_old = CheatEngine::Trainer::Packer::encrypt($simple_xml, 0);
my $decrypted_old = CheatEngine::Trainer::Unpacker::decrypt($encrypted_old);
is($decrypted_old, $simple_xml, 'Old method: encrypt then decrypt returns original');
ok($encrypted_old ne $simple_xml, 'Old method: data was actually encrypted');

# Test 3-4: New method round-trip
my $encrypted_new = CheatEngine::Trainer::Packer::encrypt($simple_xml, 1);
my $decrypted_new = CheatEngine::Trainer::Unpacker::decrypt($encrypted_new);
is($decrypted_new, $simple_xml, 'New method: encrypt then decrypt returns original');
ok($encrypted_new ne $simple_xml, 'New method: data was actually encrypted');

# Test 5: Complex XML with attributes and nested elements
my $complex_xml = '<?xml version="1.0"?>' . "\n" .
    '<CheatTable CheatEngineTableVersion="42">' . "\n" .
    '  <CheatEntries>' . "\n" .
    '    <CheatEntry>' . "\n" .
    '      <ID>0</ID>' . "\n" .
    '      <Description>"Test Cheat"</Description>' . "\n" .
    '      <VariableType>4 Bytes</VariableType>' . "\n" .
    '      <Address>12345678</Address>' . "\n" .
    '    </CheatEntry>' . "\n" .
    '  </CheatEntries>' . "\n" .
    '</CheatTable>';

my $encrypted_complex = CheatEngine::Trainer::Packer::encrypt($complex_xml, 0);
my $decrypted_complex = CheatEngine::Trainer::Unpacker::decrypt($encrypted_complex);
is($decrypted_complex, $complex_xml, 'Complex XML survives round-trip (old method)');

# Test 6: Complex XML with new method
$encrypted_complex = CheatEngine::Trainer::Packer::encrypt($complex_xml, 1);
$decrypted_complex = CheatEngine::Trainer::Unpacker::decrypt($encrypted_complex);
is($decrypted_complex, $complex_xml, 'Complex XML survives round-trip (new method)');

# Test 7: XML with special characters
my $special_xml = '<?xml version="1.0"?><root attr="&lt;&gt;&amp;&quot;">Special &amp; chars</root>';
my $encrypted_special = CheatEngine::Trainer::Packer::encrypt($special_xml, 0);
my $decrypted_special = CheatEngine::Trainer::Unpacker::decrypt($encrypted_special);
is($decrypted_special, $special_xml, 'XML with special characters survives round-trip');

# Test 8: Large XML (test compression efficiency)
my $large_xml = '<?xml version="1.0"?><CheatTable>' . ('<CheatEntry><ID>1</ID></CheatEntry>' x 100) . '</CheatTable>';
my $encrypted_large = CheatEngine::Trainer::Packer::encrypt($large_xml, 0);
my $decrypted_large = CheatEngine::Trainer::Unpacker::decrypt($encrypted_large);
is($decrypted_large, $large_xml, 'Large XML survives round-trip');
ok(length($encrypted_large) < length($large_xml), 'Compression reduces size for large repetitive data');

# Test 9: Multiple round-trips (encrypt, decrypt, encrypt, decrypt)
my $twice_encrypted = CheatEngine::Trainer::Packer::encrypt(
    CheatEngine::Trainer::Unpacker::decrypt(
        CheatEngine::Trainer::Packer::encrypt($simple_xml, 0)
    ), 0
);
my $twice_decrypted = CheatEngine::Trainer::Unpacker::decrypt($twice_encrypted);
is($twice_decrypted, $simple_xml, 'Multiple round-trips maintain data integrity');

# Test 10: Verify unpacker handles old format correctly (auto-detects format)
# Both methods should still work for decryption since unpacker auto-detects
my $old_encrypted = CheatEngine::Trainer::Packer::encrypt($simple_xml, 0);
my $old_to_new = CheatEngine::Trainer::Unpacker::decrypt($old_encrypted);
is($old_to_new, $simple_xml, 'Unpacker handles old method correctly');

# Test 11: Verify unpacker handles new method
my $new_encrypted = CheatEngine::Trainer::Packer::encrypt($simple_xml, 1);
my $new_to_old = CheatEngine::Trainer::Unpacker::decrypt($new_encrypted);
is($new_to_old, $simple_xml, 'Unpacker handles new method correctly');

# Test 12: Idempotency - decrypting already decrypted data
my $already_plain = CheatEngine::Trainer::Unpacker::decrypt($simple_xml);
is($already_plain, $simple_xml, 'Decrypting plain XML is idempotent');

# Test 13: Double encryption protection
my $encrypted = CheatEngine::Trainer::Packer::encrypt($simple_xml, 0);
my $double_attempt = CheatEngine::Trainer::Packer::encrypt($encrypted, 0);
is($double_attempt, $encrypted, 'Encrypting already encrypted data is idempotent');

# Test 14: Verify old and new formats produce different encrypted output
ok($encrypted_old ne $encrypted_new, 'Old and new methods create different encrypted formats');

done_testing();
