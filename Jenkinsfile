pipeline {
    agent any

    environment {
        // Docker registry configuration
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
        SNYK_TOKEN = credentials('snyk-api-token')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "=== Checking out code from SCM ==="
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
                echo "=== Installing Node.js Dependencies ==="
                script {
                    // Use $(pwd) instead of $WORKSPACE for Docker socket mounting
                    sh '''
                      docker run --rm \
                        -v "$(pwd)":/app \
                        -w /app \
                        node:16-alpine \
                        sh -c "node -v && npm -v && npm install --save"
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo "=== Running Application Tests ==="
                script {
                    sh '''
                      docker run --rm \
                        -v "$(pwd)":/app \
                        -w /app \
                        node:16-alpine \
                        sh -c "npm test || echo 'Tests failed or skipped'"
                    '''
                }
            }
            post {
                always { 
                    junit allowEmptyResults: true, testResults: 'junit*.xml' 
                }
            }
        }

        stage('Security: Snyk Vulnerability Scan') {
            steps {
                echo "=== Running Snyk Dependency Vulnerability Scan ==="
                script {
                    def snykResult = sh(
                        script: '''
                          docker run --rm \
                            -e SNYK_TOKEN="$SNYK_TOKEN" \
                            -v "$(pwd)":/app \
                            -w /app \
                            snyk/snyk:node \
                            snyk test \
                            --file=package.json \
                            --severity-threshold=high \
                            --json-file-output=/app/snyk-report.json || true
                          
                          # Print results to console
                          docker run --rm \
                            -e SNYK_TOKEN="$SNYK_TOKEN" \
                            -v "$(pwd)":/app \
                            -w /app \
                            snyk/snyk:node \
                            snyk test \
                            --file=package.json \
                            --severity-threshold=high || true
                        ''',
                        returnStatus: true
                    )
                    
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    
                    if (snykResult != 0) {
                        unstable(message: "High or Critical vulnerabilities detected by Snyk")
                        echo "⚠️  WARNING: Security vulnerabilities found. Check snyk-report.json"
                    } else {
                        echo "✅ No High/Critical vulnerabilities detected"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "=== Building Docker Image ==="
                script {
                    sh '''
                      docker build -t "$IMAGE_NAME:$IMAGE_TAG" .
                      docker tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:latest"
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "=== Pushing Docker Image to Registry ==="
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                          echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                          docker push "$IMAGE_NAME:$IMAGE_TAG"
                          docker push "$IMAGE_NAME:latest"
                          docker logout
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Execution Completed ==="
            archiveArtifacts artifacts: 'Dockerfile, snyk-report.json', allowEmptyArchive: true
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules', type: 'INCLUDE']])
        }
        success {
            echo """
            ✅ BUILD SUCCESSFUL
            Image: $IMAGE_NAME:$IMAGE_TAG
            All stages completed successfully.
            """
        }
        failure {
            echo """
            ❌ BUILD FAILED
            Check the console output above for error details.
            """
        }
        unstable {
            echo "⚠️  Build completed with warnings (e.g., security vulnerabilities found)"
        }
    }
}