{ config, pkgs, ... }:

{
  # System settings
  system.stateVersion = 5;
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
    # CLI tools
    vim
    neovim
    git
    curl
    wget
    htop
    btop
    tmux
    ripgrep
    fd
    jq
    yq
    nano
    speedtest-cli
    mas

    # Development
    docker
    docker-compose
    python310
    python311
    node
    rust
    ruby
    lua
    luajit
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

    # Media / multimedia
    ffmpeg
    yt-dlp
    mpv
    vlc
    svt-av1
    molten-vk
    shaderc
    libvmaf
    libvidstab
    libplacebo

    # Libraries / compression
    p7zip
    xz
    zstd
    lz4
    brotli
    libpng
    libjpeg
    freetype
    fontconfig
    cairo
    harfbuzz
    fribidi
    imath
    libtiff
    libvpx
    libvorbis
    libsoxr
    opus
    speex
    speexdsp
    rav1e
    dav1d
    aom
    libass
    theora
    x264
    x265
    xvid
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
    brews = [
      # Add any missing CLI brews here
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

  programs.ssh.knownHosts = if builtins.pathExists ./ssh-known-hosts.nix
    then import ./ssh-known-hosts.nix
    else {};

  # User
  users.users.elias = {
    name = "elias";
    home = "/Users/elias";
    shell = pkgs.zsh;
  };
}