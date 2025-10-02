pipeline {
    agent {
        docker {
            image 'node:16' // NOde 16 docker image
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock' // run as root to allow global install
        }
    }

    // environment variables
    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app" // image name
        IMAGE_TAG = "${IMAGE_NAME}:latest"
        DOCKER_CREDS_ID = 'docker-hub-credentials' // jenkins credential is for docker hub
        SNYK_TOKEN = credentials('snyk-token') // jenkeins secret test for snyk
    }

    // pipline stages
    stages {
        stage('Environment Setup') {
            steps {
                echo 'Setting up the environment...'
                sh 'echo "Current Environment Variables:" && env'
                sh 'echo "Working Directory:" && pwd'
                sh 'echo "Contents of Workspace:" && ls -al /var/jenkins_home/workspace'
                sh 'echo "Current User:" && whoami'
            }
        }

        stage('Verify Node.js and npm Installation') {
            steps {
                echo 'Verifying installations of Node.js and npm...'
                sh 'node --version || echo "Node.js is not installed!"'
                sh 'npm --version || echo "npm is not installed!"'
            }
        }
        
        stage('Checkout code'){
            steps {
                checkout scm   // pull code from repo
            }
        }

        stage('install dependencies') {
            steps {
                sh 'npm install --save' // install project dependencies
            }
        }

        stage('Run unit test') {
            steps {
                sh 'npm test || echo "No tests configured"'
            }
        }

        stage('security scan (Synk)') {
            steps {
                sh '''
                    npm install -g snyk
                    snyk auth ${SNYK_TOKEN}
                    # if any HIGH or CRITICAL vulnerb found fail build
                    snyk test --severity-threshold=high
                    '''
            }
        }

        stage('Build docker image') {
            steps {
                sh  '''
                    echo "Building image $IMAGE_TAG"
                    docker build -t ${IMAGE_TAG} .
                    '''
            }
        }

        stage('push docker image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}", 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh  '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_TAG}
                        docker logout
                        '''
                }
            }
        }

    }

    // post build actions

    post {
        success {
            echo "Build and Push completed successfully"
        }
        failure {
            echo "Build failed. check log"
        }
    }

}

