// Context object for the Livo platform
var Livo = {

	/***********************************/
	/* Implementation-related handlers */
	/***********************************/

	logDeviceReady: function() {

		console.log("Device is ready!.");
	},


	/*************/
	/* Functions */
	/*************/

	initialize: function() {

		this.bindEvents();
	},
	onDeviceReady: function(handler) {
      
      	document.addEventListener("deviceready", handler, false);
    },
	bindEvents: function() {
      
      	this.onDeviceReady(this.logDeviceReady);
	}
};

// Perform initialization
Livo.initialize();