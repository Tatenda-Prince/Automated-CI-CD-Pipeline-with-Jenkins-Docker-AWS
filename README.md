# CI/CD Pipeline with Jenkins, Docker, AWS ECR & Terraform

![image_alt]()

## Background
Manually provisioning infrastructure and deploying applications slows down software delivery and increases human error. DevOps engineers solve this using Infrastructure as Code (IaC) and CI/CD pipelines to automate deployments, enhance security, and improve reliability.

This project demonstrates how to provision infrastructure with Terraform and implement a complete CI/CD pipeline using Jenkins, Docker, AWS ECR, and Slack notifications, giving you a full-stack DevOps workflow.

## Project Overview
This project provisions an EC2 instance with Jenkins, Docker, and Java using Terraform, then sets up a full CI/CD pipeline in Jenkins that:

1.Clones a Flask app from GitHub

2.Builds and tags a Docker image

3.Pushes the image to AWS Elastic Container Registry (ECR)

4.Sends Slack notifications on pipeline success/failure


## Project Objectives
1.Provision EC2 infrastructure using Terraform

2.Automate Docker image builds and deployments using Jenkins

3.Securely manage credentials for AWS and Slack

4.Push images to AWS ECR

5.Notify DevOps teams via Slack

6.Demonstrate a real-world CI/CD pipeline with IaC


## Features
1.Terraform-provisioned EC2 for Jenkins + Docker

2.GitHub Source Code Integration

3.Jenkins Declarative Pipeline

4.Dockerized Python Flask App

5.Secure AWS ECR Authentication

6.Slack Notifications

7.IAM Role + Security Group Configurations

8.Reusable Jenkinsfile with Build Stages

## Technologies Used
Terraform-Infrastructure Provisioning (EC2, IAM)

AWS EC2-Jenkins, Docker, Java Host

Jenkins-CI/CD Pipeline Orchestration

Docker-Containerization

AWS ECR-Docker Image Registry

Flask-Python Web App

GitHub-Source Repository

Slack-Real-time Notifications

## Use Case
You work as Devops Engineer at small start that delivers Saas products to customers , as the Lead Devops Engineer you are tasked with the end-to-end automation of a Flask web app by modernizing legacy deployments,automating Python app delivery and implementing Infrastructure as Code and pipelines.

## Prerequisites
1.Terraform installed (terraform -v)

2.AWS IAM user with access to EC2, ECR, IAM

3.AWS credentials configured (aws configure)

4.GitHub repo with Flask app

5.Slack Webhook URL for notifications


## Step 1: Provision Jenkins EC2 Instance using Terraform

Terraform Files:

1.`main.tf`: EC2, Security Group, IAM Role

2.`variables.tf`: Reusable variables

3.`outputs.tf`: Public IP output

4.`terrraform.tfvars`: Key Pair


Run:
```language
terraform init

terraform apply
```

![alt_images](https://github.com/Tatenda-Prince/Automated-CI-CD-Pipeline-with-Jenkins-Docker-AWS/blob/e2c664c636ed7172d2976b3b33138ab162086c8c/screenshots/Screenshot%202025-04-12%20165209.png)


## Step 2: SSH into EC2 and install Jenkins, Docker, AWS CLI 

2.1.Installing Jenkins and Java

```language
sudo apt update
sudo apt install openjdk-17-jre
```

Verify Java is Installed
```language
java -version
```

2.2.Now, you can proceed with installing Jenkins

```language
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```

Jenkins will be available at: `http://<public-ip>:8080`

## Step 3: Login to Jenkins
3.1.`http://<public-ip>:8080` replace the public ip with your own public ip address on your EC2 instance.

3.2.After you login to Jenkins,Run the command to copy the Jenkins Admin Password
`sudo cat /var/lib/jenkins/secrets/initialAdminPassword` - Enter the Administrator password

![image_alt](https://github.com/Tatenda-Prince/Automated-CI-CD-Pipeline-with-Jenkins-Docker-AWS/blob/92b1d60bc43463c63dd12cbd5c038ccde68eb695/screenshots/Screenshot%202025-04-12%20170437.png)


3.3.Click on Install suggested plugins:

![image_alt]()

3.4.Wait for the Jenkins to Install suggested plugins

![image_alt]()

3.5.Create First Admin User or Skip the step [If you want to use this Jenkins instance for future use-cases as well, better to create admin user]

![image_alt]()

3.6.Jenkins Installation is Successful. You can now starting using the Jenkins

![image_alt]()


## Step 4: Install Plugins & Docker, AWS CLI 
4.1.Log in to Jenkins.

4.2.Go to Manage Jenkins > Manage Plugins.

4.3.In the Available tab, search for the  following.
```language
Amazon ECR
Docker 
Pipeline
Git
Blue Ocean
```
4.4.Select the plugins and click the Install button.

4.5.Restart Jenkins after the plugin is installed.

![image_alt]()


4.6.Now we must install Docker on EC2 and grant Jenkins user and Ubuntu user permission to docker
```langauge
sudo apt-get update -y
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo reboot
```

4.6.Now we must install AWS CLI on EC2
```language
sudo apt update
sudo apt install unzip curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

4.7.Create a repository in AWS ECR this where will push our docker image.

```langauge
aws ecr create-repository --repository-name flask-python-app --region us-east-1
```

## Step 5: Store Credentials in Jenkins

1. AWS Credentials

Jenkins → `Manage Jenkins` → `Credential`s → `Global` → Add Credentials

Type: Username with password

ID: `aws-creds`

Username: Your AWS Access Key

Password: Your AWS Secret Key

2. Slack Webhook

Type: Secret Text

ID: `SLACK_WEBHOOK`

Secret: Your Slack Webhook URL

## Step 6: Create Jenkins Pipeline
Use this `Jenkinsfile`:
```Language
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '970547345579.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO_NAME = 'flask-python-app'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git url: 'https://github.com/Tatenda-Prince/flask-app.git', branch: 'master'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${ECR_REPO_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region $AWS_REGION
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                    """
                }
            }
        }

        stage('Tag & Push Image to ECR') {
            steps {
                sh """
                    docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
            withCredentials([string(credentialsId: 'SLACK_WEBHOOK', variable: 'SLACK_URL')]) {
                sh """
                    curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ *Build Succeeded:* Docker image pushed to ECR!"}' $SLACK_URL
                """
            }
        }

        failure {
            echo "❌ Pipeline failed."
            withCredentials([string(credentialsId: 'SLACK_WEBHOOK', variable: 'SLACK_URL')]) {
                sh """
                    curl -X POST -H 'Content-type: application/json' --data '{"text":"❌ *Build Failed:* Check Jenkins logs for more details."}' $SLACK_URL
                """
            }
        }
    }
}

```

## Testing the System

1.Push changes to the GitHub repo

2.Jenkins auto-triggers a build

![image_alt]()

3.Docker image is built and pushed to ECR

![image_alt]()

4.Slack receives a notification

![image_alt]()

5.Pull and run image:

```language
docker pull <ecr-repo-url>:latest
docker run -p 5000:5000 <ecr-repo-url>:latest

```

![image_alt]()


## Future Enhancements
1.Automatically deploy pushed image to AWS ECS

2.Add test stage for unit testing

3.Implement rollback on pipeline failure

4.Add Grafana & Prometheus for monitoring

5.Vault integration for secrets management


## What We Learned
1.Provisioning EC2 with Terraform and securing infrastructure

2.Automating Docker builds using Jenkins Pipelines

3.Securely authenticating and pushing to AWS ECR

4.Integrating Slack for real-time collaboration

5.Building a scalable and production-grade CI/CD workflow















