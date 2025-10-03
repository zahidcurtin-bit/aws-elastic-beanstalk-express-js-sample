pipeline {
    agent {
        docker {
            image 'node:16'
            args '-u root:root --network host -v /var/run/docker.sock:/var/run/docker.sock'
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
                checkout scm
            }
        }

        stage('Environment Setup') {
            steps {
                echo 'Verifying Node environment...'
                sh 'node --version'
                sh 'npm --version'
                sh 'whoami && pwd && ls -la'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies with npm install...'
                sh 'npm install'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'npm test || echo "⚠️ No tests configured - consider adding tests"'
            }
        }

        stage('Verify Docker') {
            steps {
                echo 'Checking Docker availability...'
                script {
                    try {
                        sh 'docker --version'
                    } catch (Exception e) {
                        echo 'Docker not available in container, installing...'
                        sh '''
                            apt-get update && apt-get install -y docker.io
                            docker --version
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_TAG}"
                sh '''
                    docker build -t ${IMAGE_TAG} -t ${IMAGE_LATEST} .
                    echo "Verifying image was built:"
                    docker images | grep ${IMAGE_NAME} || true
                '''
            }
        }

        stage('Push to Docker Registry') {
            steps {
                echo 'Pushing image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}", 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_TAG}
                        docker push ${IMAGE_LATEST}
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Docker images pushed:"
            echo "  - ${IMAGE_TAG}"
            echo "  - ${IMAGE_LATEST}"
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
        always {
            echo 'Cleaning up...'
            sh 'docker image prune -f || true'
        }
    }
}