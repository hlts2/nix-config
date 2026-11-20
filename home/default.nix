{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.11";

    packages =
      with pkgs;
      [
        bat
        duf
        dust
        eza
        fd
        gh
        ghq
        gnumake
        jq
        procs
        ripgrep
        tree
        unzip
        wget
        yq
        zip
        zsh-completions
      ]
      ++ lib.optionals isLinux [
        # Linux only
        # gcc
      ]
      ++ lib.optionals isDarwin [
        # macOS only
        tart
        orchard
      ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "hlts2";
        email = "hiroto.funakoshi.hiroto@gmail.com";
      };
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
    historySubstringSearch.enable = true;

    shellAliases = {
      ls = "ls -G";
      mkdir = "mkdir -p";
      grep = "grep --color";
      ".." = "cd ../";
      "..." = "cd ../..";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = ''
      [[ -f "$HOME/.zsh/.p10k.zsh" ]] && source "$HOME/.zsh/.p10k.zsh"
    '';
  };
  home.file.".zsh/.p10k.zsh".source = ./zsh/p10k.zsh;

  # Atuin
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      search_mode = "fulltext";
      workspaces = true;
      style = "full";
      inline_height = 25;
      show_preview = true;
      secrets_filter = true;
      enter_accept = false;
      sync.records = true;
      tmux.enabled = true;
    };
  };

  # Zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    historyWidgetOptions = [ ];
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
