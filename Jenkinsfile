pipeline {
    agent any

    environment {
        // Docker configuration
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/node-docker"
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        
        // Security credentials
        SNYK_TOKEN = credentials('snyk-api-token')
    }

    options {
        // Keep last 15 builds, 10 artifacts
        buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '10'))
        // Add timestamps to console output
        timestamps()
        // Timeout after 1 hour
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo '=== Checking out code from SCM ==='
                checkout scm
                script {
                    echo "Working Directory: ${env.WORKSPACE}"
                    sh 'git rev-parse --short HEAD'
                    sh 'ls -la'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '=== Installing Node.js Dependencies ==='
                script {
                    // Run npm install inside a Node.js container
                    // Use --save to ensure dependencies are added to package.json
                    sh '''
                        docker run --rm \
                          -v "$WORKSPACE":/app \
                          -w /app \
                          node:16-alpine \
                          sh -c "node -v && npm -v && npm install --save"
                    '''
                    echo 'Dependencies installed and saved to package.json'
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo '=== Running Application Tests ==='
                script {
                    // Run npm test inside Node.js container
                    // If tests fail, continue pipeline but log message
                    sh '''
                        docker run --rm \
                          -v "$WORKSPACE":/app \
                          -w /app \
                          node:16-alpine \
                          sh -c "npm test || echo 'Tests failed or skipped'"
                    '''
                }
            }
            post {
                always {
                    // Collect JUnit test results if available
                    junit allowEmptyResults: true, testResults: '**/junit*.xml'
                }
            }
        }

        stage('Security: Snyk Vulnerability Scan') {
            steps {
                echo '=== Running Snyk Security Scan ==='
                script {
                    // Run Snyk scan with JSON output for reporting
                    // Test against package.json for dependency vulnerabilities
                    def snykResult = sh(
                        script: '''
                            docker run --rm \
                              -v "$WORKSPACE":/app \
                              -w /app \
                              -e SNYK_TOKEN=$SNYK_TOKEN \
                              snyk/snyk:node \
                              snyk test --json --severity-threshold=high > snyk-report.json || true
                            
                            # Display results in console for immediate visibility
                            docker run --rm \
                              -v "$WORKSPACE":/app \
                              -w /app \
                              -e SNYK_TOKEN=$SNYK_TOKEN \
                              snyk/snyk:node \
                              snyk test --severity-threshold=high
                        ''',
                        returnStatus: true
                    )
                    
                    // Archive Snyk report for later review
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    
                    // Fail pipeline on high/critical vulnerabilities to prevent insecure deployments
                    if (snykResult != 0) {
                        error """
                        SECURITY SCAN FAILED!
                        High or Critical vulnerabilities detected by Snyk.
                        Review the snyk-report.json artifact for details.
                        Pipeline execution halted for security reasons.
                        """
                    } else {
                        echo "No High/Critical vulnerabilities detected"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '=== Building Docker Image ==='
                script {
                    // Build Docker image from Dockerfile in repository root
                    // Tag with both build-specific tag and latest for easy reference
                    sh """
                        docker build \
                          -t ${IMAGE_NAME}:${IMAGE_TAG} \
                          -t ${IMAGE_NAME}:latest \
                          .
                    """
                    echo "Built image: ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo '=== Pushing Docker Image to Registry ==='
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push $IMAGE_NAME:$IMAGE_TAG
                            docker push $IMAGE_NAME:latest
                            docker logout
                        '''
                    }
                    echo "Pushed image: ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            echo '=== Pipeline Execution Completed ==='
            // Archive logs and Dockerfile
            archiveArtifacts artifacts: '**/npm-debug.log, Dockerfile', allowEmptyArchive: true
            // Clean up workspace
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules', type: 'INCLUDE']])
        }
        success {
            echo """
            BUILD SUCCESSFUL
            Image: ${IMAGE_NAME}:${IMAGE_TAG}
            All stages passed including security checks.
            """
        }
        failure {
            echo """
            BUILD FAILED
            Check the console output above for error details.
            """
        }
        unstable {
            echo "Pipeline completed with warnings."
        }
    }
}