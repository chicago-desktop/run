# windows/run — Run…

A module of the Windows 95 shell for the terminal desktop
([windows/shell](https://github.com/wippy-windows/windows) on
[windows/tui-desktop](https://github.com/wippy-windows/tui-desktop)): the
Start menu's **"Run…"** dialog, moved out of the shell into a module of its
own. A command field with "OK", "Cancel" and "Browse…": Enter or "OK" starts
the command in its own Bash window — the base's terminal window — and the
dialog closes; Escape and "Cancel" close it; "Browse…" opens "My Computer".
Details: [docs/run.md](docs/run.md).

The entry declares `group: ""`, which puts the item at the root of the Start
menu, next to "Programs", "Settings" and "Shut Down" — an application that
depends on this module and runs the shell gets "Run…" there without any
wiring of its own. Without a group a program would land in "Programs"; only
an explicit empty group is the root.

## Inside

- `windows.run:model` — the launch spec: the trimmed command, the refusal of
  an empty one, and the request to open the base's stock PTY window
  (`windows.tui_desktop.desktop:window_pty`) with `/bin/bash -ic '<command>
  ; exec /bin/bash -i'`, so the output and the prompt stay after the command.
  Pure; the tests exercise it without a compositor.
- `windows.run:window` — the dialog on the shell's SDK
  (`windows.shell.sdk:app`): title "Run…" in the menu, "Run" on the window,
  `window_type: dialog`, 50×10 cells, not resizable, the shell's picture
  `run`. Launching is a `desktop.open` request to the compositor; the reply
  arrives on a watched channel, so the dialog never blocks. It has no
  pictures of its own and no image pack.

The module depends on `windows/shell` (the SDK, the pictures, the explorer
"Browse…" opens) and `windows/tui-desktop` (the compositor and the PTY
window the command runs in).

## What it needs from the application

- **The base's PTY window with a shell environment.** `exec` does not
  inherit the OS environment: the application hands `HOME` and `PATH` to
  `windows.tui_desktop:exec` through `default_env` (the harness's
  `test/.wippy.yaml` shows the two overrides). Without them programs from
  `~/.local/bin` answer `command not found`.
- **Exec rights for the person.** The PTY window declares
  `meta.requires: tui_desktop.pty`; the compositor opens it only for a
  logged-on scope that has it (`app.security:admin` in the stand has
  `actions: '*'`). A refusal comes back to the dialog and is shown in place
  of the hint. The dialog itself runs under the shell's
  `windows.shell.security:view_state` policy and has no exec or spawn
  permission.

## Tests

- `test/src/run_test.lua` — the launch spec and the empty-command refusal;
  the SDK layout (the field, "OK" as the default while focus is in the
  field, "Cancel", "Browse…", the failure taking the hint's place); "Browse…"
  against a substituted request; then a live compositor
  (`test/src/run_composer.lua`): Bash and "Run…" opened from the real Start
  menu, a command typed and launched, its output on the PTY screen, the
  shell still alive after the dialog closed; Esc in cells mode.
- `test/src/window_test.lua` — the registry entry as the Start menu reads
  it (title "Run…", `group: ""`, a dialog, the shell's picture found at 32
  and 16 px), the process running the definition, Esc closing it, and
  `test/shots/run.png`: the dialog with `claude --resume` typed, drawn by
  the shell's own renderer. Look at the picture: the geometry checks do not
  see a wrong colour or a caption a pixel off.

## Developing

```bash
make setup     # resolve the dependencies from the Hub (once, and after changing them)
make check     # the repository's invariants
make lint      # late locals, then wippy lint of this namespace and the harness
make test      # the harness in test/: the dialog, the entry, a shot in test/shots/
make publish   # to the Hub, after `wippy auth login`
```

**A local build of the runtime fork is required**
([wippy-windows/runtime](https://github.com/wippy-windows/runtime), branch
`wippy-projects`): the shell declares the `gfx` module, which the release
runtime does not have, and `wippy` from PATH does not load the shell at all.
The Makefile's `WIPPY` names the build; override it with `make test WIPPY=…`.
The harness's gateway listens on :19248, apart from the shell's and the
other modules' harnesses, so they can run side by side.

The window SDK is documented in [docs/sdk.md](docs/sdk.md), a copy of the
shell's guide, and the skill for agents in
[skills/wippy-window-app/SKILL.md](skills/wippy-window-app/SKILL.md); the
rules of this repository are in [AGENTS.md](AGENTS.md).

Made from [the Windows module template](https://github.com/wippy-windows/module-template)
for modules of the Windows 95 shell. Repository:
https://github.com/wippy-windows/run.

## Licence

MIT. The dialog's picture is the shell's; there is no artwork in this
repository.
