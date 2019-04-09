#!/usr/bin/env python2

import boto3 
import time
import sys
import re
import os
import yaml

PATH=os.path.dirname(os.path.abspath(__file__))

c=yaml.load(open(PATH+"/emr_config.yaml"))

command='aws emr create-cluster --applications Name=Hadoop Name=Ganglia Name=Spark Name=Zeppelin --tags \'Project=SpaRC \' \'Name=SpaRC \' --ec2-attributes \'{"KeyName":"'+c['config']['KEY_NAME']+'","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-01a65bbdd29523d1a","EmrManagedSlaveSecurityGroup":"","EmrManagedMasterSecurityGroup":""}\' --service-role EMR_DefaultRole --release-label \''+c['config']['EMR_RELEASE']+'\' --log-uri \''+c['config']['S3_BUCKET']+'\' --name \''+c['config']['EMR_CLUSTER_NAME']+' \' --no-visible-to-all-users --instance-groups \'[{"InstanceCount":1,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":'+c['config']['MASTER_VOL']+',"VolumeType":"gp2"},"VolumesPerInstance":1}]},"InstanceGroupType":"MASTER","InstanceType":"'+c['config']['INSTANCE_TYPE']+'","Name":"Master Instance Group"},{"InstanceCount":'+c['config']['CORE_COUNT']+',"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":'+c['config']['CORE_VOL']+',"VolumeType":"gp2"},"VolumesPerInstance":1}]},"InstanceGroupType":"CORE","InstanceType":"'+c['config']['INSTANCE_TYPE']+'","BidPrice":"'+c['config']['BIG_PRICE']+'","Name":"Core Instance Group"}]\' --configurations \'[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"},"Configurations":[]}]\' --scale-down-behavior TERMINATE_AT_TASK_COMPLETION --region us-east-1  --bootstrap-actions \'Name="SpaRC-bootstrap",Path='+c['config']['BOOTSTRAP']+',Args=['+c['config']['BOOTSTRAP_ARGS']+']\''


print("\nYour AWS CLI export command:\n")
print(command)

cluster_id_json=os.popen(command).read()
#print(cluster_id_json)

cluster_id=cluster_id_json.split(": \"",1)[1].split("\"\n")[0]
print('\nClusterId: '+cluster_id+'\n')

# Gives EMR cluster information
client_EMR = boto3.client('emr')
#print(client_EMR)

# Cluster state update
status_EMR='STARTING'
time.sleep(5)
# Wait until the cluster is created 
while (status_EMR!='EMPTY'):
	print('Creating EMR...')
	details_EMR=client_EMR.describe_cluster(ClusterId=cluster_id)
	status_EMR=details_EMR.get('Cluster').get('Status').get('State')
	print('Cluster status: '+status_EMR)
	time.sleep(5)
	if (status_EMR=='WAITING'):
		print('Cluster successfully created! Starting HAIL installation...')
		break
	if (status_EMR=='TERMINATED_WITH_ERRORS'):
		sys.exit("Cluster un-successfully created. Ending installation...")

# Get public DNS from master node
master_dns=details_EMR.get('Cluster').get('MasterPublicDnsName')
master_IP=re.sub("-",".",master_dns.split(".compute")[0].split("ec2-")[1])

print('\nMaster DNS: '+ master_dns)
print('Master IP: '+ master_IP)

# Copy the key into the master
command='scp -o \'StrictHostKeyChecking no\' -i '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem hadoop@'+master_dns+':/home/hadoop/.ssh/id_rsa'
os.system(command)
print('Copying keys...')

# Copy the files needed into the master
#command='scp -o \'StrictHostKeyChecking no\' -i '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem '+c['config']['SPARC_JAR']+'  hadoop@'+master_dns+':/home/hadoop'
#os.system(command)
#print('Copying files...')

# log in the emr
command= 'ssh -i '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem -L 8888:localhost:8888 hadoop@'+master_dns 
os.system(command)



