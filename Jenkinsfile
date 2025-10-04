pipeline {
    agent {
        docker {
            image 'docker:27-dind'
            args '--privileged --network host'
        }
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    environment {
        DOCKER_TLS_CERTDIR = ''  // Disable TLS for simplicity
        DOCKER_HOST = 'unix:///var/run/docker.sock'
    }
    
    stages {
        stage('Initialize Docker Daemon') {
            steps {
                script {
                    echo '🚀 Starting Docker daemon...'
                    sh '''
                        # Start Docker daemon in background
                        dockerd --host=unix:///var/run/docker.sock \
                                --host=tcp://0.0.0.0:2375 \
                                --storage-driver=overlay2 &
                        
                        # Wait for Docker daemon to be ready
                        echo "⏳ Waiting for Docker daemon to start..."
                        for i in $(seq 1 30); do
                            if docker info > /dev/null 2>&1; then
                                echo "✅ Docker daemon is ready!"
                                docker version
                                break
                            fi
                            echo "Attempt $i/30: Docker daemon not ready yet..."
                            sleep 1
                        done
                        
                        # Verify daemon is running
                        docker info
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔨 Building Docker image: getting-started:${BUILD_NUMBER}"
                    sh """
                        docker build -t getting-started:${BUILD_NUMBER} .
                        docker images | grep getting-started
                    """
                }
            }
        }
        
        stage('Tag Image') {
            steps {
                script {
                    echo "🏷️  Tagging image for Docker Hub"
                    sh """
                        docker tag getting-started:${BUILD_NUMBER} zahidsajif/docker-study:${BUILD_NUMBER}
                        docker tag getting-started:${BUILD_NUMBER} zahidsajif/docker-study:latest
                        docker images | grep zahidsajif
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    echo "📤 Pushing image to Docker Hub"
                    // Use Jenkins credentials for Docker Hub
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials', 
                        usernameVariable: 'DOCKER_USER', 
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push zahidsajif/docker-study:${BUILD_NUMBER}
                            docker push zahidsajif/docker-study:latest
                        '''
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo "🧹 Cleaning up local images"
                    sh """
                        docker rmi getting-started:${BUILD_NUMBER} || true
                        docker rmi zahidsajif/docker-study:${BUILD_NUMBER} || true
                        docker system prune -f
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo '📊 Build Summary:'
                sh 'docker images || true'
            }
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}