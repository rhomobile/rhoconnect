// App.Views.EditUser = Backbone.View.extend({
// 	
// 	events: {
// 		"submit form" : "edit" 
// 	},
// 	
//     initialize: function() {
//         this.render();
//     },  
// 
//     edit: function(e){
// 		e.preventDefault();
// 	    var session = new Session()
// 	    var password = $("#password2").val();
// 	  	$.ajax({
// 			type: 'PUT',
// 			url: '/rc/v1/users/' + 'rhoadmin',
// 			data: {attributes : {login : 'rhoadmin', password : password}},
// 			beforeSend: function (HttpRequest) {
// 			            HttpRequest.setRequestHeader("X-RhoConnect-API-TOKEN", session.getApiKey());
// 			},
// 			success: function(){
// 				//router.navigate("users", true);
// 			},
// 			error: function(resp){
// 				if(resp.status == 422){
// 					 new App.Views.Index()
// 				}
// 				$('#settings-alert')[0].innerHTML = resp.responseText;
// 		        $('#settings-alert').css('display','block');
// 			}
// 		})
// 	},
//     
//     render: function() {
//         $('#secondary-nav').css('display','block');
// 		out = "<h3>Change Admin Password</h3>"
// 		out += "<form>"
// 	    out += "<input id='password2' type='password' name='password' value='' placeholder='Enter new password' style='margin:0'/>"
// 	    out += "<input type='submit' class='btn btn-primary' value='Save' style='margin-left:10px'/>"
// 		out += "</form>"
// 				
//         $(this.el).html(out);
//         $('#settings_main').html(this.el);
//     }
// });