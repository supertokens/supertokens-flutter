import cors from "cors";
import express from "express";
import supertokens from "supertokens-node";
import { errorHandler, middleware } from "supertokens-node/framework/express";
import { verifySession } from "supertokens-node/recipe/session/framework/express";

import { backendInfo, SuperTokensConfig } from "./config";

supertokens.init(SuperTokensConfig);

const port = Number(process.env.PORT ?? 3567);
const app = express();

app.use(express.json());
app.use(
  cors({
    origin: true,
    allowedHeaders: ["content-type", ...supertokens.getAllCORSHeaders()],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    credentials: true,
  }),
);

app.get("/ping", (_req, res) => {
  res.send({
    status: "OK",
    ...backendInfo,
  });
});

app.use(middleware());

app.get("/sessioninfo", verifySession(), (req, res) => {
  res.send({
    sessionHandle: req.session!.getHandle(),
    userId: req.session!.getUserId(),
    accessTokenPayload: req.session!.getAccessTokenPayload(),
  });
});

app.use(errorHandler());

app.listen(port, () => {
  console.log(
    `Dart 3 repro backend listening on http://127.0.0.1:${port} using ${backendInfo.recipe} via ${backendInfo.connectionURI}`,
  );
});
