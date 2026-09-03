pipeline {
    agent any
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    environment {
        // DOCKER_HUB = credentials('docker-hub-credentials')
        APP_IMAGE = "rokaa666/myapp"
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
                sh 'docker build -t ${APP_IMAGE}:${BUILD_NUMBER} .'
                sh 'docker tag ${APP_IMAGE}:${BUILD_NUMBER} ${APP_IMAGE}:latest'
                echo "Docker image built"
            }
        }

        stage('Test') {
            steps {
                sh 'docker run --rm ${APP_IMAGE}:${BUILD_NUMBER} pytest '
                echo "Tests passed"
            }
        }

        stage('Matrix Tests') {
            matrix {
                axes {
                    axis {
                        name 'PYTHON_VERSION'
                        values '3.9', '3.10', '3.11'
                    }
                }
                stages {
                    stage('Run Tests') {
                        steps {
                            sh '''
                            docker run --rm -v jenkins_home:/var/jenkins_home -w \${WORKSPACE} python:\${PYTHON_VERSION} \
                            sh -c "pip install -r requirements.txt && pytest -v"
                            '''
                        }
                    }
                }
            }
        }

        stage('Push to Registry') {
            steps {
                withVault(
                    configuration: [
                        vaultUrl: 'http://host.docker.internal:8200',
                        vaultCredentialId: 'vault-approle-cred',
                        engineVersion: 2
                        
                    ],
                    vaultSecrets: [
                        [
                            path: 'secret/data/myapp/docker',
                            secretValues: [
                                [envVar: 'DOCKER_HUB_USR', vaultKey: 'username'],
                                [envVar: 'DOCKER_HUB_PSW', vaultKey: 'password'],
                            ]
                        ]
                    ]

                ){
                    sh '''
                    echo $DOCKER_HUB_PSW | docker login -u $DOCKER_HUB_USR --password-stdin
                    docker push ${APP_IMAGE}:${BUILD_NUMBER}
                    docker push ${APP_IMAGE}:latest
                    '''
                }
                echo "Images pushed to Docker Hub"
            }
        }
        stage('Blue-Green Deployment') {
            steps {
                script {
                    sh '''
                    docker stop myapp-green || true
                    docker rm myapp-green || true 
                    docker run -d --name myapp-green --network myapp-network ${APP_IMAGE}:${BUILD_NUMBER}
                    '''
                    sleep 10

                    def healthCheck = sh(
                        script: 'docker exec myapp-nginx curl -s -o /dev/null -w "%{http_code}" http://myapp-green:8000/health',
                        returnStdout: true
                    ).trim()

                    if (healthCheck == '200') {
                        sh '''
                        sed -i 's/myapp-blue:8000/myapp-green:8000/' ~/nginx-config/nginx.conf
                        docker exec myapp-nginx nginx -s reload 
                        echo "Switched traffic to green"
                        '''
                    } else {
                        sh '''
                        docker stop myapp-green || true
                        docker rm myapp-green || true
                        echo Health check failed for green deployment. Rolling back to blue.
                        '''
                        error("Health check failed, deployment aborted")
                    }
                }
            }
        }

    }
    post {
        success {
            withVault(
                configuration: [
                    vaultUrl: 'http://host.docker.internal:8200',
                    vaultCredentialId: 'vault-approle-cred',
                    engineVersion: 2

                ],
                vaultSecrets: [
                    [
                        path: 'secret/data/myapp/docker',
                        secretValues: [
                            [envVar: 'SLACK_WEBHOOK', vaultKey: 'webhook_url']
                        ]
                    ]
                ]

            ){
            sh '''
            curl -X POST -H "Content-type: application/json" \
            --data '{"text":"✅ Deployment successful!"}' \
            ${SLACK_WEBHOOK}
            '''
            }
        }
        failure {
            withVault(
                configuration: [
                    vaultUrl: 'http://host.docker.internal:8200',
                    vaultCredentialId: 'vault-approle-cred',
                    engineVersion: 2

                ],
                vaultSecrets: [
                    [
                        path: 'secret/data/myapp/docker',
                        secretValues: [
                            [envVar: 'SLACK_WEBHOOK', vaultKey: 'webhook_url']
                        ]
                    ]
                ]

            ){
            sh '''
            curl -X POST -H "Content-type: application/json" \
            --data '{"text":"❌ Deployment failed!"}' \
            ${SLACK_WEBHOOK}
            '''
            }
        }
    }
}