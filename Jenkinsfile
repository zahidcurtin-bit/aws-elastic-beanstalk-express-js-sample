pipeline {
    agent {
        docker {
            image 'node:16'
            reuseNode true
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'your-dockerhub-username/aws-express-app'  // Update this
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install'
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                script {
                    // Create basic test script if none exists
                    sh '''
                        if ! npm run | grep -q "test"; then
                            echo "Adding test script to package.json..."
                            npm set-script test "echo 'No tests configured' && exit 0"
                        fi
                        npm test
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:24.0.9-cli'  // Use specific Docker CLI version matching your server
                    args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                echo 'Building Docker image...'
                script {
                    // Create Dockerfile if it doesn't exist
                    sh '''
                        if [ ! -f "Dockerfile" ]; then
                            echo "Creating Dockerfile..."
                            cat > Dockerfile << EOF
                        FROM node:16-alpine
                        WORKDIR /app
                        COPY package*.json ./
                        RUN npm install --production
                        COPY . .
                        EXPOSE 8080
                        USER node
                        CMD ["npm", "start"]
                        EOF
                        fi
                        
                        echo "Dockerfile contents:"
                        cat Dockerfile
                    '''
                    
                    sh """
                        echo "Building Docker image..."
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                        echo "Images built:"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }
        
        stage('Push to Docker Registry') {
            agent {
                docker {
                    image 'docker:24.0.9-cli'
                    args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                        usernameVariable: 'DOCKER_USERNAME', 
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh '''
                            echo "Logging into Docker Hub..."
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                            echo "Pushing images..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            docker logout
                            echo "Push completed successfully!"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            sh '''
                # Clean up Docker images to save space
                docker images -q ${DOCKER_IMAGE} | xargs -r docker rmi -f 2>/dev/null || true
            '''
        }
    }
}