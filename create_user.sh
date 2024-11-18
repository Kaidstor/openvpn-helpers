#!/bin/bash

# Переменные директорий
KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf
EASYRSA_DIR=~/openvpn-ca  # Замените на путь к вашей директории Easy-RSA

# Получаем имя клиента из аргумента
CLIENT_NAME=$1

# Проверка, был ли указан CLIENT_NAME
if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client_name>"
    exit 1
fi

# Переход в директорию Easy-RSA для генерации ключей
cd $EASYRSA_DIR || { echo "Directory $EASYRSA_DIR not found!"; exit 1; }

# Инициализация PKI, если не была выполнена ранее
if [ ! -d "$EASYRSA_DIR/pki" ]; then
    ./easyrsa init-pki
fi

# Генерация запроса на сертификат клиента
./easyrsa gen-req $CLIENT_NAME nopass

# Подписание сертификата клиента
./easyrsa sign-req client $CLIENT_NAME <<EOF
yes
EOF

# Создание необходимых директорий, если они не существуют
mkdir -p $KEY_DIR
mkdir -p $OUTPUT_DIR

# Копирование сертификатов и ключей клиента
cp $EASYRSA_DIR/pki/issued/$CLIENT_NAME.crt $KEY_DIR/
cp $EASYRSA_DIR/pki/private/$CLIENT_NAME.key $KEY_DIR/
cp $EASYRSA_DIR/pki/ca.crt $KEY_DIR/
cp $EASYRSA_DIR/ta.key $KEY_DIR/  # Убедитесь, что ta.key находится в указанной директории

# Создание файла .ovpn с конфигурацией
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${CLIENT_NAME}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${CLIENT_NAME}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn

echo "Конфигурация для клиента ${CLIENT_NAME} создана: ${OUTPUT_DIR}/${CLIENT_NAME}.ovpn"
