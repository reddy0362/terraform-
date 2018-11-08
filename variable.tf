variable "aws_access_key" {
        description = "Access Key"
        default = "AKIAJUTEDX7EUR2WWOBA"
}

variable "aws_secret_key" {
        description = "Secret Key"
        default = "idQkVSXWIw2slrkS9VdN890u/EPelvoFc3kVoIHX"
}

variable "region" {
        description ="region"
        default = "us-east-2"
}

variable "KeyPairName" {
        description = "Key Pair Name"
        default = "terraform"
}


variable "RootVolume" {
        description = "Root Volume"
        default = "10"
}

variable "EbsVolume" {
        description = "EBS Volume"
        default = "20"
}
