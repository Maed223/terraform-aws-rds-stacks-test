provider "aws" {
  region = "us-east-2"
} //The main difference between no-code modules and ordinary modules is that the no-code workflow requires declaring provider configuration within the module itself. Authors of standard modules usually avoid including the provider configuration within the module because it makes the module incompatible with the for_each, count, and depends_on meta-arguments. Since users will not reference no-code modules in written configuration, there is no risk of this conflict.

provider "random" {}

data "aws_availability_zones" "available" {}

resource "random_pet" "random" {}

//This module definition uses the public vpc module to create networking resources, then deploys an RDS instance, subnet group, and security group within that designated VPC.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "${random_pet.random.id}-education"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "education" {
  name       = "${random_pet.random.id}-education"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "${random_pet.random.id} Education"
  }
}

resource "aws_security_group" "rds" {
  name   = "${random_pet.random.id}-education_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["192.80.0.0/16"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${random_pet.random.id}-education_rds"
  }
}

resource "aws_db_parameter_group" "education" {
  name   = "${random_pet.random.id}-education"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "education" {
  identifier             = "${var.db_name}-${random_pet.random.id}"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.education.name
  publicly_accessible    = true
  skip_final_snapshot    = true
   storage_encrypted      = var.db_encrypted
}
//https://developer.hashicorp.com/terraform/tutorials/modules/no-code-provisioning

//When users provision infrastructure with a no-code module, Terraform Cloud will automatically launch a new workspace to manage the module's resources. 
//Because no-code modules contain their provider configuration, organization administrators must also enable automatic access to provider credentials
// MODULE AUTHOR WORKFLOW:
//git tag 1.0.0
//git push --tags
//Go to your organization's Terraform Cloud registry, click Publish, then select Module.
//Select your version control provider
//select your terraform-aws-rds repository.
//On the Add Module screen, check "Add Module to no-code provision allowlist". Click Publish module
//Select Configure Settings , which takes you to the No-code provisioning settings page.
# Click Edit versions and variable options.
# Select 1.0.0 (latest) from the Select module version dropdown. 
#Click Add dropdown options for the db_username variable. 
#Enter education in the text box.
#click Save.
# Navigate to your organization's Projects & workspaces. Click New in the top right corner and select Project in the dropdown menu.
# Enter "No-Code" as the project name, then click Create.
# Navigate to the Variable Sets page for your organization and create a new variable set.
# Enter "No Code Credentials" for the name.
# Scroll down to the Variable set scope section and select Apply to specific projects and workspaces. Select the "No-Code" project from the Apply to projects dropdown.
# Find the AWS credentials you want to use for the workspaces in this project. Set the credentials as variables using +Add Variable.

# MODULE CONSUMER WORKFLOW:
# Navigate to the Registry for your organization and select the terraform-aws-rds module
# Click the Provision workspace button on the module's details page to launch the workflow. 
# Set the variables:
# db_name	nocode
# db_password	terraformeducation
# db_username	education
# Click Next: Workspace settings.
# On workspace settings, set the workspace name to learn-terraform-no-code-provisioning.
# Select the "No-Code" project from the Project dropdown.
# In the Apply methods section, leave the method as Auto-apply
# When you create the workspace, Terraform Cloud launches a new run.

# Because you cannot interact with the Terraform configuration for the workspace, you can only change the infrastructure by editing the variable values or by updating to a different version of the module.

#MODULE AUTHOR WORKFLOW:
# When you update a no-code module, Terraform Cloud notifies every workspace that uses the module that a newer version is available.
#Add a new variable to no code module and push a new tag
# TFC will continue to use version 1.0.0 of the module until you configure it to use the new version: Go to your organization's Terraform Cloud registry, click your terraform-aws-rds module, and click Configure Settings.
# Click Edit version and variable options. Under Module version, select 1.0.1 (latest) and click Save.

#MODULE CONSUMER WORKFLOW:
# Next, navigate to your learn-terraform-no-code-provisioning workspace. You will see a notification that a no-code module version update is available.
# You already set the db_name, db_password, and db_username variables values previous run, but you must provide a value for the new db_encrypted variable. Choose true from the dropdown and click Save configuration & start plan.
# Navigate to your Workspace Settings, then to Destruction and Deletion. Select Queue destroy plan to delete your resources. 
# Optionally delete the workspace, No-Code project, No-Code Credentials variable set, and the module from your Terraform Cloud organization