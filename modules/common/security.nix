# Common security hardening for all servers
{ config, pkgs, lib, ... }:

{
  # SSH Configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowUsers = [ "elias" ];
    };
    
    # Modern ciphers only
    extraConfig = ''
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    '';
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    
    # Log dropped packets (for monitoring)
    logRefusedConnections = true;
    logRefusedPackets = false;  # Too noisy, enable for debugging
    
    # Rate limiting for SSH
    extraCommands = ''
      # Rate limit SSH connections
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    '';
  };

  # Fail2ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";  # 1 week max
      overalljails = true;
    };
    
    jails = {
      # SSH protection
      sshd = ''
        enabled = true
        port = 22
        filter = sshd
        logpath = /var/log/auth.log
        maxretry = 5
      '';
      
      # Docker service protection (if you expose ports)
      docker-auth = ''
        enabled = true
        port = http,https
        filter = docker-auth
        logpath = /var/lib/docker/containers/*/*-json.log
        maxretry = 3
      '';
    };
  };

  # Audit system (auditd)
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Monitor /etc for changes
      "-w /etc -p wa -k etc_changes"
      
      # Monitor user/group modifications
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      
      # Monitor sudo usage
      "-w /var/log/sudo.log -p wa -k sudo_log"
      
      # Monitor SSH
      "-w /etc/ssh/sshd_config -p wa -k sshd_config"
      
      # Monitor systemd
      "-w /usr/lib/systemd/ -p wa -k systemd"
      "-w /etc/systemd/ -p wa -k systemd"
    ];
  };

  # Kernel hardening
  boot.kernel.sysctl = {
    # IP forwarding (needed for WireGuard)
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 0;  # IPv6 disabled
    
    # Disable IPv6
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
    
    # Prevent SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_syn_retries" = 2;
    "net.ipv4.tcp_synack_retries" = 2;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    
    # Disable source packet routing
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # Disable ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    
    # Enable reverse path filtering
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    
    # Ignore ICMP pings
    # "net.ipv4.icmp_echo_ignore_all" = 1;  # Uncomment if you want to disable ping
    
    # Log suspicious packets
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    
    # Protect against time-wait assassination
    "net.ipv4.tcp_rfc1337" = 1;
    
    # Kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.yama.ptrace_scope" = 2;
    
    # Virtual memory
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Disable core dumps
  systemd.coredump.enable = false;
  security.pam.loginLimits = [
    { domain = "*"; type = "hard"; item = "core"; value = "0"; }
  ];

  # Automatic security updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
    flake = "/etc/nixos";
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
  };

  # Automatic reboot if kernel changes (optional)
  # systemd.services.nixos-upgrade.serviceConfig.ExecStartPost = 
  #   lib.mkIf config.system.autoUpgrade.allowReboot "${pkgs.systemd}/bin/systemctl reboot";

  # Install security tools
  environment.systemPackages = with pkgs; [
    fail2ban
    lynis          # Security auditing tool
    chkrootkit     # Rootkit checker
    rkhunter       # Another rootkit hunter
    aide           # File integrity checker
  ];

  # AppArmor or SELinux (optional - choose one)
  # security.apparmor.enable = true;
  
  # Set secure umask
  security.pam.services.sudo.text = ''
    session optional pam_umask.so umask=0077
  '';

  # Restrict su command
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };

  # Systemd service hardening template
  # Use this for your custom services
  systemd.services.example-hardened-service = {
    enable = false;  # Example only
    serviceConfig = {
      # Security options
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      SystemCallFilter = [ "@system-service" "~@privileged" ];
    };
  };

  # Weekly security audits
  systemd.services.security-audit = {
    description = "Weekly security audit";
    startAt = "weekly";
    script = ''
      ${pkgs.lynis}/bin/lynis audit system --quick --quiet > /var/log/lynis-audit.log 2>&1
    '';
  };

  # Monitor important log files
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/auth.log" = {
        frequency = "daily";
        rotate = 30;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
      "/var/log/audit/audit.log" = {
        frequency = "daily";
        rotate = 30;
        compress = true;
        delaycompress = true;
      };
    };
  };
}