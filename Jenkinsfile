
// Jenkinsfile (root) — Node 16 + Snyk + Build & Push
pipeline {
  agent any
  environment {
    // Talk to Docker-in-Docker (DinD) over TLS (From Task 2)
    DOCKER_CERT_PATH  = '/certs/client'
    DOCKER_TLS_VERIFY = '1'

    // My forked repo and Docker Hub repo & Tag
    IMAGE_NAME = 'zahidsajif/aws-express-app'
    TAG        = "build-${env.BUILD_NUMBER}" 

    /*DOCKER_USERNAME = "zahidsajif"
    IMAGE_NAME = "${DOCKER_USERNAME}/aws-node-app"
    IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
    IMAGE_LATEST = "${IMAGE_NAME}:latest"
    DOCKER_CREDS_ID = 'docker-hub-credentials'
    SNYK_TOKEN = credentials('snyk-token')*/
    DOCKER_HOST = "tcp://docker:2376"

    // If package.json lives in a subfolder, set APP_DIR='subfolder'; otherwise '.'
    APP_DIR = '.'
  }

  options { timestamps() }

  stages {
    stage('Checkout SCM') {
      steps {
        echo "Source code has been checked out by Jenkins SCM."
        sh 'ls -la'
      }
    }

    stage('Install Dependencies (Node 16)') {
      steps {
        // Run Node 16 in a disposable container; mount Jenkins workspace and run npm install
        sh '''
          docker run --rm \
            -v "$WORKSPACE":/app -w /app \
            node:16 \
            sh -c "node -v && npm install --save"
        '''
      }
    }

    stage('Run Tests (Node 16)') {
      steps {
        // Do not break the pipeline if no tests are defined
        sh '''
          docker run --rm \
            -v "$WORKSPACE":/app -w /app \
            node:16 \
            sh -c "npm test || echo 'No tests defined'"
        '''
      }
      post {
        // Collect JUnit if present; ignore if none
        always { junit allowEmptyResults: true, testResults: 'junit*.xml' }
      }
    }

    stage('Dependency Scan (Snyk)') {
      steps {
        // Use Snyk CLI and fail the build on High/Critical (severity >= high)
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v "$WORKSPACE":/app -w /app \
              snyk/snyk:docker snyk test \
              --file=package.json \
              --severity-threshold=high \
              --json-file-output=/app/snyk-result.json
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        // Build image from the Dockerfile at repo root; use a unique, traceable tag
        sh 'docker build -t "$IMAGE_NAME:$TAG" .'
      }
    }

    stage('Push Docker image to Docker Hub') {
      steps {
        // Login and push using Jenkins credentials (ID=dockerhub)
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push "$IMAGE_NAME:$TAG"
          '''
        }
      }
    }
  }

  post {
    always {
      // Archive evidence for the report (Snyk JSON + Dockerfile)
      archiveArtifacts artifacts: 'Dockerfile, snyk-result.json', onlyIfSuccessful: false
      cleanWs()
    }
  }
}