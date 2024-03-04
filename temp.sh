#!/bin/bash

# resources to remove
lbs=(checkout admin)
stacks=(checkout admin key)

aws-remove-deletion-protection() {
  if [ -z "$1" ]; then
    echo "Usage: aws-remove-deletion-protection <load_balancer_name>"
    return 1
  fi

  aws elbv2 modify-load-balancer-attributes \
                --no-cli-pager \
    --attributes Key=deletion_protection.enabled,Value=false \
    --load-balancer-arn $(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='$1'].LoadBalancerArn" --output text)
}

update-parameter-store() {
  aws ssm put-parameter --name /ec2/ami/engine/ami_id --value $(aws ec2 describe-images --filters Name=architecture,Values=x86_64 --owners self --query "Images[?contains(Name, 'rch-cf-q1-platform-dev')].[CreationDate,ImageId,Name]" --output text | sort -rk1 | awk '{ print $2 }' | head -n1) --overwrite
}

# remove deletion protection
for lb in "${lbs[@]}"; do
  aws-remove-deletion-protection "rch-cf-${lb}"
done

# remove stack
for stack in "${stacks[@]}"; do
  aws cloudformation delete-stack --stack-name "reach-engine-${stack}"
done
