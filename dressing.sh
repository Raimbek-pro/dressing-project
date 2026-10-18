#!/bin/bash
set -e   # stop at the first error

cd ~     # always start from your home folder

# Your public key from the Mac (cat ~/.ssh/gcp_dressing.pub)
PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMyUHkkOOGRSZtSjknS2zA4lexg0DXPCLgV6HnnpnHiw raimbekq75"

id admin &>/dev/null || sudo  useradd --create-home --shell /bin/bash admin
id frontend &>/dev/null || sudo useradd --create-home --shell /bin/bash frontend
id backend  &>/dev/null || sudo useradd --create-home --shell /bin/bash backend

if [ -d dressing-project ]; then
 sudo chown -R raimbekq75:raimbekq75 dressing-project
 git -C dressing-project pull 
else 
 git clone  https://github.com/Raimbek-pro/dressing-project.git
fi

cd dressing-project 

sudo chown backend:backend db api nginx docker-compose.yml README.md
sudo chown frontend:frontend frontend
sudo chmod 550 db api nginx frontend docker-compose.yml
#550 means the owner and group can read and enter, and others have no access. So frontend
#cannot open the backend folders, and backend cannot open frontend.

#sudo rights


echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin > /dev/null
sudo chmod 0440 /etc/sudoers.d/admin


# 4. SSH key for admin
sudo install -d -m 700 -o admin -g admin /home/admin/.ssh
sudo touch /home/admin/.ssh/authorized_keys
sudo grep -qxF "$PUBKEY" /home/admin/.ssh/authorized_keys \
  || echo "$PUBKEY" | sudo tee -a /home/admin/.ssh/authorized_keys > /dev/null
sudo chown admin:admin /home/admin/.ssh/authorized_keys
sudo chmod 600 /home/admin/.ssh/authorized_keys

# 5. Allow the groups to log in over SSH (keep google-sudoers!)
sudo sed -i 's/^AllowGroups .*/AllowGroups  google-sudoers admin frontend backend/' \
  /etc/ssh/sshd_config.d/10-dressing.conf
sudo sshd -t
sudo systemctl reload ssh


#6 serviced
#install docker
# install Docker (only if missing)
docker --version &>/dev/null || sudo apt install -y docker.io docker-compose

# let the containers read the project files
sudo chmod -R o+rX /home/raimbekq75/dressing-project

# write the unit file
sudo tee /etc/systemd/system/dressing.service > /dev/null <<'EOF'
[Unit]
Description=Dressing project
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/raimbekq75/dressing-project
ExecStart=/usr/bin/docker compose up -d --build
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

# load and enable it
sudo systemctl daemon-reload
sudo systemctl enable --now dressing

# quick check
sleep 10
curl localhost:8080/api/items
