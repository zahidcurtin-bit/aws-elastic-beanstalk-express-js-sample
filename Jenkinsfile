pipeline {
    agent any
    
    stages {
        stage('Diagnose') {
            steps {
                sh '''
                    echo "=== PATH ==="
                    echo $PATH
                    
                    echo "=== Which Docker ==="
                    which docker || echo "docker not found in PATH"
                    
                    echo "=== Find Docker ==="
                    find /usr -name docker 2>/dev/null || echo "docker binary not found"
                    
                    echo "=== Docker Version ==="
                    /usr/bin/docker --version || echo "docker not executable at /usr/bin/docker"
                    
                    echo "=== User ==="
                    whoami
                    
                    echo "=== Groups ==="
                    groups
                '''
            }
        }
    }
}