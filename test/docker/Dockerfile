FROM rishabhpoddar/supertokens_android_sdk_testing

USER root

WORKDIR "/home"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/flutter/bin"
# Run basic check to download Dart SDK
RUN flutter doctor && chown -R root:root /home/flutter