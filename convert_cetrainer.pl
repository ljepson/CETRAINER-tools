#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib);

use File::Basename;
use Getopt::Long;

my $in_file  = "";
my $out_file = "";
#my $debug    = 0;

GetOptions(
    "i|input=s"   => \$in_file,
    "o|output=s"  => \$out_file,
    #"debug"     => \$debug
) or die "Usage: $0 --input=<decrypted_CETRAINER.xml|encrypted.CETRAINER> [--output=output-name]\n";

sub read_file {
    my ($file) = @_;
    my $data;

    open(my $fh, '<:raw', $file) or die "Error reading input file $file: $!\n";

    {
        local $/;
        $data = <$fh>;
    }
    close($fh);

    return $data;
}

sub file_is_xml {
    my ($file) = @_;

    my $data = read_file($file);

    if (substr($data, 0, 5) =~ /^<\?xml/) {
        return 'XML';
    }

    return 'CETRAINER';
}

sub get_unique_filename {
    my ($filename) = @_;
    
    return $filename unless -e $filename;
    
    # File exists, need to create a unique name
    my ($name, $dir, $ext) = fileparse($filename, qr/\.[^.]*/);
    my $count = 1;
    
    my $new_filename;
    do {
        $new_filename = "$dir$name-$count$ext";
        $count++;
    } while (-e $new_filename);
    
    return $new_filename;
}

sub main {
    my $base_name;

    # Check command line arguments
    if (! $in_file || ! -e $in_file) {
        die "Error: Input file not found: $in_file\n";
    }

    if (! $out_file) {
        ($base_name, undef, undef) = fileparse($in_file, qr/\.[^.]*/);
        $out_file = $base_name;
    } else {
        ($base_name, undef, undef) = fileparse($out_file, qr/\.[^.]*/);
    }

    my $input_type  = file_is_xml($in_file);
    my $output_type = $input_type eq 'XML' ? 'CETRAINER' : 'xml';
    my $output_file = "${base_name}.${output_type}";
    
    # Ensure we have a unique filename that doesn't overwrite existing files
    $output_file = get_unique_filename($output_file);
    
    print "Converting: $in_file -> $output_file\n";

    my $data = read_file($in_file);
    my $result;
    
    if ($input_type eq 'XML') {
        # Encrypt the data
        require CheatEngine::Packer;

        print "Encrypting XML to CETRAINER format\n";
        $result = CheatEngine::Packer::encrypt($data);
    }
    else {
        # Decrypt the data
        print "Decrypting CETRAINER to XML format\n";

        require CheatEngine::Unpacker;
        $result = CheatEngine::Unpacker::decrypt($data);
    }
        
    # Write the converted data
    open(my $out_fh, '>:raw', $output_file) or die "Error writing output file: $!\n";
    print $out_fh $result;
    close($out_fh);
    
    print "Successfully converted to $output_file\n";
    return 0;
}

exit main(); 