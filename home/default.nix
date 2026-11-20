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
    historyWidget.command = "";
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

  # Ghostty
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Window
      title = " ";
      background-opacity = 0.8;
      window-padding-x = 8;
      window-padding-y = 4;
      window-width = 128;
      window-height = 30;
      confirm-close-surface = true;

      # Scrollback
      scrollback-limit = 100000;

      # Clipboard
      copy-on-select = "clipboard";

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";

      # Notification
      desktop-notifications = true;

      # Font
      font-family = "HackGen Console NF";
      font-size = 10;

      # Input
      mouse-hide-while-typing = true;

      # Keybindings
      keybind = [
        "alt+c=copy_to_clipboard"
        "alt+v=paste_from_clipboard"
        "alt+semicolon=increase_font_size:1"
        "alt+shift+minus=decrease_font_size:1"
        "alt+enter=new_window"
        "alt+n=new_tab"
      ];

      # Colors (iceberg theme)
      background = "#161821";
      foreground = "#d2d4de";

      # Normal colors
      palette = [
        "0=#161821"
        "1=#e27878"
        "2=#b4be82"
        "3=#e2a478"
        "4=#84a0c6"
        "5=#a093c7"
        "6=#89b8c2"
        "7=#c6c8d1"

        # Bright colors
        "8=#6b7089"
        "9=#e98989"
        "10=#c0ca8e"
        "11=#e9b189"
        "12=#91acd1"
        "13=#ada0d3"
        "14=#95c4ce"
        "15=#d2d4de"
      ];
    };
  };
}
