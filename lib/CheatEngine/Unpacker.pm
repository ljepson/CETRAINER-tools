package CheatEngine::Unpacker;

use strict;
use warnings;

use Compress::Raw::Zlib;
use Exporter 'import';

our @EXPORT_OK = qw(decrypt);

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    return $self;
}

# Function wrapper for calling as a standalone function
sub decrypt {
    my ($data) = @_;
    
    # Create an instance and call the method
    my $unpacker = __PACKAGE__->new();
    return $unpacker->_decrypt($data);
}

# The actual implementation as an object method
sub _decrypt {
    my ($self, $data) = @_;
    
    # Convert to a mutable array of bytes
    my @bytes = unpack("C*", $data);
    
    my $result;
    if (substr($data, 0, 5) =~ /^<\?xml/) {
        print "    - Unprotected CETRAINER detected\n";
        $result = $data;
    }
    else {
        print "    - Protected CETRAINER detected. Decrypting...\n";
        my $ckey = 0xCE;
        
        # First decryption step
        for (my $i = 2; $i < scalar(@bytes); $i++) {
            $bytes[$i] = $bytes[$i] ^ $bytes[$i-2];
        }
        
        # Second decryption step
        for (my $i = scalar(@bytes) - 2; $i >= 0; $i--) {
            $bytes[$i] = $bytes[$i] ^ $bytes[$i+1];
        }
        
        # Third decryption step
        for (my $i = 0; $i < scalar(@bytes); $i++) {
            $bytes[$i] = $bytes[$i] ^ $ckey;
            $ckey = ($ckey + 1) & 0xFF;
        }
        
        my $output = "";

        # Rebuild the data
        $data = pack("C*", @bytes);
        
        # Decompress
        my $inflator = Compress::Raw::Zlib::Inflate->new(-WindowBits => -15);
        
        # New method
        if (substr($data, 0, 5) eq "CHEAT") {
            my $status = $inflator->inflate(substr($data, 5), $output);

            if ($status == Z_OK || $status == Z_STREAM_END) {
                $result = substr($output, 4);  # Skip 4-byte padding
                print "    - Decompressed CETRAINER using new method\n";
            }
            else {
                die "Decompression failed: $status\n";
            }
        }
        else {
            # Old method
            my $status = $inflator->inflate($data, $output);

            if ($status == Z_OK || $status == Z_STREAM_END) {
                $result = $output;
                print "    - Decompressed CETRAINER using old method\n";
            } else {
                die "Decompression failed: $status\n";
            }
        }
    }
    
    return $result;
}

1;