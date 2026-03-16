#!/bin/bash
# =================================================================
# 01-install-jenkins-ec2.sh
# Run this ONCE on a fresh AWS EC2 (Amazon Linux 2023) instance.
# Usage: chmod +x 01-install-jenkins-ec2.sh && sudo ./01-install-jenkins-ec2.sh
# =================================================================

set -e

echo "========================================"
echo " HRMS Jenkins EC2 Bootstrap Script"
echo " Amazon Linux 2023"
echo "========================================"

# ── 1. System update ─────────────────────────────────────────────
echo "[1/8] Updating system packages..."
dnf update -y -q

# ── 2. Install Java 17 (Amazon Corretto) ─────────────────────────
echo "[2/8] Installing Java 17 (Corretto)..."
dnf install -y java-17-amazon-corretto-headless

# ── 3. Install Jenkins ────────────────────────────────────────────
echo "[3/8] Installing Jenkins (LTS)..."
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins
systemctl enable jenkins
systemctl start jenkins
echo "    Jenkins installed. Initial admin password will be shown later."

# ── 4. Install Docker + Docker Compose ───────────────────────────
echo "[4/8] Installing Docker..."
dnf install -y docker
systemctl enable docker
systemctl start docker

# Install Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "    Docker version: $(docker --version)"
echo "    Docker Compose version: $(docker compose version)"

# ── 5. Add jenkins user to docker group ──────────────────────────
echo "[5/8] Adding jenkins user to docker group..."
usermod -aG docker jenkins
# Also add ec2-user for manual debugging
usermod -aG docker ec2-user

# ── 6. Install Maven 3.9 ─────────────────────────────────────────
echo "[6/8] Installing Maven 3.9..."
MVN_VERSION="3.9.9"
wget -q "https://dlcdn.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" \
    -O /tmp/maven.tar.gz
tar -xzf /tmp/maven.tar.gz -C /opt/
ln -sfn /opt/apache-maven-${MVN_VERSION} /opt/maven
echo "    Maven version: $(/opt/maven/bin/mvn --version | head -1)"

# ── 7. Install Node.js 22 + npm ──────────────────────────────────
echo "[7/8] Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
echo "    Node: $(node --version)  npm: $(npm --version)"

# ── 8. Install AWS CLI v2 ─────────────────────────────────────────
echo "[8/8] Installing AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
dnf install -y unzip
unzip -q /tmp/awscliv2.zip -d /tmp/
/tmp/aws/install
echo "    AWS CLI version: $(aws --version)"

# ── Final configuration ───────────────────────────────────────────
# Set JAVA_HOME and Maven in PATH for all users
cat >> /etc/environment <<'EOF'
JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
M2_HOME=/opt/maven
PATH=/opt/maven/bin:/usr/lib/jvm/java-17-amazon-corretto/bin:$PATH
EOF

# Restart Jenkins to apply group changes
systemctl restart jenkins

echo ""
echo "========================================"
echo " ✅ Bootstrap complete!"
echo "========================================"
echo ""
echo " Jenkins URL   : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo " Jenkins Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo " NEXT STEPS:"
echo "   1. Open Jenkins URL in browser"
echo "   2. Enter the password above"
echo "   3. Install suggested plugins"
echo "   4. Create your admin user"
echo "   5. Run scripts/02-setup-github-ssh.sh to generate SSH keys"
echo ""
