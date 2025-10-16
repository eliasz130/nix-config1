{ config, pkgs, ... }:

{
  # System settings
  system.stateVersion = "5";
  system.primaryUser = "elias";

  # Nix settings
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      optimise.automatic = true;
    };
    gc = {
      automatic = true;
      interval = { Weekday = 7; };  # Weekly
      options = "--delete-older-than 30d";
    };
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    vim
    git
    curl
    wget
    htop
    tmux
    ripgrep
    jq
    yq
    nano
    speedtest-cli
    mas

    # Development tools
    docker
    docker-compose
    python310
    nodejs
    rust
    cmake

    # Infrastructure tools
    kubectl
    terraform
    ansible

    # Network / security
    nmap
    wireshark
    tcpdump
    netcat
    aircrack-ng
    hashcat
    john
    gobuster
    unbound
    z3

    # Media tools
    ffmpeg
    yt-dlp
    mpv
    vlc
    svt-av1
    shaderc
    libvmaf
    libplacebo

    # Compression utilities
    p7zip
    xz
    zstd
    lz4
    brotli
  ];

  # macOS system defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
      static-only = true;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleKeyboardUIMode = 3;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.trackpad.enableSecondaryClick" = true;
    };
    screencapture.location = "~/Pictures/Screenshots";
    loginwindow.GuestEnabled = false;
  };

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Meslo" ]; })
    fira-code
    jetbrains-mono
  ];

  # Homebrew integration (for GUI apps)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    taps = [
      "homebrew/cask-fonts"
      "homebrew/services"
    ];
    casks = [
      # Browsers
      "firefox"

      # Utilities
      "1password"
      "1password-cli"
      "applite"
      "chatgpt"
      "claude"
      "cloudflare-warp"
      "deepl"
      "element"
      "hiddenbar"
      "iina"
      "jdownloader"
      "keka"
      "libreoffice"
      "lulu"
      "maccy"
      "microsoft-auto-update"
      "microsoft-powerpoint"
      "microsoft-teams"
      "obsidian"
      "pearcleaner"
      "protonvpn"
      "raycast"
      "slack"
      "steam"
      "termius"
      "thunderbird"
      "utm"
      "vscodium"
      "vlc"
      "loop"
      "alt-tab"
      "barrier"
    ];
  };

  # Shell
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # User
  users.users.elias = {
    name = "elias";
    home = "/Users/elias";
    shell = pkgs.zsh;
  };
}