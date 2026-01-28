variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "model_s3_path" { 
  type    = string 
  default = "s3://smartcity-models-dev/traffic-xgboost/model.tar.gz"  # Dev bucket/path
}
variable "environment" { default = "dev" }