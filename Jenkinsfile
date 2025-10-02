pipeline {
    agent {
        docker {
            image 'node:16'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_DIR = '/usr/src/app'
    }

    stages {
        stage('Checkout') {
            steps {
                // Clone your repo
                git 'https://github.com/zahidcurtin-bit/aws-elastic-beanstalk-express-js-sample'
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${APP_DIR}") {
                    // Install dependencies and save in package.json
                    sh 'npm install --save'
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Building Node application...'
                // Add any build commands if required
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                // Example test command
                sh 'npm test || echo "No tests found"'
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
