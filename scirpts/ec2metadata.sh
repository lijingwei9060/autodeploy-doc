#!/bin/bash

#check some basic configurations before running the code
function chk_config()
{
        #check if run inside an ec2-instance
        x=$(curl -s http://169.254.169.254/)
        if [ $? -gt 0 ]; then
                echo '[ERROR] Command not valid outside EC2 instance. Please run this command within a running EC2 instance.'
                exit 1
        fi
}

#export standard metric
function export_normal_metric() {
        metric_path=$2
        RESPONSE=$(curl -fs http://169.254.169.254/latest/${metric_path}/)
        export $1=$RESPONSE
}



function export_all()
{
        export_normal_metric AMIID meta-data/ami-id
        export_normal_metric AMILAUNCHINDEX meta-data/ami-launch-index
        export_normal_metric INSTANCEID meta-data/instance-id
        export_normal_metric INSTANCETYPE meta-data/instance-type
        export_normal_metric LOCALHOSTNAME meta-data/local-hostname
        export_normal_metric LOCALIPV4 meta-data/local-ipv4
        export_normal_metric PUBLICHOSTNAME meta-data/public-hostname
        export_normal_metric PUBLICIPV4 meta-data/public-ipv4
        export_normal_metric SECURITYGROUP meta-data/security-groups
}

#check if run inside an EC2 instance
chk_config
export_all