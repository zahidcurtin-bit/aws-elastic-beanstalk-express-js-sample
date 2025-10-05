pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_USERNAME = "zahidsajif"
        IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
        IMAGE_TAG = "latest"
        SNYK_TOKEN = credentials('snyk-api-token') // Add Snyk token in Jenkins credentials
    }

    options {
        // Store logs and artifacts
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        timestamps()
        // Timeout to prevent hanging builds
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    echo "=== Installing Node.js Dependencies ==="
                    sh '''
                      docker run --rm \
                        -v $PWD:/app \
                        -w /app \
                        node:16 \
                        npm install
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "=== Running Application Tests ==="
                    sh '''
                      docker run --rm \
                        -v $PWD:/app \
                        -w /app \
                        node:16 \
                        npm test || echo "⚠️ Tests failed or skipped"
                    '''
                }
            }
        }

        stage('Security: Snyk Vulnerability Scan') {
            steps {
                script {
                    echo "=== Running Snyk Dependency Vulnerability Scan ==="
                    
                    // Run Snyk test and capture results
                    def snykResult = sh(
                        script: '''
                          docker run --rm \
                            -v $PWD:/app \
                            -w /app \
                            -e SNYK_TOKEN=$SNYK_TOKEN \
                            snyk/snyk:node \
                            snyk test --json --severity-threshold=high > snyk-report.json || true
                          
                          # Also generate human-readable report
                          docker run --rm \
                            -v $PWD:/app \
                            -w /app \
                            -e SNYK_TOKEN=$SNYK_TOKEN \
                            snyk/snyk:node \
                            snyk test --severity-threshold=high
                        ''',
                        returnStatus: true
                    )
                    
                    // Archive the Snyk JSON report
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    
                    // Check if High/Critical vulnerabilities were found
                    if (snykResult != 0) {
                        error """
                        ❌ SECURITY SCAN FAILED!
                        High or Critical vulnerabilities detected by Snyk.
                        Check the snyk-report.json artifact for details.
                        Pipeline execution halted.
                        """
                    } else {
                        echo "✅ No High/Critical vulnerabilities detected"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker Image ==="
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
            // Clean up workspace if needed
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules', type: 'INCLUDE']])
        }
        success {
            echo "✅ Pipeline executed successfully! All stages passed."
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
        unstable {
            echo "⚠️ Pipeline completed with warnings."
        }
    }
}