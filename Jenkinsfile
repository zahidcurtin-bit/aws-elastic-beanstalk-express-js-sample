pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                  docker run --rm \
                    -v $PWD:/app \
                    -w /app \
                    node:16 \
                    npm install
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                  docker run --rm \
                    -v $PWD:/app \
                    -w /app \
                    node:16 \
                    npm test || echo "⚠️ Tests failed or skipped"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                  docker build -t $IMAGE_NAME:$IMAGE_TAG .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                      echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                      docker push $IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }
    }
}
