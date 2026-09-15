# chicago/run — Run…

A module of the Chicago shell for the terminal desktop
([chicago/shell](https://github.com/chicago-desktop/shell) on
[chicago/tui-desktop](https://github.com/chicago-desktop/tui-desktop)): the
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

- `chicago.run:model` — the launch spec: the trimmed command, the refusal of
  an empty one, and the request to open the base's stock PTY window
  (`chicago.tui_desktop.desktop:window_pty`) with `/bin/bash -ic '<command>
  ; exec /bin/bash -i'`, so the output and the prompt stay after the command.
  Pure; the tests exercise it without a compositor.
- `chicago.run:window` — the dialog on the shell's SDK
  (`chicago.shell.sdk:app`): title "Run…" in the menu, "Run" on the window,
  `window_type: dialog`, 50×10 cells, not resizable, its own picture
  `chicago.run:images/run`. Launching is a `desktop.open` request to the
  compositor; the reply arrives on a watched channel, so the dialog never
  blocks.
- `chicago.run:images` — the module's own pictures, an image pack of the
  shell under `assets/images` (32 and 16 px), copied from the shell's icon
  set: an interim icon set, see `assets/images/SOURCE.md`.

The module depends on `chicago/shell` (the SDK, the image packs, the explorer
"Browse…" opens) and `chicago/tui-desktop` (the compositor and the PTY
window the command runs in).

## What it needs from the application

- **The base's PTY window with a shell environment.** `exec` does not
  inherit the OS environment: the application hands `HOME` and `PATH` to
  `chicago.tui_desktop:exec` through `default_env` (the harness's
  `test/.wippy.yaml` shows the two overrides). Without them programs from
  `~/.local/bin` answer `command not found`.
- **Exec rights for the person.** The PTY window declares
  `meta.requires: tui_desktop.pty`; the compositor opens it only for a
  logged-on scope that has it (`app.security:admin` in the stand has
  `actions: '*'`). A refusal comes back to the dialog and is shown in place
  of the hint. The dialog itself runs under the shell's
  `chicago.shell.security:view_state` policy and has no exec or spawn
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
  it (title "Run…", `group: ""`, a dialog, the module's picture found at 32
  and 16 px), the process running the definition, Esc closing it, and
  `test/shots/run.png`: the dialog with `claude --resume` typed, drawn by
  the shell's own renderer. Look at the picture: the geometry checks do not
  see a wrong colour or a caption a pixel off.

## Developing

```bash
make setup     # resolve the dependencies (once, and after changing them)
make check     # the repository's invariants
make lint      # late locals, then wippy lint of this namespace and the harness
make test      # the harness in test/: the dialog, the entry, a shot in test/shots/
make publish   # publish a release, after `wippy auth login`
```

**A build of the runtime fork from its releases is required**
([chicago-desktop/runtime](https://github.com/chicago-desktop/runtime),
`v0.3.40a-chicago.2` or newer): it resolves the shell and the base from
GitHub by tag, and the shell declares the `gfx` module, which the release
runtime does not have — `wippy` from PATH does not load the shell at all.
The Makefile's `WIPPY` names the build; override it with `make test WIPPY=…`.
The harness's gateway listens on :19248, apart from the shell's and the
other modules' harnesses, so they can run side by side.

The window SDK is documented in [docs/sdk.md](docs/sdk.md), a copy of the
shell's guide, and the skill for agents in
[skills/wippy-window-app/SKILL.md](skills/wippy-window-app/SKILL.md); the
rules of this repository are in [AGENTS.md](AGENTS.md).

Made from [the Chicago module template](https://github.com/chicago-desktop/module-template)
for modules of the Chicago shell. Repository:
https://github.com/chicago-desktop/run.

## Licence

The icon set is an interim one and is being replaced with original pixel art
([chicago-desktop/shell#1](https://github.com/chicago-desktop/shell/issues/1));
the code is MIT.
