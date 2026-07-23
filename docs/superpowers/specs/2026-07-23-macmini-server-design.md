# Design: `macmini` → 24/7 headless server

Date: 2026-07-23

## Goal

Turn the `macmini` darwin host into an always-on (24/7) headless server that survives power outages and reboots unattended, is reachable over SSH via Tailscale, and does not expose a usable desktop to anyone with physical access. Convert the config declaratively via nix-darwin.

## Scope

- **In scope:** `hosts/darwin/configuration.nix` only.
- **Out of scope:** NixOS / Linux hosts, `flake.nix` wiring, and `home/`. These are not touched.
- **Additive & surgical:** existing desktop `system.defaults` (dock, finder, trackpad, NSGlobalDomain) stay as-is. The trackpad block is a no-op on a Mac mini but is harmless and left in place.

## Primary use cases (priority order)

1. SSH remote-dev / bastion (踏み台) — always reachable over Tailscale.
2. Docker / OrbStack workloads running continuously.
3. Ollama LLM host — not used today, planned later, low priority. No Ollama-specific config in this change.

## Changes to `hosts/darwin/configuration.nix`

### A. Power — never sleep, auto-recover

```nix
power = {
  restartAfterFreeze = true;         # reboot on kernel panic
  restartAfterPowerFailure = true;   # auto power-on after outage (device support varies)
  sleep = {
    computer = "never";              # critical: the machine must not sleep
    display = 10;                    # display may still sleep; harmless headless
    harddisk = "never";
  };
};
```

### B. Remote access

- Enable Apple's built-in SSH server declaratively:

  ```nix
  services.openssh.enable = true;
  ```

- Run Tailscale as a real system daemon (`tailscaled`) instead of just the brew CLI:

  ```nix
  services.tailscale.enable = true;
  ```

- **Remove** `"tailscale"` from `homebrew.brews` — it only installed the CLI, not a managed daemon. The nix-darwin service supersedes it.

Manual one-time step after switching: `sudo tailscale up` to authenticate the node.

### C. Auto-login + physical-tamper mitigation

Auto-login is required so OrbStack containers and user-session daemons come back after an unattended reboot.

```nix
system.defaults.loginwindow.autoLoginUser = "hlts2";

system.defaults.screensaver = {
  askForPassword = true;
  askForPasswordDelay = 0;
};
```

- `autoLoginUser` writes the loginwindow plist key. **macOS limitation:** nix-darwin cannot write the encrypted password blob (`/etc/kcpassword`). A one-time manual toggle of "Automatically log in as…" in System Settings → Users & Groups is required after the first switch. Documented here as a manual step; not achievable declaratively.
- `screensaver.askForPassword` + `askForPasswordDelay = 0` mean a physically-attached monitor lands on a password-locked screen while the session keeps running underneath. This is what reconciles "auto-login for reliability" with "don't let anyone use the desktop."
- **Lock immediately after auto-login.** `screensaver.askForPassword` only locks once the display sleeps/screensaver engages, leaving the desktop exposed for up to the display-sleep interval right after boot. To close that window, a per-user LaunchAgent sleeps the display as soon as the session loads; combined with `askForPassword` (delay 0) the console then requires the password to wake, so it is locked from the moment it boots while OrbStack keeps starting underneath:

  ```nix
  launchd.user.agents.lock-on-login = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/pmset" "displaysleepnow" ];
      RunAtLoad = true;
    };
  };
  ```

  (`pmset displaysleepnow` is used rather than the classic `CGSession -suspend` lock, whose `/System/Library/CoreServices/Menu Extras/User.menu/.../CGSession` binary no longer exists on current macOS.)

  FileVault must be OFF for unattended power-failure recovery and auto-login to work (it would otherwise block boot on the disk-unlock prompt); at-rest disk encryption is traded for headless availability.

### D. Clean network identity

```nix
networking.hostName = "macmini";
networking.computerName = "macmini";
```

### E. Full automatic updates (chosen: availability traded for staying current)

```nix
system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
```

Plus the remaining `com.apple.SoftwareUpdate` keys (automatic check, download, critical/security data, config data) via `system.defaults.CustomSystemPreferences` for that domain, so OS + security updates install automatically. Auto-restart after reboot is covered by auto-login (C) and `restartAfterPowerFailure` (A), so an update-triggered reboot recovers unattended.

## Non-nix manual steps (documented, not encoded)

1. System Settings → toggle "Automatically log in as hlts2" once (writes `/etc/kcpassword`).
2. `sudo tailscale up` once to authenticate the Tailscale node.
3. OrbStack → enable "Start at login" so containers with a restart policy come up after reboot.

## What is intentionally NOT changed

- Homebrew casks (`google-chrome`, `ollama`, `orbstack`) and `onActivation` behavior — left as-is.
- Existing desktop `system.defaults` — left as-is (surgical).
- `flake.nix`, Linux host, and `home/` — untouched.

## Verification

- `darwin-rebuild build --flake .#macmini` (or `nix build .#darwinConfigurations.macmini.system`) evaluates and builds without error — proves every option path is valid.
- After apply: `pmset -g` shows `sleep 0` / autorestart; `ssh` into the host over Tailscale succeeds; `tailscale status` shows the node online; on reboot the machine returns to a locked screen with the session running.
