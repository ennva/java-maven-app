#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@master', retriever: modernSCM(
    [$class: 'GitSCMSource',
     remote: 'https://gitlab.com/nanuchi/jenkins-shared-library.git',
     credentialsId: 'gitlab-credentials'
    ]
)

pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        IMAGE_NAME = 'nanajanashia/demo-app:java-maven-2.0'
    }
    stages {
        stage('build app') {
            steps {
               script {
                  echo 'building application jar...'
                  buildJar()
               }
            }
        }
        stage('build image') {
            steps {
                script {
                   echo 'building docker image...'
                   buildImage(env.IMAGE_NAME)
                   dockerLogin()
                   dockerPush(env.IMAGE_NAME)
                }
            }
        }

	stage("provision server") {
	    environment {
	        //these env var will be pick up by provider in terraform to authenticate itsefl to the aws platform
	    	AWS_ACCESS_KEY_ID = credential('jenkins_aws_access_key_id')
	    	AWS_SECRET_ACCESS_KEY = credential('jenkins_aws_secret_access_key')
	    	//this ovverwrite the variable env_prfix in terraform
	    	TF_VAR_env_prefix = 'test'
	    }
	    steps {
	        script {
	            dir('terraform') {
	                sh("terraform init")
	                sh("terraform apply --auto-approve")
	                EC2_PUBLIC_IP = sh(
	                    script: "terraform output ec2_public_ip",
	                    returnStdout: true
	                ).trim()
	            }
	        }
	    }
	}

        stage('deploy') {
            steps {
                script {
                   # to avoid the failure of the commands below, need to wait a provision of server finish
                   echo 'waiting for EC2 server to initialize...'
                   sleep(time: 90, unit: "SECONDS")
                   echo "public_ip_address: ${EC2_PUBLIC_IP}"
                   
                   echo 'deploying docker image to EC2...'

                   def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                   
                   # get the public_ip from terraform object
                   def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                   sshagent(['ec2-server-key']) {
                       sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                       sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                       sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                   }
                }
            }
        }
    }
}
