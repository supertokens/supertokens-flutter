import EmailPassword from "supertokens-node/recipe/emailpassword";
import Session from "supertokens-node/recipe/session";
import { TypeInput } from "supertokens-node/types";

const apiPort = Number(process.env.PORT ?? 3567);
const connectionURI = "https://try.supertokens.com";

export const apiDomain =
  process.env.ST_API_DOMAIN ?? `http://127.0.0.1:${apiPort}`;

export const SuperTokensConfig: TypeInput = {
  supertokens: {
    connectionURI,
  },
  appInfo: {
    appName: "SuperTokens Dart 3 Repro",
    apiDomain,
    websiteDomain: process.env.ST_WEBSITE_DOMAIN ?? "http://localhost:3000",
    apiBasePath: "/auth",
  },
  recipeList: [EmailPassword.init(), Session.init()],
};

export const backendInfo = {
  connectionURI,
  recipe: "emailpassword",
};
