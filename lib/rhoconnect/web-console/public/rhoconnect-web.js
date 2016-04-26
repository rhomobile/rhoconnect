//$.jqplot.config.enablePlugins = true;
 $(function() {
        App.init();
 });

var App = {
    Views: {},
    Controllers: {},
    init: function() {
        router = new App.Controllers.Admins();
        Backbone.history.start();
    }
};


