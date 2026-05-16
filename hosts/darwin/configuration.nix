{ config, pkgs, inputs, username, ... }:

{
  # Nix is managed by Determinate Systems installer, not nix-darwin.
  # Settings (experimental-features, gc, etc.) are configured via Determinate.
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
      "orbstack"
      "tailscale"
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
