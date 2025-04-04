pipeline {
    agent any

    stages {
        stage('Run Deployment Script') {
            steps {
                echo 'Running run.sh to deploy the project...'
                sh './run.sh'
            }
        }
    }
}
