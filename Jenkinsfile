pipeline {
agent {
    docker {
        image 'kijanikiosk-node18-agent:1.0'
        args '--network kijanikiosk-ci'
    }
}

    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'
        NEXUS_URL = 'http://nexus:8081/repository/npm-kijanikiosk/'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Initialize Metadata') {
            steps {
                script {
                    env.PKG_VERSION = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim()

                    env.GIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.ARTIFACT_VERSION =
                        "${env.PKG_VERSION}-${env.GIT_SHORT}"

                    echo "Package: ${env.APP_NAME}"
                    echo "Artifact version: ${env.ARTIFACT_VERSION}"
                    echo "Registry: ${env.NEXUS_URL}"
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Checking container runtime versions...'
                sh 'node --version'
                sh 'npm --version'

                echo 'Installing dependencies...'
                sh 'npm ci'

                echo 'Building application...'
                sh 'npm run build'

                echo 'Verifying build output...'
                sh '''
                    set -eu
                    test -d "$BUILD_DIR"

                    FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
                    echo "Build output files: $FILE_COUNT"

                    test "$FILE_COUNT" -gt 0
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '''
                    set -eu
                    npm test
                '''
            }

            post {
                always {
                    junit(
                        allowEmptyResults: true,
                        testResults: 'test-results/*.xml'
                    )
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: "${BUILD_DIR}/**",
                    fingerprint: true,
                    onlyIfSuccessful: true
                )
            }
        }

        stage('Publish') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        # Always remove temporary npm credentials.
                        trap 'rm -f .npmrc' EXIT

                        # Generate the Nexus Basic authentication token.
                        NEXUS_TOKEN=$(
                            printf '%s' "$NEXUS_USER:$NEXUS_PASS" |
                            base64 |
                            tr -d '\\n'
                        )

                        # Create temporary npm configuration.
                        printf '%s\\n' \
                            "registry=$NEXUS_URL" \
                            "always-auth=true" \
                            "//nexus:8081/repository/npm-kijanikiosk/:_auth=$NEXUS_TOKEN" \
                            > .npmrc

                        # Set a version derived from package.json and Git.
                        npm version "$ARTIFACT_VERSION" \
                            --no-git-tag-version \
                            --allow-same-version

                        # Publish to Nexus. A failure exits non-zero.
                        npm publish --registry="$NEXUS_URL"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Published ${APP_NAME} version ${ARTIFACT_VERSION} to Nexus"
            echo "Artifact URL: ${NEXUS_URL}${APP_NAME}/-/${APP_NAME}-${ARTIFACT_VERSION}.tgz"
        }

        failure {
            echo "Pipeline FAILED at build ${BUILD_NUMBER} - check logs at ${BUILD_URL}"
        }

        always {
            cleanWs()
        }
    }
}
