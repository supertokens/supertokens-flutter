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

import RefreshTokenCounter from './refreshTokenCounter';
import CustomRefreshAPIHeaders from './customRefreshAPIHeaders';

export default async function refreshtoken(req: express.Request, res: express.Response) {
    try {
        await SuperTokens.refreshSession(req, res);
        RefreshTokenCounter.incrementRefreshTokenCount();
        CustomRefreshAPIHeaders.setCustomRefreshAPIHeaders(req.headers["testkey"]!== undefined);
        res.send("");
    } catch (err) {
        if (SuperTokens.Error.isErrorFromAuth(err) && err.errType !== SuperTokens.Error.GENERAL_ERROR) {
            if (err.errType === SuperTokens.Error.TOKEN_THEFT_DETECTED) {
                await SuperTokens.revokeSession(err.err.sessionHandle);
            }
            res.status(401).send("Session expired");
        } else {
            throw err;
        }
    }
} 