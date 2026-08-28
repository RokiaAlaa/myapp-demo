pipeline {
    agent any
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    environment {
        DOCKER_HUB = CREDENTIALS['docker_hub_credentials']
        APP_IMAGE = "roka666/myapp"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Repository cloned"
            }
        }

        stage('Build') {
            steps {
                sh 'docker build -t ${APP_IMAGE}:{BUILD_NUMBER} .'
                sh 'docker tag ${APP_IMAGE}:{BUILD_NUMBER} ${APP_IMAGE}:latest'
                echo "Docker image built"
            }
        }

        stage('Test') {
            steps {
                sh 'docker run --rm ${APP_IMAGE}:{BUILD_NUMBER} pytest '
                echo "Tests passed"
            }
        }

        stage('Push to Registry') {
            steps {
                sh '''
                    echo $DOCKER_HUB_PSW | docker login -u $DOCKER_HUB_USR --password-stdin
                    docker push ${APP_IMAGE}:{BUILD_NUMBER}
                    docker push ${APP_IMAGE}:latest'''
                echo "Images pushed to Docker Hub"
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}