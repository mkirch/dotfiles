<div align="center">
  <h1>@mkirch's Dotfiles and Settings</h1>
  <img src="https://img.shields.io/github/languages/top/mkirch/dotfiles?color=blue&label=Shell&logo=gnu-bash&logoColor=white" alt="Shell">
  <img src="https://img.shields.io/github/languages/top/mkirch/dotfiles?color=blue&label=Lua&logo=lua&logoColor=white" alt="Lua">
  <img src="https://img.shields.io/github/last-commit/mkirch/dotfiles?color=green&label=Last%20Commit&logo=git&logoColor=white" alt="Last Commit">
  <img src="https://img.shields.io/github/issues/mkirch/dotfiles?color=yellow&label=Issues&logo=github&logoColor=white" alt="Issues">
  <img src="https://img.shields.io/github/license/mkirch/dotfiles?color=blue&label=License&logo=open-source-initiative&logoColor=white" alt="License">
</div>

This repository contains my personal dotfiles. These are the base configurations I use for my development environment setup.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Configuration Files](#configuration-files)
- [Scripts](#scripts)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)

## Installation

```bash
# Clone the repository
git clone https://github.com/mkirch/dotfiles.git

# Navigate to the directory
cd dotfiles

# Run the setup script
./setup.sh
```

## Usage

After installation, you can customize the dotfiles by editing the files in the repository. 

## Configuration Files

This repository includes configuration files for various tools and applications. Here are some of the main files:

- **wezterm.lua**: Configuration for WezTerm terminal emulator.
- **init.lua**: General Lua configurations.

## Scripts

Several useful scripts are included in this repository to automate and simplify tasks:

- **update.sh**: Script to update all installed packages and configurations.
- **whisper_transcription.sh**: Script for transcribing audio using Whisper.

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/mkirch/dotfiles/issues/new).

## Contributing

Contributions are welcome! Please use [GitHub Flow](https://guides.github.com/introduction/flow/) for contributing. Create a branch, add commits, and [open a pull request](https://github.com/mkirch/dotfiles/compare/).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

### Detailed File Descriptions

#### `wezterm.lua`

This file contains the configuration for the WezTerm terminal emulator, which is optimized for performance and customization. 

#### `init.lua`

The `init.lua` file is used for general Lua-based configurations that can be applied to various tools and applications within your development environment.

#### `update.sh`

A script to update all installed packages and configurations, ensuring that your development environment remains up-to-date with the latest versions and features.

#### `whisper_transcription.sh`

A script designed to facilitate audio transcription using Whisper. This script simplifies the process of converting audio files into text.

---

### Additional Notes

Feel free to explore and modify the configurations to suit your personal preferences. These dotfiles are intended to provide a solid foundation for a productive and efficient development environment.

<div align="center">
  <h3>Happy Coding!</h3>
</div>
