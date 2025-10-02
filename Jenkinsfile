pipeline {
    agent {
        docker {
            image 'node:16'
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

        stage('Test Docker Bind') {
            steps {
                sh 'docker run --rm -v $PWD:/app node:16 ls /app'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t my-node-app .'
            }
        }
    }
}
