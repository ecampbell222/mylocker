$(function(){  
	$('.tree li:has(ul)').addClass('parent_li').find(' > span').attr('title', 'Expand this branch');
	setDesignsTree();	
	$("#myUploadedDesigns").click(function(){
		SaveShowMyUploads();
	});
	if($("#myUploadedDesigns").prop('checked')){
		$("#design-selection").toggle();
	}
});

function addCustom(catid, catcustid, iscustom) {
	if (catid == "" && catcustid == "") {
		var divID = "AddCustCat";
	}else{
		var divID = "AddCustAct" + "_" + catid + "_" + catcustid;
	}	
	var categoryName = $.trim($("#txt" + divID).val());
	if (categoryName == "") {
		alert('Please enter a category name');
	}else{
		$.ajax({
			type: 'POST',
			url: '/?t=d.AddCustom',
			dataType: 'html',
			data:{
				cat_id: catid,
				cat_cust_id: catcustid,
				is_custom: iscustom,
				category_name:categoryName
			},
			timeout: 30000,
			success: function(result) {
				if ($.trim(result) == "dup") {
					alert('The category name you chose already exists.');
				}else{
					top.location.href = "/?t=d.designs";
				}
			},
			failure: function() {
				
			}
		});
	}
}

function deleteCustom(catid, catcustid, activityid, iscustom) {
	$.ajax({
		type: 'POST',
		url: '/?t=d.DeleteCustom',
		dataType: 'html',
		data:{
			cat_id: catid,
			cat_cust_id: catcustid,
			activity_id: activityid,
			is_custom: iscustom
		},
		timeout: 30000,
		success: function(result) {
			top.location.href = "/?t=d.designs";
		},
		failure: function() {
			
		}
	});
}

function setCustomTextbox(divID, cat_id, cat_cust_id, is_custom) {
	if (divID == "AddCustCat") {
		var passDivID = divID
		var passVal = "'','',''";
	}else{
		var passDivID = divID + "_" + cat_id + "_" + cat_cust_id;
		var passVal = "'" + cat_id + "','" + cat_cust_id + "','" + is_custom + "'";
	}
	if ($("#spn" + passDivID).html().trim().indexOf("Add Custom Category") > 0 || $("#spn" + passDivID).html().trim().indexOf("Add Custom Activity") > 0) {
		var newTextbox = '<input type="text" id="txt' + passDivID + '" value="" maxlength="50" style="width:140px;" />';
		newTextbox += ' &nbsp;<button type="button" class="btn btn-sm btn-primary" onclick="javascript:addCustom(' + passVal + ');" data-toggle="modal">Add</button>';
		$("#spn" + passDivID).html(newTextbox);
		$("#txt" + passDivID).focus();
		$("#txt" + passDivID).keypress(function(event){
			var keycode = (event.keyCode ? event.keyCode : event.which);
			if(keycode == '13'){
				if (divID == "AddCustCat") {
					addCustom('','','');
				}else{
					addCustom(cat_id, cat_cust_id, is_custom);
				}
			}
		});		
	}
}
function SaveShowMyUploads(){
	$("#design-selection").toggle();
	
	$.ajax({
		type: 'POST',
		url: '/?t=s.SaveShowMyUploads',
		dataType: 'html',
		data:{
			myDesignsOnly: $("#myUploadedDesigns").prop('checked')
		},
		timeout: 30000,
		success: function(result) {
			$("#myUploadedDesignsSaved").html(result);
			$("#myUploadedDesignsSaved").fadeIn('slow', function(){
				$("#myUploadedDesignsSaved").fadeOut(3600);
			});
			
		},
		failure: function() {
			
		}
	});	
}
function loadActivities(shopid, catid, catidcust, iscustom, list){
	$.ajax({
		type: 'POST',
		url: '/?t=d.LoadActivities',
		dataType: 'html',
		data:{
			shop_id: shopid,
			cat_id: catid,
			cat_id_cust: catidcust,
			is_custom: iscustom,
			list_type: list
		},
		timeout: 30000,
		success: function(result) {
			$("#" + list + "_group_"+catid+"_"+catidcust+"_"+iscustom).html(result);
			$('.tree li.parent_li > span').unbind( "click" );
			setDesignsTree();
			setConfirmationPopUps();
		},
		failure: function() {
			
		}
	});	
}
function addToMyDesigns(shopid, data1, data2, data3, iscustom, plevel, catcust){
	$.ajax({
		type: 'POST',
		url: '/?t=d.AddDesigns',
		dataType: 'html',
		data:{
			shop_id: shopid,
			pdata1: data1,
			pdata2: data2,
			pdata3: data3,
			is_custom: iscustom,
			level: plevel,
			cat_cust: catcust
		},
		timeout: 30000,
		success: function(result) {
			if ($.trim(result) == "noact") {
				alert('You cannot add a category with 0 activities.');
				top.location.href = "/?t=d.designs";
			}else{
				$(".my-designs").html(result);
				setConfirmationPopUps();
				setDesignsTree();
				$("#no-designs-info").hide();
			}
		},
		failure: function() {
			
		}
	});
}

function deleteDesign(shopid, catid, catidcust, pdata, plevel, iscustom){
	//alert(catid + "," + catidcust + "," + pdata + "," + plevel + "," + iscustom);
	$.ajax({
		type: 'POST',
		url: '/?t=d.DeleteDesigns',
		dataType: 'html',
		data:{
			shop_id: shopid,
			cat_id: catid,
			cat_id_cust: catidcust,
			data: pdata,
			level: plevel,
			is_custom: iscustom			
		},
		timeout: 30000,
		success: function(result) {
			$(".my-designs").html(result);
			setDesignsTree();
			setConfirmationPopUps();
		},
		failure: function() {
			
		}
	});
}
function setDesignsTree(){
	$('.tree li.parent_li > span').click(function (e) {
	    var children = $(this).parent('li.parent_li').find(' > ul > li');
	    if (children.is(":visible")) {
	        children.hide('fast');
	        $(this).attr('title', 'Expand this branch').find(' > i').addClass('glyphicon-folder-close').removeClass('glyphicon-folder-open');
	    } else {
	        children.show('fast');
	        $(this).attr('title', 'Collapse this branch').find(' > i').addClass('glyphicon-folder-open').removeClass('glyphicon-folder-close');
	 
	        if ($(this).attr('data-loaded') == 0){
		        if ($(this).attr('data-level') == "group"){
		        	loadActivities($(this).attr('data-shop'), $(this).attr('data-item2'), $(this).attr('data-item3'), $(this).attr('data-custom'), $(this).attr('data-list'));
		        	$(this).attr('data-loaded','1');
		        } 
	        }
	    }
	    e.stopPropagation();
	});
	$(".mylocker-designs span").draggable({
		addClasses: true,
		// Chrome has problems with displaying dragged
		// element when appendTo is default "body"
		appendTo : ".lock",
		helper : "clone",
		appendTo: "body"
	});
	$(".my-designs").droppable({
		addClasses: true,
		activeClass : "listActive",
		//hoverClass : "listHover",
		accept : ":not(.ui-sortable-helper)",
		drop : function(event, ui) {
			if (ui.draggable.attr('data-level') != "custom") {
				$(this).find(".placeholder").remove();			
				var list = $("<li class='parent_li'></li>").html(ui.draggable.html());
				$(list).appendTo(this);
				addToMyDesigns(ui.draggable.attr('data-shop'), ui.draggable.attr('data-item'), ui.draggable.attr('data-item2'), ui.draggable.attr('data-item3'), ui.draggable.attr('data-custom'), ui.draggable.attr('data-level'), ui.draggable.attr('data-cat-custom'));
			}
		}
	})
}