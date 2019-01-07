# Note: To initiate terraform remote state please modify the line  "address = "localhost:8500"" in the  configuration files backend  section  to your desired consul address.   

# TerraformUseCase1

Step 1 : clone the repo. 

Step 2: Download the TerraformTest.pem file form the AWS Cloud Platform under london region. 

Step 3: Move the .pem file to the root directory of the project 

Step 4: Apply "Terraform init". 

Step 5: Apply "terraform plan", the system will ask for the following inputs 
		- > AMI = ami-4bc7cd2f
		- > Instance Type = t2.micro

Step 6: If you are happy with the plan run  "terraform apply". This will create your desired  insfrastructure in AWS,

Step 7: Once everything is successfully created, open the "loadBalancerAddress.txt" file to see the DNS of the load balancer.
 
