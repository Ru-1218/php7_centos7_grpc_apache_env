name="php_grpc"
docker stop $name
docker rm -f $name
docker rmi -f $name:myself