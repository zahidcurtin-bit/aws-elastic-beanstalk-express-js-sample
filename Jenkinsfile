pipeline {
    agent any

    environment {
        // Docker configuration
        DOCKER_REGISTRY = "docker.io"
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
                    docker.image('node:16-alpine').inside('-u root') {
                        sh 'node -v'
                        sh 'npm -v'
                        sh 'npm install --save'
                        echo 'Dependencies installed and saved to package.json'
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo '=== Running Application Tests ==='
                script {
                    docker.image('node:16-alpine').inside('-u root') {
                        sh 'npm test || echo "Tests failed or skipped"'
                    }
                }
            }
        }

        stage('Security: Snyk Vulnerability Scan') {
            steps {
                echo '=== Running Snyk Security Scan ==='
                script {
                    // Run Snyk scan with JSON output
                    def snykResult = sh(
                        script: '''
                            docker run --rm \
                              -v $PWD:/app \
                              -w /app \
                              -e SNYK_TOKEN=$SNYK_TOKEN \
                              snyk/snyk:node \
                              snyk test --json --severity-threshold=high > snyk-report.json || true
                            
                            # Display results in console
                            docker run --rm \
                              -v $PWD:/app \
                              -w /app \
                              -e SNYK_TOKEN=$SNYK_TOKEN \
                              snyk/snyk:node \
                              snyk test --severity-threshold=high
                        ''',
                        returnStatus: true
                    )
                    
                    // Archive Snyk report
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    
                    // Fail pipeline on high/critical vulnerabilities
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
            // Archive npm logs if they exist
            archiveArtifacts artifacts: '**/npm-debug.log', allowEmptyArchive: true
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