-------------------------------------------------------------------------------
-- Wezterm Configuration
-------------------------------------------------------------------------------
local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end
-------------------------------------------------------------------------------
-- Color Schemes
-------------------------------------------------------------------------------
-- config.color_scheme = "AdventureTime"
config.color_scheme = "ayu"
-- config.color_scheme = "Ayu Dark"
-- config.color_scheme = "Ayu Dark (Gogh)"
-- config.color_scheme = "Ayu Mirage"
-- config.color_scheme = "ayu_light"
-- config.color_scheme = "Brogrammer"
-- config.color_scheme = "Brogrammer (Base 16)"
-- config.color_scheme = "carbonfox"
-- config.color_scheme = 'Catch Me If You Can (terminal.sexy)'
-- config.color_scheme = 'Catppuccin Frappe'
-- config.color_scheme = 'Catppuccin Latte'
-- config.color_scheme = 'Chalk (base16)'
-- config.color_scheme = 'Dark Violet (base16)'
-- config.color_scheme = 'darkermatrix'
-- config.color_scheme = 'darkmatrix'
-- config.color_scheme = 'darkmoss (base16)'
-- config.color_scheme = 'Darktooth (base16)'
-- config.color_scheme = 'deep'
-- config.color_scheme = 'HaX0R_BLUE'
-- config.color_scheme = 'HaX0R_GR33N'
-- config.color_scheme = 'HaX0R_R3D'
-- config.color_scheme = 'Heetch Dark (base16)'
-- config.color_scheme = 'Homebrew'
-- config.color_scheme = 'Horizon Dark (base16)'
-- config.color_scheme = 'Humanoid dark (base16)'
-- config.color_scheme = 'Humanoid light (base16)'
-- config.color_scheme = 'Icy Dark (base16)'
-- config.color_scheme = 'Isotope (base16)'
-- config.color_scheme = 'jmbi (terminal.sexy)'
-- config.color_scheme = 'Laser'
-- config.color_scheme = 'Laserwave (Gogh)'
-- config.color_scheme = 'LiquidCarbonTransparent'
-- config.color_scheme = 'LiquidCarbonTransparentInverse'
-- config.color_scheme = 'Macintosh (base16)'
-- config.color_scheme = 'Maia (Gogh)'
-- config.color_scheme = 'Mariana'
-- config.color_scheme = 'Material'
-- config.color_scheme = 'Material (base16)'
-- config.color_scheme = 'Material (terminal.sexy)'
-- config.color_scheme = 'Material Lighter (base16)'
-- config.color_scheme = 'matrix'
-- config.color_scheme = 'Matrix (terminal.sexy)'
-- config.color_scheme = 'Modus-Vivendi'
-- config.color_scheme = 'Modus-Operandi-Tinted'
-- config.color_scheme = 'Modus-Operandi'
-- config.color_scheme = 'Mono (terminal.sexy)'
-- config.color_scheme = 'Mono Amber (Gogh)'
-- config.color_scheme = 'Mono Cyan (Gogh)'
-- config.color_scheme = 'Mono Green (Gogh)'
-- config.color_scheme = 'Mono Red (Gogh)'
-- config.color_scheme = 'Mono Theme (Gogh)'
-- config.color_scheme = 'Mono White (Gogh)'
-- config.color_scheme = 'Mono Yellow (Gogh)'
-- config.color_scheme = 'Monokai (base16)'
-- config.color_scheme = 'Monokai Vivid'
-- config.color_scheme = 'Monokai Remastered'
-- config.color_scheme = 'Neon'
-- config.color_scheme = 'Vice Dark (base16)'
-- config.color_scheme = 'Unikitty'
-- config.color_scheme = 'Unikitty Dark (base16)'
-- config.color_scheme = 'Sakura (base16)'
-- config.color_scheme = 'Sequoia Moonlight'
-- config.color_scheme = 'Spacedust'
-- config.color_scheme = 'synthwave'

-------------------------------------------------------------------------------
-- Font
-------------------------------------------------------------------------------
-- config.font = wezterm.font("Fira Code")
-- config.font = wezterm.font("Fira Code Nerd Font")
-- config.font = wezterm.font("Hack Nerd Font")
-- config.font = wezterm.font("SF Mono")
-- config.font = wezterm.font("IBM Plex Mono")

-------------------------------------------------------------------------------
-- Font Size
-------------------------------------------------------------------------------
config.font_size = 12.0

-------------------------------------------------------------------------------
-- Keyboard Settings
-------------------------------------------------------------------------------
config.enable_kitty_keyboard = true

-------------------------------------------------------------------------------
-- Launch Menu
-------------------------------------------------------------------------------
-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab, but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.

-- The launcher menu by default lists the various multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.

-- You can define your own entries using the launch_menu configuration setting. The snippet below adds two new entries to the menu; one that runs the top program to monitor process activity and a second one that explicitly launches the bash shell.

-- Each entry in launch_menu is an instance of a SpawnCommand object.

config.launch_menu = {{
    args = {'top'}
}, {
    label = 'System Processes',
    args = {'htop'}
}, {
    label = 'Weather Forecast',
    args = {'curl', '-s', 'v2.wttr.in/Chicago'}
}, {
    -- Optional label to show in the launcher. If omitted, a label
    -- is derived from the `args`
    label = 'Bash',
    -- The argument array to spawn.  If omitted the default program
    -- will be used as described in the documentation above
    args = {'bash', '-l'}

    -- You can specify an alternative current working directory;
    -- if you don't specify one then a default based on the OSC 7
    -- escape sequence will be used (see the Shell Integration
    -- docs), falling back to the home directory.
    -- cwd = "/some/path"

    -- You can override environment variables just for this command
    -- by setting this here.  It has the same semantics as the main
    -- set_environment_variables configuration option described above
    -- set_environment_variables = { FOO = "bar" },
}}

-- and finally, return the configuration to wezterm
return config
