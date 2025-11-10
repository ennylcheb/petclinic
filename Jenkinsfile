pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-dind
spec:
  containers:
  - name: jenkins
    image: jenkins/jenkins:lts-jdk21
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-certs
      mountPath: /certs/client
  - name: docker
    image: docker:25-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: /certs
    volumeMounts:
    - name: docker-certs
      mountPath: /certs/client
    - name: docker-storage
      mountPath: /var/lib/docker
  volumes:
  - name: docker-certs
    emptyDir: {}
  - name: docker-storage
    emptyDir: {}
"""
        }
    }

    environment {
        DOCKER_HOST = "tcp://localhost:2375"
        DOCKER_TLS_CERTDIR = ""
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'ennyl/petclinic'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                container('jenkins') {
                    echo '🧪 Building application with Maven (inside Jenkins container)...'
                    sh '''
                        chmod +x mvnw
                        ./mvnw clean test
                    '''
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    echo "🐳 Building Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    echo '🚀 Pushing image to Docker Hub...'
                    sh '''
                        echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jenkins') {
                    echo '📦 Deploying to Kubernetes...'
                    sh '''
                        sed -i "s|BUILD_NUMBER|${BUILD_NUMBER}|g" k8s/07-petclinic-deployment.yaml
                        kubectl apply -f k8s/07-petclinic-deployment.yaml
                        kubectl apply -f k8s/08-petclinic-service.yaml
                        kubectl rollout status deployment/petclinic --timeout=5m
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('jenkins') {
                    echo '🔍 Verifying deployment...'
                    sh '''
                        kubectl get pods -l app=petclinic
                        kubectl get svc petclinic
                        kubectl describe deployment petclinic | grep Image:
                    '''
                }
            }
        }
    }

    post {
    always {
        script {
            echo '🧹 Cleaning up Docker credentials...'
            try {
                container('docker') {
                    sh 'docker logout || true'
                }
            } catch (err) {
                echo "⚠️ Cleanup skipped (no Docker context): ${err.message}"
            }
        }
    }
    success {
        echo '✅ Pipeline completed successfully!'
        echo "Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
        echo "App URL: http://<NODE_IP>:30080"
    }
    failure {
        script {
            echo '❌ Pipeline failed. Attempting rollback...'
            try {
                container('jenkins') {
                    sh '''
                        echo "🔁 Rolling back last deployment..."
                        kubectl rollout undo deployment/petclinic || echo "No previous deployment found."
                    '''
                }
            } catch (err) {
                echo "⚠️ Rollback skipped (no Kubernetes context): ${err.message}"
            }
        }
    }
  }

}

