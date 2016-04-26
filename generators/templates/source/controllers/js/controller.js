var app = require('ballroom');
var rc = require('rhoconnect_helpers');

app.controllerName('<%=class_name%>');
app.registerHandler('sync');

// Add your custom routes here