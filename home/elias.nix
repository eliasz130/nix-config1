{ config, pkgs, lib, ... }:

{
  home.username = "elias";
  home.homeDirectory = if pkgs.stdenv.isDarwin 
    then "/Users/elias" 
    else "/home/elias";
  
  home.stateVersion = "24.11";

  # User packages (available in your PATH)
  home.packages = with pkgs; [
    # Shell utilities
    eza        # Better ls
    bat        # Better cat
    fzf        # Fuzzy finder
    zoxide     # Better cd
    direnv     # Per-directory environments
    
    # Development
    gh         # GitHub CLI
    lazygit    # Git TUI
    
    # Languages & tools
    python312
    nodejs_22
    go
    rustup
    
    # Homelab/infra specific
    wireguard-tools
    docker-compose
    
    # Network tools
    nmap
    tcpdump
    mtr
    
    # Media tools
    ffmpeg
    mediainfo
    yt-dlp
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "eliasz130";
    userEmail = "eliaspublic@icloud.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      
      # Aliases
      aliases = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      };
    };
    
    delta = {
      enable = true;
      options = {
        features = "side-by-side line-numbers decorations";
        syntax-theme = "Dracula";
      };
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      # System
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      
      # Git
      g = "git";
      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      
      # Homelab SSH shortcuts
      ssh-infra = "ssh server@192.168.1.75";
      ssh-media = "ssh server@192.168.1.76";
      
      # Docker shortcuts
      dc = "docker-compose";
      dps = "docker ps";
      dlogs = "docker logs -f";
      
      # NixOS shortcuts
      rebuild = "sudo nixos-rebuild switch --flake .#";
      rebuild-test = "sudo nixos-rebuild test --flake .#";
      rebuild-boot = "sudo nixos-rebuild boot --flake .#";
      
      # macOS nix-darwin shortcuts (if using darwin)
      darwin-rebuild = "sudo darwin-rebuild switch --flake .config/nix-config#macbook";
    };
    
    initContent = ''
      # Initialize zoxide
      eval "$(zoxide init zsh)"
      
      # FZF configuration
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      
      # Custom functions
      
      # SSH to homelab with WireGuard preference
      ssh-homelab() {
        if ping -c 1 -W 1 10.13.13.1 &> /dev/null; then
          ssh server@10.13.13.$1
        else
          ssh server@192.168.1.7$1
        fi
      }
      
      # Update all the things
      update-all() {
          echo "Updating Nix flake..."
          nix flake update --flake ~/.config/nix-config

          if [[ "$(uname)" == "Darwin" ]]; then
              if command -v brew &> /dev/null; then
                  echo "Updating Homebrew..."
                  brew update && brew upgrade
              else
                  echo "Homebrew not found, skipping..."
              fi
              echo "Rebuilding macOS system (requires sudo)..."
              sudo darwin-rebuild switch --flake ~/.config/nix-config#macbook
          else
              echo "Rebuilding NixOS system..."
              sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
          fi
      }
    '';
    
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";  # or "agnoster", "powerlevel10k/powerlevel10k"
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "sudo"
        "history"
      ];
    };
  };

  # Starship prompt (modern alternative to oh-my-zsh themes)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      
      git_branch = {
        symbol = " ";
      };
      
      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state]($style) ";
      };
    };
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    mouse = true;
    
    extraConfig = ''
      # Better prefix
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      
      # Easy config reload
      bind r source-file ~/.tmux.conf \; display "Reloaded!"
      
      # Better splits
      bind | split-window -h
      bind - split-window -v
      
      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
    
    matchBlocks = {
      "homelab-*" = {
        user = "server";
        identityFile = "~/.ssh/id_ed25519";
        forwardAgent = true;
      };
      
      "elias-server infra" = {
        hostname = "192.168.1.75";
        user = "server";
      };
      
      "elias-server2 media" = {
        hostname = "192.168.1.76";
        user = "server";
      };
      
      # WireGuard addresses
      "infra-wg" = {
        hostname = "10.13.13.1";
        user = "server";
      };
      
      "media-wg" = {
        hostname = "10.13.13.5";
        user = "server";
      };
    };
  };

  # Neovim (basic config - expand as needed)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };

  # direnv for automatic environment switching
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}