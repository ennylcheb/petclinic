pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'ennyl/petclinic'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Build and Test') {
            steps {
                echo 'Building application with Maven (inside Docker)...'
                echo 'Running tests...'
                sh '''
                    chmod +x mvnw
                    ./mvnw clean test
                '''
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                echo "This will compile the application inside Docker..."
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                sh '''
                    echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Update Kubernetes Manifest') {
            steps {
                echo "Updating deployment manifest with build number: ${BUILD_NUMBER}"
                sh '''
                    sed -i "s|BUILD_NUMBER|${BUILD_NUMBER}|g" k8s/07-petclinic-deployment.yaml
                    echo "Updated image tag:"
                    cat k8s/07-petclinic-deployment.yaml | grep "image:"
                '''
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh '''
                    kubectl apply -f k8s/07-petclinic-deployment.yaml
                    kubectl apply -f k8s/08-petclinic-service.yaml
                    echo "Waiting for deployment rollout..."
                    kubectl rollout status deployment/petclinic --timeout=5m
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                sh '''
                    echo "=== Pods Status ==="
                    kubectl get pods -l app=petclinic
                    echo ""
                    echo "=== Service Details ==="
                    kubectl get svc petclinic
                    echo ""
                    echo "=== Deployment Info ==="
                    kubectl describe deployment petclinic | grep Image:
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up Docker credentials...'
            sh 'docker logout || true'
        }
        success {
            echo '=========================================='
            echo '✅ Pipeline completed successfully!'
            echo '=========================================='
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "Application URL: http://<NODE_IP>:30080"
            echo '=========================================='
        }
        failure {
            echo '=========================================='
            echo '❌ Pipeline failed!'
            echo '=========================================='
            echo 'Check the console output above for errors'
        }
    }
}
