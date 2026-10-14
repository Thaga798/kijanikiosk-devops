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
                    credentialsId: 'nexus-credentials',   // Verifies with your Jenkins store identifier
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    // Triple single quotes preserve line structures natively
                    sh '''
                        set -e

                        # Generate base64 token securely inside the shell layer to bypass sandbox blocks
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)

                        # Create the temporary config file using a strict heredoc wrapper
                        cat > .npmrc << NPMRC
registry=http://192.168.100
//192.168.100.53:8081/repository/npm-kijanikiosk/:_auth=${NEXUS_TOKEN}
always-auth=true
NPMRC

                        # Publish the package artifact to Nexus
                        npm publish --registry http://192.168.100

                        # Clean up the configuration file immediately
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
