var rc = require('rhoconnect_helpers');
var Store = rc.Store;

var RhoInternalJsBenchAdapter = function() {

  this.query = function(resp){
    rc.source(resp,function(resp){
      var source = resp.result;
      var result;
      var db_name = get_db_name(source);
      resp.params = db_name;
      if(source.simulate_time > 0){
        setTimeout(rc.Store.getData(resp,function(resp){
          resp.send(resp.result);
        }), source.simulate_time);
      }
      else{
        rc.Store.getData(resp,function(resp){
          resp.send(resp.result);
        });
      }
    });
  };

  this.create = function(resp){
    var hsh = resp.params.create_object;
    var mockId2 = hsh["mock_id"];
    rc.source(resp,function(resp){
      var source = resp.result;
      var create_hash = {}
      create_hash[mockId2] = hsh;
      var p = [get_db_name(source),create_hash,true];
      resp.params = p;
      rc.Store.putData(resp,function(resp){
        console.log(JSON.stringify(resp));
        resp.send(mockId2);
      });
    });
  };

  this.update = function(resp){
    var id = resp.params["id"];
    var update_hash = resp.params["update_object"];
    
    rc.source(resp,function(resp){
      var source = resp.result;
      var db = get_db_name(source);
      resp.params = db;
      rc.Store.getData(resp,function(resp){
        var data = resp.result;
        //console.log("data_raw is"+JSON.stringify(data));
        if(data == null || JSON.stringify(data) === "{}"){
          new rc.Exception(resp, 'there is no data to update.');
        }
        for(var key in update_hash){
          data[id][key] = update_hash[key];
        }
        //console.log("data is"+JSON.stringify(data));
        resp.params =  [db,data];
        rc.Store.putData(resp,function(resp){
          resp.send(id);
        });
      });
      
    });
  };

  this.del = function(resp){
    var id = resp.params["id"];
    var delete_hash = resp.params["delete_object"];
    rc.source(resp,function(resp){
      var source = resp.result;
      var del_obj = {}
      del_obj[id] = delete_hash
      resp.params = [get_db_name(source),del_obj];
      rc.Store.deleteData(resp,function(resp){
        resp.send(id);
      });
    });
  };

  this.login = function(resp){
    resp.send(true);
  };

  this.logoff = function(resp){
    resp.send(true);
  };

  this.sync = function(resp){
    console.log("called sync");
  };


  function get_db_name(source){
    var res;
    if(source.user_id.substring(0,2) == 'nq')
      res = "test_db_storage:"+source.app_id + ":nquser";
    else if(source.user_id.substring(0,2) == 'mq')
        res = "test_db_storage:"+source.app_id+":mquser";
    else
      res = "test_db_storage:"+source.app_id+":benchuser";
    return res;
  }

};
module.exports = new RhoInternalJsBenchAdapter();