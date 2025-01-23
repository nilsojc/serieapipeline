<p align="center">
  <img src="assets/diagram.png" 
</p>
  
## ☁️ 30 Days DevOps Challenge - Building a Containerized API Management System for Querying Sports Data.   ☁️

This is part of the fourth project in the 30-day DevOps challenge! 

In this project, I built


<h2>Environments and Technologies Used</h2>

  - Python
  - Amazon Elastic Container Service
  - Docker
  - API Gateway
  - SerpAPI
  - Github Codespaces for Environment
  - Flask
  - IAM: Least privilege policies for ECS task execution and API Gateway.
  - Cloudwatch



  
<h2>Features</h2>  

- 🐳 ***Containerized Scalability:***
Deploy stateless API services using AWS ECS Fargate for auto-scaling containers, reducing infrastructure overhead and costs.
- 🌐 ***RESTful API Gateway:***
Expose sports data via Amazon API Gateway with custom endpoints (e.g., /fixtures, /stats) for easy integration with frontend apps or third-party tools.
- ***⚡ Real-Time Data Fetching:***
Integrate with an external Sports API to deliver live scores, player stats, and match events with low-latency caching strategies.




<h2>Step by Step Instructions</h2>

***2. Set up IAM Roles***

In this step, we will assign and assume an IAM for ECS, API gateway and Cloudwatch permissions, as well as generate short-term credentials for it.

We will start by creating a Trust Policy

1. Create a Trust Policy
Create a trust policy file (trust-policy.json) to allow ECS tasks and your account to assume the role:

```
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' > trust-policy.json
```

We will then create the role:

```
aws iam create-role \
  --role-name SportsDataAPIRole \
  --assume-role-policy-document file://trust-policy.json
```  

Instead of attaching managed policies, we’ll create custom policies with only the required permissions.

```
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}' > ecs-task-policy.json
```
```
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:DELETE"
      ],
      "Resource": "arn:aws:apigateway:*::/*"
    }
  ]
}' > api-gateway-policy.json
```

```
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    }
  ]
}' > cloudwatch-policy.json
```

We will then attach the policy to the role:

```
aws iam put-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name ECSTaskExecutionPolicy \
  --policy-document file://ecs-task-policy.json
```

```
aws iam put-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name APIGatewayManagementPolicy \
  --policy-document file://api-gateway-policy.json
  ```

```
aws iam put-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name CloudWatchMonitoringPolicy \
  --policy-document file://cloudwatch-policy.json
```

We can now generate Short-Term Credentials for use to our project with this command:

```
aws sts assume-role \
  --role-arn arn:aws:iam::137068224350:role/SportsDataAPIRole \
  --role-session-name SportsDataAPISession
```
This will return temporary AccessKeyId, SecretAccessKey, and SessionToken (valid for 1 hour by default).

We will then use the keys and export them to our environment:

```
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_SESSION_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

You can test the roles permissions by running commands like 

```
aws ecs list-tasks --cluster your-cluster-name
aws apigateway get-rest-apis
aws logs describe-log-groups
```


```

```


***1. Repo and API configuration***

We will begin by setting up the environment and code that we will be utilizing. In this instance, we will use `Github Codespaces` to create a new workspace and do the commands from there. We will be setting up an account with RapidAPI for our Serie A Sports data.

You can set environemnt variables within the settings of Codespaces. 

The AWS credentials have the variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_DEFAULT_REGION` Respectively.


Finally, we will make sure our dependencies are installed properly.

```
pip install flask
pip install python-dotenv
pip install requests
pip install google-search-results
```

We will proceed with installing the Docker CLI and Docker Desktop

```# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

***Option 2: Local AWS CLI Setup***

NOTE: Keep in mind this is for a Linux environment, check the AWS documentation to install it in your supported OS.

   ```
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
We then do `AWS configure` and enter our access and secret key along with the region. Output format set to JSON. With this command we will double check that our credentials are put in place for CLI:

```
aws sts get-caller-identity
```

***3. Creating the ECS Cluster***

We will begin by creating the ECS cluster necessary to run our containers, we will name it 'sports-api-cluster'.

```
aws ecs create-cluster \ 
--cluster-name sports-api-cluster \
--capacity-providers FARGATE \
--default-capacity-provider-strategy capacityProvider=FARGATE,weight=1,base=1
```

***4. Creating a Task Definition***

aws ecs register-task-definition \
  --family sports-api-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --container-definitions '[
    {
      "name": "sports-api-container",
      "image": "137068224350.dkr.ecr.us-east-1.amazonaws.com/sports-api:sports-api-latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "environment": [
        {
          "name": "SPORTS_API_KEY",
          "value": ""
        }
      ]
    }
  ]'

NOTE: in your local env we will define the value of SPORTS_API_KEY with the key and the AWS_ACCOUNT_ID with the account number of your AWS account.

To confirm our task definition. was done successfully we will check with this command:

```
aws ecs describe-task-definition --task-definition sports-api-task
```

***5. Run the Service with an Application Load Balancer***

In this step we will be running our ecs cluster with an application load balancer (ALB) to evenly distribute the traffic across our application.

We first begin with creating a Security Group (SG) along with traffic rules.

```
aws ec2 create-security-group \
  --group-name sports-api-sg \
  --description "Security group for sports-api-service" \
  --vpc-id <YOUR_VPC_ID>

  aws ec2 authorize-security-group-ingress \
  --group-name sports-api-sg \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
  ```
 Replace <YOUR_VPC_ID> with the VPC ID of the ECS Cluster created.

  We will then create our ALB:

  ```
  aws elbv2 create-load-balancer \
  --name sports-api-alb \
  --subnets <SUBNET_ID_1> <SUBNET_ID_2> \
  --security-groups <SECURITY_GROUP_ID> \
  --scheme internet-facing \
  --type application
```

Replace <SUBNET_ID_1>, <SUBNET_ID_2>, and <SECURITY_GROUP_ID> with your subnet IDs and the security group ID created earlier.

3. Create a Target Group
Create a target group for the ALB:

bash
Copy
aws elbv2 create-target-group \
  --name sports-api-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id <YOUR_VPC_ID> \
  --health-check-path "/sports"
Replace <YOUR_VPC_ID> with your VPC ID.

4. Create an ECS Service
Now, create the ECS service with the ALB:

bash
Copy
aws ecs create-service \
  --cluster <YOUR_CLUSTER_NAME> \
  --service-name sports-api-service \
  --task-definition sports-api-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<SUBNET_ID_1>,<SUBNET_ID_2>],securityGroups=[<SECURITY_GROUP_ID>],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=<TARGET_GROUP_ARN>,containerName=sports-api-container,containerPort=8080"
Replace:

<YOUR_CLUSTER_NAME> with your ECS cluster name.

<SUBNET_ID_1> and <SUBNET_ID_2> with your subnet IDs.

<SECURITY_GROUP_ID> with the security group ID created earlier.

<TARGET_GROUP_ARN> with the ARN of the target group created in step 3.

Finally, we will verify the service is running:

```
aws ecs describe-services \
  --cluster <YOUR_CLUSTER_NAME> \
  --services sports-api-service
```
 
***4. Set up our Python file and test***

In this step, we will be setting up our Python file. With this code

![image](/assets/image2.png)


***6.  Running the Script - Final Result.***




***7. Cleanup***

6. Cleanup (Optional)

We will be deleting the role and policies for clean up.

```
aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name ECSTaskExecutionPolicy

aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name APIGatewayManagementPolicy

aws iam delete-role-policy \
  --role-name SportsDataAPIRole \
  --policy-name CloudWatchMonitoringPolicy

aws iam delete-role \
  --role-name SportsDataAPIRole
```

<h2>Conclusion</h2>

In this project, I learned how you can leverage a Python script to grab API data, send a query to a database and parse it accordingly with Amazon Athena and Glue. I also explored it further by accessing the data generated from the api and using it to generate data visualizers that can display a table or a graph.
