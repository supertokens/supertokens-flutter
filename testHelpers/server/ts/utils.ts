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
const { exec } = require("child_process");
let { HandshakeInfo } = require("supertokens-node/lib/build/handshakeInfo");
let { DeviceInfo } = require("supertokens-node/lib/build/deviceInfo");
let { setCookie } = require("supertokens-node/lib/build/cookieAndHeaders");
let fs = require("fs");

export async function executeCommand(cmd: any): Promise<any> {
    return new Promise((resolve, reject) => {
        exec(cmd, (err: any, stdout: any, stderr: any) => {
            if (err) {
                reject(err);
                return;
            }
            resolve({ stdout, stderr });
        });
    });
};

export async function setupST() {
    let installationPath = process.env.INSTALL_PATH;
    try {
        await executeCommand("cd " + installationPath + " && cp temp/licenseKey ./licenseKey");
    } catch (ignored) { }
    await executeCommand("cd " + installationPath + " && cp temp/config.yaml ./config.yaml");
    await setKeyValueInConfig("refresh_api_path", "/refresh");
    await setKeyValueInConfig("enable_anti_csrf", "true");
};

export async function setKeyValueInConfig(key: any, value: any) {
    return new Promise((resolve, reject) => {
        let installationPath = process.env.INSTALL_PATH;
        fs.readFile(installationPath + "/config.yaml", "utf8", function (err: any, data: any) {
            if (err) {
                reject(err);
                return;
            }
            let oldStr = new RegExp("((#\\s)?)" + key + "(:|((:\\s).+))\n");
            let newStr = key + ": " + value + "\n";
            let result = data.replace(oldStr, newStr);
            fs.writeFile(installationPath + "/config.yaml", result, "utf8", function (err: any) {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    });
};

export async function cleanST() {
    let installationPath = process.env.INSTALL_PATH;
    try {
        await executeCommand("cd " + installationPath + " && rm licenseKey");
    } catch (ignored) { }
    await executeCommand("cd " + installationPath + " && rm config.yaml");
    await executeCommand("cd " + installationPath + " && rm -rf .webserver-temp-*");
    await executeCommand("cd " + installationPath + " && rm -rf .started");
};

export async function stopST(pid: any) {
    let pidsBefore = await getListOfPids();
    if (pidsBefore.length === 0) {
        return;
    }
    await executeCommand("kill " + pid);
    let startTime = Date.now();
    while (Date.now() - startTime < 10000) {
        let pidsAfter = await getListOfPids();
        if (pidsAfter.includes(pid)) {
            await new Promise(r => setTimeout(r, 100));
            continue;
        } else {
            return;
        }
    }
    throw new Error("error while stopping ST with PID: " + pid);
};

export async function killAllST() {
    let pids = await getListOfPids();
    for (let i = 0; i < pids.length; i++) {
        await stopST(pids[i]);
    }
    HandshakeInfo.reset();
    DeviceInfo.reset();
};

export async function startST(host = "localhost", port = 9000) {
    return new Promise(async (resolve, reject) => {
        let installationPath = process.env.INSTALL_PATH;
        let pidsBefore = await getListOfPids();
        let returned = false;
        let javaPath = process.env.JAVA === undefined ? "java" : process.env.JAVA
        executeCommand(
            "cd " +
            installationPath +
            ` && ${javaPath} -classpath "./core/*:./plugin-interface/*" io.supertokens.Main ./ DEV host=` +
            host +
            " port=" +
            port
        )
            .catch((err: any) => {
                if (!returned) {
                    returned = true;
                    reject(err);
                }
            });
        let startTime = Date.now();
        while (Date.now() - startTime < 20000) {
            let pidsAfter = await getListOfPids();
            if (pidsAfter.length <= pidsBefore.length) {
                await new Promise(r => setTimeout(r, 100));
                continue;
            }
            let nonIntersection = pidsAfter.filter(x => !pidsBefore.includes(x));
            if (nonIntersection.length !== 1) {
                if (!returned) {
                    returned = true;
                    reject("something went wrong while starting ST");
                }
            } else {
                if (!returned) {
                    returned = true;
                    resolve(nonIntersection[0]);
                }
            }
        }
        if (!returned) {
            returned = true;
            reject("could not start ST process");
        }
    });
};

async function getListOfPids() {
    let installationPath = process.env.INSTALL_PATH;
    try {
        (await executeCommand("cd " + installationPath + " && ls .started/")).stdout;
    } catch (err) {
        return [];
    }
    let currList = (await executeCommand("cd " + installationPath + " && ls .started/")).stdout;
    currList = currList.split("\n");
    let result = [];
    for (let i = 0; i < currList.length; i++) {
        let item = currList[i];
        if (item === "") {
            continue;
        }
        try {
            let pid = (await executeCommand("cd " + installationPath + " && cat .started/" + item))
                .stdout;
            result.push(pid);
        } catch (err) { }
    }
    return result;
}
