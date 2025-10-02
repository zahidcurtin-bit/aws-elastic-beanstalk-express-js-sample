pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
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
        
        stage('Verify Installation') {
            steps {
                sh 'node --version'
                sh 'npm --version'
                sh 'npm list --depth=0'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}