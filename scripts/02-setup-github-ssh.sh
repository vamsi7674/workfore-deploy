#!/bin/bash
# =================================================================
# 02-setup-github-ssh.sh
# Run this ON the EC2 instance (as root or ec2-user) AFTER Jenkins
# is installed. It generates SSH keys for the jenkins user so you
# can add the public key as a GitHub Deploy Key.
# Usage: sudo ./02-setup-github-ssh.sh
# =================================================================

JENKINS_HOME="/var/lib/jenkins"
SSH_DIR="${JENKINS_HOME}/.ssh"
KEY_FILE="${SSH_DIR}/github_deploy_key"

echo "======================================================"
echo " Generating GitHub SSH Deploy Key for Jenkins"
echo "======================================================"

# Create .ssh directory for jenkins user
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
chown jenkins:jenkins "${SSH_DIR}"

# Generate ED25519 key (modern, secure, compact)
if [ -f "${KEY_FILE}" ]; then
    echo "⚠️  Key already exists at ${KEY_FILE}"
    echo "   If you want to regenerate, delete it first and re-run."
else
    ssh-keygen -t ed25519 -C "jenkins-hrms-deploy" \
               -f "${KEY_FILE}" -N ""
    chown jenkins:jenkins "${KEY_FILE}" "${KEY_FILE}.pub"
    chmod 600 "${KEY_FILE}"
    chmod 644 "${KEY_FILE}.pub"
    echo "✅ Key pair generated."
fi

# Add GitHub to known_hosts (avoids "Host key verification failed")
ssh-keyscan -t ed25519 github.com >> "${SSH_DIR}/known_hosts" 2>/dev/null
chown jenkins:jenkins "${SSH_DIR}/known_hosts"
chmod 644 "${SSH_DIR}/known_hosts"

echo ""
echo "======================================================"
echo " 📋 PUBLIC KEY — Add this to GitHub Deploy Keys:"
echo " GitHub Repo → Settings → Deploy Keys → Add deploy key"
echo " Title: jenkins-hrms   Allow write access: NO"
echo "======================================================"
echo ""
cat "${KEY_FILE}.pub"
echo ""
echo "======================================================"
echo " 🔑 PRIVATE KEY — Add to Jenkins Credentials:"
echo " Jenkins → Manage Jenkins → Credentials → Global"
echo " Kind: SSH Username with private key"
echo " ID: github-ssh-key"
echo " Username: git"
echo " Private key: paste the content below"
echo "======================================================"
echo ""
cat "${KEY_FILE}"
echo ""
