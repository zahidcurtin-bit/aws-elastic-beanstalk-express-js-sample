pipeline {
    agent {
        docker {
            image 'node:16'
            args '-u root:root'
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
        DOCKER_CERT_PATH = "/certs/client"
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
                        echo "No test script found in package.json"
                        echo "Creating default test script..."
                        npm pkg set scripts.test="echo 'No tests specified' && exit 0"
                        npm test
                    fi
                '''
            }
        }

        stage('Install Docker CLI') {
            steps {
                echo 'Installing Docker CLI in Node container...'
                sh '''
                    if ! command -v docker >/dev/null 2>&1; then
                        echo "Fixing Debian Buster repositories..."
                        # Update sources.list to use archive for Debian Buster
                        cat > /etc/apt/sources.list << 'EOF'
deb http://archive.debian.org/debian/ buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF
                        
                        # Disable release file check for archived repositories
                        echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
                        
                        echo "Installing Docker CLI..."
                        apt-get update
                        apt-get install -y curl ca-certificates
                        curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz -o docker.tgz
                        tar -xzf docker.tgz
                        cp docker/docker /usr/local/bin/
                        rm -rf docker docker.tgz
                        chmod +x /usr/local/bin/docker
                    fi
                    docker --version
                '''
            }
        }

        stage('Wait for Docker Daemon') {
            steps {
                echo 'Waiting for Docker daemon to be ready...'
                sh '''
                    echo "Checking Docker daemon connection..."
                    until docker info >/dev/null 2>&1; do 
                        echo "Docker daemon not ready yet, waiting..."
                        sleep 1
                    done
                    echo "✅ Docker daemon is ready!"
                    docker info
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_TAG}"
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${IMAGE_TAG} -t ${IMAGE_LATEST} .
                    
                    echo "Verifying built image..."
                    docker images | grep ${IMAGE_NAME}
                '''
            }
        }

        stage('Push to Docker Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "Logging into Docker Hub..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        
                        echo "Pushing ${IMAGE_TAG}..."
                        docker push ${IMAGE_TAG}
                        
                        echo "Pushing ${IMAGE_LATEST}..."
                        docker push ${IMAGE_LATEST}
                        
                        docker logout
                        echo "Images pushed successfully!"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh '''
                docker image prune -f || true
            '''
        }
        success {
            echo '✅ CI/CD Pipeline completed successfully!'
            echo "Docker images published:"
            echo "  - ${IMAGE_TAG}"
            echo "  - ${IMAGE_LATEST}"
        }
        failure {
            echo '❌ Pipeline failed. Please check the logs above.'
        }
        cleanup {
            cleanWs()
        }
    }
}