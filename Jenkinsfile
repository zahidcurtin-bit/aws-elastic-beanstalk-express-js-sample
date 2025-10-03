pipeline {
    agent {
        docker {
            image 'node:16'
            args '--user root --network jenkins_jenkins -v jenkins-docker-certs:/certs/client:ro'
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
        DOCKER_CERT_PATH = "/certs/client"
        DOCKER_TLS_VERIFY = "1"
    }

    stages {
        stage('Setup Docker CLI') {
            steps {
                echo 'Installing Docker CLI...'
                sh '''
                    # Install Docker CLI if not present
                    if ! command -v docker >/dev/null 2>&1; then
                        apt-get update
                        apt-get install -y curl
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

        stage('Verify Docker Connection') {
            steps {
                echo 'Testing Docker TLS connection...'
                sh '''
                    echo "=== TLS Configuration ==="
                    echo "DOCKER_HOST: $DOCKER_HOST"
                    echo "DOCKER_CERT_PATH: $DOCKER_CERT_PATH"
                    echo "DOCKER_TLS_VERIFY: $DOCKER_TLS_VERIFY"
                    
                    echo "=== Certificate Files ==="
                    ls -la $DOCKER_CERT_PATH/
                    
                    echo "=== Testing Connection ==="
                    docker version
                    docker info
                    echo "✅ Docker TLS connection successful!"
                '''
            }
        }

        stage('Checkout Code') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh '''
                    echo "Node: $(node --version)"
                    echo "NPM: $(npm --version)"
                    npm ci
                '''
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh '''
                    if npm run 2>&1 | grep -q "test"; then
                        npm test
                    else
                        echo "Creating default test script..."
                        npm pkg set scripts.test="echo 'No tests specified' && exit 0"
                        npm test
                    fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_TAG}"
                sh '''
                    docker build -t ${IMAGE_TAG} -t ${IMAGE_LATEST} .
                    docker images | grep ${IMAGE_NAME}
                    echo "✅ Image built successfully"
                '''
            }
        }

        stage('Push to Registry') {
            steps {
                echo 'Pushing to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_TAG}
                        docker push ${IMAGE_LATEST}
                        docker logout
                        echo "✅ Images pushed successfully!"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'docker image prune -f || true'
        }
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Images published: ${IMAGE_TAG}, ${IMAGE_LATEST}"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}