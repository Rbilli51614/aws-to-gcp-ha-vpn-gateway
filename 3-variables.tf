variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-project-id"                   # Your GCP Project ID
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "southamerica-east1"                # Your GCP Region
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "southamerica-east1-a"              # Your GCP Zone
}
