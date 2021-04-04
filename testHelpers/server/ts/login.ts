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
import * as express from 'express';
import * as SuperTokens from 'supertokens-node';

import Names from './names';

export default async function login(req: express.Request, res: express.Response) {
    let session = await SuperTokens.createNewSession(res, getRandomString(), undefined, {
        name: getRandomName()
    });
    res.send("");
}

function getRandomString(): string {
    let chars = "abcdefghijklmnopqrstuvwxyz";
    let res = "";
    for (let i = 0; i < 10; i++) {
        res += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return res;
}

function getRandomName(): string {
    let randomName = Names[Math.floor(Math.random() * Names.length)];
    return randomName.firstName + " " + randomName.lastName;
}