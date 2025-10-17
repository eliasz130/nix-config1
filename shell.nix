# Development shell for homelab/infrastructure work
# Usage: nix-shell (legacy) or nix develop (flakes)
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "homelab-dev";

  buildInputs = with pkgs; [
    # Infrastructure as Code
    terraform
    ansible
    
    # Container tools
    docker
    docker-compose
    kubectl
    k9s  # Kubernetes TUI
    
    # Cloud CLIs (in case you expand)
    awscli2
    google-cloud-sdk
    
    # Network tools
    wireguard-tools
    nmap
    mtr
    
    # Configuration management
    git
    gnumake
    
    # Scripting
    python312
    python312Packages.requests
    python312Packages.pyyaml
    python312Packages.jinja2
    
    # Media tools (for *arr stack development)
    jq
    yq-go
    
    # Documentation
    mdbook
    
    # System monitoring
    htop
    btop
  ];

  shellHook = ''
    echo "🏠 Homelab Development Environment"
    echo ""
    echo "Available tools:"
    echo "  - Terraform $(terraform version | head -n1 | cut -d'v' -f2)"
    echo "  - Ansible $(ansible --version | head -n1 | cut -d' ' -f2)"
    echo "  - Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo "  - kubectl $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)"
    echo ""
    echo "Quick commands:"
    echo "  ssh-infra    - SSH to infrastructure server"
    echo "  ssh-media    - SSH to media server"
    echo "  deploy       - Run deployment script"
    echo ""
    
    # Set up convenience aliases
    alias ssh-infra='ssh elias@192.168.1.75'
    alias ssh-media='ssh elias@192.168.1.76'
    alias deploy='${./deploy.sh}'
    
    # Set environment variables
    export ANSIBLE_HOST_KEY_CHECKING=False
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # Create work directory if it doesn't exist
    mkdir -p "$HOME/homelab-work"
    
    # Set PS1 to show we're in dev environment
    export PS1='\[\033[1;32m\][homelab-dev]\[\033[0m\] \w $ '
  '';

  # Environment variables available in the shell
  MY_ENV_VAR = "homelab";
  
  # Python path for custom scripts
  PYTHONPATH = "./scripts:$PYTHONPATH";
}