{ config, pkgs, lib, inputs, username, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.11";

    packages = with pkgs; [
      # CLI tools
      ripgrep
      fd
      eza
      bat
      fzf
      jq
      yq
      tree
      unzip
      zip

      # Development
      gnumake
      go
      rustup
      nodejs

      # Git
      gh
      lazygit
    ] ++ lib.optionals isLinux [
      # Linux only
      gcc
    ] ++ lib.optionals isDarwin [
      # macOS only
    ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;
    userName = "hlts2";
    userEmail = "hiroto.funakoshi.hiroto@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      cat = "bat";
      vim = "nvim";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    escapeTime = 0;
    baseIndex = 1;
    keyMode = "vi";
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
