if [ $# != 1 ]; then
  echo "Usage: $0 DOCKER_IMAGE"
  exit 1
fi

cat <<EOF | docker build -t $1 -
FROM $1
ONBUILD ENV proxy $http_proxy
ONBUILD ENV http_proxy $http_proxy
ONBUILD ENV https_proxy $https_proxy
ONBUILD ENV no_proxy $no_proxy
ONBUILD RUN echo 'proxy=$http_proxy' >> /etc/yum.conf
ONBUILD RUN echo '{"proxy": "$http_proxy", "https_proxy": "$http_proxy"}' > ~/.bowerrc
EOF
