pipeline {

    agent any

    tools {
        nodejs 'nodejs'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
    }

    environment {
        APP_DIR     = 'hotstar-clone'
        HELM_DIR    = 'hotstar-clone/helm'

        IMAGE_NAME  = 'shubhamnavale8177/hotstar'
        IMAGE_TAG   = "${BUILD_NUMBER}"

        AWS_REGION  = 'us-east-1'
        EKS_CLUSTER = 'hotstar-eks'
    }

    triggers {
        githubPush()
    }

    stages {

        // =====================================================
        // 1. CHECKOUT
        // =====================================================

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // =====================================================
        // 2. CHECK NODE & NPM
        // =====================================================

        stage('Check Node and NPM') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "NODE AND NPM ENVIRONMENT CHECK"
                    echo "=========================================="

                    echo "Node version:"
                    node --version

                    echo "NPM version:"
                    npm --version

                    echo "NPM registry:"
                    npm config get registry

                    echo "NPM ping:"
                    npm ping

                    echo "=========================================="
                '''
            }
        }

        // =====================================================
        // 3. BUILD & TEST
        // =====================================================

        stage('Install Dependencies') {
            steps {
                dir(env.APP_DIR) {
                    sh 'npm ci'
                }
            }
        }

        stage('Build React App') {
            steps {
                dir(env.APP_DIR) {
                    sh 'CI=false npm run build'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir(env.APP_DIR) {
                    sh '''
                        CI=true npm test \
                        -- --watchAll=false --passWithNoTests
                    '''
                }
            }
        }

        // =====================================================
        // 4. SONARQUBE
        // =====================================================

        stage('SonarQube Scan') {
            steps {
                script {

                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('sonarqube') {

                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=hotstar \
                            -Dsonar.sources=${APP_DIR}/src
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate(
                        abortPipeline: true
                    )
                }
            }
        }

        // =====================================================
        // 5. TRIVY FILESYSTEM SCAN
        // =====================================================

        stage('Trivy Filesystem Scan') {
            steps {

                sh """
                    mkdir -p trivy-reports

                    trivy fs \
                    --severity CRITICAL,HIGH \
                    --exit-code 0 \
                    -o trivy-reports/fs-report.txt \
                    ${APP_DIR}
                """
            }

            post {
                always {

                    archiveArtifacts(
                        artifacts: 'trivy-reports/fs-report.txt',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        // =====================================================
        // 6. DOCKER BUILD
        // =====================================================

        stage('Docker Build') {
            steps {

                sh """
                    docker build \
                    -f ${APP_DIR}/Dockerfile \
                    -t ${IMAGE_NAME}:${IMAGE_TAG} \
                    ${APP_DIR}/
                """
            }
        }

        // =====================================================
        // 7. TRIVY IMAGE SCAN
        // =====================================================

        stage('Trivy Image Scan') {
            steps {

                sh """
                    mkdir -p trivy-reports

                    trivy image \
                    --severity CRITICAL,HIGH \
                    --exit-code 0 \
                    -o trivy-reports/image-report.txt \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }

            post {
                always {

                    archiveArtifacts(
                        artifacts: 'trivy-reports/image-report.txt',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        // =====================================================
        // 8. OWASP ZAP
        // =====================================================

        stage('OWASP ZAP Scan') {
            steps {

                sh """
                    docker run -d \
                    --name zap-target \
                    -p 8090:80 \
                    ${IMAGE_NAME}:${IMAGE_TAG}

                    sleep 15

                    mkdir -p ${WORKSPACE}/zap-reports

                    chmod 777 ${WORKSPACE}/zap-reports

                    docker run --rm \
                    --network host \
                    -v ${WORKSPACE}/zap-reports:/zap/wrk \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py \
                    -t http://localhost:8090 \
                    -r zap-report.html \
                    -I
                """
            }

            post {

                always {

                    sh """
                        docker stop zap-target || true
                        docker rm zap-target || true
                    """

                    publishHTML(
                        target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: 'zap-reports',
                            reportFiles: 'zap-report.html',
                            reportName: 'OWASP ZAP Report'
                        ]
                    )
                }
            }
        }

        // =====================================================
        // 9. DOCKER PUSH
        // =====================================================

        
    stage('Docker Push') {
        steps {
            retry(2) {
             withCredentials([
                usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )
            ]) {
                sh '''
                    set +x
                    set -e

                    trap 'docker logout >/dev/null 2>&1 || true' EXIT

                    echo "$DOCKER_PASS" | docker login \
                        -u "$DOCKER_USER" \
                        --password-stdin

                    docker push "${IMAGE_NAME}:${IMAGE_TAG}"

                    docker tag \
                        "${IMAGE_NAME}:${IMAGE_TAG}" \
                        "${IMAGE_NAME}:latest"

                    docker push "${IMAGE_NAME}:latest"
                '''
                }
            }
        }
    }


        // =====================================================
        // 10. TRIGGER CD
        // =====================================================

        stage('Trigger CD') {
            steps {

                build job: 'Hotstar-CD',
                    parameters: [
                        string(
                            name: 'IMAGE_TAG',
                            value: "${IMAGE_TAG}"
                        )
                    ],
                    wait: false
            }
        }

        // =====================================================
        // 11. CLEANUP
        // =====================================================

        stage('Cleanup') {
            steps {

                sh """
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                    docker rmi ${IMAGE_NAME}:latest || true
                    docker image prune -f
                """
            }
        }
    }

    // ==========================================================
    // POST ACTIONS
    // ==========================================================

    post {

        success {

            echo """
            ==========================================
            HOTSTAR CI PIPELINE SUCCESS
            ==========================================

            Image:
            ${IMAGE_NAME}:${IMAGE_TAG}

            Build ✓
            Test ✓
            SonarQube ✓
            Trivy ✓
            Docker Build ✓
            OWASP ZAP ✓
            Docker Push ✓
            CD Triggered ✓

            ==========================================
            """

            slackSend(
                channel: '#all-capstone-hotstar',
                color: 'good',
                message: "✅ CI SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}\nImage: ${IMAGE_NAME}:${IMAGE_TAG}\nCD Triggered"
            )
        }

        failure {

            echo """
            ===========================================
            HOTSTAR CI PIPELINE FAILED
            ===========================================

            Check the Jenkins console output.

            ===========================================
            """

            slackSend(
                channel: '#all-capstone-hotstar',
                color: 'danger',
                message: "❌ CI FAILED: ${JOB_NAME} #${BUILD_NUMBER}\nCheck Jenkins: ${BUILD_URL}"
            )
        }

        always {
            cleanWs()
        }
    }
}