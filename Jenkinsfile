pipeline {
    agent any

    environment {
        NODE_ENV       = 'test'
        BUILD_DIR      = 'dist'
        APP_NAME       = 'kijanikiosk-payments'
        NEXUS_REGISTRY = 'http://nexus:8081/repository/npm-kijanikiosk/'
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
                echo 'Installing dependencies...'
                sh 'npm ci'

                echo 'Building application...'
                sh 'npm run build'

                echo 'Verifying build output directory...'
                sh '''
                    set -eu
                    test -d "$BUILD_DIR" || {
                        echo "ERROR: build directory not found"
                        exit 1
                    }

                    FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
                    echo "Build output: $FILE_COUNT files in $BUILD_DIR/"
                    test "$FILE_COUNT" -gt 0
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running verification test suite...'
                sh 'npm test'
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

        stage('Package') {
            steps {
                script {
                    def pkgVer = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim()

                    def gitSHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.VERSION_TAG = "${pkgVer}-${gitSHA}"
                    env.TARBALL_NAME = "${APP_NAME}-${env.VERSION_TAG}.tar.gz"
                }

                echo "Creating artifact: ${env.TARBALL_NAME}"

                sh '''
                    set -eu
                    tar -czf "$TARBALL_NAME" "$BUILD_DIR/" package.json
                    ls -lh "$TARBALL_NAME"
                '''

                archiveArtifacts(
                    artifacts: '*.tar.gz',
                    fingerprint: true
                )
            }
        }

        stage('Publish') {
            steps {
                echo "Publishing package to Nexus..."

                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    script {
                        def token = sh(
                            script: '''
                                set +x
                                printf '%s' "$NEXUS_USER:$NEXUS_PASS" |
                                    base64 |
                                    tr -d '\\n'
                            ''',
                            returnStdout: true
                        ).trim()

                        try {
                            writeFile(
                                file: '.npmrc',
                                text: """\
registry=${env.NEXUS_REGISTRY}
always-auth=true
//nexus:8081/repository/npm-kijanikiosk/:_auth=${token}
"""
                            )

                            sh '''
                                set -eu
                                set +x

                                npm publish \
                                    --registry="$NEXUS_REGISTRY"
                            '''
                        } finally {
                            sh(
                                script: 'rm -f .npmrc',
                                label: 'Remove temporary npm credentials'
                            )
                        }
                    }
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

