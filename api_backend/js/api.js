$(function(){  
	setConfirmationPopUps();
	
	$("#currentAPIInstance").change(function() {		
		changeAPIInstance();
	});
});
function setConfirmationPopUps(){
	$('[data-toggle="confirmation"]').confirmation({
		onConfirm: function(event,element) { popupConfirmed(element); }
	});	
}
function addAPIKey(){
	$.ajax({
		type: 'GET',
		url: '/?t=k.GenerateAPI_Key&numKeys=' + numKeys,
		dataType: 'html',
		timeout: 1000,
		success: function(result) {
			$("#api_keys > tbody:last").append(result);
			numKeys++;
		},
		failure: function() {
			$("#api_keys > tbody:last").append("<tr><td colspan='4'>Sorry there was an error</td></tr>");
		}
	});
	
}
function saveAPIKey(key, number){
	accessSelect = $("#accessSelect_" + number);
	siteText = $("#siteInput_" + number).val();
	keyRow = $("#apikey_" + number);
		
	$.ajax({
		type: 'POST',
		url: '/?t=k.SaveAPI_Key',
		dataType: 'html',
		data:{
			api_key: key,
			access_level: accessSelect.val(),
			site: siteText,
			numKeys: number
		},
		timeout: 1000,
		success: function(result) {
			accessText = $("#accessSelect_" + number + " option:selected").text();
			keyRow.html(result);
			accessColumn = $("#accessLevel_"+ number);
			siteColumn = $("#site_"+ number);
			accessColumn.html(accessText);
			siteColumn.html(siteText);
			setConfirmationPopUps();
		},
		failure: function() {
			
		}
	});
}
function popupConfirmed(object){
	eval(object.attr("onConfirm"));
}
function deleteAPIKey(key){
	$.ajax({
		type: 'POST',
		url: '/?t=k.DeleteAPI_Key',
		dataType: 'html',
		data:{
			api_key: key,
		},
		timeout: 1000,
		success: function(result) {
			location.reload();
		},
		failure: function() {
			location.reload();
		}
	});
}
function toggleProductFilterList(menuID){
	$("#data" + menuID).toggle();
	
	if(!$("#data" + menuID).is(':visible')){
		//$("#sign" + menuID).attr("src","/images/landing_page/plus.png");
	}else{
		//$("#sign" + menuID).attr("src","/images/landing_page/minus.png");
	}
}
function saveNewInstance(){
	$.ajax({
		type: 'POST',
		url: '/?t=a.SaveNewInstance',
		dataType: 'html',
		data:{
			name: $("#addCompanyName").val(),
			address: $("#addCompanyAddress").val(),
			city: $("#addCompanyCity").val(),			
			zip: $("#addCompanyZip").val(),
			state: $("#addCompanyState").val(),
			website: $("#addCompanyWebSite").val()
		},
		timeout: 1000,
		success: function(result) {
			location.reload();
		},
		failure: function() {
			location.reload();
		}
	});	
}
function updateAccount(){
	$.ajax({
		type: 'POST',
		url: '/?t=a.SaveAccountInfo',
		dataType: 'html',
		data:{
			name: $("#shop_name").val(),
			address: $("#shop_address").val(),
			city: $("#shop_city").val(),			
			zip: $("#shop_zip").val(),
			state: $("#shop_state").val(),
			website: $("#shop_website").val(),
			cart_callback: $("#cart_callback").val(),
			color1: $("#color1").val(),
			color2: $("#color2").val(),
			color3: $("#color3").val()
		},
		timeout: 1000,
		success: function(result) {
			$("#save-status").fadeIn().delay(3000).fadeOut();
		},
		failure: function() {
			
		}
	});	
}
function changeAPIInstance(){
	$.ajax({
		type: 'POST',
		url: '/?t=a.ChangeAPIInstance',
		dataType: 'html',
		data:{
			shop_id:$("#currentAPIInstance option:selected").val(),
			shop_name: $("#currentAPIInstance option:selected").text()
		},
		timeout: 1000,
		success: function(result) {			
			location.reload();
		},
		failure: function() {
			location.reload();
		}
	});	
}
function isNumber(n) {
	return !isNaN(parseFloat(n)) && isFinite(n);
}