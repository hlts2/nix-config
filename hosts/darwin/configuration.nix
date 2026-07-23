{ config, pkgs, inputs, username, ... }:

{
  # Nix is managed by Determinate Systems installer, not nix-darwin.
  # Settings (experimental-features, gc, etc.) are configured via Determinate.
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

  # Remote access for a headless server.
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # Stable identity for SSH / Bonjour.
  networking = {
    hostName = "macmini";
    computerName = "macmini";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  # Create /etc/zshrc that loads nix-darwin environment
  programs.zsh.enable = true;

  # macOS system settings
  system = {
    primaryUser = username;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleInterfaceStyle = "Dark";
        # キーリピート設定
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
      };

      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 48;
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };

      # Headless auto-login so user-session daemons (OrbStack) return after reboot.
      loginwindow.autoLoginUser = username;

      # A physically-attached monitor must hit a locked screen.
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

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
    };

    # macOS version
    stateVersion = 5;
  };

  # Homebrew (for GUI apps and macOS-native tools not in nixpkgs)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    casks = [
      "google-chrome"
      "ollama"
      "orbstack"
    ];
  };

  # User configuration
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;
}
