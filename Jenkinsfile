pipeline {
    agent {
        docker {
            image 'node:16'
            args '''
                -u root:root 
                -v jenkins-docker-certs-client:/certs/client:ro 
                -e DOCKER_HOST=tcp://docker:2376 
                -e DOCKER_TLS_VERIFY=1 
                -e DOCKER_CERT_PATH=/certs/client
            '''
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
                    # Run tests if test script exists
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
                        # Fix for Debian Buster archived repos
                        cat > /etc/apt/sources.list <<EOF
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF
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
                    echo "Docker CLI installed:"
                    docker --version
                '''
            }
        }

        stage('Verify Docker Connection') {
            steps {
                echo 'Verifying Docker daemon connection...'
                sh '''
                    echo "=== Docker Environment ==="
                    echo "DOCKER_HOST: $DOCKER_HOST"
                    echo "DOCKER_CERT_PATH: $DOCKER_CERT_PATH"
                    echo "DOCKER_TLS_VERIFY: $DOCKER_TLS_VERIFY"
                    
                    echo "=== Certificate Files ==="
                    ls -la /certs/client/
                    
                    echo "=== Testing Docker Connection ==="
                    # Wait up to 30 seconds for docker daemon
                    timeout 30 sh -c 'until docker info >/dev/null 2>&1; do sleep 2; done' || {
                        echo "ERROR: Cannot connect to Docker daemon after 30 seconds"
                        echo "Attempting docker info for details:"
                        docker info || true
                        exit 1
                    }
                    
                    echo "✅ Docker connection successful!"
                    docker version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_TAG}"
                sh '''
                    echo "Current directory contents:"
                    ls -la
                    
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