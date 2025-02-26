.PHONY: up down status clean logs help install-istio test-connectivity deploy-test-app setup-istio-multicluster setup-kafka-replication jenkins-up jenkins-setup jenkins-agents-setup

help:
	@echo "Доступные команды:"
	@echo "  make up      - Поднять всю инфраструктуру"
	@echo "  make down    - Остановить всю инфраструктуру"
	@echo "  make status  - Проверить статус контейнеров"
	@echo "  make clean   - Удалить все контейнеры и образы"
	@echo "  make logs    - Показать логи всех контейнеров"
	@echo "  make omega-up - Поднять только сегмент omega"
	@echo "  make psi-up  - Поднять только сегмент psi"
	@echo "  make proxy-up - Поднять только прокси-сервис"
	@echo "  make jenkins-up - Поднять только Jenkins и его слейвы"
	@echo "  make jenkins-setup - Настроить Jenkins и получить начальный пароль"
	@echo "  make jenkins-agents-setup - Настроить и запустить агенты Jenkins"
	@echo "  make install-istio - Установить Istio в оба кластера Kubernetes"
	@echo "  make test-connectivity - Протестировать связь между сегментами"
	@echo "  make deploy-test-app - Развернуть тестовое приложение в обоих кластерах"
	@echo "  make setup-istio-multicluster - Настроить Istio для межкластерной коммуникации"
	@echo "  make setup-kafka-replication - Настроить репликацию между кластерами Kafka"

up:
	@echo "Поднимаем всю инфраструктуру..."
	docker-compose -f docker-compose.yaml up -d

down:
	@echo "Останавливаем всю инфраструктуру..."
	docker-compose -f docker-compose.yaml down

status:
	@echo "Статус контейнеров:"
	docker-compose -f docker-compose.yaml ps

clean:
	@echo "Удаляем все контейнеры и образы..."
	docker-compose -f docker-compose.yaml down -v --rmi all

logs:
	@echo "Логи контейнеров:"
	docker-compose -f docker-compose.yaml logs -f

omega-up:
	@echo "Поднимаем сегмент omega..."
	docker-compose -f docker-compose.yaml up -d omega-k8s omega-kafka omega-opensearch omega-monitoring

psi-up:
	@echo "Поднимаем сегмент psi..."
	docker-compose -f docker-compose.yaml up -d psi-k8s psi-kafka psi-opensearch psi-monitoring

proxy-up:
	@echo "Поднимаем прокси-сервис..."
	docker-compose -f docker-compose.yaml up -d proxy

jenkins-up:
	@echo "Поднимаем Jenkins и его слейвы..."
	docker-compose -f docker-compose.yaml up -d jenkins-master jenkins-slave-omega jenkins-slave-psi

jenkins-setup:
	@echo "Настраиваем Jenkins и получаем начальный пароль..."
	./scripts/setup_jenkins.sh

jenkins-agents-setup:
	@echo "Настраиваем и запускаем агенты Jenkins..."
	./scripts/jenkins_agents_setup.sh

install-istio:
	@echo "Устанавливаем Istio в кластеры Kubernetes..."
	./scripts/install_istio.sh

test-connectivity:
	@echo "Тестируем связь между сегментами..."
	./scripts/test_connectivity.sh

deploy-test-app:
	@echo "Разворачиваем тестовое приложение в обоих кластерах..."
	./scripts/deploy_test_app.sh

setup-istio-multicluster:
	@echo "Настраиваем Istio для межкластерной коммуникации..."
	./scripts/setup_istio_multicluster.sh

setup-kafka-replication:
	@echo "Настраиваем репликацию между кластерами Kafka..."
	./scripts/setup_kafka_replication.sh 