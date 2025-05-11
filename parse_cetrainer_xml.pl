#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open qw(:std :utf8);
use Encode qw(decode encode);

use lib qw(lib);

use Data::Dumper;
use File::Basename;
use Getopt::Long;
use XML::LibXML;

# Enable unbuffered output
$| = 1;

# Parse command line arguments
my $file     = "";
my $out_file = "output.txt";
my $force    = 0;
my $debug    = 0;
my $no_decrypt = 0;

GetOptions(
    "input=s"   => \$file,
    "output=s"  => \$out_file,
    "force"     => \$force,
    "debug"     => \$debug,
    "no-decrypt" => \$no_decrypt
) or die "Usage: $0 --input=<CETRAINER or decrypted_XML> [--output=output.txt] [--force] [--debug] [--no-decrypt]\n";

# Allow positional arguments for backward compatibility
$file = shift @ARGV if !$file && @ARGV;
$debug = 1 if grep { $_ eq '--debug' } @ARGV;

die "Usage: $0 --input=<CETRAINER or decrypted_XML> [--output=output.txt] [--force] [--debug] [--no-decrypt]\n" unless $file;

print "Processing file: $file\n";

# Check if output file exists and handle accordingly
if (-e $out_file && !$force) {
    my $count = 1;
    my ($name, $path, $suffix) = fileparse($out_file, qr/\.[^.]*/);
    my $new_output;
    
    do {
        $new_output = "$path$name-$count$suffix";
        $count++;
    } while (-e $new_output);
    
    $out_file = $new_output;
    print "No --force option; writing to $out_file instead\n";
}

# Function to read file contents
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

# Check if the file is an XML file or encrypted CETRAINER
sub is_xml {
    my ($data) = @_;
    return substr($data, 0, 5) =~ /^<\?xml/;
}

# Process an assembler script to clean it up
sub process_assembler_script {
    my ($script) = @_;
    return '' unless $script;
    
    my $processed = [];
    
    # Process each line of the script   
    foreach my $line (split /\n/, $script) {
        chomp $line;

        # Preserve the original line if it contains a comment with potentially Unicode content
        if ($line =~ m{;\s*//}) {
            push @$processed, $line;
            next;
        }

        $line =~ s/\s+/ /g; # Normalize whitespace
        $line =~ s/\s*;\s*.*$//; # Remove comments

        # Remove empty lines
        next unless $line;

        push @$processed, $line;
    }   

    return join "\n", @$processed;
}

# Read the input file and decrypt if needed
my $xml_data = read_file($file);

# Auto-decrypt if the file isn't XML and decryption isn't disabled
if (!is_xml($xml_data) && !$no_decrypt) {
    print "Encrypted CETRAINER detected. Auto-decrypting...\n";
    
    # Load the decryption module
    require CheatEngine::Unpacker;
    
    # Decrypt the data
    $xml_data = CheatEngine::Unpacker::decrypt($xml_data);
    
    # Verify we got valid XML
    if (!is_xml($xml_data)) {
        die "Decryption failed. The file could not be decrypted to a valid XML.\n";
    }
    
    print "CETRAINER successfully decrypted. Proceeding with parsing...\n";
} elsif (!is_xml($xml_data) && $no_decrypt) {
    die "Input file is not XML and --no-decrypt option was specified.\n";
}

# Main processing function
sub parse_cheat_table {
    my ($data) = @_;
    
    # Parse the XML data
    my $dom = eval { XML::LibXML->load_xml(string => $data) }
        or die "Error parsing XML data: $@\n";

    # Get the root element
    my $root = $dom->documentElement;
    
    # Process CheatEntries
    my $result = process_cheat_entries($root);

    # Extract and process LuaScript if present
    my $lua_script = $root->findvalue('./LuaScript');

    if ($lua_script) {
        push @$result, $lua_script;
    }

    return $result;
}

# Process all cheat entries recursively
sub process_cheat_entries {
    my ($root) = @_;
    
    # Find all CheatEntry elements
    my @entries = $root->findnodes('.//CheatEntry');
    
    my $result = [];
    
    foreach my $entry (@entries) {
        push @{$result}, process_cheat_entry($entry, 0);
    }

    return $result;
}

# Process a single cheat entry with proper indentation for hierarchy
sub process_cheat_entry {
    my ($entry, $depth) = @_;

    my $data   = { indent => "  " x $depth };
    
    # Extract basic info
    $data->{'id'} = $entry->findvalue('./ID') || 'N/A';
    $data->{'description'} = $entry->findvalue('./Description') || 'N/A';
    
    # Extract and process more data
    my $active  = $entry->findvalue('./Active') // '0';
    my $vtype   = $entry->findvalue('./VariableType') // 'N/A';
    my $address = $entry->findvalue('./Address') // 'N/A';
    my $offsets = $entry->findvalue('./Offsets') // '';
    my $hotkeys = $entry->findnodes('./Hotkeys/*');
    
    # Save additional details
    $data->{'active'}  = $active eq '1' ? 'Yes' : 'No';
    $data->{'vtype'}   = $vtype if $vtype;
    $data->{'address'} = $address if $address;
    
    # Save hotkeys if any
    if ($hotkeys && $hotkeys->size > 0) {
        $data->{'hotkeys'} = [];
        foreach my $hotkey ($hotkeys->get_nodelist) {
            push @{$data->{'hotkeys'}}, $hotkey->nodeName;
        }
    }
    
    # Extract and process assembler script if present
    my $assembler_script = $entry->findvalue('./AssemblerScript');
    if ($assembler_script) {
        my $processed = process_assembler_script($assembler_script);
        $data->{'assembler_script'} = $processed if $processed;
    }
     
    # Save debug info if requested
    if ($debug) {
        $data->{'debug'} = [];
        foreach my $child ($entry->childNodes()) {
            next unless $child->nodeType == XML_ELEMENT_NODE;
            push @{$data->{'debug'}}, $child->nodeName;
        }
    }
    
    # Process child entries recursively
    my @children = $entry->findnodes('./CheatEntries/CheatEntry');
    if (@children) {
        $data->{'children'} = [];
        foreach my $child (@children) {
            push @{$data->{'children'}}, process_cheat_entry($child, $depth + 1);
        }
    }
    
    return $data;
}

# Start processing
my $result = parse_cheat_table($xml_data);

sub save_result {
    my ($result) = @_;
    
    open(my $fh, '>', $out_file) or die "Could not open file '$out_file' for writing: $!";
    
    foreach my $entry (@$result) {
        if (ref($entry) eq 'HASH') {
            write_entry($fh, $entry, undef, [], "");
        } else {
            # Handle Lua scripts or other non-hash entries
            print $fh "LuaScript:\n$entry\n";
        }
    }
    
    close $fh;
    print "Results written to $out_file\n";
}

sub write_entry {
    my ($fh, $entry, $seen_refs, $path_indices, $path_prefix) = @_;
    $seen_refs    ||= {}; # To prevent infinite recursion with circular references
    $path_indices ||= []; # Track the path of indices to this entry
    
    # Skip if we've seen this reference before
    my $addr = "$entry";
    return if $seen_refs->{$addr}++;
    
    # Determine our hierarchy indicators
    my $level = scalar(@$path_indices);
    my $is_last_at_level = defined $path_indices->[-1] && $path_indices->[-1]->{is_last} || 0;
    
    # Create a visually appealing tree structure
    my $tree_prefix = "";
    if ($level > 0) {
        # Build the tree structure from path information
        for (my $i = 0; $i < $level - 1; $i++) {
            if ($path_indices->[$i]->{is_last}) {
                $tree_prefix .= ""; # Space where a completed branch was
            } else {
                $tree_prefix .= "|"; # Continuing vertical line (ASCII)
            }
        }
        
        # Add the current node's connector
        if ($is_last_at_level) {
            $tree_prefix .= "|"; # Last item corner piece (ASCII)
        } else {
            $tree_prefix .= "|"; # Middle item T-piece (ASCII)
        }
    }
    
    # Combine the visual prefix with any existing indentation
    my $visual_indent = $tree_prefix;
    
    # Create parent info string if this is a child entry
    my $parent_info = "";
    if ($level > 0 && exists $path_indices->[-1]->{index}) {
        my $current_index = $path_indices->[-1]->{index} + 1; # 1-based indexing for display
        my $total_children = $path_indices->[-1]->{total};
        $parent_info = " [Child $current_index/$total_children";
        
        if ($path_prefix) {
            $parent_info .= " of $path_prefix";
        }
        
        $parent_info .= "]";
    }
    
    # Create a path label for this entry for its children to reference
    my $this_path_label = $entry->{description} || $entry->{id};
    $this_path_label =~ s/\s+/_/g; # Replace spaces with underscores for cleaner display
    $this_path_label =~ s/^(?:'|")+([^'"]+)(?:'|")+$/$1/g; # Remove quote/double quotes
    
    # Use a uniform separator line for all entries
    my $separator = '-' x (100 - $level);

    print $fh $visual_indent . $separator . "\n";
    
     # Content prefix for additional content lines
    # Always include vertical bars for consistent hierarchy visualization
    my $content_prefix = '';
    
    if ($level == 0) {
        # For top-level entries, add a vertical bar
        $content_prefix = "| ";
    } else {
        # For nested entries, continue the appropriate pattern
        $content_prefix = ($is_last_at_level ? "" : "|"); # x ($level);
        $content_prefix .= "  "; # Add another level for content
    }
    
    # Entry details with tree structure
    print $fh $visual_indent . $content_prefix . "Cheat Entry ID: " . $entry->{id} . $parent_info . "\n";
    print $fh $visual_indent . $content_prefix . "Description: " . $entry->{description} . "\n";

    # Additional details with consistent tree structure
    print $fh $visual_indent . $content_prefix . "Active: " . $entry->{active} . "\n";
    
    if ($entry->{vtype}) {
        print $fh $visual_indent . $content_prefix . "Value Type: " . $entry->{vtype} . "\n";
    }
    
    if ($entry->{address}) {
        print $fh $visual_indent . $content_prefix . "Address: " . $entry->{address} . "\n";
    }
    
    # Print hotkeys if any
    if ($entry->{hotkeys} && @{$entry->{hotkeys}}) {
        print $fh $visual_indent . $content_prefix . "Hotkeys: " . join(" ", @{$entry->{hotkeys}}) . "\n";
    }
    
    # Print assembler script if present
    if ($entry->{assembler_script}) {
        print $fh $visual_indent . $content_prefix . "Assembler Script:\n";
        foreach my $line (split(/\n/, $entry->{assembler_script})) {
            next unless $line;
            print $fh $visual_indent . $content_prefix . "$line\n";
        }
    }
    
    # Print debug info if requested
    if ($entry->{debug} && @{$entry->{debug}}) {
        print $fh $visual_indent . $content_prefix . "DEBUG: Full node structure:\n";
        foreach my $node (@{$entry->{debug}}) {
            print $fh $visual_indent . $content_prefix . "  $node\n";
        }
    }
    
    # Process child entries recursively
    if ($entry->{children} && @{$entry->{children}}) {
        my $child_count = scalar(@{$entry->{children}});
        print $fh $visual_indent . $content_prefix . "Child Entries: $child_count\n";
        
        # Create a new path with this entry's info for child references
        my $new_path_prefix = $this_path_label;
        if ($path_prefix) {
            $new_path_prefix = "$path_prefix->$this_path_label";
        }
        
        # Process each child with its position information
        for (my $i = 0; $i < $child_count; $i++) {
            my $child   = $entry->{children}->[$i];
            my $is_last = ($i == $child_count - 1);
            
            # Create a new path indices array with this child's position
            my @new_path = @$path_indices;
            push @new_path, {
                index   => $i,
                total   => $child_count,
                is_last => $is_last
            };
            
            # Write the child with the updated path information
            write_entry($fh, $child, $seen_refs, \@new_path, $new_path_prefix);
        }
    }
    
    # No final separator needed - each entry starts with its own separator
}

save_result($result);

exit 0;