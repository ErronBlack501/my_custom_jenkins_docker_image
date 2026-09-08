pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'RUN_SONAR',
            defaultValue: true,
            description: 'Run SonarQube analysis'
        )
        booleanParam(
            name: 'DEPLOY_NEXUS',
            defaultValue: false,
            description: 'Publish the WAR file to Nexus'
        )
        string(
            name: 'NEXUS_RELEASE_URL',
            defaultValue: 'http://nexus:8081/repository/maven-releases/',
            description: 'Full URL of the Nexus releases repository'
        )
    }

    environment {
        COMPOSE_PROJECT_NAME = 'empassign-ci'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and test') {
            steps {
                script {
                    retry(3) {
                        if (isUnix()) {
                            sh 'chmod +x mvnw && ./mvnw -Dmaven.wagon.http.retryHandler.count=5 clean verify'
                        } else {
                            bat 'mvnw.cmd -Dmaven.wagon.http.retryHandler.count=5 clean verify'
                        }
                    }
                }
            }
        }

        stage('SonarQube analysis') {
            when {
                expression { params.RUN_SONAR }
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        if (isUnix()) {
                            sh '''
                                ./mvnw org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                                  -Dsonar.projectKey=empassign \
                                                                    -Dsonar.host.url=http://sonarqube:9000
                            '''
                        } else {
                            bat '''
                                mvnw.cmd org.sonarsource.scanner.maven:sonar-maven-plugin:sonar ^
                                  -Dsonar.projectKey=empassign ^
                                                                    -Dsonar.host.url=http://sonarqube:9000
                            '''
                        }
                    }
                }
            }
        }

        stage('Quality gate') {
            when {
                expression { params.RUN_SONAR }
            }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Archive WAR') {
            steps {
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                junit testResults: '**/target/surefire-reports/TEST-*.xml', allowEmptyResults: false
            }
        }

        stage('Deploy to Nexus') {
            when {
                expression { params.DEPLOY_NEXUS }
            }
            steps {
                script {
                    if (!params.NEXUS_RELEASE_URL?.trim()) {
                        error 'NEXUS_RELEASE_URL is required when DEPLOY_NEXUS is enabled.'
                    }
                }
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-account',
                    usernameVariable: 'NEXUS_USERNAME',
                    passwordVariable: 'NEXUS_PASSWORD'
                )]) {
                    withMaven(mavenSettingsConfig: 'maven-nexus-settings') {
                        script {
                            def deployCommand = "deploy:deploy-file -Dfile=target/empassign-1.0-SNAPSHOT.war " +
                                "-DgroupId=com.example -DartifactId=empassign -Dversion=1.0.${env.BUILD_NUMBER} " +
                                "-Dpackaging=war -DrepositoryId=nexus " +
                                "-Durl=${params.NEXUS_RELEASE_URL} -DgeneratePom=true"
                            if (isUnix()) {
                                sh "./mvnw ${deployCommand}"
                            } else {
                                bat "mvnw.cmd ${deployCommand}"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                script {
                    def compose = isUnix()
                        ? sh(returnStdout: true, script: 'if docker compose version >/dev/null 2>&1; then printf "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then printf "docker-compose"; else exit 1; fi').trim()
                        : bat(returnStdout: true, script: '@docker compose version >NUL 2>&1 && (echo docker compose) || (where docker-compose >NUL 2>&1 && (echo docker-compose))').trim()
                    if (isUnix()) {
                        sh "${compose} up -d --wait"
                    } else {
                        bat "${compose} up -d --wait"
                    }
                }
            }
        }

        stage('Smoke test') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'curl --fail --retry 20 --retry-delay 3 http://localhost:8080/empassign/'
                    } else {
                        bat 'curl.exe --fail --retry 20 --retry-delay 3 http://localhost:8080/empassign/'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (isUnix()) {
                    sh 'if docker compose version >/dev/null 2>&1; then docker compose logs --no-color > docker-compose.log; elif command -v docker-compose >/dev/null 2>&1; then docker-compose logs --no-color > docker-compose.log; else : > docker-compose.log; fi || true'
                } else {
                    bat 'docker compose logs --no-color > docker-compose.log 2>NUL || docker-compose logs --no-color > docker-compose.log 2>NUL || type nul > docker-compose.log'
                }
            }
            archiveArtifacts artifacts: 'docker-compose.log', allowEmptyArchive: true
        }
        failure {
            script {
                if (isUnix()) {
                    sh 'if docker compose version >/dev/null 2>&1; then docker compose ps; elif command -v docker-compose >/dev/null 2>&1; then docker-compose ps; fi || true'
                } else {
                    bat 'docker compose ps || docker-compose ps || exit /b 0'
                }
            }
        }
    }
}
