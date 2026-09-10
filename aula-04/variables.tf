variable "aws_region" {
  description = "Região AWS usada pelo Learner Lab."
  type        = string
  default     = "us-east-1"
}

variable "owner_ra" {
  description = "RA usado na tag Owner."
  type        = string
  default     = "6325016"
}

variable "instance_type" {
  description = "Tipo da instância da API."
  type        = string
  default     = "t2.micro"
}

variable "repository_url" {
  description = "Repositório público que contém aula-04/technova-api."
  type        = string
  default     = "https://github.com/iHawlKz7/iHawlKz7-unifaat-devops-portfolio.git"
}
