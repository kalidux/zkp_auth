terraform {
  source = "../modules/chaum-pederson-zkp"
}

inputs = {
  aws_region         = "us-east-2"
  ami_id             = "ami-037774efca2da0726"  
  docker_image_server = "kalidux/zkp_server:latest"  # Image Docker pour le serveur
  docker_image_client = "kalidux/zkp_client:latest"  # Image Docker pour le client
}
