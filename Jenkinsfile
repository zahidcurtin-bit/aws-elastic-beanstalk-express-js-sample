pipeline {
    agent {
        docker {
            image 'node:16'
            args '-u root:root -v /var/jenkins_home:/var/jenkins_home:ro'
            reuseNode true
        }
    }

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        IMAGE_LATEST = "${IMAGE_NAME}:latest"
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        DOCKER_HOST = "tcp://docker:2376"
        DOCKER_TLS_VERIFY = "1"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies with npm install --save...'
                sh 'npm install --save'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    if npm run 2>&1 | grep -q "test"; then
                        npm test
                    else
                        echo "No test script found, creating default..."
                        npm pkg set scripts.test="echo 'No tests specified' && exit 0"
                        npm test
                    fi
                '''
            }
        }

        stage('Setup Docker') {
            steps {
                echo 'Setting up Docker CLI and certificates...'
                sh '''
                    # Install Docker CLI
                    if ! command -v docker >/dev/null 2>&1; then
                        echo "Installing Docker CLI..."
                        cat > /etc/apt/sources.list <<EOF
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF
                        echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
                        apt-get update
                        apt-get install -y curl ca-certificates
                        curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz -o docker.tgz
                        tar -xzf docker.tgz
                        cp docker/docker /usr/local/bin/
                        rm -rf docker docker.tgz
                        chmod +x /usr/local/bin/docker
                    fi
                    
                    # Copy certificates from Jenkins home (which is mounted)
                    mkdir -p /root/.docker
                    cp -r /var/jenkins_home/.docker/certs /root/.docker/ || {
                        echo "Copying certs from alternate location..."
                        mkdir -p /certs/client
                        # Try to find certs in Jenkins workspace
                        find /var/jenkins_home -name "ca.pem" -path "*/certs/client/*" -exec dirname {} \\; | head -1 | xargs -I {} cp -r {} /certs/client/
                    }
                    
                    # Set cert path
                    export DOCKER_CERT_PATH=/certs/client
                    
                    echo "Docker setup complete"
                    docker --version
                '''
            }
        }

        stage('Verify Docker Connection') {
            steps {
                echo 'Testing Docker connection...'
                sh '''
                    export DOCKER_CERT_PATH=/certs/client
                    timeout 30 sh -c 'until docker info >/dev/null 2>&1; do echo "Waiting..."; sleep 2; done'
                    echo "✅ Docker connected!"
                    docker version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building: ${IMAGE_TAG}"
                sh '''
                    export DOCKER_CERT_PATH=/certs/client
                    docker build -t ${IMAGE_TAG} -t ${IMAGE_LATEST} .
                    docker images | grep ${IMAGE_NAME}
                '''
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        export DOCKER_CERT_PATH=/certs/client
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_TAG}
                        docker push ${IMAGE_LATEST}
                        docker logout
                        echo "✅ Push complete!"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f || true'
        }
        success {
            echo '✅ Pipeline completed!'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}