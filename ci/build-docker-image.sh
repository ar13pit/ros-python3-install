#! /usr/bin/env bash
#
# Docker image builder
# This script builds the docker image and pushes it to the Docker registry with
# image tag as the branch name of the repository

# Stop on errors
set -o errexit

# Execute script only in a CI environment
if [ "$CI" != "true" ]
then
    echo -e "\e[35m\e[1m Error!\e[0m Trying to execute a CI script in a non-CI environment. Exiting script."
    exit 1
fi

for i in "$@"
do
    case $i in
        -i=* | --image=* )
            CI_DOCKER_IMAGE_NAME="${i#*=}" ;;

        -b=* | --branch=* )
            CI_BRANCH="${i#*=}" ;;

        -pr=* | --pull_request=* )
            CI_PULL_REQUEST="${i#*=}" ;;

        -u=* | --user=* )
            CI_DOCKER_USER="${i#*=}" ;;

        -p=* | --password=* )
            CI_DOCKER_PASSWORD="${i#*=}" ;;

        -r=* | --registry=* )
            CI_DOCKER_REGISTRY="${i#*=}" ;;

        * )
            echo -e "Error! Unknown input variable '$i'"
            exit 1 ;;
    esac
done

image_substring=$(basename "$CI_DOCKER_IMAGE_NAME")
case $image_substring in
    ros-base )
        BASE_IMAGE="ubuntu:18.04" ;;
    ros-cuda )
        BASE_IMAGE="nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04" ;;
    * )
        echo -e "Error! Unknown image tag subname provided."
        echo -e "Supported names are 'ros-base' or 'ros-cuda'"
        exit 1
esac

# Create tag based on branch name
default_branch=$(git remote show origin | grep HEAD | awk '{print $3;}')
if [ "$default_branch" == "$CI_BRANCH" ]
then
    CI_DOCKER_IMAGE_TAG="latest"
else
    CI_DOCKER_IMAGE_TAG=$(echo "$CI_BRANCH" | tr '[:upper:]' '[:lower:]' | sed -e 's:/:_:g')
fi

CI_DOCKER_IMAGE_NAME="$CI_DOCKER_IMAGE_NAME":"$CI_DOCKER_IMAGE_TAG"
echo -e "\e[35m\e[1m Creating docker $CI_DOCKER_IMAGE_NAME \e[0m"

# build the Docker image (this will use the Dockerfile in the root of the repo)
docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$CI_DOCKER_IMAGE_NAME" .

# push the new Docker image to the Docker registry only after acceptance of pull request
if [ "$CI_PULL_REQUEST" == "false" ]
then
    # Authenticate to the Docker registry
    echo -e "\e[35m\e[1m Authenticating docker registry $CI_DOCKER_REGISTRY \e[0m"
    echo "$CI_DOCKER_PASSWORD" | docker login "$CI_DOCKER_REGISTRY" -u "$CI_DOCKER_USER" --password-stdin

    echo -e "\e[35m\e[1m docker push $CI_DOCKER_IMAGE_NAME \e[0m"
    docker push "$CI_DOCKER_IMAGE_NAME"

    echo -e "\e[35m\e[1m Succeeded, see: \e[0m"
    docker images
fi
