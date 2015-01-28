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
function addToMyDesigns(shopid, catid, catidcust, iscustom, plevel){
	$.ajax({
		type: 'POST',
		url: '/?t=d.AddDesigns',
		dataType: 'html',
		data:{
			shop_id: shopid,
			cat_id: catid,
			cat_id_cust: catidcust,
			is_custom: iscustom,
			level: plevel
		},
		timeout: 30000,
		success: function(result) {
			$(".my-designs").html(result);
			setConfirmationPopUps();
			setDesignsTree();
			$("#no-designs-info").hide();
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
		        	loadActivities($(this).attr('data-shop'), $(this).attr('data-item'), $(this).attr('data-item2'), $(this).attr('data-custom'), $(this).attr('data-list'));
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
			$(this).find(".placeholder").remove();			
			var list = $("<li class='parent_li'></li>").html(ui.draggable.html());
			$(list).appendTo(this);
			addToMyDesigns(ui.draggable.attr('data-shop'), ui.draggable.attr('data-item'), ui.draggable.attr('data-item2'), ui.draggable.attr('data-custom'), ui.draggable.attr('data-level'));
		}
	})
}