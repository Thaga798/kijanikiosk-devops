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
        stage('Environment Check') {
            steps {
                echo "Checking environment versions..."
                sh 'echo "Build triggered for: $(git log -1 --pretty=%s)"'
                sh 'node --version'
                sh 'npm --version'
            }
        }

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
                // Plain command ensures stable exit code propagation to halt the pipeline on failure
                sh 'npm test'
            }
            post {
                always {
                    // Publishes test tracking graphs even if the runner assets fail
                    junit allowEmptyResults: true,
                          testResults: 'test-results/*.xml'
        	    }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded: ${APP_NAME} build ${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline FAILED: ${APP_NAME} build ${BUILD_NUMBER} - check logs"
        }
        always {
            echo "Build URL: ${BUILD_URL}"
            echo "Cleaning up workspace to prevent stale artifacts..."
            cleanWs() 
        }
    }
}
