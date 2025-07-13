pipeline {
    agent any

    tools{
        maven 'maven3'
    }
    environment {
        SCANNER_HOME= tool 'sonar-scanner'
        IMAGE_TAG= "v${BUILD_NUMBER}"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Giri9608/FullStack-Blogging-App.git'
            }
        }
        stage('Compilation') {
            steps {
                sh 'mvn compile'
            }
        }
        stage('Testing') {
            steps {
                sh 'mvn test -DskipTests=true'
            }
        }
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --format table -o fs-report.html .'
            }
        }
        stage('Code Quality Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar-projectName=GCBank -Dsonar.projectKey=GCBank \
                            -Dsonar.java.binaries=target '''
                }
            }
        }
        stage('Quality Gate Check'){
            steps{
                waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
            }
        }
        stage('Build the Application'){
            steps{
                sh 'mvn package -DskipTests'
            }
        }
        stage('Push Artifacts to Nexus'){
            steps{
                withMaven(globalMavenSettingsConfig: 'Capstone', jdk: '', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh 'mvn clean deploy -DskipTests'
                }
            }
        }
        stage('Build & Tag Docker Image'){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker build -t thepraduman/bankapp:$IMAGE_TAG .'
                    }
                }
            }
        }
        stage('Docker Image Scan') {
            steps {
                sh 'trivy image --format table -o image-report.html giri/bankapp:$IMAGE_TAG'
            }
        }
        stage('Push Docker Image') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker push thepraduman/bankapp:$IMAGE_TAG'
                    }
                }
            }
        }
        stage('Update manifests file in CD repo') {
            steps {
                script{
                    cleanWs()
                    sh '''
                    git clone https://github.com/Giri9608/FullStack-Blogging-App.git
                    cd Capstone-Mega-CD-Pipeline
                    sed -i "s|thepraduman/bankapp:.*|thepraduman/bankapp:${IMAGE_TAG}|" kubernetes/Manifest.yaml

                    echo "image tag updated"
                    cat kubernetes/Manifest.yaml

                    # commit and push the changes
                    git config user.name "giri"
                    git config user.email "giridharan9608@gmail.com"
                    git add kubernetes/Manifest.yaml
                    git commit -m "image tag updated to ${IMAGE_TAG}"
                    '''

                    withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                    cd Capstone-Mega-CD-Pipeline
                    git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/Giri9608/FullStack-Blogging-App.git
                    git push origin main
                    '''
                    }
                }
            }
        }
    }
    post {
    always {
        script {
            def jobName = env.JOB_NAME
            def buildNumber = env.BUILD_NUMBER
            def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
            def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

            def body = """
                <html>
                    <body>
                        <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                            <h2>${jobName} - Build #${buildNumber}</h2>
                            <div style="background-color: ${bannerColor}; padding: 10px;">
                                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                            </div>
                            <p>Check the <a href="${env.BUILD_URL}">Console Output</a> for more details.</p>
                        </div>
                    </body>
                </html>
            """

            emailext(
                subject: "${jobName} - Build #${buildNumber} - ${pipelineStatus.toUpperCase()}",
                body: body,
                to: 'giridharan9608@gmail.com',
                from: 'giridharan9608@gmail.com',
                replyTo: 'giridharan9608@gmail.com',
                mimeType: 'text/html',
                attachmentsPattern: 'fs-report.html'
            )
        }
    }
}
}
