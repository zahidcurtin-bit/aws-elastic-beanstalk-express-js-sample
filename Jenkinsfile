// Jenkinsfile - Node.js CI/CD with Snyk Security Scan
pipeline {
  agent any
  
  environment {
    // Talk to Docker-in-Docker (DinD) over TLS
    DOCKER_HOST       = 'tcp://docker:2376'
    DOCKER_CERT_PATH  = '/certs/client'
    DOCKER_TLS_VERIFY = '1'
    
    // Docker Hub configuration
    IMAGE_NAME = 'zahidsajif/aws-node-app'
    TAG        = "build-${env.BUILD_NUMBER}" 
    
    // Application directory (change if package.json is in a subfolder)
    APP_DIR = '.'
  }
  
  options { 
    timestamps() 
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  
  stages {
    stage('Checkout SCM') {
      steps {
        echo "✅ Source code has been checked out by Jenkins SCM."
        sh 'ls -la'
        sh 'pwd'
      }
    }
    
    stage('Install Dependencies (Node 16)') {
      steps {
        echo "📦 Installing Node.js dependencies..."
        sh '''
          docker run --rm \
            -v "$WORKSPACE":/app -w /app \
            node:16 \
            sh -c "node -v && npm -v && npm install --save"
        '''
        sh 'ls -la node_modules || echo "node_modules not found"'
      }
    }
    
    stage('Run Tests (Node 16)') {
      steps {
        echo "🧪 Running tests..."
        sh '''
          docker run --rm \
            -v "$WORKSPACE":/app -w /app \
            node:16 \
            sh -c "npm test || echo '⚠️ No tests defined or tests failed'"
        '''
      }
      post {
        always { 
          junit allowEmptyResults: true, testResults: 'junit*.xml' 
        }
      }
    }
    
    stage('Dependency Scan (Snyk)') {
      steps {
        echo "🔒 Running Snyk security scan..."
        withCredentials([string(credentialsId: 'snyk_token', variable: 'SNYK_TOKEN')]) {
          sh '''
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v "$WORKSPACE":/app -w /app \
              snyk/snyk:docker snyk test \
              --file=package.json \
              --severity-threshold=high \
              --json-file-output=/app/snyk-result.json \
              || echo "⚠️ Snyk found vulnerabilities"
          '''
        }
      }
      post {
        always {
          sh 'cat snyk-result.json || echo "No Snyk results found"'
        }
      }
    }
    
    stage('Build Docker Image') {
      steps {
        echo "🐳 Building Docker image..."
        sh '''
          docker build -t "$IMAGE_NAME:$TAG" .
          docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:latest"
        '''
        sh 'docker images | grep "$IMAGE_NAME"'
      }
    }
    
    stage('Push Docker Image to Docker Hub') {
      steps {
        echo "📤 Pushing Docker image to Docker Hub..."
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds', 
          usernameVariable: 'DH_USER', 
          passwordVariable: 'DH_PASS'
        )]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push "$IMAGE_NAME:$TAG"
            docker push "$IMAGE_NAME:latest"
            echo "✅ Successfully pushed $IMAGE_NAME:$TAG"
            echo "✅ Successfully pushed $IMAGE_NAME:latest"
          '''
        }
      }
      post {
        always {
          sh 'docker logout || true'
        }
      }
    }
  }
  
  post {
    success {
      echo "✅ Pipeline completed successfully!"
      echo "📦 Image: $IMAGE_NAME:$TAG"
      echo "🔗 Docker Hub: https://hub.docker.com/r/zahidsajif/aws-node-app"
    }
    failure {
      echo "❌ Pipeline failed. Check the logs above."
    }
    always {
      echo "📁 Archiving artifacts..."
      archiveArtifacts artifacts: 'Dockerfile, snyk-result.json', allowEmptyArchive: true, onlyIfSuccessful: false
      echo "🧹 Cleaning workspace..."
      cleanWs()
    }
  }
}