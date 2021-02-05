# PAM

## Введение

Копируем Vagrantfile в директорию на компьютере.

## Запуск тестового окружения

Открываем консоль, перейдим в директорию с проектом и выполнить `vagrant up`
```shell
vagrant up
```

## Подключение к серверу и переходим в директорию со скриптом

Для подключения к серверу необходимо выполнить
```shell
vagrant ssh centos
sudo -i
```

# Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

Создаем двух пользователей user и admin:

```shell
useradd user && useradd admin
```

Задаем пароли user=user и admin=admin:

```shell
echo "user" | passwd --stdin user && echo "admin" | passwd --stdin admin
```

Добавим в группу admin=admin:

```shell
gpasswd -M admin, admin
```

Разрешим вход через ssh по паролю:

```shell
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service
```

Настроить доступ пользователей, воспользуемся модулем 'pam_exec', который позволяет выполнить скрипт при подключении пользователя. Приведем файл /etc/pam.d/sshd к следующему виду:

```shell
[root@centos ~]# cat /etc/pam.d/sshd
#%PAM-1.0
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_exec.so /usr/local/bin/pam.sh
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
```

Сам скрипт /usr/local/bin/pam.sh выглядит следующим образом:

```shell
[root@centos ~]# cat /usr/local/bin/pam.sh
#!/bin/bash

group=$(groups $PAM_USER | grep -c admin)
uday=$(date +%u)

if [[ $group -eq 1 || $uday -gt 5 ]]; then
   exit 0
  else
   exit 1
fi
```

Делаем скрипт исполняемым и проверяем подключение по ssh:

```shell
chmod +x /usr/local/bin/pam.sh
```

# Вывод
<details><summary>Пример вывода</summary>
<p>

```log
PS C:\Users\Diamond> ssh user@192.168.11.101 
user@192.168.11.101's password:
/usr/local/bin/pam.sh failed: exit code 1
Connection closed by 192.168.11.101 port 22
PS C:\Users\Diamond> ssh admin@192.168.11.101
admin@192.168.11.101's password: 
Last login: Fri Feb  5 06:24:50 2021 from 192.168.11.1
[admin@centos ~]$ exit
```
</p>
</details>

Как видим, под пользователем user соединение заркывается, а под пользователем admin подключение проходит успешно.

Также запретим вход всем пользователям, кроме группы admin, в выходные непосредственно с локальной консоли сервера. Для этого приведем файл /etc/pam.d/login к следующему виду:

```shell
[root@centos ~]# cat /etc/pam.d/login
#%PAM-1.0
auth [user_unknown=ignore success=ok ignore=ignore default=bad] pam_securetty.so
auth       substack     system-auth
auth       include      postlogin
account    required     pam_nologin.so
account    include      system-auth
account    required     pam_exec.so    /usr/local/bin/pam.sh
password   include      system-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_console.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
session    include      postlogin
-session   optional     pam_ck_connector.so
```

