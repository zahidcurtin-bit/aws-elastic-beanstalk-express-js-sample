pipeline {
  agent any

  environment {
    APP_NAME          = "aws-app"
    DOCKER_REGISTRY   = "docker.io/balalabalala"
    DOCKER_IMAGE      = "${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER}"

    DOCKER_HOST       = "tcp://docker:2376"
    DOCKER_CERT_PATH  = "/certs/client"
    DOCKER_TLS_VERIFY = "1"
  }

  stages {
    stage('Bootstrap docker CLI on controller') {
      steps {
        sh '''
          set -eux
          apt-get update
          apt-get install -y docker.io
          docker --version
        '''
      }
    }

    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/zbh1990/aws-elastic-beanstalk-express-js-sample.git'
        sh 'mkdir -p logs'
      }
    }

    stage('Install Dependencies') {
      agent { docker { image 'node:16'; args '-u root:root' } }
      steps {
        sh '''
          bash -lc '
            set -euo pipefail
            mkdir -p logs
            npm install --save 2>&1 | tee logs/install.log
          '
        '''
        stash name: 'install-log', includes: 'logs/install.log'
      }
    }

    stage('Run Tests') {
      agent { docker { image 'node:16'; args '-u root:root' } }
      steps {
        sh '''
          bash -lc '
            set -euo pipefail
            mkdir -p logs
            npm test 2>&1 | tee logs/test.log
          '
        '''
        stash name: 'test-log', includes: 'logs/test.log'
      }
    }

    stage('Security Scan - Snyk') {
      agent { docker { image 'node:16'; args '-u root:root' } }
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            bash -lc '
              set -euo pipefail
              mkdir -p logs
              npm install -g snyk
              snyk auth "$SNYK_TOKEN"
              snyk test --severity-threshold=high 2>&1 | tee logs/scan.log
            '
          '''
        }
         stash name: 'scan-log', includes: 'logs/scan.log'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          bash -lc '
            set -euo pipefail
            DOCKER_HOST=$DOCKER_HOST docker build -t ${DOCKER_IMAGE} . 2>&1 | tee logs/build.log
          '
        '''
      }
    }



   


    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            bash -lc '
              set -euo pipefail
              echo "$DOCKER_PASS" | DOCKER_HOST=$DOCKER_HOST docker login -u "$DOCKER_USER" --password-stdin
              DOCKER_HOST=$DOCKER_HOST docker push ${DOCKER_IMAGE} 2>&1 | tee logs/push.log
            '
          '''
        }
      }
    }

    stage('Collect Logs') {
        steps {
            sh 'mkdir -p logs'
            script {
            ['install-log','test-log','scan-log'].each { n ->
                try { unstash n } catch (e) { echo "No stash for ${n} (${e.message})" }
            }
            }
            sh '''
            set -e
            if [ -f /var/log/jenkins/audit.log.0 ]; then
                cp /var/log/jenkins/audit.log.0 logs/audit.log
                echo "Copied /var/log/jenkins/audit.log.0 -> logs/audit.log"
            else
                echo "audit.log.0 not found at /var/log/jenkins/audit.log.0 (skipping)"
            fi
            '''
        }
    }

  }

  post {
    always {
      archiveArtifacts artifacts: 'logs/install.log,logs/test.log,logs/scan.log,logs/build.log,logs/push.log,logs/audit.log',
                        allowEmptyArchive: true, fingerprint: true
    }
    success { echo 'Pipeline completed successfully' }
    failure { echo 'Pipeline failed' }
  }
}