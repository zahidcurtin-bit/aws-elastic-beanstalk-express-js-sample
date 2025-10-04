pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'  // ← ADD THIS BACK
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