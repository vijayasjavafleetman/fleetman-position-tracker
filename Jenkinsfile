node {
   def mvnHome
   def pom
   def artifactVersion
   def tagVersion
   def retrieveArtifact
   def name
   def SERVICE_NAME
   def NREPOSITORY_TAG
   def appname
    
   stage('Prepare') {
      mvnHome = tool 'MAVENHOME'
      appname='positionreceiver'
   }

   stage('Checkout') {
      checkout scm
   }
 
   stage('Build') {
      if (isUnix()) {
         sh "'${mvnHome}/bin/mvn' -Dmaven.test.failure.ignore clean package"
      } else {
         bat(/"${mvnHome}\bin\mvn" -Dmaven.test.failure.ignore clean package/)
      }
   }

   stage('Unit Test') {
      junit '**/target/surefire-reports/TEST-*.xml'
      archive 'target/*.jar'
   }

   stage('Integration Test') {
      if (isUnix()) {
         sh "'${mvnHome}/bin/mvn' -Dmaven.test.failure.ignore clean verify"
      } else {
         bat(/"${mvnHome}\bin\mvn" -Dmaven.test.failure.ignore clean verify/)
      }
   }

   if(env.BRANCH_NAME ==~ /release.*/){

      pom = readMavenPom file: 'pom.xml'
      artifactVersion = pom.version.replace("-SNAPSHOT", "")
      tagVersion = 'v'+artifactVersion
      name = pom.name
      REPOSITORY_TAG="${env.DOCKERHUB_USERNAME}/${env.ORGANIZATION_NAME}-${name}:${artifactVersion}"
      
      stage('Release Build And Upload Artifacts') {
         if (isUnix()) {
            sh "'${mvnHome}/bin/mvn' clean release:clean release:prepare release:perform"
         } else {
            bat(/"${mvnHome}\bin\mvn" clean release:clean release:prepare release:perform/)
         }
      }
         

      stage("QA Approval"){
         echo "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) is waiting for input. Please go to ${env.BUILD_URL}."
         input 'Approval for QA Deploy?';
      }

      stage('SSH transfer to QA') {
         script {
            sshPublisher(
               continueOnError: false,
               failOnError: true,
               publishers: [
                  sshPublisherDesc(
                     configName: "ansibleserver",
                     verbose: true,
                     transfers: [
                        sshTransfer(
                           sourceFiles: "",
                           removePrefix: "",
                           remoteDirectory: "",
                           execCommand: "cd /home/ansadmin/jenkins/${appname}-qa/workspace;rm -f *;"
                        ),
                        sshTransfer(
                           execTimeout: 999999,
                           sourceFiles: "Dockerfile,${appname}-build-playbook-qa.yaml",
                           removePrefix: "",
                           remoteDirectory: "${appname}-qa/workspace",
                           execCommand: "cd /home/ansadmin/jenkins/${appname}-qa/workspace;ansible-playbook -i /home/ansadmin/jenkins/${appname}-qa/hostconfig/hosts -u ansadmin -e tag=${REPOSITORY_TAG} -e ARTIFACT_VERSION=${artifactVersion} -e ARTIFACTORY_URL=${env.ARTIFACTORY_RELEASE_URL} -e ARTIFACTORY_USERNAME=${env.ARTIFACTORY_USERNAME} -e ARTIFACTORY_PASSWD=${env.ARTIFACTORY_PASSWD} /home/ansadmin/jenkins/${appname}-qa/workspace/${appname}-build-playbook-qa.yaml;"
                        )
                     ]
                  )
               ]
            )
         }
      }

      withEnv(["REPOSITORY_TAG=${REPOSITORY_TAG}"]){
         stage('Deploy to QA Cluster') {
            sh 'envsubst < ${WORKSPACE}/deploy.yaml > ${WORKSPACE}/udeploy.yaml'
            sh 'cat ${WORKSPACE}/udeploy.yaml'

            stage('SSH transfer') {
               script {
                  sshPublisher(
                     continueOnError: false,
                     failOnError: true,
                     publishers: [
                        sshPublisherDesc(
                           configName: "ansibleserver",
                           verbose: true,
                           transfers: [
                              sshTransfer(
                                 sourceFiles: "",
                                 removePrefix: "",
                                 remoteDirectory: "",
                                 execCommand: "cd /home/ansadmin/jenkins/${appname}-qa/workspace;rm -f *;"
                              ),
                              sshTransfer(
                                 execTimeout: 999999,
                                 sourceFiles: "udeploy.yaml,${appname}-deployment-playbook-qa.yaml",
                                 removePrefix: "",
                                 remoteDirectory: "${appname}-qa/workspace",
                                 execCommand: "cd /home/ansadmin/jenkins/${appname}-qa/workspace;ansible-playbook -i /home/ansadmin/jenkins/${appname}-qa/hostconfig/hosts -u ansadmin  /home/ansadmin/jenkins/${appname}-qa/workspace/${appname}-deployment-playbook-qa.yaml;"
                              )
                           ]
                        )
                     ]
                  )
               }
            }
         }
      }
   }

   if(env.BRANCH_NAME == 'master'){
      stage('Validate Build Post Prod Release') {
         if (isUnix()) {
            sh "'${mvnHome}/bin/mvn' clean package"
         } else {
            bat(/"${mvnHome}\bin\mvn" clean package/)
         }
      }
   }

   if(env.BRANCH_NAME == 'develop'){
      stage('Snapshot Build And Upload Artifacts') {
         if (isUnix()) {
            sh "'${mvnHome}/bin/mvn' clean deploy"
         } else {
            bat(/"${mvnHome}\bin\mvn" clean deploy/)
         }

         pom = readMavenPom file: 'pom.xml'
         artifactVersion = pom.version
         name = pom.name
         REPOSITORY_TAG="${env.DOCKERHUB_USERNAME}/${env.ORGANIZATION_NAME}-${name}:${artifactVersion}.${env.BUILD_ID}"
         echo "${REPOSITORY_TAG}"
         echo "artifact version : ${artifactVersion}"
      }

      stage('SSH transfer') {
         script {
            sshPublisher(
               continueOnError: false,
               failOnError: true,
               publishers: [
                  sshPublisherDesc(
                     configName: "ansibleserver",
                     verbose: true,
                     transfers: [
                        sshTransfer(
                           sourceFiles: "",
                           removePrefix: "",
                           remoteDirectory: "",
                           execCommand: "cd /home/ansadmin/jenkins/${appname}/workspace;rm -f *;"
                        ),
                        sshTransfer(
                           execTimeout: 999999,
                           sourceFiles: "Dockerfile,${appname}-build-playbook.yaml",
                           removePrefix: "",
                           remoteDirectory: "${appname}/workspace",
                           execCommand: "cd /home/ansadmin/jenkins/${appname}/workspace;ansible-playbook -i /home/ansadmin/jenkins/${appname}/hostconfig/hosts -u ansadmin -e tag=${REPOSITORY_TAG} -e ARTIFACT_VERSION=${artifactVersion} -e ARTIFACTORY_URL=${env.ARTIFACTORY_SNAPSHOT_URL} -e ARTIFACTORY_USERNAME=${env.ARTIFACTORY_USERNAME} -e ARTIFACTORY_PASSWD=${env.ARTIFACTORY_PASSWD} -e DOCKER_USERNAME=${env.DOCKERHUB_USERNAME} -e DOCKER_PASSWD=${env.DOCKERHUB_PASSWD} /home/ansadmin/jenkins/${appname}/workspace/${appname}-build-playbook.yaml;"
                        )
                     ]
                  )
               ]
            )
         }
      }

      withEnv(["REPOSITORY_TAG=${REPOSITORY_TAG}"]) {
         stage('Deploy to Cluster') {
            sh 'envsubst < ${WORKSPACE}/deploy.yaml > ${WORKSPACE}/udeploy.yaml'
            sh 'cat ${WORKSPACE}/udeploy.yaml'

            stage('SSH transfer') {
               script {
                  sshPublisher(
                     continueOnError: false,
                     failOnError: true,
                     publishers: [
                        sshPublisherDesc(
                           configName: "ansibleserver",
                           verbose: true,
                           transfers: [
                              sshTransfer(
                                 sourceFiles: "",
                                 removePrefix: "",
                                 remoteDirectory: "",
                                 execCommand: "cd /home/ansadmin/jenkins/${appname}/workspace;rm -f *;"
                              ),
                              sshTransfer(
                                 execTimeout: 999999,
                                 sourceFiles: "udeploy.yaml,${appname}-deployment-playbook.yaml",
                                 removePrefix: "",
                                 remoteDirectory: "${appname}/workspace",
                                 execCommand: "cd /home/ansadmin/jenkins/${appname}/workspace;ansible-playbook -i /home/ansadmin/jenkins/${appname}/hostconfig/hosts -u ansadmin  /home/ansadmin/jenkins/${appname}/workspace/${appname}-deployment-playbook.yaml;"
                              )
                           ]  
                        )
                     ]
                  )
               }
            }
         }
      }
   }   
}
