## Install Dependencies on the Ansible Controller

Run the following commands on the Ansible controller:

```bash
ansible-galaxy collection install amazon.aws
pip install boto3 botocore


# Terraform + Ansible Dynamic Inventory

This project demonstrates how to provision AWS infrastructure using OpenTofu/Terraform and configure EC2 instances using Ansible Dynamic Inventory.

## Architecture

The project uses:

- AWS EC2
- OpenTofu / Terraform
- Ansible
- AWS Dynamic Inventory
- Nginx

## Project Structure

```text
terraform-ansible-dynamic-inventory/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── aws_ec2.yml
├── ansible.cfg
├── playbook.yml
└── README.md






                 AWS
                  │
           EC2 Instances
                  │
       ┌──────────┴──────────┐
       │                     │
    VM1                     VM2
 Role=webserver          Role=webserver
       │                     │
       └──────────┬──────────┘
                  ↓
          aws_ec2.yml
        Dynamic Inventory
                  ↓
          tag_webserver
                  ↓
        install-nginx.yml
                  ↓
       ┌──────────┴──────────┐
       ↓                     ↓
   Install Nginx          Install Nginx
   Start Nginx            Start Nginx
   index.html             index.html


# terraform-ansible-dynamic-inventory

Part 2: Ansible dynamic inventory setup
Step 1: Install required Python packages and Ansible collection
bash
pip install boto3 botocore --break-system-packages
ansible-galaxy collection install amazon.aws

| Configuration                     | Meaning                                                |
| --------------------------------- | ------------------------------------------------------ |
| `plugin: amazon.aws.aws_ec2`      | Uses AWS EC2 dynamic inventory plugin                  |
| `regions`                         | Search EC2 instances in `us-east-1`                    |
| `tag:Role: webserver`             | Select only instances having `Role=webserver`          |
| `instance-state-name: running`    | Select only running instances                          |
| `keyed_groups`                    | Automatically creates Ansible groups based on EC2 tags |
| `prefix: tag`                     | Adds `tag_` to the generated group name                |
| `hostnames: ip-address`           | Uses the instance IP as inventory hostname             |
| `ansible_host: public_ip_address` | Tells Ansible to SSH using the EC2 public IP           |

So suppose AWS has:

EC2-1
Role = webserver
State = running
Public IP = 54.10.20.30

EC2-2
Role = webserver
State = running
Public IP = 54.10.20.40

EC2-3
Role = database
State = running
Public IP = 54.10.20.50

The inventory plugin will discover:

EC2-1 ✅
EC2-2 ✅
EC2-3 ❌

keyed_groups:
  - key: tags.Role
    prefix: tag
````


    Ansible creates a group:

    Verify Dynamic Inventory

List the discovered EC2 instances:

   ```bash
ansible-inventory -i aws_ec2.yml --graph
```

tag_webserver

containing EC2-1 and EC2-2.
