# Terraform static s3 hosting using a domain name hosted outside aws

For side projects, I was expecting to host static website.
I couldn't found an easy way to tick all the following features:

* low cost
* static files (no server)
* https support
* custom domain hosted by gandi.net (not aws route53)

Then I wrote the following terraform file

## configuration

ensure you've

* set up aws cli
* write your [Gandi API KEY|<https://news.gandi.net/fr/2022/01/first-published-release-of-the-community-terraform-gandi-provider-v2-0-0/>] in a file called "~/gandi/API_KEY"
* set your root domain name `export DOMAIN_NAME=domain.name.com`
* set your subdomain record `export SUB_DOMAIN_NAME=www`
* Run `./initialize-terraform.sh` with your usual parameters as this script only set the required env variables for you
