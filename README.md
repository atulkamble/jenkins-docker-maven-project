# Jenkins + Docker + Maven (GitHub → Docker Hub) — Step‑by‑Step Guide

> **Security first:** You pasted a GitHub Personal Access Token (PAT). If that token is real and active, **revoke it immediately** and create a new one with the minimum required scopes. Never commit or share tokens in chat, screenshots, or logs.
>
> * GitHub → **Settings › Developer settings › Personal access tokens** → Revoke the leaked token and **generate a new one** (classic scope: `repo` or fine‑grained with read for your repo).

---

## 1) Overview

You’ll set up a Jenkins Pipeline that:

1. Checks out code from **GitHub** (your fork of `jenkins-docker-maven-project`).
2. Builds the Java app with **Maven**.
3. Builds and tags a Docker image.
4. Pushes the image to **Docker Hub**.

We’ll do this using **Pipeline from SCM**, with credentials for both GitHub and Docker Hub.

---

## 2) Prerequisites

* **Jenkins** (controller or agent) with:

  * **Git** plugin and Git installed on the node (`git --version`).
  * **Pipeline** and **Credentials Binding** plugins (usually included by default).
  * **Docker** installed on the build node:

    * Node can run `docker build`, `docker login`, `docker push`.
    * Build user (e.g., `jenkins`) has permission to access the Docker daemon (often by adding to the `docker` group, or by using a Docker-in-Docker executor/agent).
  * **Java** and **Maven** available on the build node or installed via tools in Jenkins.
* **Docker Hub account** (username + access token/password).
* **GitHub** account and a **fork** of the repo.

> **Tip:** If your Jenkins is running in Docker, mount the host Docker socket or use a Docker agent image that includes Docker CLI and can access a DinD service.

---

## 3) Fork the repository

1. Open: `https://github.com/atulkamble/jenkins-docker-maven-project`.
2. Click **Fork** to create your own copy under your GitHub account.

---

## 4) Update the `Jenkinsfile` in your fork

Edit these two items:

1. **Docker Hub image name** — replace with **your** Docker Hub username:

```groovy
// e.g., for user "atuljkamble"
IMAGE_NAME = "atuljkamble/jenkins-docker-maven"
```

2. **Git remote URL** — point to **your** fork:

```groovy
// Example (replace github-user-name with your username)
// git branch: 'main', url: 'https://github.com/github-user-name/jenkins-docker-maven-project.git'
```

> You can either hardcode these in the Jenkinsfile, or parameterize them. A fully‑working Jenkinsfile template is provided in the **Appendix**.

---

## 5) Create Jenkins credentials

You’ll need **two** credentials.

### 5.1 GitHub credentials (for Pipeline SCM checkout)

* In Jenkins: **Manage Jenkins → Credentials → System → Global → Add Credentials**
* **Kind:** `Username with password`
* **ID (recommended):** `github-creds`
* **Username:** your GitHub username
* **Password:** your **GitHub PAT** (newly created; minimum scope `repo` for private repos, or fine‑grained with read on your fork). For public forks, a token is still recommended to avoid rate limits.

> **Never** paste tokens into Jenkinsfile. Keep them in Credentials.

### 5.2 Docker Hub credentials (for docker login & push)

* **Kind:** `Username with password`
* **ID:** `dockerhub-creds`
* **Username:** your Docker Hub username
* **Password:** Docker Hub **access token** (recommended) or your Docker Hub password.

---

## 6) Create the Pipeline job

1. In Jenkins, click **New Item** → **Pipeline**.
2. **Name:** `jenkins-docker-maven-project`
3. Click **OK**.
4. In **Pipeline** section:

   * **Definition:** *Pipeline script from SCM*
   * **SCM:** *Git*
   * **Repository URL:**

     * `https://github.com/github-user-name/jenkins-docker-maven-project.git`
   * **Credentials:** select `github-creds`
   * **Branch Specifier:** `*/main` (or your default branch)
   * **Script Path:** `Jenkinsfile` (if you kept default)
5. **Save**.

---

## 7) Configure Docker on the build node (quick checks)

* `docker --version` must work.
* `docker info` should not error.
* Ensure the Jenkins build user can run Docker commands without sudo, or configure the pipeline to use `sudo docker ...` where appropriate.

---

## 8) Run the Pipeline

1. Open your job `jenkins-docker-maven-project`.
2. Click **Build Now**.
3. Open **Build #N** → **Console Output** to follow logs.

Expected stages:

* **Checkout SCM** (from GitHub using `github-creds`)
* **Maven Build** (`mvn -B -DskipTests package` or similar)
* **Docker Build & Tag**
* **Docker Login & Push** (using `dockerhub-creds`)

---

## 9) Verify the image on Docker Hub

After success, visit Docker Hub → **Repositories** and verify that `jenkins-docker-maven:latest` (and/or the build tag) is pushed.

---

## 10) Common errors & fixes

* **`Selected Git installation does not exist. Using Default`**

  * Ensure Git is installed on the node and configured in **Manage Jenkins → Tools** (optional, works with system git).

* **`git: not found`** or `git --version` shows error

  * Install git on the node: e.g., `sudo apt-get update && sudo apt-get install -y git`.

* **Permission denied / cannot access Docker daemon**

  * Add Jenkins user to `docker` group (Linux): `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` (then re-login the session/agent).

* **`docker login` fails**

  * Re‑check `dockerhub-creds` username/token. If 2FA is enabled, you must use a Docker Hub access token, not your password.

* **Rate limit or auth issues on GitHub**

  * Ensure `github-creds` PAT is valid. Rotate if leaked. For public repos, a PAT helps avoid rate limiting.

* **`mvn: command not found`**

  * Install Maven on the node or configure a Jenkins tool installation and add to PATH in the pipeline.

---

## 11) Appendix — Jenkinsfile (ready‑to‑use template)

This Declarative Pipeline expects two credentials:

* `github-creds` (Username/Password with GitHub PAT as password)
* `dockerhub-creds` (Username/Password with Docker Hub token as password)

**What it does:**

* Checks out from your fork’s `main` branch
* Builds with Maven (skipping tests by default)
* Builds a Docker image and tags it as `latest` and `${BUILD_NUMBER}`
* Logs into Docker Hub and pushes both tags

```groovy
pipeline {
  agent any

  environment {
    // Change to your Docker Hub username/repo
    IMAGE_NAME = "atuljkamble/jenkins-docker-maven"
    // Optional: customize Java/Maven goals
    MAVEN_GOALS = "-B -DskipTests clean package"
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  triggers { }

  stages {
    stage('Checkout') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[
            url: 'https://github.com/github-user-name/jenkins-docker-maven-project.git',
            credentialsId: 'github-creds'
          ]]
        ])
      }
    }

    stage('Maven Build') {
      tools { maven 'Maven-3' } // Optional: if configured under Manage Jenkins > Tools
      steps {
        sh "mvn ${env.MAVEN_GOALS}"
        sh 'ls -lh target || true'
      }
    }

    stage('Docker Build & Tag') {
      steps {
        script {
          def buildTag = env.BUILD_NUMBER
          sh "docker build -t ${IMAGE_NAME}:latest ."
          sh "docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${buildTag}"
        }
      }
    }

    stage('Docker Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
          sh "docker push ${IMAGE_NAME}:latest"
          sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
        }
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
      archiveArtifacts artifacts: 'target/**/*.jar', onlyIfSuccessful: false
    }
    success {
      echo "Success: pushed ${IMAGE_NAME}:latest and :${BUILD_NUMBER} to Docker Hub"
    }
    failure {
      echo 'Build failed. See console output for details.'
    }
  }
}
```

> **Note:** If your Jenkins node requires `sudo` for Docker, prepend `sudo` to the `docker` commands (or better, fix group permissions).

---

## 12) Quick Reference — The items you asked to do

1. **Fork repo:** `https://github.com/atulkamble/jenkins-docker-maven-project`

2. **Edit Jenkinsfile:**

   * Set Docker Hub username → `IMAGE_NAME = "<dockerhub-user>/jenkins-docker-maven"`
   * Set Git URL → `'https://github.com/<github-user-name>/jenkins-docker-maven-project.git'`

3. **Create pipeline:** name it `jenkins-docker-maven-project`.

4. **Select Pipeline from SCM:**

   * SCM: Git
   * URL: `https://github.com/<github-user-name>/jenkins-docker-maven-project.git`
   * Credentials: `github-creds`

5. **Credentials – Git:** Username (GitHub user), Password (**PAT** token).

6. **Credentials – Docker Hub:** `dockerhub-creds` → Username + **Docker Hub token**.

7. **Run pipeline** (Build Now).

8. **Check Console Output** for each stage’s logs and errors.

---

## 13) (Optional) Parameterize the job

If you want to reuse the same job for different forks/repos or tags, add parameters and reference them in the Jenkinsfile:

```groovy
parameters {
  string(name: 'GIT_URL', defaultValue: 'https://github.com/github-user-name/jenkins-docker-maven-project.git', description: 'Git repository URL')
  string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Branch to build')
  string(name: 'IMAGE_NAME', defaultValue: 'dockerhub-user/jenkins-docker-maven', description: 'Docker image name')
}
```

Then use `${params.GIT_URL}`, `${params.GIT_BRANCH}`, etc., in the `checkout` step and `docker` commands.

---

## 14) Troubleshooting checklist (quick)

* [ ] Git installed and reachable on agent
* [ ] Maven installed or tool configured
* [ ] Docker CLI installed and daemon reachable
* [ ] Jenkins user in `docker` group (or no‑sudo required)
* [ ] Correct credentials IDs: `github-creds`, `dockerhub-creds`
* [ ] Jenkinsfile path correct (`Jenkinsfile` at repo root)
* [ ] Branch name matches (`main` vs `master`)
* [ ] PAT and Docker tokens valid (rotate if any doubt)

---

**You’re set!** Trigger a build and watch the image land on Docker Hub. If you want, I can also provide a variant that runs tests, tags by Git commit SHA, and pushes a `release-*` tag only on `main` merges.
