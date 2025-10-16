{ config, pkgs, ... }:

{
  # System settings
  system.stateVersion = 6;
  system.primaryUser = "elias";

  # Nix settings
  nix = {
    enable = false;
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
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
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # Homebrew integration (for GUI apps)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    casks = [
      "firefox"
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