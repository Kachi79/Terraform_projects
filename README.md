# Terraform_projects

Automating infrastructure with IAC using Terraform  

In this project we will provision an Aws infrastructure with 1 VPC, 6 subnets hosting 2 websites.

But we will first start with 2 public subnets.

# Create public subnets1
    resource "aws_subnet" "public1" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.0.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-west-1a"

}

# Create public subnet2
    resource "aws_subnet" "public2" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.1.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-west-1b"
}

Above is the configuration for the creation of 2 public subnets.

Hard coded values: Remember our best practice hint, Both the availability_zone and cidr_block arguments are hard coded. We should always endeavour to make our work dynamic.
Multiple Resource Blocks: Notice that we have declared multiple resource blocks for each subnet in the code. This is bad coding practice. We need to create a single resource block that can dynamically create resources without specifying multiple blocks. Imagine if we wanted to create 10 subnets, our code would look very clumsy. So, we need to optimize this by introducing a count argument.
Now let us improve our code by refactoring it. 

First, destroy the current infrastructure. Since we are still in development, this is totally fine. Otherwise, DO NOT DESTROY an infrastructure that has been deployed to production.

Fixing Hard Coded Values: We will introduce variables, and remove hard coding.
Starting with the provider block, declare a variable named region, give it a default value, and update the provider section by referring to the declared variable.
something like this:

  variable "region" {
        default = "eu-central-1"
    }

    provider "aws" {
        region = var.region
    }

    We will do the same to the cidr value in the vpc block, and all the other arguments as follows:

     variable "region" {
        default = "eu-west-1"
    }

    variable "vpc_cidr" {
        default = "172.16.0.0/16"
    }

    variable "enable_dns_support" {
        default = "true"
    }

    variable "enable_dns_hostnames" {
        default ="true" 
    }

    provider "aws" {
    region = var.region
    }

    # Create VPC
    resource "aws_vpc" "main" {
    cidr_block                     = var.vpc_cidr
    enable_dns_support             = var.enable_dns_support 
    enable_dns_hostnames           = var.enable_dns_support
    }

 Fixing multiple resource blocks: This is where things become a little tricky. It’s not complex, we are just going to introduce some interesting concepts. Loops & Data sources
Terraform has a functionality that allows us to pull data which exposes information to us. For example, every region has Availability Zones (AZ). Different regions have from 2 to 4 Availability Zones. With over 20 geographic regions and over 70 AZs served by AWS, it is impossible to keep up with the latest information by hard coding the names of AZs. Hence, we will explore the use of Terraform’s Data Sources to fetch information outside of Terraform. In this case, from AWS

Let us fetch Availability zones from AWS, and replace the hard coded value in the subnet’s availability_zone section as follws:

  # Get list of availability zones
        data "aws_availability_zones" "available" {
        state = "available"
        } 

        The above block is used to declare data sources as the configuration will make use of it later as the code gets larger.

       To make use of this new data resource, we will need to introduce a count argument in the subnet block: Something like this.

         # Create public subnet1
    resource "aws_subnet" "public" { 
        count                   = 2
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "172.16.1.0/24"
        map_public_ip_on_launch = true
        availability_zone       = data.aws_availability_zones.available.names[count.index]

    }

    Let us quickly understand what is going on here.

The count tells us that we need 2 subnets. Therefore, Terraform will invoke a loop to create 2 subnets.
The data resource will return a list object that contains a list of AZs. Internally, Terraform will receive the data like this
  ["eu-central-1a", "eu-central-1b"]

  Each of them is an index, the first one is index 0, while the other is index 1. If the data returned had more than 2 records, then the index numbers would continue to increment.

Therefore, each time Terraform goes into a loop to create a subnet, it must be created in the retrieved AZ from the list. Each loop will need the index number to determine what AZ the subnet will be created. That is why we have data.aws_availability_zones.available.names[count.index] as the value for availability_zone. When the first loop runs, the first index will be 0, therefore the AZ will be eu-central-1a. The pattern will repeat for the second loop.

But we still have a problem. If we run Terraform with this configuration, it may succeed for the first time, but by the time it goes into the second loop, it will fail because we still have cidr_block hard coded and 2 subnets cannot use one cidr block, they must have their own so we have a little more work to do.

Let’s make cidr_block dynamic.

We will introduce a function cidrsubnet() to make this happen. It accepts 3 parameters. Let us use it first by updating the configuration, then we will explore its internals.

    # Create public subnet1
    resource "aws_subnet" "public" { 
        count                   = 2
        vpc_id                  = aws_vpc.main.id
        cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
        map_public_ip_on_launch = true
        availability_zone       = data.aws_availability_zones.available.names[count.index]
    }

we will introduce the cidrsubnet function, this function works like an algorithm to dynamically create a subnet CIDR per AZ. Regardless of the number of subnets created, it takes care of the cidr value per subnet.

Its parameters are cidrsubnet(prefix, newbits, netnum)

The prefix parameter must be given in CIDR notation, same as for VPC.
The newbits parameter is the number of additional bits with which to extend the prefix. For example, if given a prefix ending with /16 and a newbits value of 4, the resulting subnet address will have length /20
The netnum parameter is a whole number that can be represented as a binary integer with no more than newbits binary digits, which will be used to populate the additional bits added to the prefix

You can experiment how this works by entering the terraform console and keep changing the figures to see the output.

On the terminal, run terraform console
type cidrsubnet("172.16.0.0/16", 4, 0)
Hit enter
See the output
Keep change the numbers and see what happens.
To get out of the console, type exit

