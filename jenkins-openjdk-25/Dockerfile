FROM jenkins/jenkins:lts

USER root

# Install dependencies, including CA certificates
RUN apt-get update && apt-get install -y \
        wget \
        unzip \
        ca-certificates \
        && update-ca-certificates \
    && wget https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25+36/OpenJDK25U-jdk_x64_linux_hotspot_25_36.tar.gz \
    && tar -xzf OpenJDK25U-jdk_x64_linux_hotspot_25_36.tar.gz -C /opt/ \
    && rm OpenJDK25U-jdk_x64_linux_hotspot_25_36.tar.gz \
    && update-alternatives --install /usr/bin/java java /opt/jdk-25+36/bin/java 1

USER jenkins

