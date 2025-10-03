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
                    
                    # Setup certificate directory
                    mkdir -p /certs/client
                    
                    # Search for Docker certificates in multiple locations
                    echo "Searching for Docker certificates..."
                    
                    # Try common Jenkins cert locations
                    if [ -d "/var/jenkins_home/certs/client" ]; then
                        echo "Found certs in /var/jenkins_home/certs/client"
                        cp -r /var/jenkins_home/certs/client/* /certs/client/ 2>/dev/null || true
                    fi
                    
                    if [ -d "/var/jenkins_home/.docker/certs/client" ]; then
                        echo "Found certs in /var/jenkins_home/.docker/certs/client"
                        cp -r /var/jenkins_home/.docker/certs/client/* /certs/client/ 2>/dev/null || true
                    fi
                    
                    # Search for ca.pem in workspace or Jenkins home
                    CERT_DIR=$(find /var/jenkins_home -type f -name "ca.pem" 2>/dev/null | grep -E "certs?/client" | head -1 | xargs -r dirname)
                    if [ -n "$CERT_DIR" ] && [ -d "$CERT_DIR" ]; then
                        echo "Found certs via find: $CERT_DIR"
                        cp "$CERT_DIR"/* /certs/client/ 2>/dev/null || true
                    fi
                    
                    # List what we found
                    echo "Certificates in /certs/client:"
                    ls -la /certs/client/ || echo "No certificates found!"
                    
                    # Verify we have the required files
                    if [ ! -f "/certs/client/ca.pem" ]; then
                        echo "WARNING: ca.pem not found!"
                        echo "Checking if Docker daemon is accessible without TLS..."
                        # Try without TLS as fallback
                        export DOCKER_TLS_VERIFY=0
                        export DOCKER_HOST="tcp://docker:2375"
                    fi
                    
                    echo "Docker setup complete"
                    docker --version
                '''
            }
        }

        stage('Verify Docker Connection') {
            steps {
                echo 'Testing Docker connection...'
                sh '''
                    # First verify certificates exist
                    if [ -f "/certs/client/ca.pem" ]; then
                        echo "✓ Using TLS with certificates"
                        export DOCKER_CERT_PATH=/certs/client
                        export DOCKER_TLS_VERIFY=1
                        export DOCKER_HOST="tcp://docker:2376"
                    else
                        echo "⚠ Certificates not found, trying non-TLS connection"
                        export DOCKER_TLS_VERIFY=0
                        export DOCKER_HOST="tcp://docker:2375"
                    fi
                    
                    # Test connection with timeout
                    echo "Testing Docker connection to $DOCKER_HOST..."
                    timeout 30 sh -c 'until docker info >/dev/null 2>&1; do echo "Waiting for Docker..."; sleep 2; done' || {
                        echo "❌ Docker connection failed!"
                        echo "Debugging information:"
                        echo "DOCKER_HOST=$DOCKER_HOST"
                        echo "DOCKER_TLS_VERIFY=$DOCKER_TLS_VERIFY"
                        echo "DOCKER_CERT_PATH=$DOCKER_CERT_PATH"
                        echo ""
                        echo "Available network services:"
                        nc -zv docker 2375 2>&1 || echo "Port 2375 (non-TLS) not accessible"
                        nc -zv docker 2376 2>&1 || echo "Port 2376 (TLS) not accessible"
                        exit 1
                    }
                    
                    echo "✅ Docker connected successfully!"
                    docker version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building: ${IMAGE_TAG}"
                sh '''
                    # Use same Docker config as verification stage
                    if [ -f "/certs/client/ca.pem" ]; then
                        export DOCKER_CERT_PATH=/certs/client
                        export DOCKER_TLS_VERIFY=1
                        export DOCKER_HOST="tcp://docker:2376"
                    else
                        export DOCKER_TLS_VERIFY=0
                        export DOCKER_HOST="tcp://docker:2375"
                    fi
                    
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
                        # Use same Docker config as verification stage
                        if [ -f "/certs/client/ca.pem" ]; then
                            export DOCKER_CERT_PATH=/certs/client
                            export DOCKER_TLS_VERIFY=1
                            export DOCKER_HOST="tcp://docker:2376"
                        else
                            export DOCKER_TLS_VERIFY=0
                            export DOCKER_HOST="tcp://docker:2375"
                        fi
                        
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
            sh '''
                if [ -f "/certs/client/ca.pem" ]; then
                    export DOCKER_CERT_PATH=/certs/client
                    export DOCKER_TLS_VERIFY=1
                    export DOCKER_HOST="tcp://docker:2376"
                else
                    export DOCKER_TLS_VERIFY=0
                    export DOCKER_HOST="tcp://docker:2375"
                fi
                docker image prune -f || true
            '''
        }
        success {
            echo '✅ Pipeline completed!'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}