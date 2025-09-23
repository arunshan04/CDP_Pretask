# mkdir -p ~/.ssh
echo "$AWS_SSH_PRIVATE_KEY_SG" > key-SG.pem
chmod 600 key-SG.pem
