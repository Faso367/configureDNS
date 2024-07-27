#!/bin/bash

# Проверка аргументов
if [ $# -ne 2 ]; then
    echo "Использование: $0 доменное_имя ip_адрес"
    exit 1
fi

DOMAIN=$1
IP=$2
REVERSE_IP=$(echo $IP | awk -F. '{print $3"."$2"."$1}')

# Установка Bind9
apt update
apt install -y bind9

# Создание каталога для зон
mkdir -p /etc/bind/zones

# Настройка зоны прямого просмотра
ZONE_FILE="/etc/bind/zones/db.$DOMAIN"
bash -c "cat > $ZONE_FILE" <<EOL
\$TTL 604800
@   IN  SOA ns.$DOMAIN. admin.$DOMAIN. (
                $(date +%Y%m%d%H) ; Serial
                604800     ; Refresh
                86400      ; Retry
                2419200    ; Expire
                604800 )   ; Negative Cache TTL

@   IN  NS  ns.$DOMAIN.
ns  IN  A   $IP
@   IN  A   $IP
EOL

# Настройка зоны обратного просмотра
REVERSE_ZONE_FILE="/etc/bind/zones/db.$REVERSE_IP"
bash -c "cat > $REVERSE_ZONE_FILE" <<EOL
\$TTL 604800
@   IN  SOA ns.$DOMAIN. admin.$DOMAIN. (
                $(date +%Y%m%d%H) ; Serial
                604800     ; Refresh
                86400      ; Retry
                2419200    ; Expire
                604800 )   ; Negative Cache TTL

@   IN  NS  ns.$DOMAIN.
$(echo $IP | awk -F. '{print $4}')  IN  PTR $DOMAIN.
EOL

# Настройка файла конфигурации Bind
NAMED_CONF_LOCAL="/etc/bind/named.conf.local"
bash -c "cat >> $NAMED_CONF_LOCAL" <<EOL
zone "$DOMAIN" {
    type master;
    file "$ZONE_FILE";
};

zone "$(echo $REVERSE_IP).in-addr.arpa" {
    type master;
    file "$REVERSE_ZONE_FILE";
};
EOL

# Перезапуск службы Bind9
systemctl restart bind9

# Настройка локальной машины для использования вашего DNS-сервера
RESOLV_CONF="/etc/resolv.conf"
bash -c "echo 'nameserver $IP' | cat - $RESOLV_CONF > temp && mv temp $RESOLV_CONF"

# Настройка /etc/systemd/resolved.conf для постоянных изменений
RESOLVED_CONF="/etc/systemd/resolved.conf"
bash -c "cat >> $RESOLVED_CONF" <<EOL

[Resolve]
DNS=$IP
DNSStubListener=no
EOL

# Перезапуск службы systemd-resolved
systemctl restart systemd-resolved

echo "Настройка завершена. Домен $DOMAIN настроен с IP-адресом $IP."
