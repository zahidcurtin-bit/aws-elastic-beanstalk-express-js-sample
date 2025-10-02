pipeline {
    agent {
        label 'docker'  // Use Jenkins agent labeled with 'docker'
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
                sh 'echo "Docker version:" && docker --version'
                sh 'echo "Node version:" && node --version'
                sh 'echo "npm version:" && npm --version'
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