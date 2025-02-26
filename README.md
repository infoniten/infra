# Тестовый полигон для DevOps

Этот проект представляет собой тестовый полигон, эмулирующий продуктивную инфраструктуру с двумя изолированными сегментами сети (omega и psi), соединенными через прокси-сервис.

## Архитектура

Инфраструктура состоит из следующих компонентов:

### Сегмент Omega
- Kubernetes кластер (k3s)
- Kafka + Zookeeper
- OpenSearch для логирования
- Prometheus + Grafana для мониторинга

### Сегмент Psi
- Kubernetes кластер (k3s)
- Kafka + Zookeeper
- OpenSearch для логирования
- Prometheus + Grafana для мониторинга

### Прокси-сервис
- Nginx, который проксирует запросы между сегментами
- Валидирует JSON и XML запросы

## Требования

- Docker
- Docker Compose
- Не менее 8 ГБ оперативной памяти
- Не менее 20 ГБ свободного места на диске

## Установка и запуск

### Запуск всей инфраструктуры

```bash
make up
```

### Запуск только определенных сегментов

```bash
# Запуск только сегмента Omega
make omega-up

# Запуск только сегмента Psi
make psi-up

# Запуск только прокси-сервиса
make proxy-up
```

### Остановка инфраструктуры

```bash
make down
```

### Проверка статуса контейнеров

```bash
make status
```

### Просмотр логов

```bash
make logs
```

### Очистка (удаление всех контейнеров и образов)

```bash
make clean
```

### Дополнительные команды

```bash
# Установка Istio в оба кластера Kubernetes
make install-istio

# Настройка Istio для межкластерной коммуникации
make setup-istio-multicluster

# Развертывание тестового приложения в обоих кластерах
make deploy-test-app

# Тестирование связи между сегментами
make test-connectivity

# Настройка репликации между кластерами Kafka
make setup-kafka-replication
```

## Доступ к сервисам

### Kubernetes
- Omega: https://localhost:6443
- Psi: https://localhost:6445

### Kafka
- Omega: localhost:9092
- Psi: localhost:9093

### OpenSearch
- Omega: http://localhost:9200
- Psi: http://localhost:9201

### Prometheus
- Omega: http://localhost:9090
- Psi: http://localhost:9091

### Grafana
- Omega: http://localhost:3000
- Psi: http://localhost:3001

### Прокси
- HTTP: http://localhost:8080
- HTTPS: https://localhost:8443

## Примечания

- Для доступа к Kubernetes кластерам используйте kubeconfig файлы, которые будут созданы в директориях `config/omega/k8s/kubeconfig.yaml` и `config/psi/k8s/kubeconfig.yaml`.
- Прокси-сервис настроен для валидации JSON и XML запросов между сегментами.
- Для тестирования коммуникации между сегментами используйте соответствующие хосты в прокси: `omega-to-psi.local` и `psi-to-omega.local`. 