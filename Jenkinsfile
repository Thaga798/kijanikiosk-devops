pipeline {
    agent {
        docker {
            image 'kijanikiosk-node18-agent:1.0'
            args '-v /tmp:/tmp --network kijanikiosk-ci'
        }
    }

    environment {
        NODE_ENV         = 'test'
        BUILD_DIR        = 'dist'
        APP_NAME         = 'kijanikiosk-payments'
        PKG_VERSION      = ''
        GIT_SHORT        = ''
        ARTIFACT_VERSION = ''
        NEXUS_URL        = 'http://nexus:8081/repository/npm-kijanikiosk/'
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

                    echo "Application: ${env.APP_NAME}"
                    echo "Artifact version: ${env.ARTIFACT_VERSION}"
                    echo "Nexus repository: ${env.NEXUS_URL}"
                }
            }
        }

        stage('Lint') {
            steps {
               sh 'npm ci --no-audit' 
               sh 'npm run lint'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    set -eu

                    npm ci --no-audit
                    npm run build

                    if [ ! -d "$BUILD_DIR" ]; then
                        echo "ERROR: Build output directory is missing."
                        exit 1
                    fi

                    if [ -z "$(find "$BUILD_DIR" -type f -print -quit)" ]; then
                        echo "ERROR: Build output directory is empty."
                        exit 1
                    fi

                    echo "Build output verified:"
                    find "$BUILD_DIR" -type f
                '''

stash(
    name: 'build-output',
    includes: 'dist/**,src/**,test/**,package.json,package-lock.json',
    useDefaultExcludes: false
)
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        unstash 'build-output'
                        sh 'npm test'
                    }

                    post {
                        always {
junit testResults: 'test-results/**/*.xml',
      allowEmptyResults: false                        }
                    }
                }

                stage('Security Audit') {
                    steps {
                        sh 'npm audit --audit-level=high'
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'dist/**',
                    fingerprint: true
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

                        trap 'rm -f .npmrc' EXIT

                        NEXUS_TOKEN="$(printf '%s' \
                            "$NEXUS_USER:$NEXUS_PASS" \
                            | base64 | tr -d '\\n')"

                        printf '%s\\n' \
                          "registry=$NEXUS_URL" \
                          "//nexus:8081/repository/npm-kijanikiosk/:_auth=$NEXUS_TOKEN" \
                          "always-auth=true" > .npmrc

                        echo "Preparing ${APP_NAME}@${ARTIFACT_VERSION}"

                        npm version "$ARTIFACT_VERSION" \
                            --no-git-tag-version \
                            --allow-same-version

                        echo "Publishing ${APP_NAME}@${ARTIFACT_VERSION} to Nexus"

                        npm publish --registry="$NEXUS_URL"

                        echo "Nexus publish command completed successfully."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: ${APP_NAME}@${ARTIFACT_VERSION} published to ${NEXUS_URL}"
        }

        failure {
            echo "FAILURE: ${JOB_NAME} #${BUILD_NUMBER}"
            echo "Review the build log: ${BUILD_URL}console"
        }

        changed {
            echo "Build status changed to ${currentBuild.currentResult} - ${JOB_NAME} #${BUILD_NUMBER}"
        }

        always {
            cleanWs()
        }
    }
}
