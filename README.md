## SpaRC on Amazon EMR: `cloudformation` tool 

This `cloudformation` tool creates an EMR cluster with `JupyterNotebook` installed. 

## Before using this tool (Prerequisites)

This tool requires the following programs to be installed (if any of them is missing, they will be installed for you
!): 

* Python3 and pip (via Homebrew), including the necessary libraries
* Amazon's `Command Line Interface (CLI)` utility
* If there is no AWS account configured it will start the configuration for you. For additional help visit: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html 

## How to use this tool

This tool is executed from the terminal using Amazon's `CLI` utility. Before getting started, make sure you have: 

a) **A valid EC2 key pair**. For additional details on how to create and use your key, visit: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

b) **A configured `CLI` account**. If your `CLI` account has been previously configured, the tool will use it. If you want to re-configure a to use under a specific account or a different user, at the terminal type `aws configure`

## EMR `cloudformation`

Open your terminal and clone this repository: `git clone https://github.com/hms-dbmi/hail-on-EMR`. 
 
1. `cd` into the `SpaRC-on-EMR/src` folder and with the text editor of your preference open the configuration file: `SpaRC_on_EMR.yaml`. This file will be used to provide information necessary to create the cluster. Fill in the fields as necessary using your personal key and security groups (SG) information and save your changes. See configuration details below:

```yaml
config:
  EMR_CLUSTER_NAME: "SpaRC-TEST" # Give a name to the EMR cluster
  EMR_RELEASE: "emr-5.17.0" # The EMR release
  KEY_NAME: "my-key" # Input your key name DO NOT include the .pem extension
  PATH_TO_KEY: "/full-path/to-key/" # Full path to .pem file
  INSTANCE_TYPE: "r5.xlarge" # Select the instance type, see table below.
  CORE_COUNT: "3" # Number of cores. Additional reference in the EC2 FAQs website 
  SUBNET_ID: "subnet-12345" # Select you private subnet. See the EC2 FAQs website
  SLAVE_SECURITY_GROUP: "" # Creates a new group by default.
  MASTER_SECURITY_GROUP: "" # Creates a new group by default.
  EC2_NAME_TAG: "my-hail-EMR" # Tags for the individual EC2 instances
  PROJECT_TAG: "my-project" # Project tag
  S3_BUCKET: "s3n://my-s3-bucket/" # Input your project's S3 bucket
  BIG_PRICE: "0.2" # You can set the big price for the code 
  MASTER_VOL: "32" # You can set the SizeInGB for the master
  CORE_VOL: "32" # You can set the SizeInGB for the code
  BOOTSTRAP: "s3://boostrap-sparc.sh" # The bootstrap script you want to choose
  PATH_TO_SPARC: "/SpaRC-on-EMR/src/" # Full path to SpaRC-LocalCluster-assembly.jar file
  SPARC_JAR: "LocalCluster-assembly.jar" # The SpaRC-LocalCluster-assembly.jar
```
For additional configuration details regarding the **emr** release, visit: <https://console.aws.amazon.com/elasticmapreduce/home?region=us-east-1#quick-create\:>. 

|Suggested **`INSTANCE_TYPE`s** |
|:-------------------------:| 
| c4.2xlarge | 
| c4.4xlarge | 
| c4.8xlarge | 
| r4.2xlarge | 
| r4.4xlarge | 
| r4.8xlarge |
| r5.2xlarge |
| r5.4xlarge |
| r5.8xlarge |

See additional instance details at: https://aws.amazon.com/ec2/instance-types/

2. Execute the command: `sh sparc_cloudformation_emr.sh`. The EMR creation takes between 5-7 minutes. The installation log file is located at `tail -f /tmp/cloudcreation_log.out`; the logs are available, under the same path, at both the local installation computer and at the master node of your EMR
3. You can check the status of the EMR creation at: https://console.aws.amazon.com/elasticmapreduce/home?region=us-east-1. The EMR is successfully created once it gets the status `Waiting`. After created, you can do your analysis.



