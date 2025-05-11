# CheatEngine Trainer Tools

This project provides utilities for working with CheatEngine's `.CETRAINER` files - both encrypting them and decrypting them.

## Features

- Decrypt protected `.CETRAINER` files to plain XML format
- Encrypt plain XML files back to protected `.CETRAINER` format
- Supports both old and new CheatEngine compression methods
- Automatically handles file name conflicts by creating unique filenames
- Parse and extract cheat entries from decrypted XML files into readable format

## Installation

### Prerequisites

This project requires Perl and the following modules:

- Compress::Raw::Zlib
- XML::LibXML (for parsing XML files)

You can install the required modules using cpanm:

```
cpanm --installdeps .
```

## Usage

### Converting CETRAINER files (both encryption and decryption)

```sh
perl convert_cetrainer.pl --input=<file.CETRAINER or file.xml> [--output=output-basename]
```

The script automatically detects if the input file is an XML file or an encrypted CETRAINER file and performs the appropriate conversion:
- XML files will be encrypted to CETRAINER format
- CETRAINER files will be decrypted to XML format

If no output name is provided, the script uses the input filename with the appropriate extension.

### Parsing XML Cheat Tables

Once you have a decrypted XML file, you can parse it to extract the cheat entries in a more readable format:

```sh
perl parse_cetrainer_xml.pl --input=<decrypted_CETRAINER.xml> [--output=output.txt] [--force] [--debug]
```

This tool:
- Extracts all cheat entries with their hierarchical structure
- Shows details like ID, description, addresses, and assembler scripts
- Preserves the parent-child relationships of cheat entries
- Formats the output as a readable tree structure
- Includes Lua scripts if present in the original file

The `--debug` option shows additional node structure information.

## File safety

The tools will never overwrite existing files. If the target file already exists, they will automatically create new filenames with incrementing numbers (e.g., trainer-1.xml, trainer-2.xml).

## Documentation

- For details on the CETRAINER file format, see [DOCS/CETRAINER.md](DOCS/CETRAINER.md)
- Credits and acknowledgments are available in [CREDITS.md](CREDITS.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
