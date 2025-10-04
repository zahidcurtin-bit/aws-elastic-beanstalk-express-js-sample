pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    
    stages {
        stage('Build and Tag') {
            steps {
                echo "🔨 Building Docker image: getting-started:${BUILD_NUMBER}"
                sh """
                    docker build -t getting-started:${BUILD_NUMBER} .
                    docker tag getting-started:${BUILD_NUMBER} zahidsajif/docker-study:${BUILD_NUMBER}
                    docker tag getting-started:${BUILD_NUMBER} zahidsajif/docker-study:latest
                """
            }
        }
        
        stage('Verify Build') {
            steps {
                echo "✅ Verifying built images..."
                sh """
                    docker images | grep getting-started
                    docker images | grep zahidsajif
                """
            }
        }
        
        stage('Cleanup Old Builds') {
            steps {
                echo "🧹 Cleaning up old images (keeping last 3)"
                sh '''
                    # Remove old getting-started images (keep last 3)
                    docker images getting-started --format "{{.Tag}}" | \
                    grep -E '^[0-9]+$' | \
                    sort -rn | \
                    tail -n +4 | \
                    xargs -I {} docker rmi getting-started:{} 2>/dev/null || true
                    
                    # Remove old zahidsajif images (keep last 3)
                    docker images zahidsajif/docker-study --format "{{.Tag}}" | \
                    grep -E '^[0-9]+$' | \
                    sort -rn | \
                    tail -n +4 | \
                    xargs -I {} docker rmi zahidsajif/docker-study:{} 2>/dev/null || true
                    
                    # Remove dangling images
                    docker image prune -f
                    
                    # Show disk usage
                    echo "📊 Docker disk usage:"
                    docker system df
                '''
            }
        }
    }
    
    post {
        always {
            echo '📊 Final image list:'
            sh 'docker images | head -20'
        }
        success {
            echo "✅ Build #${BUILD_NUMBER} completed successfully!"
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} failed!"
        }
    }
}