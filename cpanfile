requires 'Compress::Raw::Zlib', '2.0'; # For compression/decompression
requires 'File::Basename';             # For file path handling
requires 'Getopt::Long';               # For command-line options
requires 'XML::LibXML';                # For parsing XML files

# Test dependencies
on 'test' => sub {
    requires 'Test::More', '0.98';      # For basic testing
    requires 'File::Temp';              # For temporary test files
}; 