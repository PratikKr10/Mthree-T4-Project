pipeline {
    agent any

    environment {
        NAMESPACE = "uber"
    }

    stages {

        stage('🧪 Check Minikube') {
            steps {
                script {
                    echo "🔍 Checking if Minikube is running..."
                    def status = sh(script: "minikube status | grep 'host: Running'", returnStatus: true)
                    if (status != 0) {
                        error("❌ Minikube is not running! Please start it manually using 'minikube start' before running this pipeline.")
                    } else {
                        echo "✅ Minikube is running."
                    }
                }
            }
        }

        stage('🔨 Build & Deploy') {
            steps {
                echo '🏗 Running run.sh to build & deploy...'
                sh './run.sh'
            }
        }
    }

    post {
        failure {
            echo '💥 Build failed. Check logs for errors.'
        }
        success {
            echo '🎉 Deployment successful!'
        }
    }
}
