pipeline {
    agent {
        docker {
            image 'node:16'
            args '--network project2-compose_jenkins -v /certs/client/client:/certs/client:ro -e DOCKER_HOST=tcp://docker-dind:2376 -e DOCKER_TLS_VERIFY=1 -e DOCKER_CERT_PATH=/certs/client'
            reuseNode true
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'your-dockerhub-username/your-app-name'  // Change this to your Docker Hub username/image name
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'  // Jenkins credential ID for Docker Hub
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
                sh 'npm test'
            }
        }
        
        stage('Install Docker CLI') {
            steps {
                echo 'Installing Docker CLI in Node container...'
                sh '''
                    apt-get update
                    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
                    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                    apt-get update
                    apt-get install -y docker-ce-cli
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Push to Docker Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                                                      usernameVariable: 'DOCKER_USERNAME', 
                                                      passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo $DOCKER_PASSWORD | docker login ${DOCKER_REGISTRY} -u $DOCKER_USERNAME --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            docker logout ${DOCKER_REGISTRY}
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
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}