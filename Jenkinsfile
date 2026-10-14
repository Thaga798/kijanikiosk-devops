pipeline {
    agent any

    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'
        
        // Centralized IP address routing variable to guarantee zero string truncation
        NEXUS_REGISTRY_URL = 'http://192.168.0'
        
        // Dynamically compute unique version payload tags for Nexus immutability
        PKG_VERSION = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
        GIT_SHORT   = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        ARTIFACT_VERSION = "${PKG_VERSION}-${GIT_SHORT}"
        TARBALL_NAME     = "${APP_NAME}-${ARTIFACT_VERSION}.tar.gz"
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
                echo "Target Artifact Build Version: ${ARTIFACT_VERSION}"
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
                echo "Compressing deployment tarball: ${TARBALL_NAME}..."
                sh "tar -czf ${TARBALL_NAME} ${BUILD_DIR}/ package.json"
                sh "ls -lh ${TARBALL_NAME}"
            }
        }

        stage('Publish') {
            steps {
                echo "Securely publishing package to Nexus registry..."
                // Inject credentials safely using the usernamePassword block binding pattern
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',   // The ID from the credentials store
                    usernameVariable: 'NEXUS_USER',       // Variable name for the username
                    passwordVariable: 'NEXUS_PASS'        // Variable name for the password
                )]) {
                    sh '''
                        set -e

                        # Generate base64 token from the injected credentials dynamically
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)

                        # Create a clean .npmrc file using our safe environment variable
                        cat > .npmrc << NPMRC
registry=${NEXUS_REGISTRY_URL}
//192.168.0.100:8081/repository/npm-kijanikiosk/:_auth=${NEXUS_TOKEN}
always-auth=true
NPMRC

                        # Automated deployment execution
                        npm publish --registry ${NEXUS_REGISTRY_URL}

                        # Clean up the sensitive config file instantly inside the workspace environment
                        rm -f .npmrc
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded: ${APP_NAME} build ${BUILD_NUMBER} uploaded as version ${ARTIFACT_VERSION}"
        }
        failure {
            echo "Pipeline FAILED: ${APP_NAME} build ${BUILD_NUMBER} - verify execution logs."
        }
        always {
            cleanWs()
        }
    }
}
