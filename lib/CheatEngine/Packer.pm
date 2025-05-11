package CheatEngine::Packer;

use strict;
use warnings;

use Compress::Raw::Zlib;
use Exporter 'import';

our @EXPORT_OK = qw(encrypt);

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    return $self;
}

# Function wrapper for calling as a standalone function
sub encrypt {
    my ($data, $use_new_method) = @_;
    
    # Create an instance and call the method
    my $packer = __PACKAGE__->new();
    return $packer->_encrypt($data, $use_new_method);
}

# The actual implementation as an object method
sub _encrypt {
    my ($self, $data, $use_new_method) = @_;

    # Default to old method if not specified
    $use_new_method //= 0;
    
    # Check if the data is already encrypted
    if (substr($data, 0, 5) !~ /^<\?xml/) {
        print "    - Data doesn't look like an XML file, might already be encrypted.\n";
        return $data;
    }
    
    print "    - Unprotected CETRAINER detected. Encrypting...\n";
    
    # Compress the data based on the method
    my $compressed_data;
    my $deflator = Compress::Raw::Zlib::Deflate->new(
        -Level      => 9,       # Maximum compression
        -WindowBits => -15,     # Raw deflate format
    );
    
    my $output = "";
    my $status;
    
    if ($use_new_method) {
        print "    - Compressing CETRAINER using new method\n";

        # Add 4 bytes padding before compression
        my $padding = pack("C4", 0, 0, 0, 0);

        $status = $deflator->deflate($padding . $data, $output);

        $status == Z_OK
            or die "Compression failed: $status\n";

        $status = $deflator->flush($output);

        $status == Z_OK
            or die "Flush failed: $status\n";

        $compressed_data = "CHEAT" . $output;
    }
    else {
        print "    - Compressing CETRAINER using old method\n";

        $status = $deflator->deflate($data, $output);

        $status == Z_OK
            or die "Compression failed: $status\n";

        $status = $deflator->flush($output);

        $status == Z_OK
            or die "Flush failed: $status\n";

        $compressed_data = $output;
    }
    
    # Convert to a mutable array of bytes
    my @bytes = unpack("C*", $compressed_data);
    
    # Apply encryption in reverse order of the decryption
    my $ckey = 0xCE;
    
    # Step 1: XOR each byte with the key (same as in decrypt)
    for (my $i = 0; $i < scalar(@bytes); $i++) {
        $bytes[$i] = $bytes[$i] ^ $ckey;
        $ckey = ($ckey + 1) & 0xFF;
    }
    
    # Step 2: Reverse the second decryption step
    for (my $i = 0; $i < scalar(@bytes) - 1; $i++) {
        $bytes[$i] = $bytes[$i] ^ $bytes[$i+1];
    }
    
    # Step 3: Reverse the first decryption step
    for (my $i = scalar(@bytes) - 1; $i > 1; $i--) {
        $bytes[$i] = $bytes[$i] ^ $bytes[$i-2];
    }
    
    print "    - CETRAINER encrypted successfully\n";
    return pack("C*", @bytes);
}

1;