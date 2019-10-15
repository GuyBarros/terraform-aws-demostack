#!/usr/bin/env bash
echo "==> User"

echo "--> Creating user"
sudo useradd "${demo_username}" \
  --shell /bin/bash \
  --create-home
echo "${demo_username}:${demo_password}" | sudo chpasswd
sudo tee "/etc/sudoers.d/${demo_username}" > /dev/null <<"EOF"
%${demo_username} ALL=NOPASSWD:ALL
EOF
sudo chmod 0440 "/etc/sudoers.d/${demo_username}"
sudo usermod -a -G sudo "${demo_username}"
sudo su "${demo_username}" \
  -c "ssh-keygen -q -t rsa -N '' -b 4096 -f ~/.ssh/id_rsa -C training@hashicorp.com"
sudo sed -i "/^PasswordAuthentication/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo su "${demo_username}" \
  -c 'git config --global color.ui true'
sudo su "${demo_username}" \
  -c 'git config --global user.email "training@hashicorp.com"'
sudo su ${demo_username} \
  -c 'git config --global user.name "HashiCorp Demo"'
sudo su ${demo_username} \
  -c 'git config --global credential.helper "cache --timeout=3600"'
sudo su ${demo_username} \
  -c 'mkdir -p ~/.cache; touch ~/.cache/motd.legal-displayed; touch ~/.sudo_as_admin_successful'

echo "--> Giving sudoless for Docker"
sudo usermod -aG docker "${demo_username}"


echo "--> Adding helper for identity retrieval"
sudo tee /etc/profile.d/identity.sh > /dev/null <<"EOF"
function identity {
  echo "${identity}"
}
EOF

echo "--> Ignoring LastLog"
sudo sed -i'' 's/PrintLastLog\ yes/PrintLastLog\ no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "--> Setting bash prompt"
sudo tee -a "/home/${demo_username}/.bashrc" > /dev/null <<"EOF"
export PS1="\u@\h:\w > "
EOF

echo "--> Installing Vim plugin for Terraform"
# Pathogen bundle manager
mkdir -p /home/${demo_username}/.vim/autoload /home/${demo_username}/.vim/bundle && curl -LSso /home/${demo_username}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
echo "execute pathogen#infect()" >> /home/${demo_username}/.vimrc
# Terraform plugin
cd /home/${demo_username}/.vim/bundle && git clone https://github.com/hashivim/vim-terraform.git
# Airline plugin for vim statusbar
git clone https://github.com/vim-airline/vim-airline /home/${demo_username}/.vim/bundle/vim-airline
sudo chown -R ${demo_username}:${demo_username} /home/${demo_username}/.vim*

echo "==> User is done!"
