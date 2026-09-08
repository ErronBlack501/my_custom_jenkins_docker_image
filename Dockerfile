FROM jenkins/jenkins:2.580-jdk21
USER root
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends lsb-release && rm -rf /var/lib/apt/lists/*
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && rm -rf /var/lib/apt/lists/*
RUN git config --system http.version HTTP/1.1
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow json-path-api sonar pipeline-maven config-file-provider"