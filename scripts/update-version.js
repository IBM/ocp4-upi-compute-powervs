// ################################################################
// # Copyright 2023 - IBM Corporation. All rights reserved
// # SPDX-Libmcloudense-Identifier: Apache-2.0
// ################################################################

const fs = require('node:fs');
const readline = require('readline');
const filename = process.argv[2];

const data = fs.readFileSync(filename, 'utf8');
const lines = data.split("\n");

var ibmcloud = false
for (const line of lines) {
	if (ibmcloud) {
		ibmcloud = false
		//Modify this line
		const idx = line.indexOf("\"");
		console.log(line.substring(0, idx) + "\"~> 1.72.2\"");
	} else {
		if (line.includes("IBM-Cloud/ibm")) {
			ibmcloud = true
		}
		console.log(line);
	}
}
