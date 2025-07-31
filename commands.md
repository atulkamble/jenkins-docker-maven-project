// jenkins-docker-maven-project

1) fork repo https://github.com/atulkamble/jenkins-docker-maven-project
2) edit Jenkinsfile 

add dockerhub username in Jenkinsfile
example: atuljkamble

IMAGE_NAME = "atuljkamble/jenkins-docker-maven"

add github username/ repo url 
example: atulkamble

git branch: 'main', url: 'https://github.com/atulkamble/jenkins-docker-maven-project.git'

3) create pipeline 
name it: jenkins-docker-maven-project

4) Select pipeline from SCM 

add url 

https://github.com/atulkamble/jenkins-docker-maven-project.git

5) credentials - git >> username and password 

password - token 

6) set dockerhub-creds >> add username and password 

7) run pipeline

8) check console output 
