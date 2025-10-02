pipeline {
    agent {
        docker {
            image 'node:16-alpine'  // Node 16 Docker image as build agent
            args '--privileged'     // Optional: for additional permissions
        }
    }

    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"  // Replace with your Docker Hub username
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "${IMAGE_NAME}:latest"
        
        // Jenkins credentials ID for Docker Hub
        DOCKER_CREDS_ID = 'docker-hub-credentials'  // Create this in Jenkins
    }

    stages {
        // Stage 1: Environment verification
        stage('Verify Environment') {
            steps {
                echo 'Verifying Node.js and npm installation...'
                sh 'node --version'
                sh 'npm --version'
                sh 'echo "Current directory:" && pwd'
                sh 'echo "Workspace contents:" && ls -la'
            }
        }
        
        // Stage 2: Checkout source code
        stage('Checkout Code') {
            steps {
                checkout scm  // Pulls code from the repository
            }
        }

        // Stage 3: Install dependencies
        stage('Install Dependencies') {
            steps {
                echo 'Installing project dependencies...'
                sh 'npm install --save'  // Install dependencies
                
                // Verify installation
                sh 'echo "Node modules installed:" && ls -la node_modules/ || echo "No node_modules found"'
            }
        }

        // Stage 4: Run unit tests
        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                script {
                    // Check if test script exists in package.json
                    def hasTestScript = sh(
                        script: 'npm run | grep -q "test" && echo "exists" || echo "not exists"',
                        returnStdout: true
                    ).trim()
                    
                    if (hasTestScript == "exists") {
                        sh 'npm test'
                    } else {
                        echo 'No test script found in package.json, skipping tests'
                        // Create a simple test file if none exists
                        sh '''
                            if [ ! -f test.js ]; then
                                echo "// Basic test file" > test.js
                                echo "console.log('Tests would run here');" >> test.js
                                node test.js
                            fi
                        '''
                    }
                }
            }
        }

        // Stage 5: Build Docker image
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    // Verify Dockerfile exists
                    sh 'ls -la | grep Dockerfile || echo "Dockerfile not found, creating one..."'
                    
                    // Create Dockerfile if it doesn't exist - FIXED HEREDOC SYNTAX
                    sh '''
                        if [ ! -f Dockerfile ]; then
                            cat > Dockerfile << EOF
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 8080
CMD ["node", "app.js"]
EOF
                            echo "Created Dockerfile"
                        fi
                        
                        cat Dockerfile
                    '''
                }
                
                sh """
                    docker build -t ${IMAGE_TAG} .
                    echo "Docker image built successfully:"
                    docker images | grep ${DOCKER_USERNAME} || true
                """
            }
        }

        // Stage 6: Push to Docker Registry
        stage('Push to Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}", 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "Logging into Docker Hub..."
                        echo "\${DOCKER_PASS}" | docker login -u "\${DOCKER_USER}" --password-stdin
                        
                        echo "Pushing image: ${IMAGE_TAG}"
                        docker push ${IMAGE_TAG}
                        
                        echo "Logging out from Docker Hub..."
                        docker logout
                        
                        echo "Image pushed successfully to ${DOCKER_REGISTRY}/${IMAGE_TAG}"
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            // Clean up Docker images to save space
            sh 'docker system prune -f || true'
        }
        success {
            echo '✅ CI/CD Pipeline completed successfully!'
            // You can add notifications here (email, Slack, etc.)
        }
        failure {
            echo '❌ Pipeline failed! Check the logs for details.'
            // You can add failure notifications here
        }
    }
}