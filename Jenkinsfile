pipeline {
    agent any

    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'
        
        // Universal Docker local host bridge network address
        NEXUS_IP   = 'host.docker.internal'
        NEXUS_PORT = '8081'
        NEXUS_REPO = 'npm-kijanikiosk'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Environment Check') {
            steps {
                echo "Initializing Build Metadata For: ${APP_NAME}"
                sh 'node --version'
                sh 'npm --version'
            }
        }

        stage('Build') {
            steps {
                echo "Installing dependencies..."
                sh 'npm ci'

                echo "Building application..."
                sh 'npm run build'

                echo "Verifying build output directory..."
                sh '''
                    set -e
                    test -d "${BUILD_DIR}" || { echo "ERROR: build directory not found"; exit 1; }
                    echo "Build output: $(ls ${BUILD_DIR} | wc -l) files in ${BUILD_DIR}/"
                '''
            }
        }

        stage('Test') {
            steps {
                echo "Running target verification test suite..."
                sh 'npm test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    def pkgVer = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
                    def gitSHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.VERSION_TAG = "${pkgVer}-${gitSHA}"
                    env.TARBALL_NAME = "${APP_NAME}-${env.VERSION_TAG}.tar.gz"
                }
                echo "Compressing deployment tarball: ${env.TARBALL_NAME}..."
                sh "tar -czf ${env.TARBALL_NAME} ${BUILD_DIR}/ package.json"
                sh "ls -lh ${env.TARBALL_NAME}"
            }
        }

        stage('Publish') {
            steps {
                echo "Securely publishing package to Nexus registry..."
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                        set -e

                        # Calculate authorization token dynamically inside execution phase
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)

                        # Reconstruct .npmrc file using the universal host internal DNS pointer
                        echo "registry=http://${NEXUS_IP}:${NEXUS_PORT}/repository/${NEXUS_REPO}/" > .npmrc
                        echo "//${NEXUS_IP}:${NEXUS_PORT}/repository/${NEXUS_REPO}/:_auth=${NEXUS_TOKEN}" >> .npmrc
                        echo "always-auth=true" >> .npmrc

                        # Execute publication script targeting the internal host routing mapping
                        npm publish --registry http://${NEXUS_IP}:${NEXUS_PORT}/repository/${NEXUS_REPO}/

                        # Immediately remove temporary secret tracking file
                        rm -f .npmrc
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
