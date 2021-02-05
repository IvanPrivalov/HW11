#!/usr/bin/env bash
sudo -i
### Задание 1
useradd user && useradd admin
echo "user" | passwd --stdin user && echo "admin" | passwd --stdin admin
gpasswd -M admin, admin
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service
cp /vagrant/pam.sh /usr/local/bin
sed -i "7i account    required     pam_exec.so /usr/local/bin/pam.sh" /etc/pam.d/sshd
sed -i "7i account    required     pam_exec.so /usr/local/bin/pam.sh" /etc/pam.d/login
systemctl restart sshd.service
chmod +x /usr/local/bin/pam.sh