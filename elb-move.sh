#!/bin/bash
########################################################
## ELB (ElasticLoadBalancer) Instance Mover
## - move instances of elb in specific availability-zone,
## - from ELB1 to ELB2
## 
## @auth xeni@thecommerce.co.kr
## @date 2017.JUN.20
## 
echo 'hello ELB instance mover'

#### configuration.
REGION=ap-southeast-1
AZ=ap-southeast-1a
ELB1=deploy-test2
ELB2=deploy-test3


#### script main body.
echo "move instances from $ELB1 to $ELB2"

# shared variables.
instance_ids=()
ELB1_DNSName=''
ELB2_DNSName=''

list_instances(){
	echo "#list instances of $ELB1"
	ELB1_DNSName=$(aws elb describe-load-balancers --region "$REGION" --load-balancer-names "$ELB1" --query LoadBalancerDescriptions[].DNSName --output text) || errexit "DNSName Error"
	echo "> DNSName=$ELB1_DNSName"

	instance_ids_all=$(aws elb describe-load-balancers --region "$REGION" --load-balancer-names "$ELB1" --query LoadBalancerDescriptions[].Instances[].InstanceId --output text) || errexit "Instances Error"
	echo "> instances=$instance_ids_all"

	#instance_ids=()
	for instance_id in $instance_ids_all; do 
		echo ">> instance_id=$instance_id"
		zone=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$instance_id" --query Reservations[].Instances[].Placement.AvailabilityZone --output text) || errexit "Instance AvailabilityZone"
		echo ">> zone=$zone"
		if [ "$zone" == "$AZ" ]
		then
			instance_ids+=("$instance_id")
		fi
	done

	echo "! instances in $AZ = ${instance_ids[*]}"	
	echo ""
}

deregister_instances(){
	echo "#deregister instances from $ELB1"

	for instance_id in ${instance_ids[@]}; do
		echo ">> instance=$instance_id"
		ret=$(aws elb deregister-instances-from-load-balancer --region "$REGION" --load-balancer-name "$ELB1" --instances "$instance_id" --output text) || errexit "deregister instances"
		echo ">>> result=$ret"
	done
}

register_instances(){
        echo "#register instances to $ELB2"

        for instance_id in ${instance_ids[@]}; do
                echo ">> instance=$instance_id"
                ret=$(aws elb register-instances-with-load-balancer --region "$REGION" --load-balancer-name "$ELB2" --instances "$instance_id" --output text) || errexit "register instances"
                echo ">>> result=$ret"
        done
}

# Main Body
list_instances
deregister_instances
register_instances


echo "instance_ids=${instance_ids[*]}"
echo "${instance_ids[*]}" | xargs -I {} -P 10 echo "hi {}"
