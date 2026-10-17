pipeline {
    agent none

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
        skipDefaultCheckout()
    }

    stages {
        stage('Initialize Metadata') {
            agent {
                docker {
                    image 'kijanikiosk-node18-agent:1.0'
                    args '--network kijanikiosk-ci'
                }
            }

            steps {
                checkout scm

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

                    echo "Application: ${env.APP_NAME}"
                    echo "Package version: ${env.PKG_VERSION}"
                    echo "Git revision: ${env.GIT_SHORT}"
                    echo "Artifact version: ${env.ARTIFACT_VERSION}"
                }
            }

            post {
                always {
                    cleanWs()
                }
            }
        }

        stage('Lint') {
            agent {
                docker {
                    image 'kijanikiosk-node18-agent:1.0'
                    args '--network kijanikiosk-ci'
                }
            }

            steps {
                checkout scm
                sh 'npm ci'
                sh 'npm run lint'
            }

            post {
                always {
                    cleanWs()
                }
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'kijanikiosk-node18-agent:1.0'
                    args '--network kijanikiosk-ci'
                }
            }

            steps {
                checkout scm

                sh '''
                    set -eu

                    echo "Node.js version:"
                    node --version

                    echo "npm version:"
                    npm --version

                    echo "Git version:"
                    git --version

                    sh 'npm ci --invalid-flag-intentional'
                    npm run build

                    test -d "$BUILD_DIR"
                    test -n "$(find "$BUILD_DIR" -type f -print -quit)"

                    echo "Build output:"
                    find "$BUILD_DIR" -type f -print
                '''

                stash(
                    name: 'build-output',
                    includes: 'dist/**,package.json,package-lock.json'
                )
            }

            post {
                always {
                    cleanWs()
                }
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    agent {
                        docker {
                            image 'kijanikiosk-node18-agent:1.0'
                            args '--network kijanikiosk-ci'
                        }
                    }

                    steps {
                        checkout scm
                        unstash 'build-output'

                        sh '''
                            set -eu
                            npm ci
                            npm test
                        '''
                    }

                    post {
                        always {
                            junit(
                                allowEmptyResults: true,
                                testResults: 'test-results/*.xml'
                            )
                            cleanWs()
                        }
                    }
                }

                stage('Security Audit') {
                    agent {
                        docker {
                            image 'kijanikiosk-node18-agent:1.0'
                            args '--network kijanikiosk-ci'
                        }
                    }

                    steps {
                        checkout scm
                        unstash 'build-output'

                        sh '''
                            set -eu
                            npm ci
                            npm audit --audit-level=high
                        '''
                    }

                    post {
                        always {
                            cleanWs()
                        }
                    }
                }
            }
        }

        stage('Archive') {
            agent {
                docker {
                    image 'kijanikiosk-node18-agent:1.0'
                    args '--network kijanikiosk-ci'
                }
            }

            steps {
                checkout scm
                unstash 'build-output'

                archiveArtifacts(
                    artifacts: "${BUILD_DIR}/**",
                    fingerprint: true,
                    onlyIfSuccessful: true
                )
            }

            post {
                always {
                    cleanWs()
                }
            }
        }

        stage('Publish') {
            agent {
                docker {
                    image 'kijanikiosk-node18-agent:1.0'
                    args '--network kijanikiosk-ci'
                }
            }

            steps {
                checkout scm
                unstash 'build-output'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh(
                        label: 'Publish package to Nexus',
                        script: '''
                            set -eu
                            set +x

                            trap 'rm -f .npmrc' EXIT

                            printf '%s\\n' \
                              "registry=$NEXUS_URL" \
                              "//$(
                                  printf '%s' "$NEXUS_URL" |
                                  sed 's|^https\\?://||; s|/$||'
                              )/:username=$NEXUS_USER" \
                              "//$(
                                  printf '%s' "$NEXUS_URL" |
                                  sed 's|^https\\?://||; s|/$||'
                              )/:_password=$(printf '%s' "$NEXUS_PASS" | base64 | tr -d '\\n')" \
                              "//$(
                                  printf '%s' "$NEXUS_URL" |
                                  sed 's|^https\\?://||; s|/$||'
                              )/:email=jenkins@localhost" \
                              "//$(
                                  printf '%s' "$NEXUS_URL" |
                                  sed 's|^https\\?://||; s|/$||'
                              )/:always-auth=true" > .npmrc

                            npm version "$ARTIFACT_VERSION" \
                              --no-git-tag-version \
                              --allow-same-version

                            npm publish --registry="$NEXUS_URL"
                        '''
                    )
                }
            }

            post {
                always {
                    cleanWs()
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS: ${env.APP_NAME}@${env.ARTIFACT_VERSION}"
            echo "Nexus repository: ${env.NEXUS_URL}"
            echo "Package path: ${env.APP_NAME}/-/${env.APP_NAME}-${env.ARTIFACT_VERSION}.tgz"
        }

        failure {
            echo "Pipeline FAILED for ${env.APP_NAME}."
            echo "Check the failed stage logs before attempting publication again."
        }

        aborted {
            echo "Pipeline was aborted or timed out."
        }
    }
}
