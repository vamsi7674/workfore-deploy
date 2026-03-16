pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'Maven3'
        nodejs 'NodeJS22'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timestamps()
    }

    environment {
        // ── Backend ─────────────────────────────────────────────
        JAR_NAME       = 'Workforce-0.0.1-SNAPSHOT.jar'
        BACKEND_DIR    = 'final deploye/RevWorkforce'
        // ── EC2 ─────────────────────────────────────────────────
        REMOTE_HOST    = '13.201.140.55'
        REMOTE_USER    = 'ec2-user'
        REMOTE_DIR     = '/home/ec2-user/workforce'
        EC2_SSH_KEY_ID = 'ec2-ssh-key'
        // ── Frontend ─────────────────────────────────────────────
        FRONTEND_DIR   = 'final deploye/RevWorkForce-Frontend'
        S3_BUCKET      = 'hrms-portal-vamsi'
        AWS_REGION     = 'ap-south-1'
        AWS_CREDS_ID   = 'aws-s3-credentials'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '── Checking out code ──'
                git branch: 'main',
                    credentialsId: 'github-ssh-key',
                    url: 'git@github.com:vamsi7674/workfore-deploy.git'
            }
        }

        // ══════════════════════════════════════
        //  BACKEND STAGES
        // ══════════════════════════════════════

        stage('Backend: Build JAR') {
            steps {
                echo '── Building Spring Boot JAR ──'
                dir("${BACKEND_DIR}") {
                    sh 'mvn -B clean package -DskipTests -q'
                    archiveArtifacts artifacts: "target/${JAR_NAME}", fingerprint: true
                }
            }
        }

        stage('Backend: Transfer to EC2') {
            steps {
                echo '── Transferring files to EC2 ──'
                withCredentials([sshUserPrivateKey(
                    credentialsId: "${EC2_SSH_KEY_ID}",
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i \$SSH_KEY ${REMOTE_USER}@${REMOTE_HOST} \
                            'mkdir -p ${REMOTE_DIR}'
                        scp -o StrictHostKeyChecking=no -i \$SSH_KEY \
                            '${BACKEND_DIR}/target/${JAR_NAME}' \
                            ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
                        scp -o StrictHostKeyChecking=no -i \$SSH_KEY \
                            '${BACKEND_DIR}/docker-compose.yml' \
                            ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
                        scp -o StrictHostKeyChecking=no -i \$SSH_KEY \
                            '${BACKEND_DIR}/deploy.sh' \
                            ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
                    """
                }
            }
        }

        stage('Backend: Deploy on EC2') {
            steps {
                echo '── Deploying Docker Compose stack on EC2 ──'
                withCredentials([
                    sshUserPrivateKey(credentialsId: "${EC2_SSH_KEY_ID}", keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'mysql-root-password',  secretVariable: 'MYSQL_ROOT_PASS'),
                    string(credentialsId: 'mysql-user-password',  secretVariable: 'MYSQL_USER_PASS'),
                    string(credentialsId: 'spring-mail-password', secretVariable: 'MAIL_PASS')
                ]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i \$SSH_KEY ${REMOTE_USER}@${REMOTE_HOST} \
                        "MYSQL_ROOT_PASSWORD='\$MYSQL_ROOT_PASS' \
                         MYSQL_PASSWORD='\$MYSQL_USER_PASS' \
                         SPRING_MAIL_PASSWORD='\$MAIL_PASS' \
                         JAR_NAME='${JAR_NAME}' \
                         APP_PORT='8080' \
                         bash ${REMOTE_DIR}/deploy.sh"
                    """
                }
                echo '✅ Backend deployed!'
            }
        }

        // ══════════════════════════════════════
        //  FRONTEND STAGES
        // ══════════════════════════════════════

        stage('Frontend: Install & Build') {
            steps {
                echo '── Building Angular app ──'
                dir("${FRONTEND_DIR}") {
                    sh '''
                        node --version
                        npm --version
                        npm ci --prefer-offline
                        npx ng build --configuration production
                    '''
                }
            }
        }

        stage('Frontend: Deploy to S3') {
            steps {
                echo '── Syncing Angular build to S3 ──'
                withCredentials([usernamePassword(
                    credentialsId: "${AWS_CREDS_ID}",
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir("${FRONTEND_DIR}") {
                        sh """
                            # Sync all files except index.html (with long-term cache)
                            aws s3 sync dist/HRMS-Portal/browser/ s3://${S3_BUCKET}/ \
                                --region ${AWS_REGION} \
                                --delete \
                                --cache-control 'public, max-age=31536000' \
                                --exclude 'index.html'

                            # Upload index.html with no-cache (so routing always works)
                            aws s3 cp dist/HRMS-Portal/browser/index.html \
                                s3://${S3_BUCKET}/index.html \
                                --region ${AWS_REGION} \
                                --cache-control 'no-cache, no-store, must-revalidate' \
                                --content-type 'text/html'

                            echo "✅ Frontend live at: http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Full HRMS Deployment SUCCESS — Backend on EC2 + Frontend on S3'
        }
        failure {
            echo '❌ Deployment FAILED — check stage logs above'
        }
    }
}
