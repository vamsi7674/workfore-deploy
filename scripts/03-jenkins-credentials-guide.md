# HRMS Jenkins & AWS Credentials Setup Guide

This guide covers everything you need to configure in Jenkins (and AWS) before running the pipelines.

---

## Step 1 — Install Required Jenkins Plugins

Go to: **Jenkins → Manage Jenkins → Plugins → Available plugins**

Search and install:
| Plugin | Purpose |
|--------|---------|
| `Pipeline` | Core pipeline support |
| `Git Plugin` | GitHub integration |
| `SSH Agent Plugin` | SSH key injection in pipelines |
| `Credentials Binding Plugin` | Secret injection |
| `Publish Over SSH` | (optional, not used in new pipeline) |
| `NodeJS Plugin` | Node.js tool support |

---

## Step 2 — Configure Global Tools

Go to: **Jenkins → Manage Jenkins → Tools**

### JDK
- Name: `JDK17`
- Install automatically: ✅
- Version: `17` (adoptium / temurin)

### Maven
- Name: `Maven3`
- Install automatically: ✅
- Version: `3.9.9`

### NodeJS
- Name: `NodeJS22`
- Install automatically: ✅
- Version: `22.x`

---

## Step 3 — Add Jenkins Credentials

Go to: **Jenkins → Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

### 3a. GitHub SSH Key
| Field | Value |
|-------|-------|
| Kind | SSH Username with private key |
| ID | `github-ssh-key` |
| Username | `git` |
| Private Key | Paste the private key output from `02-setup-github-ssh.sh` |

### 3b. EC2 SSH Key (your AWS `.pem` file)
| Field | Value |
|-------|-------|
| Kind | SSH Username with private key |
| ID | `ec2-ssh-key` |
| Username | `ec2-user` |
| Private Key | Paste the content of your EC2 `.pem` key file |

### 3c. MySQL Root Password
| Field | Value |
|-------|-------|
| Kind | Secret text |
| ID | `mysql-root-password` |
| Secret | `YourStrongRootPassword123!` |

### 3d. MySQL User Password
| Field | Value |
|-------|-------|
| Kind | Secret text |
| ID | `mysql-user-password` |
| Secret | `YourStrongUserPassword123!` |

### 3e. Spring Mail Password (Gmail App Password)
| Field | Value |
|-------|-------|
| Kind | Secret text |
| ID | `spring-mail-password` |
| Secret | 16-character Gmail App Password |

### 3f. AWS S3 Credentials (for frontend)
| Field | Value |
|-------|-------|
| Kind | Username with password |
| ID | `aws-s3-credentials` |
| Username | Your AWS Access Key ID |
| Password | Your AWS Secret Access Key |

---

## Step 4 — Create Backend Pipeline Job

1. **Jenkins → New Item**
2. Name: `hrms-backend`  Type: **Pipeline**
3. Under **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `git@github.com:vamsi7674/workfore-deploy.git`
   - Credentials: `github-ssh-key`
   - Branch: `*/main`
   - Script Path: `final deploye/RevWorkforce/Jenkinsfile`
4. Save → **Build Now**

---

## Step 5 — Create Frontend Pipeline Job

1. **Jenkins → New Item**
2. Name: `hrms-frontend`  Type: **Pipeline**
3. Under **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `git@github.com:vamsi7674/workfore-deploy.git`
   - Credentials: `github-ssh-key`
   - Branch: `*/main`
   - Script Path: `final deploye/RevWorkForce-Frontend/Jenkinsfile`
4. **Update `S3_BUCKET`** in the Jenkinsfile with your bucket name before running
5. Save → **Build Now**

---

## Step 6 — AWS S3 Bucket Setup (Frontend)

1. Go to **AWS Console → S3 → Create bucket**
2. Bucket name: e.g. `hrms-portal-frontend` (must be globally unique)
3. Region: `ap-south-1` (or your chosen region)
4. **Uncheck** "Block all public access"
5. Enable **Static website hosting**:
   - Index document: `index.html`
   - Error document: `index.html` (for Angular routing)
6. Add this **Bucket Policy** (replace `YOUR-BUCKET-NAME`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

---

## Step 7 — EC2 Security Group Rules

In **AWS Console → EC2 → Security Groups**, add these inbound rules:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP only | SSH access |
| 8080 | TCP | 0.0.0.0/0 | Spring Boot API (called by S3 frontend) |
| 8765 | TCP | Your IP only | Jenkins UI (use 8080 if Jenkins uses that port) |

> **Note**: Jenkins default port is 8080. If your Spring Boot also uses 8080, change Jenkins to 8765 in `/etc/sysconfig/jenkins` (set `JENKINS_PORT=8765`).

---

## Step 8 — Update Angular Environment File

Before running the frontend pipeline, update the API URL in the Angular app:

File: `final deploye/RevWorkForce-Frontend/src/environments/environment.prod.ts`

```typescript
export const environment = {
  production: true,
  apiUrl: 'http://YOUR_EC2_PUBLIC_IP:8080'  // ← replace with your new EC2 IP
};
```

Commit and push this change before triggering the frontend build.

---

## Webhook Setup (Optional — Auto-trigger on Git Push)

1. Go to **Jenkins → hrms-backend → Configure → Build Triggers**
2. Enable **"GitHub hook trigger for GITScm polling"**
3. In **GitHub → Repo → Settings → Webhooks → Add webhook**:
   - Payload URL: `http://YOUR_EC2_IP:8080/github-webhook/`
   - Content type: `application/json`
   - Events: `Just the push event`
