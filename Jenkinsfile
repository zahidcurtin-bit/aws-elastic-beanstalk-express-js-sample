pipeline {
    options {
        timeout(time: 1, unit: 'HOURS')
    }

    agent {
    docker {
        image 'node:16'
        args '-u root'   // optional: run as root if you need permissions
    }
}
    stages {
        stage('build and push') {
            steps {
                sh "docker build -t getting-started:$BUILD_NUMBER ."
                sh "docker tag getting-started:$BUILD_NUMBER zahidsajif/docker-study:$BUILD_NUMBER"
                script {
                    docker.withRegistry("", 'registryCredential') {
                        sh "docker push zahidsajif/docker-study:$BUILD_NUMBER"
                    }
                }
            }
        }
    }
}
