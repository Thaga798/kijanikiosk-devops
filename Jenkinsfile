pipeline {
    agent any

    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Build') {
            steps {
                echo "Installing dependencies for ${APP_NAME}..."
                sh 'npm ci'

                echo "Building application..."
                sh 'npm run build'

                echo "Verifying build output..."
                sh '''
                    set -e
                    test -d "${BUILD_DIR}" || { echo "ERROR: build directory not found"; exit 1; }
                    echo "Build output: $(ls ${BUILD_DIR} | wc -l) files in ${BUILD_DIR}/"
                '''
            }
        }
        stage('Test') {
            steps {
                echo "Running test suite for ${APP_NAME}..."
                sh 'npm test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'test-results/*.xml'
                }
            }
        }
        stage('Archive') {
            steps {
                echo "Archiving build artifacts from ${BUILD_DIR}..."
                // Archives the output folder with fingerprinting enabled
                archiveArtifacts artifacts: "${BUILD_DIR}/**", fingerprint: true
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded: ${APP_NAME} build ${BUILD_NUMBER}. Artifacts available at ${BUILD_URL}artifact/"
        }
        failure {
            echo "Pipeline FAILED: ${APP_NAME} build ${BUILD_NUMBER} - a step exited with a non-zero status. Check build logs."
        }
        always {
            cleanWs()
        }
    }
}
