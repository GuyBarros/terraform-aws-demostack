# AMI Standalone

This [Packer](https://www.packer.io/docs/index.html) config builds an AMI that can be deployed by Terraform for the student code project.

It contains a running Go web app.

# Usage

## Build

Your AWS credentials must be preloaded into environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).

    packer build ami-standalone.json

The new AMI ID will be emitted to the console.

## Destroy

You must manually delete the image from Amazon S3 and delete the snapshot from the AWS console.

