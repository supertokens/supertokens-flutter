/* Copyright (c) 2020, VRAI Labs and/or its affiliates. All rights reserved.
 *
 * This software is licensed under the Apache License, Version 2.0 (the
 * "License") as published by the Apache Software Foundation.
 *
 * You may not use this file except in compliance with the License. You may
 * obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */
import * as cookieParser from 'cookie-parser';
import * as express from 'express';
import * as http from 'http';
import * as SuperTokens from 'supertokens-node';

import { testGetRefreshCounter } from './getRefreshTokenCounter';
import testLogin from './login';
import testLogout from './logout';
import testRefreshtoken from './refreshtoken';
import RefreshTokenCounter from './refreshTokenCounter';
import { testHeaders } from './testHeaders';
import testUserInfo from './userInfo';
import { cleanST, killAllST, setKeyValueInConfig, setupST, startST } from './utils';

import CustomRefreshAPIHeaders from './customRefreshAPIHeaders';
import { testGetCustomRefreshAPIHeaders } from './getCustomRefreshAPIHeaders';

let bodyParser = require("body-parser");

let urlencodedParser = bodyParser.urlencoded({ limit: "20mb", extended: true, parameterLimit: 20000 });
let jsonParser = bodyParser.json({ limit: "20mb" });

let app = express();
app.use(urlencodedParser);
app.use(jsonParser);
app.use(cookieParser());

SuperTokens.init({
  hosts: "http://localhost:9000"
});

app.post("/startst", async (req, res) => {
  try {
    let accessTokenValidity = req.body.accessTokenValidity === undefined ? 10 : req.body.accessTokenValidity;
    let setAntiCsrf = req.body.setAntiCsrf === undefined ? true : req.body.setAntiCsrf;
    let refreshTokenValidity = req.body.refreshTokenValidity === undefined ? 144000 : req.body.refreshTokenValidity;
    await setKeyValueInConfig("refresh_token_validity", refreshTokenValidity);
    await setKeyValueInConfig("access_token_validity", accessTokenValidity);
    await setKeyValueInConfig("enable_anti_csrf", setAntiCsrf);
    let pid = await startST();
    res.send(pid + "");
  } catch (err) {
    console.log(err);
  }
});

app.post("/beforeeach", async (req, res) => {
  RefreshTokenCounter.resetRefreshTokenCount();
  CustomRefreshAPIHeaders.resetCustomRefreshAPIHeaders();
  await killAllST();
  await setupST();
  await setKeyValueInConfig("cookie_domain", '"127.0.0.1"');
  await setKeyValueInConfig("cookie_secure", "false");
  res.send();
});

app.post("/after", async (req, res) => {
  await killAllST();
  await cleanST();
  res.send();
});

app.post("/login", function (req, res) {
  testLogin(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.get("/multipleInterceptors", function (req, res) {
  res.status(200).send(req.headers["interceptorheader"]);
});

app.get("/checkDeviceInfo", function (req, res) {
  res.status(200).send(req.headers)
});

app.get("/testError", function (req, res) {
  res.status(500).send("custom message");
});

app.get("/checkCustomHeader", function (req, res) {
  testGetCustomRefreshAPIHeaders(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.get("/testPing", function (req, res) {
  res.status(200).send("success");
});

app.get("/testConfig", function (req, res) {
  res.status(200).send(req.query.key);
});

app.get("/userInfo", function (req, res) {
  testUserInfo(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.post("/refresh", function (req, res) {
  testRefreshtoken(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.post("/logout", function (req, res) {
  testLogout(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.get("/refreshCounter", function (req, res) {
  testGetRefreshCounter(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  });
});

app.get("/header", function (req, res) {
  testHeaders(req, res).catch(err => {
    console.log(err);
    res.status(500).send("");
  })
});

app.get("/stop", async (req, res) => {
  process.exit();
});

app.use("*", function (req, res, next) {
  res.status(404).send("Not found");
});

let server = http.createServer(app);
server.listen(8080, "0.0.0.0");
