#!/bin/bash

# Запрос у пользователя IP-адреса сервера
read -p "Введите IP-адрес сервера: " SERVER_IP

# Запрос у пользователя имени пользователя
read -p "Введите имя пользователя: " USER

#SERVER_IP="localhost"
#USER="lekaic"

# генерируем ключ
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "password"

# echo "Копируем ключ"
#cat ~/.ssh/id_ed25519.pub | ssh $USER@$SERVER_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
cat ~/.ssh/id_ed25519.pub | ssh $USER@$SERVER_IP -p 3333 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

echo "Отправляем скрипты на сервер"
scp -P 3333 dns_any.sh $USER@$SERVER_IP:/tmp/dns_any.sh
scp -P 3333 dns_localhost.sh $USER@$SERVER_IP:/tmp/dns_localhost.sh
echo "Успешно"

#scp script.sql $USER@$SERVER_IP:/script.sql
#scp remote_script.sh $USER@$SERVER_IP:/tmp/remote_script.sh