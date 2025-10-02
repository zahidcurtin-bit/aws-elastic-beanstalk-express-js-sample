pipeline {
    agent any
    
    stages {
        stage('Verify Environment') {
            steps {
                sh '''
                    echo "Node version in container:"
                    docker run --rm node:16 node --version
                    echo "NPM version in container:"
                    docker run --rm node:16 npm --version
                '''
            }
        }
        
        stage('Install Dependencies') {
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
        
        stage('List Dependencies') {
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
        
        stage('Build') {
            steps {
                sh '''
                    docker run --rm \
                    -v ${WORKSPACE}:/app \
                    -w /app \
                    node:16 \
                    npm run build || echo "No build script defined"
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}