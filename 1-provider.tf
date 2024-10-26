

provider "aws" {
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::058264095432:role/GitHubAction-AssumeRoleWithAction"
  }
}

terraform {
  required_version = ">= 1.0"

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "xeniumsolution"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "tf-k8s-aws-selfmanaged"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }

}


provider "random" {}

# Helm provider

# provider "helm" {
#   #alias = x
#   kubernetes {
#     host                   = aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#     #token                  = data.aws_eks_cluster_auth.eks.token
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.id]
#       command     = "aws"
#     }    
#   }
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = aws_eks_cluster.eks.name
# }


# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }
