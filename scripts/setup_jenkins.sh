#!/bin/bash

# Скрипт для настройки Jenkins и его слейвов

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка, запущен ли Jenkins
if ! docker ps | grep -q "jenkins-master"; then
    echo "Ошибка: Jenkins мастер не запущен"
    echo "Сначала запустите инфраструктуру с помощью 'make up'"
    exit 1
fi

echo "=== Настройка Jenkins ==="

# Получение начального пароля администратора
echo -e "\n=== Получение начального пароля администратора ==="
JENKINS_PASSWORD=$(docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null)

if [ -z "$JENKINS_PASSWORD" ]; then
    echo -e "${RED}✗ Не удалось получить начальный пароль администратора${NC}"
    echo "Возможно, Jenkins еще не полностью инициализирован. Подождите несколько минут и попробуйте снова."
    echo "Вы также можете получить пароль вручную с помощью команды:"
    echo "docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword"
else
    echo -e "${GREEN}✓ Начальный пароль администратора: $JENKINS_PASSWORD${NC}"
    echo "Используйте этот пароль для первоначальной настройки Jenkins по адресу http://localhost:8080/jenkins"
fi

# Инструкции по настройке слейвов
echo -e "\n=== Инструкции по настройке слейвов ==="
echo "1. Войдите в Jenkins по адресу http://localhost:8080/jenkins"
echo "2. Перейдите в 'Manage Jenkins' -> 'Manage Nodes and Clouds'"
echo "3. Нажмите 'New Node' и создайте два новых узла:"
echo "   - Имя: omega-agent"
echo "     - Тип: Permanent Agent"
echo "     - Remote root directory: /home/jenkins/agent"
echo "     - Labels: omega"
echo "     - Launch method: Launch agent via Java Web Start"
echo "   - Имя: psi-agent"
echo "     - Тип: Permanent Agent"
echo "     - Remote root directory: /home/jenkins/agent"
echo "     - Labels: psi"
echo "     - Launch method: Launch agent via Java Web Start"
echo "4. Для каждого агента получите секретный ключ и используйте его для запуска агента:"
echo "   docker exec jenkins-slave-omega java -jar /usr/share/jenkins/agent.jar -jnlpUrl http://jenkins-master:8080/jenkins/computer/omega-agent/slave-agent.jnlp -secret <SECRET> -workDir /home/jenkins/agent"
echo "   docker exec jenkins-slave-psi java -jar /usr/share/jenkins/agent.jar -jnlpUrl http://jenkins-master:8080/jenkins/computer/psi-agent/slave-agent.jnlp -secret <SECRET> -workDir /home/jenkins/agent"

# Создание примера pipeline для обоих сегментов
echo -e "\n=== Пример pipeline для обоих сегментов ==="
cat << 'EOF'
pipeline {
    agent none
    
    stages {
        stage('Omega Segment') {
            agent {
                label 'omega'
            }
            steps {
                sh 'echo "Выполнение задачи в сегменте Omega"'
                sh 'hostname'
                sh 'curl -s http://omega-kafka:9092 || echo "Проверка соединения с Kafka в сегменте Omega"'
            }
        }
        
        stage('Psi Segment') {
            agent {
                label 'psi'
            }
            steps {
                sh 'echo "Выполнение задачи в сегменте Psi"'
                sh 'hostname'
                sh 'curl -s http://psi-kafka:9092 || echo "Проверка соединения с Kafka в сегменте Psi"'
            }
        }
    }
}
EOF

echo -e "\n=== Настройка Jenkins завершена ===" 