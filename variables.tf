# Project Name - will prefex all generated AWS resource names 
variable "project_name" {
  default = "CP-TGW"
}


######################################
######## Account Settings ############
######################################

provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  /*
      Shared credential files is a text file with the following format:
        [<PROFILE>]
        aws_access_key_id = <ACCESS_KEY_ID>
        aws_secret_access_key = <SECRETE_ACCESS_KEY
  */
  profile = "default"
  region  = "${var.region}"
}
variable "region" {
  default = "us-east-1"
}


data "aws_availability_zones" "azs" {}


#########################################
############# Topology ##################
#########################################

# Managemnt VPC
variable "management_cidr_vpc" {
  description = "Management VPC"
  default     = "10.10.0.0/16"
}

# Inbound VPC
variable "inbound_cidr_vpc" {
  description = "Inbound VPC"
  default     = "10.20.0.0/16"
}

# Outbound VPC
variable "outbound_cidr_vpc" {
  description = "Outbound VPC"
  default     = "10.30.0.0/16"
}

# VPC hosting out private facing website
variable "spoke_1_cidr_vpc" {
  description = "VPC hosting a private facing website"
  default     = "10.110.0.0/16"
}

# VPC hosting a test endpoint
variable "spoke_2_cidr_vpc" {
  default = "10.120.0.0/16"
}

variable "spoke_1_high_port" {
  description = "Choose the (random-unique) high port that will be used to access the web server in Spoke-1"
  default = "9080"
}


###########################################
############# Server Settings #############
###########################################
# Hashed password for the Check Point servers - you can generate this with the command 'openssl passwd -1 <PASSWORD>'
# You can instead SSH into the server and run (from clish): 'set user admin password', followed by 'save config'
variable "password_hash" {
  description = "Password for the Check Point servers"
  default     = "$1$9d67a7b9$/pSopv.HlQXa7J5R213BB1"
}

# Private key
variable "key_name" {
  default = "shared"
}

# SIC key
variable "sic_key" {
  default = "vpn12345"
}

variable "version" {
  default = "R80.30"
}

variable "management_server_size" {
  default = "m5.xlarge"
}

variable "outbound_asg_server_size" {
  default = "c5.large"
}

variable "inbound_asg_server_size" {
  default = "c5.large"
}


####################################
######### Check Point Names ########
####################################
variable "management_server_name" {
  description = "The name of the mangement server in the cloudformation template"
  default     = "CP-TGW-Management"
}

variable "outbound_configuration_template_name" {
  description = "The name of the outbound template name in the cloudformation template"
  default     = "tgw-outbound-template"
}

variable "inbound_configuration_template_name" {
  description = "The name of the inbound template name in the cloudformation template"
  default     = "tgw-inbound-template"
}
variable "vpn_community_name" {
  description = "The name of the VPN Community used by the TGW ASG"
  default     = "tgw-community"  
}
