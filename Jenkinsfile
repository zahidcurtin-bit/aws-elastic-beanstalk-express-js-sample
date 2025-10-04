pipeline {
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    
    agent any
    stages {
        
        stage('build and push') {
            
           steps {
               

             sh "docker build -t getting-started:$BUILD_NUMBER ."
             sh "docker tag getting-started:$BUILD_NUMBER zahidsajif/docker-study:$BUILD_NUMBER"
            
           }
        }
    }
}