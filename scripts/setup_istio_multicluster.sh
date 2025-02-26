#!/bin/bash

# Скрипт для настройки Istio для межкластерной коммуникации

# Проверка наличия необходимых утилит
command -v kubectl >/dev/null 2>&1 || { echo "Ошибка: kubectl не установлен"; exit 1; }
command -v istioctl >/dev/null 2>&1 || { echo "Ошибка: istioctl не установлен. Установите Istio сначала."; exit 1; }

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для настройки Istio в кластере
setup_istio_cluster() {
    local cluster_name=$1
    local kubeconfig_path=$2
    local peer_cluster=$3
    local peer_kubeconfig_path=$4
    
    echo -e "\n=== Настройка Istio для межкластерной коммуникации в кластере $cluster_name ==="
    
    # Создание namespace для Istio
    echo "Создание namespace 'istio-system'..."
    KUBECONFIG=$kubeconfig_path kubectl create namespace istio-system 2>/dev/null || true
    
    # Создание секрета с учетными данными для доступа к peer-кластеру
    echo "Создание секрета с учетными данными для доступа к кластеру $peer_cluster..."
    KUBECONFIG=$kubeconfig_path istioctl x create-remote-secret \
        --name=$peer_cluster \
        --context=$(KUBECONFIG=$peer_kubeconfig_path kubectl config current-context) \
        --kubeconfig=$peer_kubeconfig_path | \
        KUBECONFIG=$kubeconfig_path kubectl apply -f -
    
    # Создание Gateway для межкластерной коммуникации
    echo "Создание Gateway для межкластерной коммуникации..."
    cat > /tmp/multicluster-gateway.yaml << EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: cross-network-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: tls
      protocol: TLS
    tls:
      mode: AUTO_PASSTHROUGH
    hosts:
    - "*.local"
EOF
    
    # Применение манифеста Gateway
    echo "Применение манифеста Gateway..."
    if KUBECONFIG=$kubeconfig_path kubectl apply -f /tmp/multicluster-gateway.yaml; then
        echo -e "${GREEN}✓ Gateway для межкластерной коммуникации успешно создан в кластере $cluster_name${NC}"
    else
        echo -e "${RED}✗ Ошибка при создании Gateway для межкластерной коммуникации в кластере $cluster_name${NC}"
        return 1
    fi
    
    # Удаление временного файла
    rm /tmp/multicluster-gateway.yaml
    
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

# Настройка Istio в кластере omega
setup_istio_cluster "omega" "$(pwd)/config/omega/k8s/kubeconfig.yaml" "psi" "$(pwd)/config/psi/k8s/kubeconfig.yaml"

# Настройка Istio в кластере psi
setup_istio_cluster "psi" "$(pwd)/config/psi/k8s/kubeconfig.yaml" "omega" "$(pwd)/config/omega/k8s/kubeconfig.yaml"

echo -e "\n=== Настройка Istio для межкластерной коммуникации завершена ==="
echo -e "Теперь сервисы в обоих кластерах могут взаимодействовать через Istio Service Mesh" 