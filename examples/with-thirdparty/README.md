# SuperTokens Example App

## Add dependencies

This example uses requires the following dependencies:

- [supertokens_flutter](https://pub.dev/documentation/supertokens/latest/)
- [google_sign_in](https://pub.dev/packages/google_sign_in)
- [flutter_appauth](https://pub.dev/packages/flutter_appauth)
- [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple)

## Setup

### Google

- Create OAuth credentials for Android on [Google cloud console](https://console.cloud.google.com/).
- Create OAuth credentials for iOS on [Google cloud console](https://console.cloud.google.com/).
- Create OAuth credentials for Web on [Google cloud console](https://console.cloud.google.com/). This is required because we need to get the authorization code in the app to be able to use SuperTokens. You need to provide all values (including domains and URLs) for Google login to work, you can use dummy values if you do not have a web application.
- Replace all occurences of `GOOGLE_IOS_CLIENT_ID` with the client id for iOS in the app's code (including the info.plist)
- Replace `GOOGLE_IOS_URL_SCHEME` with the value of `GOOGLE_IOS_CLIENT_ID` in reverse, for example if the iOS client id is com.org.scheme the value you want to set is scheme.org.com. Google cloud console will provide a way to copy the URL scheme to make this easier.
- Replace all occurences of `GOOGLE_WEB_CLIENT_ID` with the client id for Web in both the iOS code (including the info.plist) and the backend code
- Replace all occurences of `GOOGLE_WEB_CLIENT_SECRET` with the client secret in the backend code

### Github login

- Create credentials for an OAuth app from Github Developer Settings
- Use `com.supertokens.supertokensexample://oauthredirect` when configuring the Authorization callback URL. If you are using your own redirect url be sure to update the `Info.plist` for ios and the `loginWithGithub` function in `login.dart`.
- Replace all occurences of `GITHUB_CLIENT_ID` in both the frontend and backend
- Replace all occurences of `GITHUB_CLIENT_SECRET` in the backend code

### Apple login

- Add the Sign in with Apple capability for your app's primary target. This is already done for this example app so no steps are needed.
- If you are not using Xcode's automatic signing you will need to manually add the capability against your bundle id in Apple's dashboard.
- Replace all occurrences of `APPLE_CLIENT_ID`. This should match your bundle id
- Replace all occurrences of `APPLE_KEY_ID`. You will need to create a new key with the Sign in with Apple capability on Apple's dashboard.
- Replace all occurences of `APPLE_PRIVATE_KEY`, when you create a key there will be an option to download the private key. You can only download this once.
- Replace all occurrences of `APPLE_TEAM_ID` with your Apple developer account's team id

## Running the app

- Replace the value of the API domain in `constants.dart` and /backend/config.ts to match your machines local IP address
- Navigate to the /backend folder and run npm run start
- Open the code in VSCode or the IDE of your choice and run the app like yoo normally would with Flutter

## How it works

- On app launch we check if a session exists and redirect to login if it doesnt
- We add the SuperTokens interceptor to Dio so that the SuperTokens SDK can manage session tokens for us
- After logging in we call APIs exposed by the SuperTokens backend SDKs to create a session and redirect to the home screen
- On the home screen we call a protected API to fetch session information
