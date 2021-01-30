terraform {
  required_version = "0.14.0"
  required_providers {
    aws = {
      version = ">= 3.21.0"
      source  = "hashicorp/aws"
    }
  }
}
## ユーザとリージョンの設定
variable "region" {
  default = "ap-northeast-1"
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key

}

## VPC領域の作成
resource "aws_vpc" "rails_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "VPC領域"
  }
}

## パブリックサブネットの作成
resource "aws_subnet" "PublicSubnetA" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "PublicSubnetA"
  }
}

## パブリックサブネットの作成
resource "aws_subnet" "PublicSubnetC" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "PublicSubnetC"
  }
}


## プライベートサブネットの作成
resource "aws_subnet" "PrivateSubnetA" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "PrivateSubnetA"
  }
}

## プライベートサブネットの作成
resource "aws_subnet" "PrivateSubnetC" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "PrivateSubnetC"
  }
}

##ルートテーブルの追加(0.0.0.0/0)
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.rails_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yamada-web_GW.id
  }
}

##ルートテーブルの追加(1a)
resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.PublicSubnetA.id
  route_table_id = aws_route_table.public-route.id
}

##ルートテーブルの追加(1c)
resource "aws_route_table_association" "public-c" {
  subnet_id      = aws_subnet.PublicSubnetC.id
  route_table_id = aws_route_table.public-route.id
}

##ゲートウェイの設定
resource "aws_internet_gateway" "yamada-web_GW" {
  vpc_id = aws_vpc.rails_vpc.id
}

## Rails用セキュリティグループの設定
resource "aws_security_group" "rails-web" {
  name        = "rails-web"
  description = "rails-web"
  vpc_id      = aws_vpc.rails_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "rails-web"
  }
}

variable "ami" {
  default = "ami-0992fc94ca0f1415a"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "volume_size" {
  default = 8
}

##EC2(rails-web01)
resource "aws_instance" "rails-web01" {
  ami               = var.ami
  availability_zone = "ap-northeast-1a"
  instance_type     = var.instance_type
  key_name          = aws_key_pair.key_pair.id
  private_ip        = "10.0.1.10"

  disable_api_termination = false
  vpc_security_group_ids  = [aws_security_group.rails-web.id]
  subnet_id               = aws_subnet.PublicSubnetA.id

  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size
  }

  tags = {
    Name = "rails-web01"
  }
}

##EIP(rails-web01)
resource "aws_eip" "rails-web01" {
  instance = aws_instance.rails-web01.id
  vpc      = true
}

## EC2 key pairの作成
variable "key_name" {
  description = "keypair name"
  default     = "rails-web01"
}

## キーファイル
## 生成場所のPATH指定をしたければ、ここを変更するとよい。
locals {
  public_key_file  = "./.ssh/id_rsa.pub"
  private_key_file = "./.ssh/id_rsa"
}

## キーペアを作る
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

## 秘密鍵ファイルを作る
resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem

}

## sshのキー設定
resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh

}

## キー名
output "key_name" {
  value = var.key_name
}

## 秘密鍵ファイルPATH（このファイルを利用してサーバへアクセスする。）
output "private_key_file" {
  value = local.private_key_file
}

## 秘密鍵内容
output "private_key_pem" {
  value = tls_private_key.keygen.private_key_pem
}

## 公開鍵ファイルPATH
output "public_key_file" {
  value = local.public_key_file
}

## 公開鍵内容（サーバの~/.ssh/authorized_keysに登録して利用する。）
output "public_key_openssh" {
  value = tls_private_key.keygen.public_key_openssh
}

## EC2にキーペアを登録
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh
}


