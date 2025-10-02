pipeline {
    agent {
        docker {
            image 'node:16'
            args '--link dind:dind -e DOCKER_HOST=tcp://dind:2376'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'docker version'
                sh 'npm install --save'
            }
        }
    }
}
