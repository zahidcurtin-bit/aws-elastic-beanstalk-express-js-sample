pipeline {
    agent {
        docker {
            image 'node:16-alpine'
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "${IMAGE_NAME}:latest"
        DOCKER_CREDS_ID = 'docker-hub-credentials'
    }

    stages {
        stage('Verify Environment') {
            steps {
                echo 'Verifying environment...'
                sh 'node --version && npm --version'
                sh 'docker --version'
                sh 'echo "Current directory:" && pwd && ls -la'
            }
        }
        
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing project dependencies...'
                sh 'npm install --save'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                script {
                    def hasTestScript = sh(
                        script: 'npm run | grep -q "test" && echo "exists" || echo "not exists"',
                        returnStdout: true
                    ).trim()
                    
                    if (hasTestScript == "exists") {
                        sh 'npm test'
                    } else {
                        echo 'No test script found in package.json, skipping tests'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    // Create Dockerfile if it doesn't exist
                    sh '''
                        if [ ! -f Dockerfile ]; then
                            cat > Dockerfile << EOF
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 8080
CMD ["node", "app.js"]
EOF
                            echo "Created Dockerfile"
                        fi
                        echo "Dockerfile contents:"
                        cat Dockerfile
                    '''
                }
                
                sh """
                    docker build -t ${IMAGE_TAG} .
                    echo "Docker image built successfully:"
                    docker images | grep ${DOCKER_USERNAME} || echo "Image created but not found in list"
                """
            }
        }

        stage('Push to Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}", 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "\${DOCKER_PASS}" | docker login -u "\${DOCKER_USER}" --password-stdin
                        docker push ${IMAGE_TAG}
                        docker logout
                        echo "Image pushed successfully to ${DOCKER_REGISTRY}/${IMAGE_TAG}"
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            // Clean up Docker images to save space
            sh 'docker system prune -f || true'
        }
        success {
            echo '✅ CI/CD Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed! Check the logs for details.'
        }
    }
}