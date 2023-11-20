import ThirdParty from "supertokens-node/recipe/thirdparty";
import Session from "supertokens-node/recipe/session";
import { TypeInput } from "supertokens-node/types";
import Dashboard from "supertokens-node/recipe/dashboard";

export const SuperTokensConfig: TypeInput = {
  supertokens: {
    // this is the location of the SuperTokens core.
    connectionURI: "https://try.supertokens.com",
  },
  appInfo: {
    appName: "SuperTokens Demo App",
    apiDomain: "http://192.168.29.16:3001",
    websiteDomain: "http://localhost:3000", // this value does not matter for the android app
  },
  // recipeList contains all the modules that you want to
  // use from SuperTokens. See the full list here: https://supertokens.com/docs/guides
  recipeList: [
    ThirdParty.init({
      signInAndUpFeature: {
        providers: [
          // We have provided you with development keys which you can use for testing.
          // IMPORTANT: Please replace them with your own OAuth keys for production use.
          {
            config: {
              thirdPartyId: "google",
              clients: [
                {
                  clientId: "580674050145-shkfcshav895dsoj61vuf6s5iml27glr.apps.googleusercontent.com",
                  clientSecret: "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",
                },
              ],
            },
          },
          {
            config: {
              thirdPartyId: "github",
              clients: [
                {
                  clientId: "eee1670bbc37d98c1d30",
                  clientSecret: "9b0c5134a89ba98a813adb72e56d9765dd36c966",
                },
              ],
            },
          },
          {
            config: {
              thirdPartyId: "apple",
              clients: [
                {
                  clientId: "APPLE_CLIENT_ID",
                  additionalConfig: {
                    keyId: "APPLE_KEY_ID",
                    privateKey: "APPLE_PRIVATE_KEY",
                    teamId: "APPLE_TEAM_ID",
                  },
                },
              ],
            },
          },
        ],
      },
    }),
    Session.init(),
    Dashboard.init(),
  ],
};
