ness = require('./Ness')

WSServer = {}

class NessServer extends require('ws').Server
	@startup: (port, success) ->
		# Server
		Server = new (require('ws').Server)({port: 8080});
	
		Server.on 'connection', (socket) ->
			# Create the object
			socket.entity = new (ness.Models.Client)({socket: socket})
			
			# Add clients
			ness.Clients.push socket
			
			# Messages
			socket.on 'message', (message) ->
				try
					message = JSON.parse(message)
					socket.entity.parseMessage(message.id, message.data)
				catch error
					console.log 'Invalid message, will close socket.'
					socket.close()
					return
			
			# Add close event
			socket.on 'close', ->
				@.entity.onClose()
				index = ness.Clients.indexOf(@)
				ness.Clients.splice(index) unless index is -1
		
		if Server?
			success(Server)
		else
			throw new Error("Server could not be started.")
	
module.exports = NessServer