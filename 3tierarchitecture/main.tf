
locals {
  appname  = var.appname
  envname = var.envname
  department = var.department
  
  common_tags = {
    appname = local.appname
    envname  = local.envname
    department  = local.department
  }
}


#https://medium.com/cognitoiq/terraform-and-aws-application-load-balancers-62a6f8592bcf
#https://github.com/masterwali/tf-module-aws-three-tier-network-vpc