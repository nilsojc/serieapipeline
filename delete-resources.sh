#!/bin/bash

# Deleting Role Policies
aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name ECSTaskExecutionPolicy

aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name APIGatewayManagementPolicy

aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name CloudWatchMonitoringPolicy

# Deleting Role Created
aws iam delete-role \
  --role-name SportsDataAPIRole

# Deleting Load Balancers, Target Groups, ECS Cluster, ECR Repository with Docker Image and Security Group.

aws elbv2 delete-load-balancer --load-balancer-arn sports-api-alb-production-675789625.us-east-1.elb.amazonaws.com
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:us-east-1:137068224350:targetgroup/sports-api-target-group-prod/9d7b089432892ecc
aws ecs delete-cluster --cluster sports-api-cluster
aws ecr delete-repository --repository-name sports-api --force
aws ec2 delete-security-group --group-id sg-0524853978308bf6a