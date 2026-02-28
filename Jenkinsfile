pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'chmod +x ./build/build.sh'
                sh './build/build.sh'
            }
        }
    }

    post {
        success {
            echo 'end build container-compose-starter success'
        }

        always {
            echo 'start post'
            archiveArtifacts artifacts: '**/*.tar.gz'
        }
    }
}