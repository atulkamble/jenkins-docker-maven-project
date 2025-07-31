**Complete Jenkins + Docker + Maven project setup**, including:

* A simple Maven Java app
* A Dockerfile to containerize the app
* Jenkins pipeline to build, test, and package using Maven
* Docker image creation and push to Docker Hub (optional)

---

## 🔧 Project Structure

```
jenkins-docker-maven-project/
├── Dockerfile
├── Jenkinsfile
├── pom.xml
└── src/
    └── main/
        └── java/
            └── com/example/
                └── App.java
```

---

## 1️⃣ Java App (`App.java`)

`src/main/java/com/example/App.java`:

```java
package com.example;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello from Maven + Jenkins + Docker!");
    }
}
```

---

## 2️⃣ Maven Config (`pom.xml`)

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>jenkins-docker-maven</artifactId>
    <version>1.0-SNAPSHOT</version>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

---

## 3️⃣ Dockerfile

```Dockerfile
FROM maven:3.8.5-openjdk-11 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package

FROM openjdk:11
WORKDIR /app
COPY --from=builder /app/target/jenkins-docker-maven-1.0-SNAPSHOT.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

---

## 4️⃣ Jenkinsfile (Pipeline Script)

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = "atuljkamble/jenkins-docker-maven"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/atulkamble/jenkins-docker-maven-project.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:latest")
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                            dockerImage.push()
                        }
                    }
                }
            }
        }
    }
}
```

> 🔐 `dockerhub-creds`: Add your DockerHub username/password in Jenkins credentials (ID: `dockerhub-creds`).

---

## 5️⃣ Setup Jenkins Server (Optional Quickstart on Docker)

```bash
docker run -d --name jenkins \
  -u root -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

Install plugins:

* Docker
* Pipeline
* Git
* Maven Integration

---

## ✅ Run Flow

1. Push code to GitHub
2. Jenkins Pipeline runs:

   * Pulls code
   * Builds using Maven
   * Creates Docker image
   * Pushes image to Docker Hub

---

## 🔗 GitHub Repo

Let's name the GitHub repository:

### ✅ **`jenkins-docker-maven-project`**

You can use this name when creating your repo on GitHub:

```bash
gh repo create jenkins-docker-maven-project --public --source=. --remote=origin --push
```

Or manually push your code:

### 🧾 GitHub Push Commands

```bash
git init
git remote add origin https://github.com/<your-username>/jenkins-docker-maven-project.git
git add .
git commit -m "Initial commit - Jenkins + Docker + Maven pipeline project"
git push -u origin main
```
docker, docker pipeline, blue ocean


## ✅ Create DockerHub Credentials in Jenkins

To resolve this, you must **add your DockerHub credentials** in Jenkins.

### 🔐 Step-by-Step to Add DockerHub Credentials:

1. **Go to Jenkins Dashboard**

2. Click **"Manage Jenkins"**

3. Click **"Credentials"**

4. Under `(global)` → Click **"(global) credentials (unrestricted)"**

5. Click **"Add Credentials"**

6. Fill in the form:

   * **Kind**: `Username with password`
   * **Username**: *Your DockerHub username*
   * **Password**: *Your DockerHub password or PAT*
   * **ID**: `dockerhub-creds`  ✅ *This must match your `Jenkinsfile`*
   * **Description**: `DockerHub login for pushing images`

7. Click **Save**



