#!/bin/bash

# Проверяем, передан ли аргумент
if [ $# -eq 0 ]; then
    echo "Использование: $0 доменное_имя"
    exit 1
fi

DOMAIN=$1

# Установка BIND9
apt update
apt install -y bind9

# Настройка BIND9
NAMED_CONF_LOCAL="/etc/bind/named.conf.local"
ZONE_FILE="/etc/bind/db.$DOMAIN"

# Добавление зоны в named.conf.local
echo "zone \"$DOMAIN\" {
    type master;
    file \"$ZONE_FILE\";
};" | tee -a $NAMED_CONF_LOCAL

# Создание файла зоны
bash -c "cat > $ZONE_FILE" <<EOL
;
; BIND data file for $DOMAIN
;
\$TTL    604800
@       IN      SOA     ns.$DOMAIN. root.$DOMAIN. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$DOMAIN.
ns      IN      A       127.0.0.1
@       IN      A       127.0.0.1
EOL

# Перезапуск BIND9
systemctl restart bind9

echo "Настройка завершена. Зона $DOMAIN добавлена и BIND9 перезапущен."
