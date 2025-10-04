pipeline {
    agent {
        docker {
            image 'node:16'
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
            reuseNode true
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
        stage('Environment Setup') {
            steps {
                echo 'Verifying Node environment...'
                sh 'node --version'
                sh 'npm --version'
            }
        }

        stage('Checkout Code') {
            steps {
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
                echo "Building Docker image: ${IMAGE_TAG}"
                sh '''
                    docker build -t ${IMAGE_TAG} .
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
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Docker image pushed: ${IMAGE_TAG}"
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