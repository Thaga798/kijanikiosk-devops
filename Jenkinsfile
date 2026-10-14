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
                    // Using single quotes (''') blocks Jenkins from misinterpreting colons and punctuation strings
                    sh '''
                        set -e

                        # Generate base64 token securely at runtime
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)

                        # Write configuration parameters using raw strings to prevent text slicing
                        echo 'registry=http://192.168.100' > .npmrc
                        echo '//192.168.100.53:8081/repository/npm-kijanikiosk/:_auth='"${NEXUS_TOKEN}" >> .npmrc
                        echo 'always-auth=true' >> .npmrc

                        # Execute the upload directly using our clean config context
                        npm publish --registry http://192.168.100

                        # Instantly remove the authentication file
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
