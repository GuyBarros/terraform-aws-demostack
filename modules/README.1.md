# HashiCorp Training Tools & Curriculum

This repository contains the necessary scripts and files for building
customizable workstations that have the HashiCorp tools setup. These are
primarily used for trainings and sales demos, but you are free to use them as
you see fit.

### Download

The preferred way to download and use the contents of this repository is via tagged [releases](https://github.com/hashicorp/training/releases).

We will cut an RC or a full version when we're happy with the content or near to an impending release of related HashiCorp software. 

Releases also include changenotes so you can see if your course is affected.

### Contents

This repository includes multiple resources, including:

- `presentations` - Slide decks and curriculum for courses.
- `terraform` - Configuration scripts for building the student lab environment.
- `manager` - A Rails web app for sending notifications to students and printing completion certificates. Deployed on Heroku.

Elsewhere:

- Demo code for individual classes, such as [Terraform Beginner](https://github.com/hashicorp/demo-terraform-beginner)

## Presentations (`presentations`)

Slides for each course. Folders contain:

- `Makefile` -- Running `make` will export PDF and PPTX for each presentation, unless AppleScript decides to bail. If you get an error, try opening the Keynote file first, then run `make` again.
- `description.md` -- Course description for use on conference sites or when selling the course.
- Multiple Keynote files -- When available, you'll see one file per section of the course. Otherwise, there will be a single file for the entire course.

## Lab Environment (`terraform`)

The `terraform` directory contains configuration files for building the lab instances on AWS. Each student receives a machine that is preloaded with source code and running daemons of Vault, Consul, etc.

### Requirements

You will need the following:

- An IAM user and access keys with permission to create instances, IAM users, and IAM policies
- A paid or whitelisted [Atlas account](https://atlas.hashicorp.com/)

### Bootstrapping

**All commands should be run from inside the `terraform` folder!**

Prior to the start of the class, bootstrap the lab environment. You will need to
know the total number of workstations to bootstrap and some other key
information. Create a `terraform.tfvars` file and fill all of the required
values from `variables.tf`. Here is an example:

```hcl
workstations      = "10"
namespace         = "customer-training"
public_key        = "ssh-rsa AAAAC3NzaC1lZDI1NTE5AAA...."
owner             = "geoffrey"
```

AWS credentials should be provided with ENV vars such as:

```bash
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
```

It is **highly** suggested that you specify a unique `training_username` and `training_password` that students will use to login to their workstations (all students share the same name and password). Leaving these at the default is a security risk.

```hcl
training_username = "butter-sprocket-9823"
training_password = "908&*-otesanthoeu-28loteg"
```

**NOTE: `public_key` is the contents of your public key file, not a path. This is for better compatibility with Terraform Enterprise.**

`owner` is the IAM username of the account who manages the lab. This can be used by Mozilla's Reaper tool to shut down instances overnight or shut down expired ones (documentation needed...read the [Reaper repo](https://github.com/mozilla-services/reaper) for now).

In general, you want to over-provision the number of workstations. This way if
extra students join, or if there's an issue with one of the workstations, you
can just pull another one from the pool.

There are other configuration options, but they have sane default values. If you
get conflicts when provisioning, you may need to choose a different
`cidr_block`. For most installations, this is unnecessary, but if you have
multiple training sessions running simultaneously in the same AWS environment,
you may need to tweak these values.

After you have filled out the information, run:

```shell
$ terraform init
```

This will download the required providers. Then run:

```shell
$ terraform plan
```

This will show you the output. The number of resources will be fairly large.
Next run:

```shell
$ terraform apply
```

This process can take some time depending on the size of the cluster. The output
will contain a list of IP addresses to distribute to students.

## Web App (`manager`)

Currently running at [training.hashicorp.com/manager](https://training.hashicorp.com/manager). Contact HashiCorp staff via your preferred method for access.

This application can be used by instructors to send notifications to students in advance of the class. It also generates a PDF of course completion certificates that can be printed on heavy card stock and given to students.

The application is written in Rails and is currently deployed on Heroku. HashiCorp staff can find Heroku credentials in the 1Password vault for "Training." The app can be deployed with the `bin/deploy` script in this repo.

For deployment, authenticate with `team-training@hashicorp.com` and the Heroku API key.

User accounts for the web app must be created in the Rails console on Heroku. See the `README` in the `manager` directory for more details.

### Build Class

Create the class online at:

https://training.hashicorp.com/manager

If you need access, please contact training@hashicorp.com. Enter each student's
name, email, and IP address on the training manager.

**The name of the class will also be the name that appears on the training
certificates**, so please choose the name carefully. Be sure to choose a correct
start and end time, and enter the facility address.

After all the information is complete, send the appropriate registration email
to the attendees.

### Accessing Instances

The default login credentials for all training instances are `training:training`. A web-based shell is installed at `/wetty`, for example: 

      http://54.245.19.202/wetty/

Or, connect over standard SSH:

```shell
$ ssh training@54.23.144.5
Password: training
```

The training user has full sudo/root permissions on the system. This may change
in the future, but for now we give the students full control.

If the training login is not succeeding, it likely means the provisioner failed
or has not yet finished. Please wait 5 minutes and try again. If the problem
persists, try logging in with the `ubuntu` user; this login requires
public/private key authentication.

```shell
$ ssh ubuntu@54.23.144.5
```

To begin debugging, check the cloud-init output:

```shell
$ sudo tail -f /var/log/cloud-init-output.log
```

Logs for individual components reside in `/var/log/upstart/<SERVICE>.log`. For example, you could find the Vault logs by running:

```shell
$ sudo tail -f /var/log/upstart/vault.log
```

### Destroying

To save on costs, we recommend only keeping instances alive for 24 hours after
the end of the course. After you are done, run:

```shell
$ terraform destroy
```

This will delete all the instances, IAM credentials, and supporting
infrastructure.

If this operation times out, the most likely situation is that a student in
Terraform training did not destroy his/her instance. As a result, you may need
to manually login to the AWS console and delete any active instances, then run
the destroy command again.
