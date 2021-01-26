terraform {
  required_version = "0.14.0"
  required_providers {
    aws = {
      version = ">= 3.21.0"
      source  = "hashicorp/aws"
    }
  }
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
 
  tags  = {
    Name = "PublicSubnetA"
  }
}

## パブリックサブネットの作成
resource "aws_subnet" "PublicSubnetC" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"
 
  tags  = {
    Name = "PublicSubnetC"
  }
}


## プライベートサブネットの作成
resource "aws_subnet" "PrivateSubnetA" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"
 
  tags  = {
    Name = "PrivateSubnetA"
  }
}

## プライベートサブネットの作成
resource "aws_subnet" "PrivateSubnetC" {
  vpc_id            = aws_vpc.rails_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
 
  tags  = {
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