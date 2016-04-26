var rc = require('rhoconnect_helpers');

var <%=class_name%> = function(){

  this.login = function(resp){
    // TODO: Login to your data source here if necessary
    resp.send(true);
  };

  this.query = function(resp){
    var result = {};
    // TODO: Query your backend data source and assign the records
    // to a nested hash structure. Then return your result.
    // For example:
    //
    // {
    //   "1": {"name": "Acme", "industry": "Electronics"},
    //   "2": {"name": "Best", "industry": "Software"}
    // }
    resp.send(result);
  };

  this.create = function(resp){
    // TODO: Create a new record in your backend data source.  Then
    // return the result.
    resp.send('someId');
  };

  this.update = function(resp){
    // TODO: Update an existing record in your backend data source.
    // Then return the result.
    resp.send(true);
  };

  this.del = function(resp){
    // TODO: Delete an existing record in your backend data source
    // if applicable.  Be sure to have a hash key and value for
    // "object" and return the result.
    resp.send(true);
  };

  this.logoff = function(resp){
    // TODO: Logout from the data source if necessary.
    resp.send(true);
  };

  this.storeBlob = function(resp){
    // TODO: Handle post requests for blobs here.
    // Reference the blob object's path with resp.params.path.
    new rc.Exception(
      resp, "Please provide some code to handle blobs if you are using them."
    );
  };
};

module.exports = new <%=class_name%>();