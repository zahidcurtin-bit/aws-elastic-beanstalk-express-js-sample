pipeline {
    agent any
    
    stages {
        stage('Verify Docker') {
            steps {
                sh '''
                    docker --version
                    docker info
                    docker run hello-world
                '''
            }
        }
        
        stage('Test Node 16') {
            steps {
                sh '''
                    docker pull node:16
                    docker run --rm node:16 node --version
                '''
            }
        }
    }
}