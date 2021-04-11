FROM rishabhpoddar/supertokens_android_sdk_testing

WORKDIR "/home"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/flutter/bin"
# Run basic check to download Dark SDK
RUN flutter doctor