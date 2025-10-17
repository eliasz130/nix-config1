# Travel USB - Portable NixOS system with persistence
{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # System
  networking.hostName = "travel-nixos";
  time.timeZone = "America/New_York";

  # Kernel & boot
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Support more filesystems
    supportedFilesystems = [ "ntfs" "exfat" "btrfs" "ext4" "xfs" "zfs" ];
    
    # Hardware support
    initrd.availableKernelModules = [ 
      "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" 
      "rtsx_pci_sdmmc" "nvme"
    ];
  };

  # Networking with multiple options
  networking = {
    networkmanager.enable = true;
    wireless.enable = false;  # NetworkManager handles this
    
    # Firewall mostly disabled for flexibility
    firewall.enable = false;
    
    # Enable IPv6
    enableIPv6 = true;
  };

  # Services useful for travel/rescue
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;  # Convenience for travel
        PermitRootLogin = "no";
      };
    };
    
    # Auto-mount USB devices
    udisks2.enable = true;
    
    # Network discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    
    # X11 with lightweight desktop (optional)
    xserver = {
      enable = true;
      
      displayManager.lightdm.enable = true;
      desktopManager.xfce = {
        enable = true;
        enableXfwm = true;
      };
      
      # US keyboard layout
      xkb.layout = "us";
    };
  };

  # Persistence - save specific directories across reboots
  # This assumes you'll partition the USB with a persistent storage partition
  fileSystems."/persist" = {
    device = "/dev/disk/by-label/PERSIST";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "nofail" ];
  };

  # Bind mount important directories to persistent storage
  fileSystems."/home" = {
    device = "/persist/home";
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/etc/nixos" = {
    device = "/persist/nixos";
    fsType = "none";
    options = [ "bind" "nofail" ];
  };

  # Comprehensive tool suite for travel/rescue/work
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    nano
    
    # Shell & CLI tools
    zsh
    tmux
    screen
    htop
    btop
    iotop
    
    # File managers
    mc          # Midnight Commander
    ranger
    
    # Network tools
    wget
    curl
    rsync
    nmap
    tcpdump
    wireshark
    iperf3
    mtr
    traceroute
    dig
    whois
    
    # System tools
    parted
    gparted
    smartmontools
    testdisk
    ddrescue
    
    # Development
    git
    python3
    nodejs
    go
    gcc
    gnumake
    
    # Container tools
    docker
    docker-compose
    podman
    
    # Infrastructure
    kubectl
    terraform
    ansible
    
    # SSH & VPN
    wireguard-tools
    openvpn
    
    # Backup & sync
    rclone
    borgbackup
    restic
    
    # Media tools
    ffmpeg
    imagemagick
    
    # Compression
    p7zip
    unzip
    unrar
    
    # Disk utilities
    ncdu        # Disk usage analyzer
    duf         # Better df
    
    # Hardware info
    lshw
    pciutils
    usbutils
    
    # File recovery
    photorec
    extundelete
    
    # Browsers (for GUI mode)
    firefox
    
    # Office (lightweight)
    libreoffice
    
    # Remote desktop
    freerdp
    remmina
    
    # Password management
    keepassxc
    
    # System monitoring
    glances
    
    # Network monitoring
    bandwhich
    
    # Benchmarking
    sysbench
    stress-ng
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;  # Start manually to save resources
  };

  # User with sudo access
  users.users.traveler = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ];
    initialPassword = "rW&xrit8";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
    ];
  };

  # Allow sudo without password (convenience for travel)
  security.sudo.wheelNeedsPassword = false;

  # Zsh as default shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Auto-login to console (GUI login still requires password)
  services.getty.autologinUser = lib.mkForce null;  # Disable for security

  # Useful shell aliases
  environment.shellAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    "..." = "cd ../..";
    
    # Quick network tests
    myip = "curl ifconfig.me";
    ports = "netstat -tulanp";
    
    # Disk usage
    diskspace = "duf";
    folders = "ncdu";
    
    # Process management
    psg = "ps aux | grep -v grep | grep -i -e VSZ -e";
    
    # Docker shortcuts
    dps = "docker ps";
    dimg = "docker images";
    
    # System info
    sysinfo = "inxi -Fxz";
  };

  # Configure console
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Localization
  i18n.defaultLocale = "en_US.UTF-8";

  # Sound (for GUI mode)
  hardware.pulseaudio.enable = true;
  
  # Enable firmware updates
  services.fwupd.enable = true;

  # NixOS version
  system.stateVersion = "24.11";

  # ISO-specific settings
  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    
    # Customize boot menu
    appendToMenuLabel = " - Travel USB";
    
    # Compression
    squashfsCompression = "zstd -Xcompression-level 15";
  };
}