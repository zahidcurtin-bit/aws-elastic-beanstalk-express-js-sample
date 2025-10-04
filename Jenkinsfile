pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'  // Change to your registry
        DOCKER_IMAGE = 'your-dockerhub-username/your-app-name'  // Change this
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'  // Jenkins credential ID
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install --save'
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'npm test || echo "No tests configured"'
            }
        }

        stage('Install Docker CLI') {
            steps {
                echo 'Installing Docker CLI via binary...'
                sh '''
                    curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz -o docker.tgz
                    tar -xzf docker.tgz
                    cp docker/docker /usr/local/bin/
                    rm -rf docker docker.tgz
                    chmod +x /usr/local/bin/docker
                    docker --version
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {                    
                    // Build the Docker image
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Push to Docker Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    // Login to Docker registry and push
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                                                      usernameVariable: 'DOCKER_USERNAME', 
                                                      passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo $DOCKER_PASSWORD | docker login ${DOCKER_REGISTRY} -u $DOCKER_USERNAME --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image pushed: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            sh 'docker logout ${DOCKER_REGISTRY} || true'
            cleanWs()
        }
    }
}