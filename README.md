# pulsar-keyboard-macros package

Keyboard macro extension for Pulsar.

# Requirements

openSUSE / Fedora / RHEL / CentOS: libxext-devel libxtst-devel libxkbfile-devel libxkbcommon-devel wayland-devel

Debian / Ubuntu / Linux Mint: libxext-dev libxtst-dev libxkbfile-dev libxkbcommon-dev wayland-dev

# Shortcuts

```ctrl-x (```  start recording

```ctrl-x )```  stop recording

```ctrl-x e```  execute macro

```ctrl-x ctrl-e```  execute macro N times

```ctrl-x b```  execute macro to the end of file

```ctrl-x ctrl-b``` execute macro from the beginning to the end of file

# Other Methods

- pulsar-keyboard-macros:name_last_kbd_macro
    Give a command name to the most recently defined keyboard macro.
    You can execute it, in command palette, use 'pulsar-keyboard-macros.user:{a-command-name}'.

- pulsar-keyboard-macros:execute_named_macro
    Execute a named keyboard macro(see pulsar-keyboard-macros:name_last_kbd_macro).

- pulsar-keyboard-macros:save
    Save all named macros

- pulsar-keyboard-macros:quick_save
    Quick save all named macros

- pulsar-keyboard-macros:load
    Load saved macros

- pulsar-keyboard-macros:quick_load
    Load quick_saved macros
