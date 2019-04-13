#!/bin/bash -x -e

echo -e "Generating the EMR cluster\n"

#pip install --upgrade pip

# Install the AWS command tool
#pip install awscli

# Save the AWS Keys to the default folder 
CREDENTIALS=$(ls  ~/.aws)
if [ -z "$CREDENTIALS" ]; then
	echo "Your AWS configuration file is required!"
	echo "For help visit:"
	echo "https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html"
	echo "See your accessKeys.csv file to find the Access Keys"
	echo -e "Your inputs should look like this:\n"
	echo "AWS Access Key ID [None]: AKIAIEXAMPLEKEY"
	echo "AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
	echo "Default region name [None]: us-east-1"
	echo "Default output format [None]: json"
	aws configure
else 
	echo "Using existing AWS credentials..."
	echo -e "To reconfigure run: aws configure\n"
fi

#echo "Installing required packages"
#python -m pip install boto3 pyyaml 
#pip install -U pip -q 
#pip uninstall -y greenlet -q
#pip install -Iv greenlet==0.4.13 -q

echo "Starting EMR cluster. This operation takes 15-20 minutes..."
python /home/wuda/SpaRC/sparc-on-emr/src/emr_start.py
