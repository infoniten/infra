#!/bin/bash

# Скрипт для тестирования связи между сегментами через прокси

# Проверка наличия необходимых утилит
command -v curl >/dev/null 2>&1 || { echo "Ошибка: curl не установлен"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Ошибка: jq не установлен. Установите его для тестирования JSON"; exit 1; }

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для тестирования JSON запроса
test_json_request() {
    local endpoint=$1
    local json_data=$2
    local description=$3
    
    echo -e "\nТестирование JSON запроса: $description"
    echo "Endpoint: $endpoint"
    echo "Данные: $json_data"
    
    # Отправка JSON запроса
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Host: $endpoint" -d "$json_data" http://localhost:8080 -w "\n%{http_code}")
    
    # Извлечение статус-кода
    status_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    # Проверка статус-кода
    if [[ $status_code -eq 200 ]]; then
        echo -e "${GREEN}✓ Успешно! Статус: $status_code${NC}"
        echo "Ответ: $response_body"
    else
        echo -e "${RED}✗ Ошибка! Статус: $status_code${NC}"
        echo "Ответ: $response_body"
    fi
}

# Функция для тестирования XML запроса
test_xml_request() {
    local endpoint=$1
    local xml_data=$2
    local description=$3
    
    echo -e "\nТестирование XML запроса: $description"
    echo "Endpoint: $endpoint"
    echo "Данные: $xml_data"
    
    # Отправка XML запроса
    response=$(curl -s -X POST -H "Content-Type: application/xml" -H "Host: $endpoint" -d "$xml_data" http://localhost:8080 -w "\n%{http_code}")
    
    # Извлечение статус-кода
    status_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    # Проверка статус-кода
    if [[ $status_code -eq 200 ]]; then
        echo -e "${GREEN}✓ Успешно! Статус: $status_code${NC}"
        echo "Ответ: $response_body"
    else
        echo -e "${RED}✗ Ошибка! Статус: $status_code${NC}"
        echo "Ответ: $response_body"
    fi
}

# Проверка, запущены ли контейнеры
if ! docker ps | grep -q "proxy"; then
    echo "Ошибка: прокси-сервис не запущен"
    echo "Сначала запустите инфраструктуру с помощью 'make up' или 'make proxy-up'"
    exit 1
fi

echo "=== Тестирование связи между сегментами через прокси ==="

# Тестирование запросов из omega в psi
echo -e "\n=== Запросы из omega в psi ==="

# Валидный JSON запрос
test_json_request "omega-to-psi.local" '{"message": "Hello from Omega", "data": {"key": "value"}}' "Валидный JSON"

# Невалидный JSON запрос
test_json_request "omega-to-psi.local" '{"message": "Invalid JSON, "data": {"key": "value"}}' "Невалидный JSON"

# Валидный XML запрос
test_xml_request "omega-to-psi.local" '<?xml version="1.0" encoding="UTF-8"?><root><message>Hello from Omega</message><data><key>value</key></data></root>' "Валидный XML"

# Невалидный XML запрос
test_xml_request "omega-to-psi.local" '<?xml version="1.0" encoding="UTF-8"?><root><message>Invalid XML</message><data><key>value</key></data>' "Невалидный XML"

# Тестирование запросов из psi в omega
echo -e "\n=== Запросы из psi в omega ==="

# Валидный JSON запрос
test_json_request "psi-to-omega.local" '{"message": "Hello from Psi", "data": {"key": "value"}}' "Валидный JSON"

# Невалидный JSON запрос
test_json_request "psi-to-omega.local" '{"message": "Invalid JSON, "data": {"key": "value"}}' "Невалидный JSON"

# Валидный XML запрос
test_xml_request "psi-to-omega.local" '<?xml version="1.0" encoding="UTF-8"?><root><message>Hello from Psi</message><data><key>value</key></data></root>' "Валидный XML"

# Невалидный XML запрос
test_xml_request "psi-to-omega.local" '<?xml version="1.0" encoding="UTF-8"?><root><message>Invalid XML</message><data><key>value</key></data>' "Невалидный XML"

echo -e "\n=== Тестирование завершено ===" 