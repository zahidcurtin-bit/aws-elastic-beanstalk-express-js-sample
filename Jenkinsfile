pipeline {
    agent any   // runs on Jenkins host which already has git
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'node:16'
                }
            }
            steps {
                sh 'npm install --save'
            }
        }
    }
}
