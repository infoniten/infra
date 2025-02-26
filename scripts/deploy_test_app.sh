#!/bin/bash

# Скрипт для развертывания тестового приложения в кластерах Kubernetes

# Проверка наличия необходимых утилит
command -v kubectl >/dev/null 2>&1 || { echo "Ошибка: kubectl не установлен"; exit 1; }

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для развертывания приложения в кластере
deploy_app() {
    local cluster_name=$1
    local kubeconfig_path=$2
    
    echo -e "\n=== Развертывание тестового приложения в кластере $cluster_name ==="
    
    # Создание namespace
    echo "Создание namespace 'test-app'..."
    KUBECONFIG=$kubeconfig_path kubectl create namespace test-app 2>/dev/null || true
    
    # Включение автоматического внедрения sidecar для Istio
    echo "Включение автоматического внедрения sidecar для Istio..."
    KUBECONFIG=$kubeconfig_path kubectl label namespace test-app istio-injection=enabled --overwrite
    
    # Создание временного файла с манифестом для деплоймента
    cat > /tmp/test-app-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: test-app
  namespace: test-app
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-app
  namespace: test-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app
            port:
              number: 80
EOF
    
    # Применение манифеста
    echo "Применение манифеста..."
    if KUBECONFIG=$kubeconfig_path kubectl apply -f /tmp/test-app-deployment.yaml; then
        echo -e "${GREEN}✓ Тестовое приложение успешно развернуто в кластере $cluster_name${NC}"
    else
        echo -e "${RED}✗ Ошибка при развертывании тестового приложения в кластере $cluster_name${NC}"
        return 1
    fi
    
    # Удаление временного файла
    rm /tmp/test-app-deployment.yaml
    
    # Ожидание запуска подов
    echo "Ожидание запуска подов..."
    KUBECONFIG=$kubeconfig_path kubectl wait --for=condition=available --timeout=60s deployment/test-app -n test-app
    
    # Вывод информации о подах
    echo -e "\nИнформация о подах:"
    KUBECONFIG=$kubeconfig_path kubectl get pods -n test-app
    
    # Вывод информации о сервисе
    echo -e "\nИнформация о сервисе:"
    KUBECONFIG=$kubeconfig_path kubectl get svc -n test-app
    
    return 0
}

# Проверка наличия kubeconfig файлов
if [ ! -f "./config/omega/k8s/kubeconfig.yaml" ]; then
    echo "Ошибка: kubeconfig для кластера omega не найден"
    echo "Сначала запустите кластеры с помощью 'make up' или 'make omega-up'"
    exit 1
fi

if [ ! -f "./config/psi/k8s/kubeconfig.yaml" ]; then
    echo "Ошибка: kubeconfig для кластера psi не найден"
    echo "Сначала запустите кластеры с помощью 'make up' или 'make psi-up'"
    exit 1
fi

# Развертывание приложения в кластере omega
deploy_app "omega" "$(pwd)/config/omega/k8s/kubeconfig.yaml"

# Развертывание приложения в кластере psi
deploy_app "psi" "$(pwd)/config/psi/k8s/kubeconfig.yaml"

echo -e "\n=== Развертывание тестового приложения завершено ===" 