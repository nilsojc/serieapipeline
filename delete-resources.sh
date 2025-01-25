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

aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:137068224350:loadbalancer/app/sports-api-alb-production/acba8d2162f458c5
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:us-east-1:137068224350:targetgroup/sports-api-target-group-prod/9d7b089432892ecc
aws ecs delete-service \
  --cluster sports-api-cluster \
  --service sports-api-service-production \
  --force \
  --region us-east-1
aws ecs deregister-task-definition \
  --task-definition "arn:aws:ecs:us-east-1:137068224350:task-definition/sports-api-task2:1" \
  --region us-east-1    
aws ecs delete-task-definitions \
  --task-definitions "arn:aws:ecs:us-east-1:137068224350:task-definition/sports-api-task2:1" \
  --region us-east-1
aws ecs delete-cluster --cluster sports-api-cluster
aws ecr delete-repository --repository-name sports-api --force
aws ec2 delete-security-group --group-id sg-0524853978308bf6a

# Replace the ARN and ID's with the ones generated in your project.