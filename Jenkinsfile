pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm install --save'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker --version'  // now works
            }
        }
    }
}
