# /etc/nixos/configuration.nix for elias-server (Infrastructure Server)
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # System
  networking.hostName = "elias-server";
  time.timeZone = "America/New_York";  # Adjust to your timezone

  # Boot
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Networking
  networking = {
    networkmanager.enable = false;
    useDHCP = false;
    interfaces.enp0s31f6 = {  # Adjust interface name from hardware-configuration.nix
      ipv4.addresses = [{
        address = "192.168.1.75";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.1.1";
    nameservers = [ "127.0.0.1" "1.1.1.1" ];  # Use own Pi-hole first
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22      # SSH
        53      # DNS (Pi-hole)
        80      # HTTP (Nginx Proxy Manager)
        443     # HTTPS (Nginx Proxy Manager)
        81      # NPM Admin
        9090    # Cockpit
        3001    # Uptime Kuma
      ];
      allowedUDPPorts = [ 
        53      # DNS (Pi-hole)
        51820   # WireGuard
      ];
    };
    
    # Disable IPv6
    enableIPv6 = false;
  };

  # WireGuard Server Configuration
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.13.13.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/root/wireguard-private.key";
    
    # Peers
    peers = [
      # Media Server
      {
        publicKey = "MEDIA_SERVER_PUBLIC_KEY_HERE";
        allowedIPs = [ "10.13.13.5/32" ];
      }
      
      # Your laptop/phone when traveling
      {
        publicKey = "LAPTOP_PUBLIC_KEY_HERE";
        allowedIPs = [ "10.13.13.10/32" ];
      }
      
      {
        publicKey = "PHONE_PUBLIC_KEY_HERE";
        allowedIPs = [ "10.13.13.11/32" ];
      }
    ];
    
    # NAT for WireGuard traffic
    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.13.13.0/24 -o enp0s31f6 -j MASQUERADE
    '';
    
    postDown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.13.13.0/24 -o enp0s31f6 -j MASQUERADE
    '';
  };

  # Enable IP forwarding for WireGuard
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = true;  # Behind firewall, OK for internal use
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Docker Compose services
  virtualisation.oci-containers = {
    backend = "docker";
    
    containers = {
      # Pi-hole (DNS & Ad-blocking)
      pihole = {
        image = "pihole/pihole:latest";
        ports = [
          "53:53/tcp"
          "53:53/udp"
          "8080:80/tcp"  # Web interface
        ];
        volumes = [
          "pihole-config:/etc/pihole"
          "pihole-dnsmasq:/etc/dnsmasq.d"
        ];
        environment = {
          TZ = "America/New_York";
          WEBPASSWORD = "change-me-please";  # Change this!
          FTLCONF_LOCAL_IPV4 = "192.168.1.75";
          DNS1 = "1.1.1.1";
          DNS2 = "1.0.0.1";
        };
        extraOptions = [
          "--dns=127.0.0.1"
          "--dns=1.1.1.1"
          "--cap-add=NET_ADMIN"
        ];
      };

      # Nginx Proxy Manager
      nginx-proxy-manager = {
        image = "jc21/nginx-proxy-manager:latest";
        ports = [
          "80:80"
          "443:443"
          "81:81"  # Admin interface
        ];
        volumes = [
          "npm-data:/data"
          "npm-letsencrypt:/etc/letsencrypt"
        ];
        environment = {
          DB_SQLITE_FILE = "/data/database.sqlite";
        };
      };

      # Home Assistant
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        volumes = [
          "homeassistant-config:/config"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          TZ = "America/New_York";
        };
        extraOptions = [
          "--network=host"  # Required for device discovery
          "--privileged"    # Required for USB devices
        ];
      };

      # Uptime Kuma (Monitoring)
      uptime-kuma = {
        image = "louislam/uptime-kuma:latest";
        ports = [ "3001:3001" ];
        volumes = [
          "uptime-kuma-data:/app/data"
        ];
        environment = {
          TZ = "America/New_York";
        };
      };
    };
  };

  # Storage mounts
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  # Backup service
  systemd.services.daily-backup = {
    description = "Daily backup of important data";
    startAt = "02:00";
    script = ''
      #!/bin/sh
      BACKUP_DIR="/mnt/storage/backups/$(date +%Y-%m-%d)"
      mkdir -p "$BACKUP_DIR"
      
      # Backup docker volumes
      ${pkgs.docker}/bin/docker run --rm \
        -v pihole-config:/source:ro \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/pihole-config.tar.gz -C /source .
      
      ${pkgs.docker}/bin/docker run --rm \
        -v npm-data:/source:ro \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/npm-data.tar.gz -C /source .
      
      ${pkgs.docker}/bin/docker run --rm \
        -v homeassistant-config:/source:ro \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/homeassistant-config.tar.gz -C /source .
      
      ${pkgs.docker}/bin/docker run --rm \
        -v uptime-kuma-data:/source:ro \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/uptime-kuma-data.tar.gz -C /source .
      
      # Backup system configs
      ${pkgs.rsync}/bin/rsync -av /etc/nixos/ "$BACKUP_DIR/nixos-config/"
      
      # Keep only last 30 days
      find /mnt/storage/backups/ -type d -mtime +30 -exec rm -rf {} +
      
      echo "Backup completed: $BACKUP_DIR"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Monitoring - Send alerts if services go down
  systemd.services.service-monitor = {
    description = "Monitor critical services";
    startAt = "*:0/15";  # Every 15 minutes
    script = ''
      #!/bin/sh
      SERVICES="docker pihole nginx-proxy-manager homeassistant uptime-kuma wg-quick-wg0"
      
      for service in $SERVICES; do
        if ! ${pkgs.systemd}/bin/systemctl is-active --quiet "$service"; then
          echo "WARNING: $service is not running!" | ${pkgs.systemd}/bin/systemd-cat -t service-monitor -p warning
        fi
      done
    '';
  };

  # User accounts
  users.users.elias = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
    ];
    shell = pkgs.zsh;
  };

  # ZSH for better shell experience
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    nano
    
    # System monitoring
    htop
    btop
    iotop
    
    # Network tools
    curl
    wget
    rsync
    nmap
    tcpdump
    bind  # for dig
    
    # Docker tools
    docker-compose
    lazydocker
    
    # System tools
    tmux
    screen
    git
    
    # WireGuard tools
    wireguard-tools
    
    # Backup tools
    restic
    borgbackup
  ];

  # NixOS version
  system.stateVersion = "24.11";
}