FROM rishabhpoddar/supertokens_node_driver_testing
# TODO: Change for flutter
ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" \
   ANDROID_HOME="/usr/local/android-sdk" \
   ANDROID_VERSION=28 \
   ANDROID_BUILD_TOOLS_VERSION=28.0.3

RUN mkdir "$ANDROID_HOME" .android \
   && cd "$ANDROID_HOME" \
   && curl -o sdk.zip $SDK_URL

RUN apt-get install unzip

# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN cd "$ANDROID_HOME" && unzip sdk.zip \
   && rm sdk.zip \
   && yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

# Install Android Build Tool and Libraries
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
   "platforms;android-${ANDROID_VERSION}" \
   "platform-tools"

RUN apt-get install -y jq