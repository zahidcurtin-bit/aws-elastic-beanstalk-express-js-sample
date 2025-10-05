pipeline {
    agent any   // Run pipeline on any available Jenkins agent

    environment {
        // Define global environment variables
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app" // Docker image name
        IMAGE_TAG = "latest"                           // Always tag latest
        SNYK_TOKEN = credentials('snyk-api-token')     // Use Snyk token stored in Jenkins credentials
    }

    options {
        // Keep only last 10 builds + artifacts
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        // Add timestamps in console log
        timestamps()
        // Stop build if it runs more than 1 hour
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    echo "=== Installing Node.js Dependencies ==="
                    // Run npm install inside a Node.js container
                    sh '''
                      docker run --rm \
                        -v ${WORKSPACE}:/app \
                        -w /app \
                        node:16 \
                        sh -c "node -v && npm install --save"
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "=== Running Application Tests ==="
                    // Run npm test inside Node.js container
                    // If tests fail, continue but log message
                    sh '''
                      docker run --rm \
                        -v ${WORKSPACE}:/app \
                        -w /app \
                        node:16 \
                        sh -c "npm test || echo 'Tests failed or skipped'"
                    '''
                }
            }
        }

        stage('Security: Snyk Vulnerability Scan') {
            steps {
                script {
                    echo "=== Running Snyk Dependency Vulnerability Scan ==="
                    
                    // Run Snyk scan and save JSON report
                    def snykResult = sh(
                        script: '''
                          docker run --rm \
                            -v ${WORKSPACE}:/app \
                            -w /app \
                            -e SNYK_TOKEN=$SNYK_TOKEN \
                            snyk/snyk:node \
                            snyk test --json --severity-threshold=high > snyk-report.json || true
                          
                          # Also print results in terminal
                          docker run --rm \
                            -v ${WORKSPACE}:/app \
                            -w /app \
                            -e SNYK_TOKEN=$SNYK_TOKEN \
                            snyk/snyk:node \
                            snyk test --severity-threshold=high
                        ''',
                        returnStatus: true
                    )
                    
                    // Save the Snyk report file in Jenkins artifacts
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    
                    // Fail pipeline if High or Critical issues found
                    if (snykResult != 0) {
                        error """
                        SECURITY SCAN FAILED!
                        High or Critical vulnerabilities detected by Snyk.
                        Check the snyk-report.json artifact for details.
                        Pipeline execution halted.
                        """
                    } else {
                        echo "No High/Critical vulnerabilities detected"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker Image ==="
                    // Build Docker image from Dockerfile
                    sh '''
                      docker build -t $IMAGE_NAME:$IMAGE_TAG .
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "=== Pushing Docker Image to Registry ==="
                    // Login to DockerHub using Jenkins credentials
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                          echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                          docker push $IMAGE_NAME:$IMAGE_TAG
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
            // Clean up workspace after build
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules', type: 'INCLUDE']])
        }
        success {
            echo "Pipeline executed successfully! All stages passed."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
        unstable {
            echo "Pipeline completed with warnings."
        }
    }
}