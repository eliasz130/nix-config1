# Home Manager configuration - works on both macOS and NixOS
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
    ansible
    terraform
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
    userName = "Elias";
    userEmail = "your-email@example.com";
    
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
      ssh-infra = "ssh elias@192.168.1.75";
      ssh-media = "ssh elias@192.168.1.76";
      
      # Docker shortcuts
      dc = "docker-compose";
      dps = "docker ps";
      dlogs = "docker logs -f";
      
      # NixOS shortcuts
      rebuild = "sudo nixos-rebuild switch --flake .#";
      rebuild-test = "sudo nixos-rebuild test --flake .#";
      rebuild-boot = "sudo nixos-rebuild boot --flake .#";
      
      # macOS nix-darwin shortcuts (if using darwin)
      darwin-rebuild = "darwin-rebuild switch --flake .#macbook";
    };
    
    initExtra = ''
      # Initialize zoxide
      eval "$(zoxide init zsh)"
      
      # FZF configuration
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      
      # Custom functions
      
      # SSH to homelab with WireGuard preference
      ssh-homelab() {
        if ping -c 1 -W 1 10.13.13.1 &> /dev/null; then
          ssh elias@10.13.13.$1
        else
          ssh elias@192.168.1.7$1
        fi
      }
      
      # Quick docker-compose wrapper
      dce() {
        docker-compose exec $1 ${2:-bash}
      }
      
      # Update all the things
      update-all() {
        echo "Updating nix..."
        nix flake update
        
        ${if pkgs.stdenv.isDarwin then ''
          echo "Updating homebrew..."
          brew update && brew upgrade
        '' else ""}
        
        echo "Rebuilding system..."
        ${if pkgs.stdenv.isDarwin then 
          "darwin-rebuild switch --flake ~/.config/nix-config#macbook" 
        else 
          "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)"}
      }
    '';
    
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";  # or "agnoster", "powerlevel10k/powerlevel10k"
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "kubectl"
        "terraform"
        "ansible"
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
        user = "elias";
        identityFile = "~/.ssh/id_ed25519";
        forwardAgent = true;
      };
      
      "elias-server infra" = {
        hostname = "192.168.1.75";
        user = "elias";
      };
      
      "elias-server2 media" = {
        hostname = "192.168.1.76";
        user = "elias";
      };
      
      # WireGuard addresses
      "infra-wg" = {
        hostname = "10.13.13.1";
        user = "elias";
      };
      
      "media-wg" = {
        hostname = "10.13.13.5";
        user = "elias";
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
      vim-terraform
      ansible-vim
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