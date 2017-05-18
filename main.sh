#!/bin/bash
. ./functions
. ../config.cfg

checkAuth

case $1 in
add)
	echo "Creating Amazon environment for user $username"

#########################
# Create IAM & get keys #
#########################

addIAMUser $username
#echo "AccessKeyId: ${ACCESSKEYS[0]}"
#echo "SecretAccessKey: ${ACCESSKEYS[1]}"


####################
# Create S3 bucket #
####################

createS3Bucket $username $s3bucetName


###################
# Create IPA user #
###################

createIPAUser $username $firstName $lastName $emailAddress "$pubKey"

#############################
# Create EFS Home directory #
#############################

createEFSHomedir $username $efsUrl

#####################################
# Generate keys for synchronization #
#####################################

generateSshKeys $username $pubKey


#############################
# Generate AMI init scripts #
#############################

generateUserDataFile $username "${ACCESSKEYS[0]}" "${ACCESSKEYS[1]}" $userDataFile $efsUrl $s3bucetName


####################
# Run AMI Instance #
####################

runInstance $username $userDataFile $amiImgId $instanceType "$secGroups" $vpcSubnetId $iamKeyName


################
# Configure HS #
################

addUserToHS $username $hesServerIpAddress $efsUrlProxy


###########################
# Create credentials file #
###########################

createCredentialsFile $username "${ACCESSKEYS[0]}" "${ACCESSKEYS[1]}" $amiIpAddress $hesServerIpAddress $credFileName



############################
# Encrypt credentials file #
############################

encryptCredentialsFile "$pubKey" $credFileName $encCredFileName



;;


del)
	echo "Deleteing Amazon environment for user $username"

############
# Clean HS #
############

delUserFromHS $username $hesServerIpAddress


###################################
# Delete IAM user and Access Kyes #
###################################

delIAMUser $username


####################
# Delete S3 Bucket #
####################

deleteS3Bucket $username $s3bucetName


###################
# Delete IPA user #
###################

deleteIPAUser $username


#############################
# Delete EFS Home directory #
#############################

deleteEFSHomedir $username $efsUrl


##########################
# Remove AMI init script #
##########################

rm -rf ./$userDataFile


#######################
# Remove AMI Instance #
#######################

terminateInstance $username


###########################
# Remove credentials file #
###########################

rm -rf ./$credFileName


#####################################
# Remove encrypted credentials file #
#####################################

rm -rf ./$encCredFileName

;;



*)
	echo "Please, choose action (add or del) \$username."
	exit 1

esac
	
