{ config, pkgs, ... }:

{
  # System settings
  system.stateVersion = 6;
  system.primaryUser = "elias";
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix = {
    enable = false;
  };

  nix.extraOptions = ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
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
    (yazi.override {
		  _7zz = _7zz-rar;  # Support for RAR extraction
	  })
    fastfetch
    eza
    zsh-syntax-highlighting
    maccy
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

  security.pam.services.sudo_local.touchIdAuth = true;

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
      cleanup = "zap";
    };
    taps = [];
    brews = [];
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
      "keka"
      "libreoffice"
      "lulu"
      "microsoft-auto-update"
      "microsoft-powerpoint"
      "microsoft-teams"
      "obsidian"
      "pearcleaner"
      "protonvpn"
      "raycast"
      "slack"
      "steam"
      "thunderbird"
      "utm"
      "vscodium"
      "vlc"
      "barrier"
      "iterm2"
      "hazeover"
    ];
  };

  # Shell
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    extraConfig = ''
      yabai -m config focus_follows_mouse no
      yabai -m config mouse_follows_focus yes
      yabai -m config window_placement second_child
      yabai -m config window_opacity on
      yabai -m config window_opacity_duration 0.0
      yabai -m config window_topmost on
      yabai -m config window_shadow float
      yabai -m config active_window_opacity 1.0
      yabai -m config normal_window_opacity 1.0
      yabai -m config split_ratio 0.50
      yabai -m config auto_balance on
      yabai -m config mouse_modifier fn
      yabai -m config mouse_action1 move
      yabai -m config mouse_action2 resize
      yabai -m config layout bsp
      yabai -m config top_padding 10
      yabai -m config bottom_padding 10
      yabai -m config left_padding 10
      yabai -m config right_padding 10
      yabai -m config window_gap 10

      yabai -m rule --add app='System Preferences' manage=off
    '';
  };

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = builtins.readFile ./config/skhdrc;
  };

  # User
  users.users.elias = {
    name = "elias";
    home = "/Users/elias";
    shell = pkgs.zsh;
  };
}