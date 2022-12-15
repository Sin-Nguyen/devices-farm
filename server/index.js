var express = require('express')
var app = express()
const { exec } = require('child_process')
const deviceFarmPort = 4722

app.listen(4722, () => {
	console.log('Welcome to Appium Farm Server.')
	console.log(`Server is running on port ${deviceFarmPort}`)
})

app.get('/', (req, res, next) => {
	res.format({
		'text/plain': () => res.send('Welcome to Appium Farm Server'),
	})
})

const resObject = (resRaw) => {
	return {
		message: resRaw,
	}
}

const resAppiumObject = (appiumConfigJson, portServerMessage) => {
	return {
		message: {
			portServerRunning: portServerMessage,
			serverInfo: appiumConfigJson,
		},
	}
}

app.get('/' + 'port/list', (req, res) => {
	exec('sh ./index.sh port -l', (error, stdout, stderr) => {
		const ports = stdout.split('\n')
		let portListReady = []
		let portListBusy = []
		ports.forEach((port) => {
			const portInfo = port
				.replace('Checking ports from 4724 to 4730', '')
				.match(/[0-9]{4}/g)
			if (port.includes('READY')) {
				portListReady.push(portInfo[0])
			}
			if (port.includes('Busy')) {
				portListBusy.push(portInfo[0])
			}
		})
		res.format({
			'appliation/json': () =>
				res.send({
					READY: portListReady,
					BUSY: portListBusy,
				}),
		})
	})
})

app.get('/' + 'port', (req, res) => {
	const port = req.query.specificPort
	exec('sh ./index.sh port -p ' + port, (error, stdout, stderr) => {
		if (stdout.includes('...........')) {
			const portResult = stdout
				.replace(`Checking port ${port}`, '')
				.replaceAll('\n', '')
			res.format({ 'appliation/json': () => res.send(resObject(portResult)) })
		}
	})
})

app.post('/' + 'appium/:port/start', (req, res) => {
	const port = req.params.port
	if (port === undefined || port === ':port') {
		res.status(400).send('Port is required')
		return
	}
	exec('sh ./index.sh appium -start -p ' + port, (error, stdout, stderr) => {
		if (stdout.includes('Appium config is')) {
			const rawRes = stdout.match(/(.*running.*)/g)[0]
			const appiumConfigJson = require('../node/config.appiumrc.json')
			delete appiumConfigJson.server['debug-log-spacing']
			delete appiumConfigJson.server['log']
			delete appiumConfigJson.server['log-level']
			delete appiumConfigJson.server['log-no-colors']
			delete appiumConfigJson.server['log-timestamp']
			delete appiumConfigJson.server['no-perms-check']
			delete appiumConfigJson.server['long-stacktrace']
			delete appiumConfigJson.server['tmp']
			delete appiumConfigJson.server['trace-dir']
			delete appiumConfigJson.server['strict-caps']
			const response = resAppiumObject(appiumConfigJson.server, rawRes)
			res.format({ 'appliation/json': () => res.send(response) })
		}

		if (stdout.includes('Error')) {
			res.format({
				'appliation/json': () => res.send(resObject(stdout)),
			})
		}
	})
})

app.post('/' + 'appium/:port/kill', (req, res) => {
	const port = req.params.port
	exec('sh ./index.sh appium -kill ' + port, (error, stdout, stderr) => {
		if (stdout.includes('Unknown parameter passed')) {
			res.format({ 'appliation/json': () => res.send(resObject(stdout)) })
		}

		if (stdout.includes('killed')) {
			const rawRes = stdout.match(/(.*killed.*)/g)[0]
			res.format({ 'appliation/json': () => res.send(resObject(rawRes)) })
		}

		if (stdout.includes('Error')) {
			res.format({
				'appliation/json': () => res.send(resObject(stdout.replace('\n', ''))),
			})
		}
	})
})

app.get('/' + 'farm/:port/devices', (req, res) => {
	const port = req.params.port
	exec(`sh ./index.sh device -p ${port} -l`, (error, stdout, stderr) => {
		res.format({ 'appliation/json': () => res.send(stdout) })
	})
})

app.get('/' + 'farm/:port/device', (req, res) => {
	const port = req.params.port
	const udid = req.query.udid
	const ready = req.query.ready

	if (port === undefined || port === ':port') {
		res.status(400).send('Port is required')
		return
	}

	if (udid === undefined && ready === false) {
		res.status(400)
		res.format({
			'appliation/json': () =>
				res.send({
					message: `Error . Please use one of params [udid , isReady]`,
				}),
		})
		return
	}

	if (udid !== undefined && ready === undefined) {
		exec(
			`sh ./index.sh device -p ${port} -d ${udid}`,
			(error, stdout, stderr) => {
				if (stdout.includes('null')) {
					res.status(404)
					res.format({
						'appliation/json': () =>
							res.send({
								ErrorMessage: `Error : Not found udid "${udid}" in port ${port} `,
							}),
					})
					return
				}

				res.format({ 'appliation/json': () => res.send(stdout) })
			},
		)
		return
	}
	if (udid === undefined && ready !== undefined) {
		exec(`sh ./index.sh device -p ${port} -ready`, (error, stdout, stderr) => {
			res.format({ 'appliation/json': () => res.send(stdout) })
		})
		return
	}

	res.status(400)
	res.format({
		'appliation/json': () =>
			res.send({
				message: `Error . Please use one of params [udid , isReady]`,
			}),
	})
	return
})
