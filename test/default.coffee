WebSocket = require('ws')

describe '', ->
	client = {}
	before (done) =>
		console.log 'Connecting on port 8080...'
		client = new WebSocket('ws://localhost:8080');
		client.on 'open', =>
			console.log 'Connected'
			done()

	it 'should disconnect', (done) ->
			done()