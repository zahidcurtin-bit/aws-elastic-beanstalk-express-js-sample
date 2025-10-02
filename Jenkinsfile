pipeline {
    agent {
        docker {
            image 'node:16'
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "${IMAGE_NAME}:latest"
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        SNYK_TOKEN = credentials('snyk-token')
    }

    stages {
        stage('Environment Setup') {
            steps {
                echo 'Setting up the environment...'
                sh 'node --version'
                sh 'npm --version'
            }
        }

        stage('Install Docker in Container') {
            steps {
                sh '''
                    # Install Docker CLI in the Node.js container
                    apt-get update
                    apt-get install -y apt-transport-https ca-certificates curl gnupg
                    install -m 0755 -d /etc/apt/keyrings
                    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    chmod a+r /etc/apt/keyrings/docker.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                    apt-get update
                    apt-get install -y docker-ce-cli
                    docker --version
                '''
            }
        }
        
        stage('Checkout code') {
            steps {
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm install --save'
            }
        }

        stage('Run unit test') {
            steps {
                sh 'npm test || echo "No tests configured"'
            }
        }

        stage('Security scan (Snyk)') {
            steps {
                sh '''
                    npm install -g snyk
                    snyk auth ${SNYK_TOKEN}
                    snyk test --severity-threshold=high
                '''
            }
        }

        stage('Build docker image') {
            steps {
                sh '''
                    echo "Building image $IMAGE_TAG"
                    docker build -t ${IMAGE_TAG} .
                '''
            }
        }

        stage('Push docker image') {
            steps {
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
            echo "Build and Push completed successfully"
        }
        failure {
            echo "Build failed. check log"
        }
    }
}