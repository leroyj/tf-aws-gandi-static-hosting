# Terraform static s3 hosting using a custom domain name managed outside aws (gandi)

## Why this project?

For a side project, I was expecting to host a static website.
I then realized that it wasn't that easy to get it cost effectively.
I couldn't found an easy way to tick all the following features:

* **Hosted**: I don't want to self-host it at home.
* **low cost**: I want it to be cost effective - it's a personal project after all
* **static files**: I don't want to fire up a server instance for a couple of pages
* **https support**: wake up we're in 2022!
* **custom domain**: I owned a domain at gandi.net and I don't want to change
* **no repo access**: don't ask me why but I'm reluctant to share my repo access
(bye cloudflare)

Then I wrote the following Terraform file to host on AWS using my gandi.net domain.
The tricky part here is that as s3 hosting http only, you need to setup Cloudfront
which can be quite painful:

1. I need to declare the subdomain zone in Route53
2. I get the NS from this new Route53 domain to create them in my domain hosted at gandi.net
3. Aws Certificate Manager can then issue the certificate by using custom CNAME record check.
4. Everything is then ready to setup the Cloudfront distribution.
5. I secure the s3 access by using an OAI (Origin Access Identity) keep it private

Easy ? No
The following module automate this task using Terraform

## Prerequisites

You need:

* an AWS account with API keys and check that the free tier cover the costs (I bet)
* a domain name managed on gandi.net and generate the API key

## How to use it?

* Set up the [AWS CLI](https://aws.amazon.com/fr/cli/)
* Write your [Gandi API KEY](https://news.gandi.net/fr/2022/01/first-published-release-of-the-community-terraform-gandi-provider-v2-0-0/) in a file called `~/gandi/API_KEY`.
  Remember to limit the access to this file (600)
* [_Optional_] The script `./initialize-terraform.sh` automatically set the required env variables for you. It uses the values of the default AWS profile. whether you need to customize your aws config, you should to define them as follow
  * Rename the file `terraform.tfvars.example` as `terraform.tfvars`
  * edit it with your custom values_
* Edit the main.tf file following the template example
* [_The first time only_] Run `./initialize-terraform.sh init` to download the dependencies
* Run `./initialize-terraform.sh validate` to check the file syntax
* Run `./initialize-terraform.sh plan` to check planned actions
* Run `./initialize-terraform.sh apply` to create the infra

Et voilà!
