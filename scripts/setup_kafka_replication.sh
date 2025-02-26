#!/bin/bash

# Скрипт для настройки репликации между кластерами Kafka

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка, запущены ли контейнеры
if ! docker ps | grep -q "omega-kafka"; then
    echo "Ошибка: Kafka в сегменте omega не запущена"
    echo "Сначала запустите инфраструктуру с помощью 'make up' или 'make omega-up'"
    exit 1
fi

if ! docker ps | grep -q "psi-kafka"; then
    echo "Ошибка: Kafka в сегменте psi не запущена"
    echo "Сначала запустите инфраструктуру с помощью 'make up' или 'make psi-up'"
    exit 1
fi

echo "=== Настройка репликации между кластерами Kafka ==="

# Создание тестовых топиков в обоих кластерах
echo -e "\n=== Создание тестовых топиков ==="

echo "Создание топика 'test-topic-omega' в кластере omega..."
docker exec -it omega-kafka kafka-topics.sh --create --topic test-topic-omega --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo "Создание топика 'test-topic-psi' в кластере psi..."
docker exec -it psi-kafka kafka-topics.sh --create --topic test-topic-psi --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Настройка MirrorMaker2 для репликации между кластерами
echo -e "\n=== Настройка MirrorMaker2 для репликации ==="

# Создание конфигурационного файла для MirrorMaker2
cat > /tmp/mm2.properties << EOF
# Кластеры
clusters=omega, psi

# Конфигурация кластера omega
omega.bootstrap.servers=omega-kafka:9092
omega.security.protocol=PLAINTEXT

# Конфигурация кластера psi
psi.bootstrap.servers=psi-kafka:9092
psi.security.protocol=PLAINTEXT

# Настройка репликации из omega в psi
omega->psi.enabled=true
omega->psi.topics=test-topic-omega

# Настройка репликации из psi в omega
psi->omega.enabled=true
psi->omega.topics=test-topic-psi

# Общие настройки
replication.factor=1
refresh.topics.interval.seconds=10
sync.topic.configs.enabled=true
EOF

# Запуск MirrorMaker2 в контейнере
echo "Запуск MirrorMaker2 для репликации между кластерами..."
docker run -d --name kafka-mirrormaker \
    --network omega-network \
    --network psi-network \
    -v /tmp/mm2.properties:/tmp/mm2.properties \
    bitnami/kafka:latest \
    /opt/bitnami/kafka/bin/connect-mirror-maker.sh /tmp/mm2.properties

# Проверка, что MirrorMaker2 запущен
if docker ps | grep -q "kafka-mirrormaker"; then
    echo -e "${GREEN}✓ MirrorMaker2 успешно запущен${NC}"
else
    echo -e "${RED}✗ Ошибка при запуске MirrorMaker2${NC}"
    exit 1
fi

# Удаление временного файла
rm /tmp/mm2.properties

echo -e "\n=== Тестирование репликации ==="

# Отправка сообщений в топик omega
echo "Отправка тестовых сообщений в топик 'test-topic-omega'..."
docker exec -it omega-kafka bash -c "echo 'Тестовое сообщение из omega' | kafka-console-producer.sh --topic test-topic-omega --bootstrap-server localhost:9092"

# Отправка сообщений в топик psi
echo "Отправка тестовых сообщений в топик 'test-topic-psi'..."
docker exec -it psi-kafka bash -c "echo 'Тестовое сообщение из psi' | kafka-console-producer.sh --topic test-topic-psi --bootstrap-server localhost:9092"

# Ожидание репликации
echo "Ожидание репликации сообщений (10 секунд)..."
sleep 10

# Проверка репликации из omega в psi
echo -e "\nПроверка репликации из omega в psi (чтение из 'test-topic-omega' в кластере psi):"
docker exec -it psi-kafka kafka-console-consumer.sh --topic test-topic-omega --bootstrap-server localhost:9092 --from-beginning --max-messages 1

# Проверка репликации из psi в omega
echo -e "\nПроверка репликации из psi в omega (чтение из 'test-topic-psi' в кластере omega):"
docker exec -it omega-kafka kafka-console-consumer.sh --topic test-topic-psi --bootstrap-server localhost:9092 --from-beginning --max-messages 1

echo -e "\n=== Настройка репликации между кластерами Kafka завершена ===" 