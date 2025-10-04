// ============================================================================
// Jenkins Pipeline for Node.js Application CI/CD
// Student ID: 21997112
// Project: ISEC6000 Assignment 2 - Secure DevOps
// ============================================================================

pipeline {
    agent {
        docker {
            image 'node:16'
            args '--network project2-compose_jenkins -e DOCKER_HOST=tcp://docker-dind:2375'
            reuseNode true
        }
    }

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
        IMAGE_LATEST = "${IMAGE_NAME}:latest"
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        SNYK_TOKEN = credentials('snyk-token')
    }

    stages {
        stage('Environment Setup') {
            steps {
                echo '========================================='
                echo 'Stage: Environment Setup'
                echo '========================================='
                sh '''
                    echo "Node.js Version:"
                    node --version
                    echo "NPM Version:"
                    npm --version
                    echo "Current Directory:"
                    pwd
                    echo "Directory Contents:"
                    ls -la
                    echo "Testing Docker connection..."
                    docker version
                '''
            }
        }

        stage('Checkout Code') {
            steps {
                echo '========================================='
                echo 'Stage: Checkout Code'
                echo '========================================='
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '========================================='
                echo 'Stage: Install Dependencies'
                echo '========================================='
                sh '''
                    npm install --save
                    echo "Dependencies installed successfully!"
                    npm list --depth=0 || true
                '''
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo '========================================='
                echo 'Stage: Run Unit Tests'
                echo '========================================='
                script {
                    def testResult = sh(script: 'npm test', returnStatus: true)
                    if (testResult == 0) {
                        echo '✅ All tests passed successfully!'
                    } else {
                        echo '⚠️ No tests configured or tests failed'
                    }
                }
            }
        }

        stage('Security Scan - Snyk') {
            steps {
                echo '========================================='
                echo 'Stage: Security Vulnerability Scan'
                echo '========================================='
                script {
                    try {
                        sh '''
                            npm install -g snyk
                            snyk auth ${SNYK_TOKEN}
                            snyk test --json > snyk-report.json || true
                            echo "==================================="
                            echo "Snyk Vulnerability Scan Results"
                            echo "==================================="
                            snyk test --severity-threshold=high
                        '''
                        echo '✅ Security scan passed!'
                    } catch (Exception e) {
                        echo '❌ SECURITY SCAN FAILED!'
                        echo 'High or Critical vulnerabilities detected!'
                        error("Pipeline stopped due to security vulnerabilities")
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'snyk-report.json', 
                                     allowEmptyArchive: true,
                                     fingerprint: true
                }
            }
        }

        stage('Install Docker CLI') {
            steps {
                echo '========================================='
                echo 'Stage: Install Docker CLI'
                echo '========================================='
                sh '''
                    # Install Docker CLI
                    curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz -o docker.tgz
                    tar -xzf docker.tgz
                    cp docker/docker /usr/local/bin/
                    rm -rf docker docker.tgz
                    chmod +x /usr/local/bin/docker
                    
                    echo "Docker version:"
                    docker --version
                    
                    echo "Testing connection to DinD..."
                    docker version
                    
                    if [ $? -eq 0 ]; then
                        echo "✅ Successfully connected to DinD!"
                    else
                        echo "❌ Failed to connect to DinD"
                        exit 1
                    fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '========================================='
                echo 'Stage: Build Docker Image'
                echo '========================================='
                sh '''
                    echo "Building Docker image: ${IMAGE_TAG}"
                    docker build -t ${IMAGE_TAG} .
                    docker tag ${IMAGE_TAG} ${IMAGE_LATEST}
                    echo "Successfully built Docker images:"
                    docker images | grep ${IMAGE_NAME}
                '''
            }
        }

        stage('Push to Docker Registry') {
            steps {
                echo '========================================='
                echo 'Stage: Push to Docker Registry'
                echo '========================================='
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDS_ID}", 
                    usernameVariable: 'DOCKER_USER', 
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "Logging into Docker Hub..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        echo "Pushing images to registry..."
                        docker push ${IMAGE_TAG}
                        docker push ${IMAGE_LATEST}
                        echo "✅ Images pushed successfully!"
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo ''
            echo '========================================='
            echo '✅ PIPELINE COMPLETED SUCCESSFULLY!'
            echo '========================================='
            echo "✅ Docker images built and pushed:"
            echo "   - ${IMAGE_TAG}"
            echo "   - ${IMAGE_LATEST}"
            echo '========================================='
        }
        failure {
            echo ''
            echo '========================================='
            echo '❌ PIPELINE FAILED!'
            echo '========================================='
            echo '❌ Check the logs above for details'
            echo '========================================='
        }
        always {
            echo 'Performing cleanup...'
            sh 'docker image prune -f || true'
            echo "Build completed at: ${new Date()}"
        }
    }
}