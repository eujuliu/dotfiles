function push-image
    set IMAGE_NAME $argv[1]
    set DOCKER_USERNAME $argv[2]
    set TAG (test -n "$argv[3]; and echo $argv[3]; or echo "latest")
    set DOCKERFILE_PATH $argv[4]

    if test -z "$IMAGE_NAME" -o -z "$DOCKER_USERNAME"
        echo "Usage: push-image <image-name> <docker-username> [tag] <Dockerfile-path>"
        return 1
    end

    set FULL_IMAGE "$DOCKER_USERNAME/$IMAGE_NAME:$TAG"

    echo "Building Docker image: $IMAGE_NAME..."
    docker build -t $IMAGE_NAME -f $DOCKERFILE_PATH .; or begin
        echo "Build failed"
        return 1
    end

    echo "Tagging image as: $FULL_IMAGE"
    docker tag $IMAGE_NAME $FULL_IMAGE

    echo "Logging into Docker Hub..."
    docker login; or begin
        echo "Login failed"
        return 1
    end

    echo "Pushing image to Docker Hub..."
    docker push $FULL_IMAGE; or begin
        echo "Push failed"
        return 1
    end

    echo "Done! Image pushed: $FULL_IMAGE"
end
