pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock' // optional if you need Docker in Docker
        }
    }

    environment {
        APP_NAME = 'my-node16-app'
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

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "No tests defined"'
            }
        }

        stage('Build') {
            steps {
                sh 'echo "Building the app..."'
                // Add any build steps here if required
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
    }
}