# "Run…"

"Start → Run…" opens a command field. For example: `top`, `top -d 2`,
`claude` or `claude --resume`. Enter and "OK" run the command in a separate
Bash window, Escape and "Cancel" close the dialog. Tab moves between the
field and the buttons; the field supports arrows, Home/End, Backspace/Delete
and Ctrl+A.

The Bash window is the desktop base's stock terminal window
`chicago.tui_desktop.desktop:window_pty` — the same one "Start → Programs →
Bash" opens. There is no copy of the PTY process in this module: the dialog
names the base's entry in its launch spec (`chicago.run:model`, `model.PTY`).

The command runs through `/bin/bash -ic`: arguments, quotes, variables,
pipelines and Bash's interactive setup are available. After the command
`exec /bin/bash -i` runs, so the output, the error and the shell prompt
remain. An explicit `exit` or `exec` in the command itself keeps its usual
meaning. The named program must be installed and reachable by Bash through
PATH.

## What the application has to provide

Bash starts with `-i` and reads `~/.bashrc`. The application passes `HOME`
and `PATH` to the base's executor `chicago.tui_desktop:exec` through
`default_env`: `exec.native` itself does not inherit the OS environment.
Without these variables programs from `~/.local/bin` (for example, `claude`,
`codex`) give `command not found`, even when they are installed for the
user. Check: `command -v claude codex`. The harness in `test/.wippy.yaml`
shows the two overrides.

The PTY window runs under its entry's policy in the base (exec on the
server, under the OS account); the base's entry declares
`meta.requires: tui_desktop.pty`, and the compositor asks the logged-on
person's scope for it. A person whose scope has no exec right is refused a
Bash with the reason on the desktop — and the dialog shows the compositor's
refusal in place of its hint. The dialog itself needs nothing beyond the
shell's `chicago.shell.security:view_state` policy: it has no `exec.run` or
`process.spawn` permissions.

## How it is built

The dialog asks the compositor to open the window through
`window_api.request` and closes after a successful reply. The command is
passed as a single `-c` argument, with quotes and backslashes preserved: it
is interpreted by Bash, not by Wippy's argument parser.

The dialog is built on the shell SDK (`chicago.shell.sdk:app`): a 32 px
icon (the shell's own picture `run`), two hint lines as one multi-line
label, an `input` field, the buttons "OK" (the default), "Cancel" and
"Browse…" — the last one opens "My Computer" (`chicago.shell.explorer:window`,
which stays in the shell) and waits for the compositor's reply over the same
channel, without closing the dialog. The window title is "Run"
(`definition.title`), the ellipsis stays on the menu item. The size of
50×10 cells follows the Windows 95 reference. It has no layout, renderer or
line editor of its own. The compositor's reply to the request to open a
window arrives on its own channel (`context.watch`), so the dialog does not
freeze.

The entry declares `group: ""` — the root of Start, next to "Programs",
"Settings" and "Shut Down". Without a group a program lands in "Programs";
only an explicit empty group is the root.

## Checks

`test/src/run_test.lua` — the launch spec, the SDK layout and the
default-button rule, "Browse…" against a substituted request, the real
Start menu of a live compositor (`test/src/run_composer.lua`) and launching
Bash under a PTY, the terminal surviving after the dialog is closed,
cancelling with Esc in cells mode. `test/src/window_test.lua` — the
registry entry as the Start menu reads it, the shell's picture found by the
shell, the process running the definition, and `test/shots/run.png`: the
dialog with `claude --resume` typed, drawn by the shell's renderer.

Bash windows use a black background and light-gray text by default. This
also applies to programs opened through "Run…". An ANSI color reset returns
these window colors; colors set explicitly by the application are kept. The
empty area and the inner edges of the frame also stay black.
