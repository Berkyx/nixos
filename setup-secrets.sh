#!/usr/bin/env bash
set -euo pipefail

echo "🔑 Setting up server secrets..."

# Ensure server user and home directory exist
sudo mkdir -p /home/server/.config/sops/age
sudo chown -R server:server /home/server || true

# Generate age key if needed
if ! sudo test -f /home/server/.config/sops/age/keys.txt; then
    echo "📝 Generating age key..."
    sudo -u server age-keygen -o /home/server/.config/sops/age/keys.txt
    sudo chmod 600 /home/server/.config/sops/age/keys.txt
else
    echo "✅ Age key already exists"
fi

# Get public key
PUBLIC_KEY=$(sudo grep "public key:" /home/server/.config/sops/age/keys.txt | cut -d' ' -f4)
echo "🔍 Public key: $PUBLIC_KEY"

# Update .sops.yaml in this directory
cat > .sops.yaml << EOF
keys:
  - &server $PUBLIC_KEY

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
    - age:
      - *server 
EOF

echo "📄 Created .sops.yaml"

# Create secrets directory and file
mkdir -p secrets
if [ ! -f secrets/secrets.yaml ] || [ ! -s secrets/secrets.yaml ]; then
    echo "🎲 Generating new passwords..."
    
    # Generate random passwords
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    GRAFANA_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    REDIS_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Create unencrypted secrets
    cat > secrets/secrets.yaml << EOF
server:
  postgres_password: $POSTGRES_PASS
  grafana_admin_password: $GRAFANA_PASS
  redis_password: $REDIS_PASS
EOF
    
    echo "🔐 Encrypting secrets..."
    SOPS_AGE_KEY_FILE=/home/server/.config/sops/age/keys.txt sops -e -i secrets/secrets.yaml
    
    echo "✅ Secrets created and encrypted!"
else
    echo "✅ Secrets already exist"
fi

echo "🎉 Setup complete! Now run: sudo nixos-rebuild switch" 