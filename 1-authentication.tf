provider "aws" {
  region  = "us-east-1"                 # Choose your region
  profile = "default"
}

provider "awscc" {
  region  = "us-east-1"                 # Choose your region
  profile = "default"
}

provider "google" {
  credentials = "your-json-key.json"    # Your JSON Key Here
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}
