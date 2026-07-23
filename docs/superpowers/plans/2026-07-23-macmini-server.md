# macmini 24/7 Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the `macmini` darwin host into a headless 24/7 server: never sleeps, auto-recovers after power loss, reachable over SSH+Tailscale, and physically tamper-mitigated.

**Architecture:** Purely additive edits to `hosts/darwin/configuration.nix` using nix-darwin first-class modules (`power`, `services.openssh`, `services.tailscale`, `system.defaults.loginwindow` / `screensaver` / `SoftwareUpdate`, `networking`). The `tailscale` Homebrew brew is removed in favor of the managed `tailscaled` daemon. Nothing else in the repo changes.

**Tech Stack:** Nix flakes, nix-darwin (`nixos-unstable` nixpkgs), macOS (aarch64-darwin).

## Global Constraints

- Touch **only** `hosts/darwin/configuration.nix`. Do not modify `flake.nix`, `home/`, or any Linux/NixOS host.
- Additive & surgical: leave the existing `system.defaults` desktop blocks (`NSGlobalDomain`, `dock`, `finder`, `trackpad`) untouched.
- Every commit uses `git commit --signoff` (mandatory signoff trailer).
- The nix build/switch (`darwin-rebuild`) **must run on the Mac mini** — an `aarch64-darwin` system cannot build on the `x86_64-linux` dev box. Plan authoring/edits happen anywhere; evaluation and apply happen on the target.
- Branch: `feat/macmini-server` (already created).

## File Structure

- **Modify:** `hosts/darwin/configuration.nix` — the only file changed. All server settings are added to the existing attrset; the `homebrew.brews` list loses its one `tailscale` entry.

There is no test file — nix has no unit-test layer here. Each task's verification is flake evaluation (`nix eval`/`nix flake check`) and, in the final task, live checks on the running server (`pmset`, `ssh`, `tailscale status`).

---

### Task 1: Power — never sleep, auto-recover

**Files:**
- Modify: `hosts/darwin/configuration.nix` (add a top-level `power` block)

**Interfaces:**
- Produces: a `power` attrset consumed by nix-darwin's `power` module. No other task depends on it.

- [ ] **Step 1: Add the `power` block**

Insert after the `nixpkgs.config.allowUnfree = true;` line (before `environment.systemPackages`):

```nix
  # Server power behavior: never sleep, recover unattended.
  power = {
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
    sleep = {
      computer = "never";
      display = 10;
      harddisk = "never";
    };
  };
```

- [ ] **Step 2: Verify the flake still evaluates**

Run (locally on Linux — eval, not build): `nix eval .#darwinConfigurations.macmini.config.power.sleep.computer`
Expected: `"never"`

If authoring on Linux where the darwin config can't fully evaluate, at minimum run `nix flake check --no-build 2>&1 | head` and confirm no parse/option error for `power`.

- [ ] **Step 3: Commit**

```bash
git add hosts/darwin/configuration.nix
git commit --signoff -m "feat(darwin): keep macmini awake and auto-recover on power loss"
```

---

### Task 2: Remote access — SSH daemon + Tailscale service

**Files:**
- Modify: `hosts/darwin/configuration.nix` (add `services.openssh` + `services.tailscale`; remove `tailscale` from `homebrew.brews`)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `services.openssh.enable` and `services.tailscale.enable` both `true`; `homebrew.brews` no longer contains `"tailscale"`.

- [ ] **Step 1: Add the services block**

Insert a `services` block after the `power` block from Task 1:

```nix
  # Remote access for a headless server.
  services.openssh.enable = true;
  services.tailscale.enable = true;
```

- [ ] **Step 2: Remove the tailscale brew**

In the existing `homebrew` block, delete the `brews` list that contains only `tailscale`. Change:

```nix
	brews = [
      "tailscale"
	];
    casks = [
```

to:

```nix
    casks = [
```

- [ ] **Step 3: Verify evaluation and the brew removal**

Run (locally on Linux — eval, not build): `nix eval .#darwinConfigurations.macmini.config.services.tailscale.enable`
Expected: `true`

Run: `nix eval .#darwinConfigurations.macmini.config.homebrew.brews --json`
Expected: `[]` (no `tailscale`)

- [ ] **Step 4: Commit**

```bash
git add hosts/darwin/configuration.nix
git commit --signoff -m "feat(darwin): enable sshd and run tailscale as a managed daemon"
```

---

### Task 3: Auto-login + physical-tamper mitigation

**Files:**
- Modify: `hosts/darwin/configuration.nix` (extend `system.defaults` with `loginwindow` + `screensaver`)

**Interfaces:**
- Consumes: the existing `system.defaults` attrset.
- Produces: `system.defaults.loginwindow.autoLoginUser = username`; `system.defaults.screensaver.askForPassword = true`.

- [ ] **Step 1: Add loginwindow + screensaver to `system.defaults`**

Inside the existing `system.defaults = { ... }` attrset (alongside `NSGlobalDomain`, `dock`, `finder`, `trackpad`), add:

```nix
      # Headless auto-login so user-session daemons (OrbStack) return after reboot.
      loginwindow.autoLoginUser = username;

      # A physically-attached monitor must hit a locked screen.
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };
```

- [ ] **Step 2: Verify evaluation**

Run (locally on Linux — eval, not build): `nix eval .#darwinConfigurations.macmini.config.system.defaults.loginwindow.autoLoginUser`
Expected: `"hlts2"`

Run: `nix eval .#darwinConfigurations.macmini.config.system.defaults.screensaver.askForPassword`
Expected: `true`

- [ ] **Step 3: Commit**

```bash
git add hosts/darwin/configuration.nix
git commit --signoff -m "feat(darwin): auto-login headless with password-locked screen"
```

---

### Task 4: Network identity

**Files:**
- Modify: `hosts/darwin/configuration.nix` (add a `networking` block)

**Interfaces:**
- Produces: `networking.hostName` and `networking.computerName` both `"macmini"`.

- [ ] **Step 1: Add the networking block**

Insert after the `services` block from Task 2:

```nix
  # Stable identity for SSH / Bonjour.
  networking = {
    hostName = "macmini";
    computerName = "macmini";
  };
```

- [ ] **Step 2: Verify evaluation**

Run (locally on Linux — eval, not build): `nix eval .#darwinConfigurations.macmini.config.networking.hostName`
Expected: `"macmini"`

- [ ] **Step 3: Commit**

```bash
git add hosts/darwin/configuration.nix
git commit --signoff -m "feat(darwin): set macmini hostname and computer name"
```

---

### Task 5: Full automatic updates

**Files:**
- Modify: `hosts/darwin/configuration.nix` (extend `system.defaults` with `SoftwareUpdate` + `CustomSystemPreferences`)

**Interfaces:**
- Consumes: the existing `system.defaults` attrset.
- Produces: `system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true` plus `com.apple.SoftwareUpdate` / `com.apple.commerce` keys via `CustomSystemPreferences`.

- [ ] **Step 1: Add SoftwareUpdate settings to `system.defaults`**

Inside the existing `system.defaults = { ... }` attrset, add:

```nix
      # Full automatic updates (OS + security + App Store). Reboots recover via auto-login.
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      CustomSystemPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
          ConfigDataInstall = 1;
        };
        "com.apple.commerce".AutoUpdate = true;
      };
```

Note: `AutomaticallyInstallMacOSUpdates` is set once via the typed option only — do **not** also add it under `CustomSystemPreferences` (duplicate-key conflict on the same domain).

- [ ] **Step 2: Verify evaluation**

Run (locally on Linux — eval, not build): `nix eval .#darwinConfigurations.macmini.config.system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates`
Expected: `true`

Run: `nix eval .#darwinConfigurations.macmini.config.system.defaults.CustomSystemPreferences --json`
Expected: JSON containing `com.apple.SoftwareUpdate` with `CriticalUpdateInstall = 1`.

- [ ] **Step 3: Commit**

```bash
git add hosts/darwin/configuration.nix
git commit --signoff -m "feat(darwin): enable full automatic macOS and app updates"
```

---

### Task 6: Build, switch, and verify on hardware

**Files:**
- None (apply + verification only)

**Interfaces:**
- Consumes: the completed `hosts/darwin/configuration.nix` from Tasks 1–5.

- [ ] **Step 1: Build the whole system (on the Mac mini)**

Run: `darwin-rebuild build --flake .#macmini`
Expected: builds with no evaluation or option error. This is the real gate that every option path is valid.

- [ ] **Step 2: Switch**

Run: `sudo darwin-rebuild switch --flake .#macmini`
Expected: activation completes; `tailscaled` and `sshd` are registered.

- [ ] **Step 3: Perform the documented manual one-time steps**

1. System Settings → Users & Groups → set "Automatically log in as **hlts2**" (writes `/etc/kcpassword`; nix cannot).
2. Run `sudo tailscale up` and authenticate the node.
3. OrbStack → Settings → enable "Start at login".

- [ ] **Step 4: Verify server behavior**

Run: `pmset -g | grep -E "sleep|autorestart"`
Expected: computer `sleep 0`; `autorestart 1`.

Run (from another Tailscale node): `ssh hlts2@macmini 'tailscale status'`
Expected: SSH succeeds and the node shows online.

Reboot test: `sudo reboot`, then after it returns confirm SSH works again and the physical console (if a monitor is attached) shows a password-locked screen.

- [ ] **Step 5: (No commit — verification only.)** If any step fails, fix the relevant task's edit and re-run `darwin-rebuild switch`.

---

## Post-implementation

After Task 6 passes, push the branch and open a PR:

```bash
git push -u origin feat/macmini-server
```
