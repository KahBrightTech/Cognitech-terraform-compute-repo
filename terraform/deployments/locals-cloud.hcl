#-------------------------------------------------------
# Cloud variables 
#-------------------------------------------------------
locals {

  repo = {
    root = get_parent_terragrunt_dir()
  }
  account_info = {
    mdpp = {
      name   = "mdpreproduction"
      number = "485147667400"
    }
    mdp = {
      name   = "mdproduction"
      number = "730335294148"
    }
    tpp = {
      name   = "trn-preproduction"
      number = "485147667400"
    }

    tp = {
      name   = "trn-production"
      number = "730335294148"
    }
    intpp = {
      name   = "int-preproduction"
      number = "730335294148"
    }
    intp = {
      name   = "int-production"
      number = "388927731914"
    }
  }

  billing_code_number = {
    kah = "90471"
    int = "TBD"
    dev = "TBD"
    qa  = "TBD"
  }
  region_prefix = {
    primary   = "use1"
    secondary = "usw2"
  }
  regions = {
    use1 = {
      availability_zones = {
        primary   = "us-east-1a"
        secondary = "us-east-1b"
        tertiary  = "us-east-1c"
      }
      name     = "us-east-1"
      name_abr = "use1"
    }

    usw2 = {
      availability_zones = {
        primary   = "us-west-2a"
        secondary = "us-west-2b"
        tertiary  = "us-west-2c"
      }
      name     = "us-west-2"
      name_abr = "usw2"
    }

    elastic_ips = {
      primary   = ["peipa", "peipb"]
      secondary = ["seipa", "seipb"]
    }

    nat_gateway = {
      primary   = ["pnata", "pnatb"]
      secondary = ["snata", "snatb"]
    }
  }
  repo = {
    root = get_parent_terragrunt_dir()
  }

  lambda = {
    start_instance = {
      runtime              = "python3.9"
      handler              = "index.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "start-ec2/index.zip"
      timeout              = "120"
      layer_s3_key         = "layers/layers.zip"
    }
    stop_instance = {
      runtime              = "python3.9"
      handler              = "index.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "stop-ec2/index.zip"
      timeout              = "120"
      layer_s3_key         = "layers/layers.zip"
    }
    user_credentials = {
      runtime              = "python3.9"
      handler              = "lambda_handler.lambda_handler"
      private_bucklet_name = "cognitech-lambdas-bucket"
      lamda_s3_key         = "IAM-Credentials/codes/generate_iam_report.zip"
      timeout              = "120"
      layer_s3_key         = "IAM-Credentials/layers/python.zip"
    }
  }

  Service_catalog = {
    Training = {
      InstanceStatus = {
        name          = "InstanceStatus"
        description   = "Service Catalog portfolio for all Instance status"
        provider_name = "Brigthain"
        products = [
          {
            name        = "start_instances" # Has to be the same as the provisioning_artifact_parameters keys 
            description = "Start an EC2 instance"
            type        = "CLOUD_FORMATION_TEMPLATE"
            owner       = "Brigthain"
          },
          {
            name        = "stop_instances" # Has to be the same as the provisioning_artifact_parameters keys
            description = "Stop an EC2 instance"
            type        = "CLOUD_FORMATION_TEMPLATE"
            owner       = "Brigthain"
          }
        ]
        provisioning_artifact_parameters = [
          {
            name         = "StartInstanceTemplate"
            description  = "Template to start EC2 instances"
            type         = "CLOUD_FORMATION_TEMPLATE"
            template_url = "https://cognitech-lambdas-bucket.s3.us-east-1.amazonaws.com/Service-Catalog-cfn-templates/LambdaInstanceStart.yaml"
          },
          {
            name         = "StopInstanceTemplate"
            description  = "Template to stop EC2 instances"
            type         = "CLOUD_FORMATION_TEMPLATE"
            template_url = "https://cognitech-lambdas-bucket.s3.us-east-1.amazonaws.com/Service-Catalog-cfn-templates/LambdaInstanceStop.yaml"
          }
        ]
        associate_admin_role   = true
        associate_iam_group    = true
        associate_network_role = true
      }
    }
  }
}