pipeline {
    agent any
    
    stages {
        stage('Pull Node 16 Image') {
            steps {
                sh 'docker pull node:16'
            }
        }
        
        stage('Build in Node Container') {
            steps {
                sh '''
                    docker run --rm \
                    -v ${WORKSPACE}:/app \
                    -w /app \
                    node:16 \
                    npm install --save
                '''
            }
        }
        
        stage('Verify') {
            steps {
                sh '''
                    docker run --rm \
                    -v ${WORKSPACE}:/app \
                    -w /app \
                    node:16 \
                    npm list --depth=0
                '''
            }
        }
    }
}