pipeline {
    agent {
        docker {
            image 'your-custom-node-docker:latest' // replace with your built image
            args '--link dind:dind -e DOCKER_HOST=tcp://dind:2376'
        }
    }

    environment {
        DOCKER_TLS_VERIFY = '1'
        DOCKER_CERT_PATH = '/certs/client'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install --save'
            }
        }

        stage('Test Docker CLI') {
            steps {
                // List Docker version to confirm CLI works
                sh 'docker version'
                // Optionally, list containers in DinD to test connection
                sh 'docker ps'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t my-node-app .'
            }
        }
    }
}
