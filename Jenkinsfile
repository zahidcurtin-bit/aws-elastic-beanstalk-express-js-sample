pipeline {
    agent {
        docker {
            image 'docker:latest'  // Use an image with Docker installed
            args '-v /var/run/docker.sock:/var/run/docker.sock'  // Mount Docker socket
        }
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    
    stages {
        stage('build and push') {
            steps {
                sh "docker build -t getting-started:${BUILD_NUMBER} ."
                sh "docker tag getting-started:${BUILD_NUMBER} zahidsajif/docker-study:${BUILD_NUMBER}"
            }
        }
    }
}