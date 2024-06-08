#!/bin/bash

RUNNER_BIN=https://gitea.com/gitea/act_runner/releases/download/v0.2.10/act_runner-0.2.10-linux-amd64

while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2 # past argument and value
      ;;
    --gitea-ip)
      GITEA_IP="$2"
      shift 2 # past argument and value
      ;;
    --gitea-instance-url)
      GITEA_INSTANCE_URL="$2"
      shift 2 # past argument and value
      ;;
    --key-file)
      KEY="$2"
      shift 2 # past argument and value
      ;;
    --dl-url)
      RUNNER_BIN="$2"
      shift 2 # past argument and value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# Setup ssh key
rsync -av ~/.ssh/$KEY $TARGET:.ssh
ssh $TARGET "
chmod 600 .ssh/$KEY
echo 'IdentityFile ~/.ssh/$KEY' > ~/.ssh/config
"

# Install Gitea Action Runner
rsync act_runner.service $TARGET:./
rsync runner_config.yaml $TARGET:./

token=`ssh ubuntu@$GITEA_IP "sudo su git -c 'gitea --config /etc/gitea/app.ini actions generate-runner-token'"`
ssh $TARGET "
sudo wget $RUNNER_BIN -xO /usr/local/bin/act_runner
sudo chmod +x /usr/local/bin/act_runner
sudo mkdir /etc/act_runner

sudo mv runner_config.yaml /etc/act_runner/config.yaml
sudo /usr/local/bin/act_runner register --config /etc/act_runner/config.yaml --no-interactive --instance $GITEA_INSTANCE_URL --token $token --name $TARGET

sudo mv act_runner.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable act_runner --now
"
