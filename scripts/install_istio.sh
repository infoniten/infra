#!/bin/bash

# Скрипт для установки Istio в кластерах Kubernetes

# Проверка наличия необходимых утилит
command -v kubectl >/dev/null 2>&1 || { echo "Ошибка: kubectl не установлен"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Ошибка: curl не установлен"; exit 1; }

# Функция для установки Istio в кластер
install_istio() {
    local cluster_name=$1
    local kubeconfig_path=$2
    
    echo "Установка Istio в кластер $cluster_name..."
    
    # Загрузка Istio
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.18.0 sh -
    
    # Переход в директорию Istio
    cd istio-1.18.0
    
    # Установка Istio с использованием указанного kubeconfig
    KUBECONFIG=$kubeconfig_path ./bin/istioctl install --set profile=demo -y
    
    # Включение автоматического внедрения sidecar
    KUBECONFIG=$kubeconfig_path kubectl label namespace default istio-injection=enabled
    
    # Возврат в исходную директорию
    cd ..
    
    echo "Istio успешно установлен в кластер $cluster_name"
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

# Установка Istio в кластер omega
install_istio "omega" "$(pwd)/config/omega/k8s/kubeconfig.yaml"

# Установка Istio в кластер psi
install_istio "psi" "$(pwd)/config/psi/k8s/kubeconfig.yaml"

echo "Установка Istio завершена в обоих кластерах" 