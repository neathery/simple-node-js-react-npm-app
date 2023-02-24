#!/bin/bash
# Running Jenkins inside Docker
# Ref: https://www.jenkins.io/doc/tutorials/build-a-node-js-and-react-app-with-npm/
#
# 1. Create bridge network (jenkins)
# 2. Download/Create docker:dind image
# 3. Build jenkins-blueocean image
# 4. Run the jenkins-blueocean image as a container

# ----------------------------------------------------------------------
# This command will tell the script to exit if it encounters any errors
# ----------------------------------------------------------------------
set -e

# ----------------------------------------------------------------------
# Set colors
# ----------------------------------------------------------------------

BBlue='\033[1;34m'  
On_Blue='\033[44m'       
BPurple='\033[1;35m' 
Cyan='\033[0;36m'
BCyan='\033[1;36m' 
On_Cyan='\033[46m'
Green='\033[0;32m' 
BGreen='\033[1;32m'
On_Green='\033[42m'       
Red='\033[0;31m'          
BRed='\033[1;31m'
On_Red='\033[41m'                 
White='\033[0;37m' 
BWhite='\033[1;37m'            
Color_Off='\033[0m'

# ----------------------------------------------------------------------
# Create Jenkins bridge network
# ----------------------------------------------------------------------
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${On_Blue}                 jenkins bridge network                 ${Color_Off}"
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${Cyan}---> Checking for the jenkins bridge network?           ${Color_Off}"
docker network ls
cmd="docker network ls"
listing=$(eval "$cmd")
if [ `echo $listing | grep -c jenkins ` -gt 0 ];
then
   echo -e "${Cyan}---> Jenkins bridge network exists                      ${Color_Off}"
else
   # Create bridge network
   echo -e "${Cyan}---> Creating the jenkins bridge network...             ${Color_Off}"
   docker network create jenkins
fi

# ----------------------------------------------------------------------
# Download/Create docker:dind image
# ----------------------------------------------------------------------
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${On_Blue}                docker-jenkins container                ${Color_Off}"
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${Cyan}---> Checking for the jenkins-docker container?  ${Color_Off}"
docker container ls
cmd="docker container ls"
listing=$(eval "$cmd")
if [ `echo $listing | grep -c jenkins ` -gt 0 ];
then
   echo -e "${Cyan}---> Removing jenkins-docker container and docker:dind image... ${Color_Off}"
   # Stop jenkins-docker container
   docker container stop jenkins-docker
   # Remove docker image
   docker image rm docker:dind
fi
# Create bridge network
echo -e "${Cyan}---> Download docker image and create the jenkins-docker container...  ${Color_Off}"
docker run --name jenkins-docker --rm --detach --privileged --network jenkins --network-alias docker --env DOCKER_TLS_CERTDIR=/certs --volume jenkins-docker-certs:/certs/client --volume jenkins-data:/var/jenkins_home --publish 2376:2376 --publish 3000:3000 --publish 6000:6000 docker:dind --storage-driver overlay2

# ----------------------------------------------------------------------
# Build myjenkins-blueocean image
# ----------------------------------------------------------------------
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${On_Blue}           jenkin-blueocean container                   ${Color_Off}"
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${Cyan}---> Checking for the jenkins-blueocean container?  ${Color_Off}"
docker container ls
cmd="docker container ls"
listing=$(eval "$cmd")
if [ `echo $listing | grep -c jenkins-blueocean ` -gt 0 ];
then
   echo -e "${Cyan}---> Removing jenkins-blueocean container... ${Color_Off}"
   # Stop myjenkins-blueocean container
   docker container stop jenkins-blueocean
   docker container rm jenkins-blueocean
fi
echo -e "${Cyan}---> Building jenkins-blueocean image... ${Color_Off}"
# Build jenkins-blueocean image
docker build -t myjenkins-blueocean:2.375.3-1 .
echo -e "${Cyan}---> Run jenkins-blueocean image as a container... ${Color_Off}"
# ----------------------------------------------------------------------
# Run the jenkins-blueocean image as a container
# ----------------------------------------------------------------------
docker run --name jenkins-blueocean --detach --network jenkins --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --publish 8080:8080 --publish 50000:50000 --volume jenkins-data:/var/jenkins_home --volume jenkins-docker-certs:/certs/client:ro --volume "$HOME":/home --restart=on-failure --env JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" myjenkins-blueocean:2.375.3-1

# ----------------------------------------------------------------------
# Next steps
# ----------------------------------------------------------------------
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${On_Blue}                 Complete the setup                     ${Color_Off}"
echo -e "${On_Blue}                                                        ${Color_Off}"
echo -e "${On_Cyan}---> Open the following in a browser: http://localhost:8080/  ${Color_Off}"
echo -e "${Cyan}---> When you first access a new Jenkins instance, you are asked to unlock it using an automatically-generated password. ${Color_Off}"
echo -e "${Cyan}------> A. Find the password in the docker:dind container under the /var/jenkins_home/secrets/initialAdminPassword directory ${Color_Off}"
echo -e "${Cyan}------>                   -OR-  ${Color_Off}"
echo -e "${Cyan}------> B. Run the following command to get the password: docker logs jenkins-blueocean ${Color_Off}"