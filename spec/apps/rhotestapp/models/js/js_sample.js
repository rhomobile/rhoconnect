var rc = require('rhoconnect_helpers');
var Store = rc.Store;

var JsSample = function() {

  this.query = function(resp){
    var result = {'1': {'name': 'iPhone'}};
    if(resp.params && resp.params.raise_an_error){
      new rc.ServerErrorException(resp, 'query error occured');
    }

    if(resp.params && resp.params.test_non_hash){
      result = true;
    }
    resp.send(result);
  };

  this.create = function(resp){
    if(resp.params.create_object['txtfile-rhoblob'] === 'blob_created'){
      resp.send('blob_created');
    } else{
      resp.send('2');
    }
  };

  this.update = function(resp){
    resp.send('');
  };

  this.del = function(resp){
    resp.send('');
  };

  this.login = function(resp){
    var result = "success";
    resp.send(result);
  };

  this.logoff = function(resp){
    resp.send(true);
  };

  this.testGetValue = function(resp){
    resp.params = 'foo';
    Store.getValue(resp,function(resp){
      resp.send(resp.result);
    });
  };

  this.testGetData = function(resp){
    resp.params = 'foo';
    Store.getData(resp,function(resp){
      resp.send(resp.result);
    });
  };

  this.testGetModelData = function(resp){
    rc.getData(resp,function(resp){
      resp.send(resp.result);
    });
  };

  this.testPutValue = function(resp){
    Store.putValue(resp,function(resp){
      resp.send(resp.result);
    });
  };

  this.testPutData = function(resp){
    Store.putData(resp,function(resp){
      resp.send(resp.result);
    });
  };

  this.getUser = function(resp){
    var user = resp.currentUser;
    resp.send(user);
  };

  this.getSource = function(resp){
    rc.source(resp,function(resp){
      var source = resp['result']['id'];
      resp.send(source);
    });
  };

  this.testStashResult = function(resp){
    for(var i = 0; i < 2; i++){
      var item = i.toString();
      resp.params = {};
      resp.params[item] = {'name': item};
      rc.stashResult(resp);
    }
    // Master Document now contains { '0': {'name': '0'}, '1': {'name': '1'} }
    resp.send(true);
  };

  this.testRaiseException = function(resp){
    new rc.Exception(resp, 'some custom message');
  };

  this.testRaiseLoginException = function(resp){
    new rc.LoginException(resp, 'some login message');
  };

  this.testRaiseLogoffException = function(resp){
    new rc.LogoffException(resp, 'some logoff message');
  };

  this.testRaiseTimeoutException = function(resp){
    new rc.ServerTimeoutException(resp, 'some timeout message');
  };

  this.testRaiseErrorException = function(resp){
    new rc.ServerErrorException(resp, 'some error message');
  };

  this.testRaiseConflictException = function(resp){
    new rc.ObjectConflictErrorException(resp, 'some object conflict message');
  };

  this.partitionName = function(resp){
    resp.send(resp.params.user_id + '_partition');
  };


  this.storeBlob = function(resp){
    var fs = require('fs');
    if(fs.existsSync(resp.params.path)){
      resp.send('blob_created');
    } else{
      resp.send('no blob');
    }
  };

};

module.exports = new JsSample();