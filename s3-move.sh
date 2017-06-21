#!/bin/bash
########################################################
## S3 File Mover
## - make bakcup file with timestamp.
## - upload & overwrite file into s3.
##
## @auth xeni@thecommerce.co.kr
## @date 2017.JUN.20
##
echo 'hello S3 File uploader'

#### configuration.
BUCKET=ecm-prd1-dep-test
WAR=hello-world.war


#### script main body.
echo "upload $WAR into $BUCKET"

timestamp(){
	date +"%Y%m%d-%H%M%S"
}

backup_war(){
	echo "#backup old war image"
	TS=$(timestamp)
	echo "> timestamp=$TS"
	new_file=${WAR/.war/".$TS.war"}
	echo "> new_file=$new_file"
	result=$(aws s3 cp "s3://$BUCKET/$WAR" "s3://$BUCKET/$new_file" --output text) || errexit "s3 cp error"
	echo $result
}

upload_war(){
	echo "#upload local war image to s3"
	result=$(aws s3 cp "$WAR" "s3://$BUCKET/$WAR" --output text) || errexit "s3 upload error"
	echo $result
}

### main
backup_war
upload_war	
