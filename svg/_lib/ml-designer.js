	var yt,tt,bt; 							//to reference text elements to use with text input boxes
	var myDesigns,backDesigns; 				//to hold JSON containing info for all designs (parsed form XML)
	var designList=[]; 						//holds the mylDesign objects for the design pick list
	var backDesignList=[]; 					//holds the mylDesign objects for the design pick list
	var backDesignListCart=[];				//holds the mylDesign objects used when picking a back design from the cart
	var refreshInProgress=false; 			//flag so that I know all designs in process of being updated
	var cancelRefresh=false; 				//flag so design refresh can be cancelled if in progress
	var selectedProduct=''; 				//productid of selected product
	var selectedDC1=''; 					//currently selected design color name
	var selectedDC2=''; 					//currently selected design color 2 name
	var selectedDC1Hex='';  				//currently selected design color hex
	var selectedDC2Hex='';  				//currently selected design color 2 hex
	var currentDesign,currentBackDesign; 	//Index of selected design from front or back design list
	var currentFrontDesignId,currentBackDesignId; // design id for current design used in the cart
	var viewShown=1; 						//1 front, 2 back
	var zoomState=0; 						//0=zoomed out, 1 = zoomed in
	var zoomInProgress=false; 
	var currentPrice=0;
	var skus={}; 							//skuids and prices populated by including code
	var	skuids=[]; 							//array of skuids populated by including code
	var topTextEdited=false;				//has topText been edited? (if it has then new text will be used when setting front design)
	var bottomTextEdited=false;				//has bottomText been edited?
	var yearTextEdited=false;
	var nameTextEdited=false;
	var numberTextEdited=false;
	var discounts=[]; 						//array of discounts
	var minDiscountLevel; 					//smallest qty that qualifies for discount
	var bulkShown=0; 						//whether bulk pricing shown;
	var bulkBackText=[]; 					//array to keep up with text boxes for text for bulk backdesigns
	var numBackBoxes=0;
	var singleSize=false;					// set to true in setSizes() if the product is a single size product	
	var sizePremRange='';  					//holds range of premimum sizes eg 2XL - 6XL
	var currentActivityId=0;				
	var url="";								//url to get XML for front designs; base_designs_url is set in the calling CFM file
	var backurl="";							//url to get XML for back designs; base_backurl is set in the calling CFM file
	var urlParams={};						
	var dm='';
	var backdm='';
	var zoomDm='';
	var backZoomDM='';								
	var products={};
	var backproducts={};
	var customizations={};
	var selectToggle=1;						//Flash step select boxes (used to flash them if add to cart pressed and values not selected)
	var selectState=1; 						//State of sku qty select boxes (used to flash them if add to cart pressed and values not selected)
	var borderToggle=1;						//Used to flash bulk qty box
	var bulkBorderState=1;					//Used to flash bulk qty box
	var frontHasNameNum=false;				//True if at least one front design has team name/num
	var initialLoadDone=false;
	var isBulkEnabled=false;				//True if ready for bulk ordering
	var inputTimeout=null;
	var zoomOutOnClose=false;				//Used to zoom back out if we zoom in when we edit text or design colors
	var cartView='single';					//"single"=single size, "multiple"=multiple sizes, "roster"=roster entry
	var multipleSizesBlockMaxHeight=0;		//Used when toggling between single and multiple size cart views
	var isPriceDetailVisible=false;
	var arrCartRows=[];						//Array of cart row objects holding sku,qty,name,number
	var tQuantity=0;						//current total quantity used by add-to-cart
	var globalCValues;						// initial color values passed through url.c parameter (can be blank/empty)
	var globalTValues;						// initial text-field values passed through url.t parameter (can be blank/empty)
	var designsLoading=false;				// set true while loading designs, to keep from changing activity while designs are still being built
	var thumbSize=90;
	var zmScaleNormal="scale(0.32)";		// this should match the initial number for the scale set in the div's style 
	var zmScaleZoomed="scale(1.01)";		// DO NOT set this to 1.0 because it won't match when toggling
	var touchControls=false;
	var sportNameChoices=[];
	var personalizationNameChoices=[];
	var cartRowCount=0;						// Always contains the number of ADDITIONAL cart rows to help with tab key control
	var isExtActSelector=false;				// will be true if the external activity selector is displayed

//globalHideBulk - To Use, figure out how to test, probably just set default to 1

	if (typeof globalIsDev == "undefined") { globalIsDev = 0; }
	if (globalSkuPrice == "" || globalSkuPrice == "0.00") { isBulkEnabled = false; }

	function svginit(evt) {
		// do any initialization things here
		SVGRoot = document.getElementById('svg');
	}

	//This could change, not sure how the url is going to look
	//example: http://dev.mylocker.net/my/shop/yoyo/product-2010-2000-DarkChocolate_2283_22.html?hideBulk=1
	function setStage() {	//// CALLED FROM DOCUMENT ONLOAD
		setSizes();
		setDiscounts();
		setPrice();

		var topText 		= document.getElementById('toptext');
		var bottomText 		= document.getElementById('bottomtext');
		var yearText 		= document.getElementById('yeartext');
		var nameText 		= document.getElementById('teamname');
		var numberText 		= document.getElementById('teamnum');
		var cartSField 		= document.getElementById('cS');
		var cartQField 		= document.getElementById('cQ');
		var cartNameText 	= document.getElementById('cart-name-field-0');
		var cartNumberText 	= document.getElementById('cart-number-field-0');
		var btnMoreProducts	= document.getElementById('swap-product');

		cartSField.onkeydown = function(e) {
			cartTabControl(this,e);
		};
		cartQField.onkeydown = function(e) {
			cartTabControl(this,e);
		};
		cartNameText.onkeydown = function(e) {
			cartTabControl(this,e);
		};
		cartNumberText.onkeydown = function(e) {
			cartTabControl(this,e);
		};
		topText.onclick = function() {
			this.select();
		};
		topText.onkeyup = function() {
			topTextEdited = true;
		    clearTimeout(inputTimeout);
		    inputTimeout = setTimeout(refreshActiveFront, 500, {topText : this.value});
		};
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			topText.onblur = function() {
				wtn(this);
			};
		} else {
			topText.onkeydown = function(e) {
				kd(this,e);
			};
		}
		bottomText.onclick = function() {
			this.select();
		};
		bottomText.onkeyup = function() {
			bottomTextEdited = true;
		    clearTimeout(inputTimeout);
		    inputTimeout = setTimeout(refreshActiveFront, 500, {bottomText : this.value});
		};
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			bottomText.onblur = function() {
				wtn(this);
			};
		} else {
			bottomText.onkeydown = function(e) {
				kd(this,e);
			};
		}
		yearText.onclick = function() {
			this.select();
		};
		yearText.onkeyup = function() {
			yearTextEdited = true;
		    clearTimeout(inputTimeout);
		    inputTimeout = setTimeout(refreshNameOrNumber, 500, {yearText : this.value});
		};
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			yearText.onblur = function() {
				wtn(this);
			};
		} else {
			yearText.onkeydown = function(e) {
				kd(this,e);
			};
		}
		nameText.onclick = function() {
			this.select();
		};
		nameText.onkeyup = function() {
			nameTextEdited = true;
		    clearTimeout(inputTimeout);
		    inputTimeout = setTimeout(refreshNameOrNumber, 500, {teamName : this.value});
		};
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			nameText.onblur = function() {
				wtn(this);
			};
		} else {
			nameText.onkeydown = function(e) {
				kd(this,e);
			};
		}
		numberText.onclick = function() {
			this.select();
		};
		numberText.onkeyup = function() {
			numberTextEdited = true;
		    clearTimeout(inputTimeout);
		    inputTimeout = setTimeout(refreshNameOrNumber, 500, {teamNum : this.value});
		};
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			numberText.onblur = function() {
				wtn(this);
			};
		} else {
			numberText.onkeydown = function(e) {
				kd(this,e);
			};
		}
		cartNameText.onkeyup = function() {
			nameTextEdited = true;
			clearTimeout(inputTimeout);
			inputTimeout = setTimeout(refreshNameOrNumber, 500, {teamName : this.value}, true);
		};
		cartNumberText.onkeyup = function() {
			numberTextEdited = true;
			clearTimeout(inputTimeout);
			inputTimeout = setTimeout(refreshNameOrNumber, 500, {teamNum : this.value}, true);
		};
		/****** seems to cause issues with IE ***********
		nameText.onclick = function() {
			if (this.value.toUpperCase() == 'MY NAME') this.value = '';
			this.select();
		}
		*************************************************
		nameText.addEventListener("focus", function(event) {
			event.target.select();
		});
		************************************************/

		setSvgFilters(globalPrimary.substr(globalPrimary.length - 6).toUpperCase(),1,true);
		setSvgFilters(globalSecond.substr(globalSecond.length - 6).toUpperCase(),2,true);

		sportNameChoices = getSportNameChoices();
		personalizationNameChoices = getPersonalizations();

		//Check api call to see if bulk pricing should display
		if (globalHideBulk == '1') {
			document.getElementById("bulk-priceing-button").style.display = "none";
		}
		// initialize the More Products button
		if (globalSkuPrice !== '0.00' && globalHideViewMore != '1') {
			btnMoreProducts.style.display = '';
			document.getElementById('action-column').style.marginTop = '3px';
		}
		if (parent.showMenu)
			btnMoreProducts.onclick = parent.showMenu;
		else
			btnMoreProducts.onclick = showMoreProductsOverlay;


		if (!isNaN(globalDefaultActivity) && globalDefaultActivityText !== '') {
			document.getElementById('dih-activity-name').innerHTML = he.escape(globalDefaultActivityText);
		}
		
		// initialize the design ideas header
		initInternalOrExternalActivitySelector();

		// initialize passed-in colors
		initInitialColors(globalC);

		// initialize passed-in (or cookied) text values
		initInitialText(globalT);

		// initialize the print colors
		setPrintColorsNew(products['prod_'+selectedProduct].backgroundColor,true);

		// setup design URLs and load designs
		url = base_designs_url;
		url += '&frontDesignTypeId=' + products['prod_'+selectedProduct].designTypeId;
		url += '&designTypeId=' + products['prod_'+selectedProduct].designTypeId;
		url += '&productCategoryId=' + globalProdCat;

		backurl = base_backurl;
		backurl += '&frontDesignTypeId=' + products['prod_'+selectedProduct].designTypeId;

		if (docCookies.hasItem('_mldd') && honorDocCookies == '1') { //  a cookied design takes precedence because it means the visitor has selected a new design
			var cookiedDesignIDs = docCookies.getItem('_mldd').split(',');
			if (cookiedDesignIDs[globalDesignTypeID-1] !== '0') {
				url += "&d="+cookiedDesignIDs[globalDesignTypeID-1]+"&g="+docCookies.getItem('_mldg');
			}
		} else if (globalD != '') { 
			url += "&d="+globalD+"&g="+encodeURIComponent(globalG);
		}

		if (docCookies.hasItem('_mlda') && honorDocCookies == '1') {
			var activity_id = parseInt(docCookies.getItem('_mlda'));
			if (!isNaN(activity_id)) {
				document.getElementById('activityList').value = activity_id;
				url += '&activityid='+activity_id;
				currentActivityId = activity_id;
			}
		} else if (globalDefaultActivity !== '' && globalDefaultActivity !== '0') {
			if (!isNaN(globalDefaultActivity)) {
				document.getElementById('activityList').value = globalDefaultActivity;
				url += '&activityid='+globalDefaultActivity;
				currentActivityId = globalDefaultActivity;
				docCookies.setItem('_mlda',currentActivityId,null,'/');
			}
		}

		showHideColors();
		loadXMLDoc();
	}

	function showHideColors() {
		for (var i = 0; i < colConv.length; i++) {
			//split on comma, 0 = origColor, 1 = convColor
		    //alert(colConv[i]);
		}		
	}

	function kd(_this,_e) {
		var kc = _e.keyCode || _e.which;
//console && console.log(kc);
		if (kc == 9 && _e.shiftKey) {
			if (!shiftTab(_this)) _e.preventDefault();
		} else if (kc == 9) {
			if (!tab(_this)) _e.preventDefault();
		}
	}

	function shiftTab(el) {
		var hasTT = document.getElementById('topTextSpan').style.display !== 'none' ? true : false;
		var hasBT = document.getElementById('bottomTextSpan').style.display !== 'none' ? true : false;
		var hasYT = document.getElementById('yearTextSpan').style.display !== 'none' ? true : false;
		var hasNT = document.getElementById('nameTextSpan').style.display !== 'none' ? true : false;
		var hasMT = document.getElementById('numberTextSpan').style.display !== 'none' ? true : false;
		if (el.id == 'bottomtext' && hasTT) return true;
		if (el.id == 'yeartext' && (hasBT || hasTT)) return true;
		if (el.id == 'teamname' && (hasYT || hasBT || hasTT)) return true;
		if (el.id == 'teamnum' && (hasNT || hasYT || hasBT || hasTT)) return true;
		return false;
	}

	function tab(el) {
		var hasTT = document.getElementById('topTextSpan').style.display !== 'none' ? true : false;
		var hasBT = document.getElementById('bottomTextSpan').style.display !== 'none' ? true : false;
		var hasYT = document.getElementById('yearTextSpan').style.display !== 'none' ? true : false;
		var hasNT = document.getElementById('nameTextSpan').style.display !== 'none' ? true : false;
		var hasMT = document.getElementById('numberTextSpan').style.display !== 'none' ? true : false;
		if (el.id == 'teamname' && hasMT) return true;
		if (el.id == 'yeartext' && (hasNT || hasMT)) return true;
		if (el.id == 'bottomtext' && (hasYT || hasNT || hasMT)) return true;
		if (el.id == 'toptext' && (hasBT || hasYT || hasNT || hasMT)) return true;
		return false;
	}

	function gaTrackEvent(_category,_action) {
//console.log('gaTrackEvent');
		try {
			if (parent._gaq.push) {
				parent._gaq.push(['_trackEvent',_category,_action]);
			} else {
//console.log('no _gaq.push');
			}
		} catch (e) {
//console.log(e);
		}
	}

	function loadXMLDoc() {
		//see if product image has loaded to ensure we have height
		if (products['prod_'+selectedProduct].frontImg.width==0 ||  typeof backproducts['prod_'+selectedProduct]=='undefined' ? false : backproducts['prod_'+selectedProduct].frontImg.width==0){
			//if not wait 50ms and try again
			setTimeout('loadXMLDoc',50);
		}
		var xmlhttp;
		var x;
		if (window.XMLHttpRequest) {				// code for IE7+, Firefox, Chrome, Opera, Safari
	  		xmlhttp=new XMLHttpRequest();
	  	} else {									// code for IE6, IE5 - waste, because they don't support SVG anyway.
	  		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	  	}
	  	xmlhttp.addEventListener("progress", updateProgress, false);
	  	//xmlhttp.addEventListener("load", transferComplete, false);
	  	xmlhttp.addEventListener("error", transferFailed, false);
	  	xmlhttp.addEventListener("abort", transferCanceled, false);

		xmlhttp.onreadystatechange=function() {
	  		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
				x=xmlhttp.responseText;
				loadBackXMLDoc(x);
	    	}
	  	}
	  	 
		xmlhttp.open("GET",url,true);
		xmlhttp.send();
		 
	}

	function transferFailed(xmlhttpEvent) {
		//alert("Transfer Failed!");
	}

	function transferCanceled(xmlhttpEvent) {
		//alert("Transfer Canceled!");
	}

	function updateProgress(xmlhttpEvent) {
		var loaded = xmlhttpEvent.loaded;
		designsLoaded = parseInt(loaded/2500);
		document.getElementById('progress_text').innerHTML = Math.floor(designsLoaded/10)*10 + "+ designs loaded";
	}

	function transferComplete(xmlhttpEvent) {
		var x = xmlhttpEvent.responseText;
		loadBackXMLDoc(x);
	}

	function flipPanelToBack() {
		document.getElementById('fp-back').style.top="0";
		return false;
	}
	function showTextEdit(doZoom) {
		doZoom = (typeof doZoom === 'boolean') ? doZoom : true;
		if (zoomState == 0 && doZoom) {
			toggleZoom();
			zoomOutOnClose = true;
		}
		document.getElementById('fp-t').style.top="0";
		return false;
	}
	function showColorEdit() {
		if (zoomState == 0) {
			toggleZoom();
			zoomOutOnClose = true;
		}
		document.getElementById('fp-dc').style.top="0";
		return false;
	}
	function hideTextEdit() {
		if (zoomOutOnClose) {
			zoomOutOnClose = false;
			if (zoomState) toggleZoom();
		}
		document.getElementById('fp-t').style.top="110%";
		return false;
	}
	function hideColorEdit() {
		if (zoomOutOnClose) {
			zoomOutOnClose = false;
			if (zoomState) toggleZoom();
		}
		document.getElementById('fp-dc').style.top="110%";
		return false;
	}
	function showColorSelectors(_set) {
		var pct = document.getElementById('pct');
		var dct = document.getElementById('dct');
		var pcdiv = document.getElementById('fp-front');
		var dcdiv = document.getElementById('fp-dc');
		if (_set == 'product') {
			pct.className = 'cst-left cst-on';
			dct.className = 'cst-right cst-off';
			pcdiv.style.display = 'block';
			dcdiv.style.display = 'none';
		} else {
			pct.className = 'cst-left cst-off';
			dct.className = 'cst-right cst-on';
			pcdiv.style.display = 'none';
			dcdiv.style.display = 'block';
		}
	}
	function flipPanelToFront() {
		document.getElementById('fp-back').style.top="100%";
		return false;
	}

	function showDesigns() {
		document.getElementById('designer_center_section').className = " flip";
		document.getElementById('leftcol').className = " flip";
	}

	function hideDesigns() {
		document.getElementById('leftcol').className = "";
		document.getElementById('designer_center_section').className = "";
	}

	function loadBackXMLDoc(frontXML) {
//console.log(backurl);
		var xmlhttp;
		var x;
		if (window.XMLHttpRequest) {				// code for IE7+, Firefox, Chrome, Opera, Safari
	  		xmlhttp=new XMLHttpRequest();
	  	} else {									// code for IE6, IE5 - waste, because they don't support SVG anyway.
	  		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	  	}
		xmlhttp.onreadystatechange=function() {
	  		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
				x=xmlhttp.responseText;
				getDesigns(frontXML,x);
	    	}
	  	}
		xmlhttp.open("GET",backurl,true);
		xmlhttp.send();
	}

	function getDesigns(xmlString,backXmlString) {
		var parseXML;
		if (typeof window.DOMParser != "undefined") {
		   
		    parseXML = function(xmlStr) {
		        return ( new window.DOMParser() ).parseFromString(xmlStr, "text/xml");
		    };
		} else if (typeof window.ActiveXObject != "undefined" &&
		    
		       new window.ActiveXObject("Microsoft.XMLDOM")) {
		    parseXML = function(xmlStr) {
		        var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
		        xmlDoc.async = "false";
		        xmlDoc.loadXML(xmlStr);
		        return xmlDoc;
		    };
		} else {
		    throw new Error("No XML parser found");
		}
		myDesigns = parseXML(xmlString);
		myDesigns=XMLObjectifier.xmlToJSON(myDesigns);

		backDesigns = parseXML(backXmlString);
		backDesigns=XMLObjectifier.xmlToJSON(backDesigns);
		
	
		loadDesignList(myDesigns,true);
		loadBackDesignList(backDesigns);

		//setPrice();
	}

	function callCustomLogoUpload() {
		if (parent.customLogoUpload) parent.customLogoUpload(globalDesignTypeID);
		else console.log('parent.customLogoUpload function does not exist.');
	}
	
	function loadDesignList(designData,isInitialLoad) {
//console.log("Function loadDesignList...");
		isInitialLoad = (typeof isInitialLoad === 'boolean') ? isInitialLoad : false;
		var designScale 	= thumbSize / (115 + 6);	// 115 + 3 pixels padding on all sides
		var thumbImgSize 	= thumbSize - 4;			// the upload logo thumb image has 2px padding;
        var showStar 		= false;
        if (products['prod_'+selectedProduct].designTypeId == 3) showStar = true;
		var viewSettings={ //to pass paramaters to designer with desired window properties and product View Properties
			height 				: thumbSize,
			width 				: thumbSize,
			centerOffsetX 		: 0,
			centerOffsetY 		: 0,
			designOffsetX 		: 0,
			designOffsetY 		: 0,
			designScale 		: designScale,
			designRotation		: 0,
			designTypeId		: products['prod_'+selectedProduct].designTypeId,
			backgroundColor		: products['prod_'+selectedProduct].backgroundColor,
			showBackColor		: false,
			prodImgHeight		: thumbSize,
			prodImgWidth		: thumbSize,
			showStar			: showStar,
			useThumbFilters 	: true,
			forcePNGs 			: true
		};

		var mysvglist = document.getElementById('svglist');
		var myactivitylist = document.getElementById('activityList');
		var mypersonalizations = document.getElementById('personalizations');
		var design_thumb_color = dc['hex_'+globalPrimary.substr(globalPrimary.length - 6)].toLowerCase().replace(/\s/g,'-');
		var myActivityText = "";
		try {
			myActivityText = myactivitylist.options[myactivitylist.selectedIndex].innerHTML;
		} catch (e) {}

		if (myActivityText != "") myactivitylist.options[myactivitylist.selectedIndex].innerHTML = "generating designs... ";

		toggleActivitySelectDisabled();
		designsLoading=true;

		var i = 0,
			interval = setInterval(function() {
				if (myActivityText != "") {
					myactivitylist.options[myactivitylist.selectedIndex].innerHTML = "generating designs... " + parseInt(i / designData.design.length * 100) + "%";
				}

				if (globalLogoUploadThumbPosition-1 == i 
					&& globalShowLogoUploadThumb == '1'
					&& parent.customLogoUpload) {
					var myimg = document.createElement('img');
					myimg.src="/images/customLogoUploadPlaceholder.png";
					myimg.border="0";
					myimg.alt="";
					myimg.style.width=thumbImgSize + "px";
					myimg.style.height=thumbImgSize + "px";
					myimg.style.paddingLeft="2px";
					myimg.style.paddingTop="2px";
					var mya = document.createElement('a');
					mya.id="logo-upload-thumb";
					mya.href="javascript:void(0);";
					mya.tabindex="-1";
					mya.onclick=callCustomLogoUpload;
					mya.i=i;
					mya.style.textDecoration="none";
					mya.style.display="inline-block";
					mya.style.width=thumbSize+'px';
					mya.style.height=thumbSize+'px';
					mya.style.margin="3px";
					mya.className="dsgn_thumb";
					//mya.className+=" dsgn_thumb_"+design_thumb_color;
					mya.appendChild(myimg);
					mysvglist.appendChild(mya);
				}
				if (i == 1) {
					setFrontDesign(0,showFront);
				}

				if (i == designData.design.length) {
					clearInterval(interval);
					toggleActivitySelectDisabled();
					if (myActivityText != "") myactivitylist.options[myactivitylist.selectedIndex].innerHTML = myActivityText;
					designsLoading = false;
					return;
				}

				var mya = document.createElement('a');
				mya.id="adesign_"+i;
				mya.href="javascript:setFrontDesignByClick("+i+");hideDesigns();";
				mya.tabindex="-1";
				mya.i=i;
				mya.style.textDecoration="none";
				mya.style.display="inline-block";
				mya.style.width=thumbSize+'px';
				mya.style.height=thumbSize+'px';
				mya.style.margin="3px";
				mya.className="dsgn_thumb";
				mya.className+=" dsgn_thumb_"+design_thumb_color;
				/*
				mya.onmouseover = function() {
					setListBorder('design',this.i);
				}
				mya.onmouseout = function() {
					clearListBorder('design',this.i);
				}
				*/
				var mysvg=document.createElementNS("http://www.w3.org/2000/svg","svg");
				mysvg.setAttribute("id","design_"+i);
				mysvg.setAttribute("style","width:"+thumbSize+"px; height:"+thumbSize+"px;");
				mya.appendChild(mysvg);
				mysvglist.appendChild(mya);
				designList.push( new mylDesign(
										mysvglist,
										'design_'+i,
										designData.design[i],
										viewSettings,
										customizations,
										myactivitylist,
										myActivityText.replace(/&amp;/g, '&'),
										mypersonalizations,
										i,
										designData.design.length,
										'front'				)
				)
				if (designList[i].hasTeamName || designList[i].hasTeamNum) frontHasNameNum=true;
				if (isInitialLoad && (globalT !== '' || (docCookies.hasItem('_mldt') && honorDocCookies == '1')) && i==0) {
//console.log('loading special design: ');
					designList[i].drawDesign({	primary:globalPrimary.substr(globalPrimary.length - 6).toUpperCase(),
												second:globalSecond.substr(globalSecond.length - 6).toUpperCase(),
												topText: globalTValues[0],
												bottomText: globalTValues[1],
												yearText: globalTValues[2],
												teamName: globalTValues[3],
												teamNum: globalTValues[4]
											});
				} else {
					designList[i].drawDesign({	primary:globalPrimary.substr(globalPrimary.length - 6).toUpperCase(),
												second:globalSecond.substr(globalSecond.length - 6).toUpperCase(),
												topText: 'notSet',
												bottomText: 'notSet',
												yearText: globalYearText,
												teamName: globalNameText,
												teamNum: globalNumText
											});
				}
				i++;
			}, 1);

	}

	function toggleActivitySelectDisabled() {
		var act_select = document.getElementById('activityList');
		var ext_act_select 	= document.getElementById('dih-external-activity-selector-link');
		act_select.disabled = !act_select.disabled;
		if (act_select.disabled) {
			ext_act_select.onclick = "";
			ext_act_select.style.opacity = ".2";
		} else {
			ext_act_select.onclick = openDesignIdeas;
			ext_act_select.style.opacity = "1";
		}
	}

	function loadBackDesignList(designData){
//console.log("Function loadDesignList...");
		var designScale 	= thumbSize / (115 + 6);	// 115 + 3 pixels padding on all sides
		var thumbImgSize 	= thumbSize - 2;			// the upload logo thumb image has 2px padding on top & left;
		var viewSettings={ //to pass paramaters to designer with desired window properties and product View Properties
			height 				: thumbSize,
			width 				: thumbSize,
			centerOffsetX 		: 0,
			centerOffsetY 		: 0,
			designOffsetX 		: 0,
			designOffsetY 		: 0,
			designScale 		: designScale,
			designRotation		: 0,
			backgroundColor		: products['prod_'+selectedProduct].backgroundColor,
			showBackColor		: false,
			prodImgHeight		: thumbSize,
			prodImgWidth		: thumbSize,
			showStar			: false,
			useThumbFilters 	: true,
			forcePNGs 			: true
		};
		var viewSettingsCart={ //to pass paramaters to designer with desired window properties and product View Properties
			height 				: thumbSize,
			width 				: thumbSize,
			centerOffsetX 		: 0,
			centerOffsetY 		: 0,
			designOffsetX 		: 0,
			designOffsetY 		: 0,
			designScale 		: designScale,
			designRotation		: 0,
			backgroundColor		: products['prod_'+selectedProduct].backgroundColor,
			showBackColor		: false,
			prodImgHeight		: thumbSize,
			prodImgWidth		: thumbSize,
			showStar			: false,
			useThumbFilters 	: true,
			forcePNGs 			: true
		};

		var mysvglist = document.getElementById('svgbacklist');
		var backlistwrapper = document.getElementById('svgbacklist-wrapper');
		var flipBackListDisplayWrapper = false;
		if (backlistwrapper.style.display == 'none') {
			backlistwrapper.style.display = '';
			flipBackListDisplayWrapper = true;
		}
		var mysvglistc = document.getElementById('cart-svgbacklist');
		var myactivitylist = document.getElementById('activityList');
		var mypersonalizations = document.getElementById('personalizations');
		var design_thumb_color = dc['hex_'+globalPrimary.substr(globalPrimary.length - 6)].toLowerCase().replace(/\s/g,'-');

		for(var i=0;i<designData.design.length;i++){
			/******** leave this out for a minute ********************/
			var mya = document.createElement('a');
			var myac = document.createElement('a');
			mya.id = "abackdesign_"+i;
			myac.id = "abackdesignc_"+i;
			mya.href = "javascript:setBackDesign("+i+");";
			mya.tabindex = "-1";
			myac.href = "javascript:setBackDesign("+i+",showCartPageOne);";
			myac.tabindex = "-1";
			mya.i = myac.i = i;
			mya.style.textDecoration = myac.style.textDecoration = "none";
			mya.style.display = myac.style.display = "inline-block";
			mya.style.margin = myac.style.margin = "3px";
			mya.style.width = thumbSize+"px";
			mya.style.height = thumbSize+"px";
			myac.style.width = thumbSize+"px";
			myac.style.height = thumbSize+"px";
			mya.className = "dsgn_thumb dsgn_thumb_"+design_thumb_color;
			myac.className = "dsgn_thumb_cart dsgn_thumb_"+design_thumb_color;
			/*
			mya.onmouseover = function() {
				setListBorder('backdesign',this.i);
			}
			mya.onmouseout = function() {
				clearListBorder('backdesign',this.i);
			}
			*/
			var mysvg=document.createElementNS("http://www.w3.org/2000/svg","svg");
			var mysvgc=document.createElementNS("http://www.w3.org/2000/svg","svg");
			mysvg.setAttribute("id","backdesign_"+i);
			mysvgc.setAttribute("id","backdesignc_"+i);
			mysvg.setAttribute("style","width:"+thumbSize+"px; height:"+thumbSize+"px;");
			mysvgc.setAttribute("style","width:"+thumbSize+"px; height:"+thumbSize+"px;");
			mya.appendChild(mysvg);
			myac.appendChild(mysvgc);
			mysvglist.appendChild(mya);
			mysvglistc.appendChild(myac);
			/**********************************************************/
			backDesignList.push( new mylDesign(
									mysvglist,
									'backdesign_'+i,
									designData.design[i],
									viewSettings,
									customizations,
									myactivitylist,
									'',
									mypersonalizations,
									i,
									designData.design.length,
									'back'
				)
			)
			backDesignListCart.push( new mylDesign(
									mysvglistc,
									'backdesignc_'+i,
									designData.design[i],
									viewSettingsCart,
									customizations,
									myactivitylist,
									'',
									mypersonalizations,
									i,
									designData.design.length,
									'back'
				)
			)
			backDesignList[i].drawDesign({	primary:globalPrimary.substr(globalPrimary.length - 6).toUpperCase(),
											second:globalSecond.substr(globalSecond.length - 6).toUpperCase()});
			backDesignListCart[i].drawDesign({	primary:globalPrimary.substr(globalPrimary.length - 6).toUpperCase(),
												second:globalSecond.substr(globalSecond.length - 6).toUpperCase()});
		}

		if (flipBackListDisplayWrapper) backlistwrapper.style.display = 'none';
		setBackDesign(0);
	}

	function hideT() {
		document.getElementById('fp-t-t').innerHTML = '';
	}

	function showT() {
		document.getElementById('fp-t-t').innerHTML = 'CUSTOMIZE YOUR TEXT:';
	}

	function initControls(){
//console.log(arguments.callee.caller.name+': initControls()');
		document.getElementById('backViewBut').style.display='none';

		var cbt = document.getElementById('zoomDivBack');
		var cbth = document.getElementById('cbth');
		cbt.style.opacity='0';
		cbth.style.display='none';

		// show or hide the "add row" link in the cart
		if ((!dm.hasTeamName && !dm.hasTeamNum && singleSize && numBackProducts < 1) || globalSkuPrice == '0.00') {
			//document.getElementById('btn-add-to-cart').onclick = ncAddToCart;
			document.getElementById('add-row').style.display = 'none';
		} else {
			document.getElementById('add-row').style.display = '';
		} 

		// show or hide the size drop-downs based on whether it's a single size product or not
		if (singleSize) {
			//document.getElementById('ncS').style.display='none';
			var nfields = document.getElementsByClassName('cart-size-field');
			var nfLength = nfields.length;
			/* need to add a filler if we're going to remove this column
			for (var i=1; i<nfLength; i++) {
				nfields[i].style.display='none';
			}
			*/
		} else {
			//document.getElementById('ncS').style.display='inline-block';
			var nfields = document.getElementsByClassName('cart-size-field');
			var nfLength = nfields.length;
			for (var i=1; i<nfLength; i++) {
				nfields[i].style.display='inline-block';
			}
		}

		if (nfLength > 2 && document.getElementById('addback2').checked) {
			if (nfLength > 2) document.getElementById('ncWrapper').style.display = 'none';
			else document.getElementById('ncWrapper').style.display = 'block';
			document.getElementById('btn-add-to-cart').onclick = popCart;
		} else if (nfLength > 2) {
			document.getElementById('ncWrapper').style.display = 'none';
			document.getElementById('btn-add-to-cart').onclick = popCart;
		} else {
			document.getElementById('ncWrapper').style.display = 'block';
			document.getElementById('btn-add-to-cart').onclick = ncAddToCart;
		}

		// hide ALL text inputs and color selectors, we'll display the ones we need
		hideT();
		document.getElementById('topTextSpan').style.display='none';
		document.getElementById('bottomTextSpan').style.display='none';
		document.getElementById('yearTextSpan').style.display='none';
		document.getElementById('nameTextSpan').style.display='none';
		document.getElementById('numberTextSpan').style.display='none';
		document.getElementById('dc2Div').style.display='none';	
		document.getElementById('dc2TitleDiv').style.display='none';

		// hide ALL name & number inputs in the cart, we'll display the ones we need
		var nfields = document.getElementsByClassName('cart-name-field');
		var nfLength = nfields.length;
		for (var i=1; i<nfLength; i++) {
			nfields[i].style.display='none';
		}
		var nfields = document.getElementsByClassName('cart-number-field');
		var nfLength = nfields.length;
		for (var i=1; i<nfLength; i++) {
			nfields[i].style.display='none';
		}

		// show or hide design color 2
		if (typeof currentDesign !== 'undefined') {
			if (dm.numberOfColors < 2) {
				document.getElementById('dc2Div').style.display='none';	
				document.getElementById('dc2TitleDiv').style.display='none';	
			} else{
				document.getElementById('dc2Div').style.display='';	
				document.getElementById('dc2TitleDiv').style.display='';	
			}
		}

		// highlight selected design border
		if (typeof currentDesign !== 'undefined')
			setListBorder('design',currentDesign);
		if (typeof currentBackDesign !== 'undefined' && numBackProducts > 0)
			setListBorder('backdesign',currentBackDesign);

		// add back design checkbox
		if (numBackProducts > 0) {
			document.getElementById('addback-checkbox').style.display='block';
			document.getElementById('addback-checkbox-replacement').style.display='none';
		} else {
			document.getElementById('addback-checkbox').style.display='none';
			document.getElementById('addback-checkbox-replacement').style.display='block';
		}

		// setup maximum characters for name/number fields (everything has to be smaller than the default, or the default is used)
		var ttMaxCharsDefault = 100;	// top text
		var btMaxCharsDefault = 100;	// bottom text
		var ytMaxCharsDefault = 4;		// year text
		var tnMaxCharsDefault = 50;		// name
		var tmMaxCharsDefault = 3;		// number
		var ftnMaxChars = 0;
		var ftmMaxChars = 0;
		var btnMaxChars = 0;
		var btmMaxChars = 0;
		if (typeof currentDesign !== 'undefined') {
			if (dm.hasTeamName) ftnMaxChars = parseInt(dm.getTeamName().getTextMaxChars());
			if (dm.hasTeamNum) ftmMaxChars = parseInt(dm.getTeamNum().getTextMaxChars());
		}
		if (typeof currentBackDesign !== 'undefined' && document.getElementById('addback2').checked && numBackProducts > 0) {
			cbt.style.opacity = '1';
			cbth.style.display = 'block';
			if (backdm.hasTeamName) btnMaxChars = parseInt(backdm.getTeamName().getTextMaxChars());
			if (backdm.hasTeamNum) btmMaxChars = parseInt(backdm.getTeamNum().getTextMaxChars());
		}
		if (ftnMaxChars > 0 && btnMaxChars > 0) var tnMaxChars = Math.min(tnMaxCharsDefault,ftnMaxChars,btnMaxChars);
		else if (ftnMaxChars > 0) var tnMaxChars = Math.min(tnMaxCharsDefault,ftnMaxChars);
		else if (btnMaxChars > 0) var tnMaxChars = Math.min(tnMaxCharsDefault,btnMaxChars);
		else var tnMaxChars = tnMaxCharsDefault;

		if (ftmMaxChars > 0 && btmMaxChars > 0) var tmMaxChars = Math.min(tmMaxCharsDefault,ftmMaxChars,btmMaxChars);
		else if (ftmMaxChars > 0) var tmMaxChars = Math.min(tmMaxCharsDefault,ftmMaxChars);
		else if (btmMaxChars > 0) var tmMaxChars = Math.min(tmMaxCharsDefault,btmMaxChars);
		else var tmMaxChars = tmMaxCharsDefault;

		// first the cart... cart name/number inputs don't care what view we're in.
		var showCartNameFields = false;
		var showCartNumFields = false;
		if (typeof currentDesign !== 'undefined') {
			if (dm.hasTeamName) showCartNameFields = true;
			if (dm.hasTeamNum) showCartNumFields = true;
		}
		if (typeof currentBackDesign !== 'undefined' && document.getElementById('addback2').checked && numBackProducts > 0) {
			if (backdm.hasTeamName) showCartNameFields = true;
			if (backdm.hasTeamNum) showCartNumFields = true;
		}
		if (showCartNameFields) {
			var nfields = document.getElementsByClassName('cart-name-field');
			var nfLength = nfields.length;
			for (var i=1; i<nfLength; i++) {
				nfields[i].style.display='inline-block';
				if (tnMaxChars > 0) nfields[i].maxLength = tnMaxChars;
			}
		}
		if (showCartNumFields) {
			var nfields = document.getElementsByClassName('cart-number-field');
			var nfLength = nfields.length;
			for (var i=1; i<nfLength; i++) {
				nfields[i].style.display='inline-block';
				if (tmMaxChars > 0) nfields[i].maxLength = tmMaxChars;
			}
		}
		// ************ done setting cart name/number field visibility ************

		// regular text inputs
		if (viewShown == 1) { 	// front view
			document.getElementById('frontViewBut').style.display='none';
			if (numBackProducts > 0) {
				document.getElementById('backViewBut').style.display='block';
			}else{
				document.getElementById('zoomDivBackBorder').style.left="-600px";
				document.getElementById('zoomDivBack').style.left="-1200px";
			}			
			if (typeof currentDesign !== 'undefined') {
				if (dm.hasTopText) {
					showT();
					tt=dm.getTopText();
					document.getElementById('topTextSpan').style.display='';
					if (tt.getText().toLowerCase() != document.getElementById('toptext').value.toLowerCase() && topTextEdited)
						refreshActiveFront({topText: document.getElementById('toptext').value});
					else
						document.getElementById('toptext').value=tt.setTextCase(tt.getText());
					ttMaxChars = (tt.getTextMaxChars() > 0) ? Math.min(ttMaxCharsDefault,tt.getTextMaxChars()) : ttMaxCharsDefault;
					document.getElementById('toptext').maxLength = ttMaxChars;
					document.getElementById('toptext').value = document.getElementById('toptext').value.substr(0,ttMaxChars);
				}
				if (dm.hasBottomText) {
					showT();
					bt=dm.getBottomText();
					document.getElementById('bottomTextSpan').style.display='';
					if (bt.getText().toLowerCase() != document.getElementById('bottomtext').value.toLowerCase() && bottomTextEdited)
						refreshActiveFront({bottomText: document.getElementById('bottomtext').value});
					else
						document.getElementById('bottomtext').value=bt.setTextCase(bt.getText());
					btMaxChars = (bt.getTextMaxChars() > 0) ? Math.min(btMaxCharsDefault,bt.getTextMaxChars()) : btMaxCharsDefault;
					document.getElementById('bottomtext').maxLength = btMaxChars;
					document.getElementById('bottomtext').value = document.getElementById('bottomtext').value.substr(0,btMaxChars);
				}
				if (dm.hasYearText) {
					showT();
					yt=dm.getYearText();
					document.getElementById('yearTextSpan').style.display='';
					if (yt.getText().toLowerCase() != document.getElementById('yeartext').value.toLowerCase() && yearTextEdited)
						refreshActiveFront({yearText : document.getElementById('yeartext').value});
					else
						document.getElementById('yeartext').value=yt.getText();
					//ytMaxChars = (yt.getTextMaxChars() > 0) ? Math.min(ytMaxCharsDefault,yt.getTextMaxChars()) : ytMaxCharsDefault;
					var ytMaxChars = ytMaxCharsDefault;	// hard-coded to 4, because of issues trying to set it separately for yearleft and yearright
					document.getElementById('yeartext').maxLength = ytMaxChars;
					document.getElementById('yeartext').value = document.getElementById('yeartext').value.substr(0,ytMaxChars);
				}
				if (dm.hasTeamName) {
					showT();
					tn=dm.getTeamName();
					document.getElementById('nameTextSpan').style.display='';
					document.getElementById('teamname').maxLength = tnMaxChars;
					if (tn.getText().toLowerCase() != document.getElementById('teamname').value.toLowerCase()) {
						refreshActiveFront({teamName : document.getElementById('teamname').value});
					}
				}
				if (dm.hasTeamNum) {
					showT();
					tm=dm.getTeamNum();
					document.getElementById('numberTextSpan').style.display='';
					document.getElementById('teamnum').maxLength = tmMaxChars;
					if (tm.getText().toLowerCase() != document.getElementById('teamnum').value.toLowerCase()) {
						refreshActiveFront({teamNum : document.getElementById('teamnum').value});
					}
				}
			}
		} else {				// back view
			document.getElementById('backViewBut').style.display='none';
			document.getElementById('frontViewBut').style.display='block';
			if (typeof currentBackDesign !== 'undefined') {
				if (backdm.hasTeamName) {
					showT();
					tn=backdm.getTeamName();
					document.getElementById('nameTextSpan').style.display='';
					document.getElementById('teamname').maxLength = tnMaxChars;
					//document.getElementById('teamname').value=tn.setTextCase(tn.getText());
				}
				if (backdm.hasTeamNum) {
					showT();
					tm=backdm.getTeamNum();
					document.getElementById('numberTextSpan').style.display='';
					document.getElementById('teamnum').maxLength = tmMaxChars;
					//document.getElementById('teamnum').value=tm.setTextCase(tm.getText());
				}
				if (backdm.hasYearText) {
					showT();
					yt=backdm.getYearText();
					document.getElementById('yearTextSpan').style.display='';
					document.getElementById('yeartext').maxLength = ytMaxCharsDefault;
				}
			}
		}
	} 

	function wtn(blurEl) {
		/* 	iOS devices ... need this onblur to stop movement.  the arrow keys on the keyboard don't fire keydown events without this! */
		if (navigator.userAgent.toLowerCase().indexOf('ipod') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('ipad') >= 0 ||
			navigator.userAgent.toLowerCase().indexOf('iphone') >= 0) {
			if (typeof event.relatedTarget !== 'undefined' && event.relatedTarget !== null) {
				if (typeof event.relatedTarget.id === 'undefined') {
					blurEl.focus(); // stay put
				} else if (event.relatedTarget.id != 'toptext' 
						&& event.relatedTarget.id != 'bottomtext' 
						&& event.relatedTarget.id != 'yeartext'
						&& event.relatedTarget.id != 'teamname'
						&& event.relatedTarget.id != 'teamnum'
						) {
						blurEl.focus();	// stay put
				}
			}
		}
	}

	window._setProduct = function(_cat,_prod) {
		if (typeof _cat === 'undefined' || typeof _prod === 'undefined') return;
		if (_cat == '' || isNaN(_cat) || parseInt(_cat) == 0 || _prod == '' || isNaN(_prod) || parseInt(_prod) == 0) return;
		setProducts(_cat,_prod);
	}

	function setProducts(_cat,_prod) {
		if (typeof _cat === 'undefined' || typeof _prod === 'undefined') return;
		if (_cat == '' || isNaN(_cat) || parseInt(_cat) == 0 || _prod == '' || isNaN(_prod) || parseInt(_prod) == 0) return;
		if (_cat == globalProdCat) {
			if (_prod == selectedProduct) {
				return;
			} else {
				setProduct('',_prod);
				return;
			}
		}
		globalProdCat 		= _cat;
		var prod 			= new prodProxy;
		var prodViews 		= prod.getProductViewTypes(_cat); 	// ToDo: we should test this and return if it doesn't at least have 'front' in the result
		var fp 				= prod.getProduct('1',_cat,_prod,_prod);	// ToDo: we should test length before continuing
		var bp 				= prod.getProduct('2',_cat,_prod,_prod);
		var prodSizes 		= prod.getProductSizeSKUs(_prod);
		var newDesignTypeId = "";
		products 			= {};
		backproducts 		= {};
		numBackProducts 	= bp.DATA.length;
		removeAllColorSquares();
		if (bp.DATA.length) {
			var col = new Object();
			for (var i=0; i < bp.COLUMNS.length; i++) {
				col[bp.COLUMNS[i]] = i;
			}
			for (var i=bp.DATA.length-1;i>=0;i--) {
				var p = bp.DATA[i][col['PRODUCTID']];
				var prodID = 'prod_'+p;
	 			var str = "" + bp.DATA[i][col['HEXCOLOR']];
	 			var pad = "000000";
				var c1 = pad.substring(0, pad.length - str.length) + str;
				backproducts[prodID] = { 
					height 				: globalWinSize,
					width 				: globalWinSize,
					desc				: (bp.DATA[i][col['COLORDESCRSECONDARY']] !== null && bp.DATA[i][col['COLORDESCRSECONDARY']] !== '') ? bp.DATA[i][col['COLORDESCR']] + ' / ' + bp.DATA[i][col['COLORDESCRSECONDARY']] : bp.DATA[i][col['COLORDESCR']],
			 		frontImg			: new Image(),
			 		frontImgPath		: bp.DATA[i][col['DESIGNBOXEDVIEW']] !== 1 ? pip + '/' + bp.DATA[i][col['IMAGEFILENAME']].replace(/\.jpg$/,'.png') : '',
					centerOffsetX 		: bp.DATA[i][col['CENTEROFFSETX']],
					centerOffsetY 		: bp.DATA[i][col['CENTEROFFSETY']],
					designOffsetX 		: bp.DATA[i][col['DESIGNOFFSETX']],
					designOffsetY 		: bp.DATA[i][col['DESIGNOFFSETY']],
					designScale 		: bp.DATA[i][col['DESIGNSCALE']] * globalWinSize / 385,
					prodImgHeight		: 0,
					prodImgWidth		: 0,
					designRotation		: bp.DATA[i][col['DESIGNROTATION']],
					backgroundColor		: '#'+c1,
					designTypeId		: bp.DATA[i][col['DESIGNTYPEID']],
					showBackColor		: bp.DATA[i][col['DESIGNBOXEDVIEW']] == 1 ? true : false,
					showFrontImage		: false,
					prodID 				: p,
					prodName 			: bp.DATA[i][col['PRODUCTNAME']]
				};
				backproducts[prodID].frontImg.prodID = prodID;
				backproducts[prodID].frontImg.onload = function() { 
					var ls = (this.height >= this.width) ? this.height : this.width;
					backproducts[this.prodID].prodImgHeight = this.height * globalWinSize / ls; 
					backproducts[this.prodID].prodImgWidth = this.width * globalWinSize / ls; 
				};
			}
		}
		var col = new Object();
		for (var i=0; i < fp.COLUMNS.length; i++) {
			col[fp.COLUMNS[i]] = i;
		}
		for (var i=fp.DATA.length-1;i>=0;i--) {
			var p = fp.DATA[i][col['PRODUCTID']];
			var prodID = 'prod_'+p;
 			var str = "" + fp.DATA[i][col['HEXCOLOR']];
 			var pad = "000000";
			var c1 = pad.substring(0, pad.length - str.length) + str;
			var c2 = ""
			if (fp.DATA[i][col['HEXCOLORSECONDARY']] !== null) {
				var str = "" + fp.DATA[i][col['HEXCOLORSECONDARY']];
				var pad = "000000";
				c2 = pad.substring(0, pad.length - str.length) + str;
			}
			var cdesc = (fp.DATA[i][col['COLORDESCRSECONDARY']] !== null && fp.DATA[i][col['COLORDESCRSECONDARY']] !== '') ? fp.DATA[i][col['COLORDESCR']] + ' / ' + fp.DATA[i][col['COLORDESCRSECONDARY']] : fp.DATA[i][col['COLORDESCR']]
			products[prodID] = { 
				height 				: globalWinSize,
				width 				: globalWinSize,
				desc				: cdesc,
		 		frontImg			: new Image(),
		 		frontImgPath		: fp.DATA[i][col['DESIGNBOXEDVIEW']] !== 1 ? pip + '/' + fp.DATA[i][col['IMAGEFILENAME']].replace(/\.jpg$/,'.png') : '',
				centerOffsetX 		: fp.DATA[i][col['CENTEROFFSETX']],
				centerOffsetY 		: fp.DATA[i][col['CENTEROFFSETY']],
				designOffsetX 		: fp.DATA[i][col['DESIGNOFFSETX']],
				designOffsetY 		: fp.DATA[i][col['DESIGNOFFSETY']],
				designScale 		: fp.DATA[i][col['DESIGNSCALE']] * globalWinSize / 385,
				prodImgHeight		: 0,
				prodImgWidth		: 0,
				designRotation		: fp.DATA[i][col['DESIGNROTATION']],
				backgroundColor		: '#'+c1,
				designTypeId		: fp.DATA[i][col['DESIGNTYPEID']],
				showBackColor		: fp.DATA[i][col['DESIGNBOXEDVIEW']] == 1 ? true : false,
				showFrontImage		: false,
				prodID 				: p,
				prodName 			: fp.DATA[i][col['PRODUCTNAME']]
			};
			products[prodID].frontImg.prodID = prodID;
			products[prodID].frontImg.onload = function() { 
				var ls = (this.height >= this.width) ? this.height : this.width;
				products[this.prodID].prodImgHeight = this.height * globalWinSize / ls; 
				products[this.prodID].prodImgWidth = this.width * globalWinSize / ls; 
			};
			newDesignTypeId = fp.DATA[i][col['DESIGNTYPEID']];
			addColorSquare(_prod,p,fp.DATA[i][col['COLORBOX']],c1,c2,cdesc)
			/*
			if (_prod == p) {
				try {
					setProduct('',_prod);
				} catch(e) {}
			}
			*/
		}
		setProduct('',_prod); //move below if possible
		if (newDesignTypeId != globalDesignTypeID) {
			globalDesignTypeID = newDesignTypeId;
			setDesigns(); 
		} else {
			initControls();			
		}
		//showhide color here

		setPrice();
	}

	function setDesigns() {
		// setup design URLs and load them
		var aSelect = document.getElementById('activityList');
		var a = aSelect.options[aSelect.selectedIndex].value;
		var tmpurl = url;
		url = base_designs_url;
		url += '&frontDesignTypeId=' + globalDesignTypeID;
		url += '&designTypeId=' + globalDesignTypeID;
		url += '&productCategoryId=' + globalProdCat;
		url += a !== 0 ? '&activityid=' + a : '';
		designList=[];
		var designsNode = document.getElementById('svglist');
		deleteChildren(designsNode);
		reloadXMLDoc();
		url=tmpurl;

		if (numBackProducts) {
			backurl = base_backurl;
			backurl += '&frontDesignTypeId=' + globalDesignTypeID;
			reloadBackXMLDoc();
		}
	}

	function removeAllColorSquares() {
		var csDiv = document.getElementById('pcpsw');
		deleteChildren(csDiv);
		csDiv = document.getElementById('pcTiny');
		deleteChildren(csDiv);
	}

	function addColorSquare(spid,pid,src,c1,c2,cdesc) {
		var csDiv = document.getElementById('pcpsw');
		var pcTny = document.getElementById('pcTiny');

		var tinySi = document.createElement('div');
		tinySi.className = 'productColorPickSquareInner';
		if (c2 !== "") {
			tinySi.style.cssText = "border-top:14px solid #"+c1+"; border-right:14px solid #"+c2+";";
		} else { 
			tinySi.style.cssText = "border-top:14px solid #"+c1+"; border-right:14px solid #"+c1+";";
		}
		var si = document.createElement('div');
		si.className = 'pcpsi';
		if (src !== '') {
			si.style.cssText = "width:40px;height:40px;background-size:contain;background-image:url('/"+src+"');";
		}

		var to = document.createElement('div');
		to.id = "colorsquare_"+pid;
		to.pid = pid;
		to.className = (spid == pid) ? 'colorSwatch border-red' : 'colorSwatch';
		to.onclick = function() { setProduct('',this.pid) }
		to.onmouseover = function() { showColor(this,this.pid) }
		to.onmouseout = function() { hideColor(this,this.pid) }
		to.appendChild(tinySi);
		pcTny.appendChild(to);

		var so = document.createElement('div');
		so.id="pcs_"+pid;
		so.pid=pid;
		so.className = (spid == pid) ? 'cpso-on' : 'cpso';
		so.onclick = function() { setProduct('',this.pid) }
		so.appendChild(si);
		csDiv.appendChild(so);
//console.log(so);
	}

	function swapTouchControls() {
		var touchElements = ['pcDiv-al','pcDiv-ar','pcTouch','dc1Div-al','dc1Div-ar','dc1Touch','dc2Div-al','dc2Div-ar','dc2Touch'];
		var tinyElements = ['pcTiny','dc1Tiny','dc2Tiny'];
		if (touchControls) {
			for (var i = touchElements.length - 1; i >= 0; i--) {
				document.getElementById(touchElements[i]).style.display = 'none';
			};
			for (var i = tinyElements.length - 1; i >= 0; i--) {
				document.getElementById(tinyElements[i]).style.display = '';
			};
			document.getElementById('touch-control-swap').innerHTML = "Touch Friendly";
			touchControls = false;
		} else {
			for (var i = tinyElements.length - 1; i >= 0; i--) {
				document.getElementById(tinyElements[i]).style.display = 'none';
			};
			for (var i = touchElements.length - 1; i >= 0; i--) {
				document.getElementById(touchElements[i]).style.display = '';
			};
			document.getElementById('touch-control-swap').innerHTML = "Mouse Friendly";
			touchControls = true;
		}
		return false;
	}

// <div id="pcs_<cfoutput>#productid#</cfoutput>" data-pid="<cfoutput>#productid#</cfoutput>" class="cpso<cfif productid eq url.prodid>-on</cfif>" onclick="setProduct(this,<cfoutput>#productid#</cfoutput>);"><div class="pcpsi" style="<cfif colorbox neq ''>width:40px; height:40px; background-size:contain; background-image:url('/<cfoutput>#colorbox#</cfoutput>');<cfelse>border-top:40px solid #<cfoutput>#hexcolor#</cfoutput>; border-right:40px solid #<cfif hexcolorsecondary neq ''><cfoutput>#hexcolorsecondary#</cfoutput><cfelse><cfoutput>#hexcolor#</cfoutput></cfif>;</cfif>" /></div>	}

	function setSizes(){
		var prod = new prodProxy;
		var sizes=prod.getProductSizeSKUs(selectedProduct);
		var sizelist=document.getElementById('sku');
		var tmp,priceDiff;
		var sizeText='';
		var lastPremSize='';
		sizePremRange=""
		skuids=[];
		skus={};
		//clear current options from selectList
		sizelist.options.length=0;
		
		//set base price
		globalSkuPrice=currentPrice=sizes.DATA[0][2];
		
		// push the "Size:" option onto the top of the list
		if (sizes.DATA.length > 1)
			sizelist.options[sizelist.options.length] = new Option('Size:','');

		// push the sizes onto the option list
		for (var i=0;i<sizes.DATA.length;i++){
			priceDiff=0;
			
			try {
				tmp=niceSizeName(sizes.DATA[i][3]);
			} catch (e) {
				tmp="One Size";
				singleSize = true;
			}
			try {
				sizeText=shortSizeName(sizes.DATA[i][3]);
			} catch (e) {
				sizeText="OFA"
			}
			if (sizes.DATA[i][2] != currentPrice) {
				if (sizePremRange.length == 0) sizePremRange=sizeText;
				lastPremSize=sizeText;
				priceDiff=parseFloat(sizes.DATA[i][2])-parseFloat(currentPrice);
				priceDiff=priceDiff.toFixed(2);
				tmp=tmp+' (+ $'+ priceDiff.toString() +')';
			}
			//Add option
			sizelist.options[sizelist.options.length] = new Option(tmp, sizes.DATA[i][0]);
			skuids.push(sizes.DATA[i][0]);
			skus['sku_'+sizes.DATA[i][0]]={
											price:sizes.DATA[i][2],
											sizePremium:priceDiff,
											size:sizeText
										};

		}
		optionsHTML = sizelist.innerHTML;
		var sizeEls = document.getElementsByClassName('cart-size-field');
		var ncSizeEl = document.getElementById('ncS');
		ncSizeEl.innerHTML = optionsHTML;
		for (var i=1; i<sizeEls.length; i++) {
			sizeEls[i].innerHTML = optionsHTML;
		}
		sizePremRange=sizePremRange+' - '+lastPremSize;
	}

	function cloneSizeBlock() {
		var sizeNode = document.getElementById('size-row-to-clone');
		var sizeNodeClone = sizeNode.cloneNode(true);
		//sizeNodeClone.id = 'size-row-'+Math.floor(Math.random()*(9999999 - 1 + 1) + 1);
		var selNode = sizeNodeClone.getElementsByClassName('cart-size-field')[0];
		var qtyNode = sizeNodeClone.getElementsByClassName('cart-quantity-field')[0];
		var nameNode = sizeNodeClone.getElementsByClassName('cart-name-field')[0];
		var numNode = sizeNodeClone.getElementsByClassName('cart-number-field')[0];
		selNode.onkeydown = function(e) {
			cartTabControl(this,e);
		}
		qtyNode.onkeydown = function(e) {
			cartTabControl(this,e);
		}
		nameNode.onkeydown = function(e) {
			cartTabControl(this,e);
		}
		numNode.onkeydown = function(e) {
			cartTabControl(this,e);
		}
		nameNode.onkeyup = function() {
			clearTimeout(inputTimeout);
			inputTimeout = setTimeout(setPrice, 500);
		}
		numNode.onkeyup = function() {
			clearTimeout(inputTimeout);
			inputTimeout = setTimeout(setPrice, 500);
		}
		cartRowCount++;
		sizeNodeClone.id = 'cr_'+cartRowCount;
		sizeNodeClone.style.cssText = '';
		document.getElementById('sizes-block').appendChild(sizeNodeClone);
		initControls();
		setPrice();
		return false;
	}

	function deleteCpRow(node) {
		node.parentNode.removeChild(node);
		cartRowCount--;
		reAssignCartRowIds();
		initControls();
		setPrice();
		return false;
	}

	function reAssignCartRowIds() {
		/***** row[0] is the hidden clone row; row[n] is the add row button *****/
		var cartRows = document.getElementsByClassName('cp-row');
		for (var i=1; i <= cartRows.length-2; i++) {
			cartRows[i].id = 'cr_'+(i-1);
		};
	}

	function continueShopping() {
		closeCart();
		deleteAllExtraCpRows();
		setQtyToOne();
		setAddBackDesignUnchecked();
		initControls();
		setPrice();
	}

	function deleteAllExtraCpRows(recalc) {
		recalc = (typeof recalc === 'boolean') ? recalc : false;
		var cartRows = document.getElementsByClassName('cp-row');
		for (var i = cartRows.length - 2; i >= 2; i--) {
			var el = cartRows[i];
			el.parentNode.removeChild(el);
			cartRowCount--;
		};
		if (recalc) {
			initControls();
			setPrice();
		}
	}

	function setQtyToOne(recalc) {
		recalc = (typeof recalc === 'boolean') ? recalc : false;
		var qf1 = document.getElementById('cQ');
		var qf2 = document.getElementById('ncQ');
		if (qf1 !== null) { qf1.value = 1; }
		if (qf2 !== null) { qf2.value = 1; }
		if (recalc) {
			initControls();
			setPrice();
		}
	}

	function setAddBackDesignUnchecked(recalc) {
		recalc = (typeof recalc === 'boolean') ? recalc : false;
		//var cb1 = document.getElementById('addback');
		var cb2 = document.getElementById('addback2');
		//if (cb1 !== null) { cb1.checked = false; }
		if (cb2 !== null) { cb2.checked = false; }
		if (recalc) {
			initControls();
			setPrice();
		}
	}

	function cartTabControl(el,evt) {
		var kc = evt.keyCode || evt.which;
		if (kc == 9 && evt.shiftKey) {
			if (parseInt(el.parentNode.parentNode.getAttribute('id').split('_')[1]) == 0 && el.getAttribute('class') == 'cart-size-field') evt.preventDefault();
		} else if (kc == 9) {
			var hasQ = !el.parentNode.getElementsByClassName('cart-quantity-field')[0].disabled;
			var hasN = el.parentNode.getElementsByClassName('cart-name-field')[0].style.display == 'none' ? false : true;
			var hasM = el.parentNode.getElementsByClassName('cart-number-field')[0].style.display == 'none' ? false : true;
			var hasNextRow = (document.getElementById('cr_'+(parseInt(el.parentNode.parentNode.getAttribute('id').split('_')[1])+1)) == null) ? false : true;
			if (el.getAttribute('class') == 'cart-size-field') {
				if (!(hasQ || hasN || hasM || hasNextRow)) evt.preventDefault();
			} else if (el.getAttribute('class') == 'cart-quantity-field') {
				if (!(hasN || hasM || hasNextRow)) evt.preventDefault();
			} else if (el.getAttribute('class') == 'cart-name-field') {
				if (!(hasM || hasNextRow)) evt.preventDefault();
			} else if (el.getAttribute('class') == 'cart-number-field') {
				if (!hasNextRow) evt.preventDefault();
			}
		}
	}

	function niceSizeName(size){
		if (size.toUpperCase()=='XX-LARGE') return '2XL';
		if (size.toUpperCase()=='XXX-LARGE') return '3XL';
		if (size.toUpperCase()=='XXXX-LARGE') return '4XL';
		return size;
	}

	function shortSizeName(size){
		if (size.toUpperCase()=='X-LARGE') return 'XL';
		else if (size.toUpperCase()=='LARGE') return 'L';
		else if (size.toUpperCase()=='MEDIUM') return 'M';
		else if (size.toUpperCase()=='SMALL') return 'S';
		else if (size.toUpperCase()=='X-SMALL') return 'XS';
		else if (size.toUpperCase()=='XX-LARGE') return '2XL';
		else if (size.toUpperCase()=='XXX-LARGE') return '3XL';
		else if (size.toUpperCase()=='XXXX-LARGE') return'4XL';
		else if (size.substr(3,6).toUpperCase()=='MONTHS') return size.substr(0,2)+'M';
		else if (size.substr(2,6).toUpperCase()=='MONTHS') return size.substr(0,1)+'M';
		else if (size.substr(0,4).toUpperCase()=='FREE') return size.substr(5,100);
		else return size;
	}

	function setDiscounts() {
		var prod = new prodProxy;
		var discountData=prod.getProductDiscountLevels(selectedProduct);
		var prodDiscountCol=2;
		var catDiscountCol=6;
		discounts = [];
		minDiscountLevel=0;
		if (globalHideBulk == 1) {
			document.getElementById("discount-grid-border").style.display = "none";
			setDiscountText(0,'');
		}else{
			for (var i=0;i<discountData.DATA.length;i++){
				discounts.push({
					qstart : discountData.DATA[i][0],
					qend : discountData.DATA[i][1],
					discount : discountData.DATA[i][prodDiscountCol] ? discountData.DATA[i][prodDiscountCol] : (discountData.DATA[i][catDiscountCol] ? discountData.DATA[i][catDiscountCol] : 0)
				})	
				if (minDiscountLevel == 0 && discounts[i].discount > 0) minDiscountLevel=discounts[i].qstart;
			}

			setDiscountText(1,'');
		}
	}

	function setDiscountText(qty, productName) {
		var discountTitle = '<font color="black">' + productName + '</font>';
		if (getDiscount(qty) > 0) {	// we have passed the threshold for applying a discount
			discountTitle += ' <i><font class="bulk-title-extra">Add More, Save More!</font></i>';
		}else if (parseInt(minDiscountLevel) > 0) {
			discountTitle += ' <i><font class="bulk-title-extra">Bulk Discounts... Starting At Only ' + minDiscountLevel + ' Items!</font></i>';
		}

		document.getElementById('bulk-savings-start').innerHTML = discountTitle;
	}

	function getDiscount(qty){
		for(var i=0;i<discounts.length;i++){
			if (parseInt(qty) >= discounts[i].qstart && parseInt(qty) <= discounts[i].qend) return parseFloat(discounts[i].discount/100);
		}
		return 0;
	}

	function blankDiscounts() {
		document.getElementById("discount-grid-border").style.display = "none";
		document.getElementById("discount-grid-display").innerHTML = "";
	}

	function drawDiscounts() {
		var disDiscount = '<table width="100%" cellspacing="0" cellpadding="0"><tr><td align="center" width="50%"><span style="font-size:10px;font-weight:bold;color:#333333;">PIECES</span></td><td align="center" width="50%"><span style="font-size:10px;font-weight:bold;color:#333333;">PRICE EACH</span></td></tr>';
		var j = 0;
		for(var i=0;i<discounts.length;i++){
			if (minDiscountLevel <= discounts[i].qstart) {
				var discountBackColor = "#EAEAEA";
				if (j.toString().substring(-1) == "0" || j.toString().substring(-1) == "2" || j.toString().substring(-1) == "4" || j.toString().substring(-1) == "6" || j.toString().substring(-1) == "8") {
					discountBackColor = "#D3D3D3";
				}
				var disPriceVal = parseFloat(currentPrice) * (1 - parseFloat(discounts[i].discount/100));
				disDiscount += '<tr><td align="center" style="color:#333333;background-color:' + discountBackColor +';">' + discounts[i].qstart + '-' + discounts[i].qend + '</td>';
				disDiscount += '<td align="center" style="font-weight:bold;background-color:' + discountBackColor +';">$' + disPriceVal.toFixed(2) + '</td></tr>';
				j++;
			}
		}
		//Remove next 6 lines when done testing
		/*
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#D3D3D3;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#D3D3D3;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#EAEAEA;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#EAEAEA;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#D3D3D3;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#D3D3D3;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#EAEAEA;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#EAEAEA;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#D3D3D3;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#D3D3D3;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#EAEAEA;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#EAEAEA;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#D3D3D3;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#D3D3D3;">$xx</td></tr>';
		disDiscount += '<tr><td align="center" style="color:#333333;background-color:#EAEAEA;">xx-yy</td><td align="center" style="font-weight:bold;background-color:#EAEAEA;">$xx</td></tr>';
		*/
		disDiscount += '</table>';
		if (i > 0) {
			document.getElementById("discount-grid-border").style.display = "block";
			document.getElementById("discount-grid-display").innerHTML = disDiscount;
		}
		
		return 0;
	}

	function alertGraphics() {
		var alrtText = "Please confirm that you want to disable the currently active design for SVG viewers...\n\n";
		var _designData = myDesigns.design[currentDesign];
		alrtText += "Design ID: "+_designData.design_id+"\n\nGraphics Files:\n";
		for (var d=0; d < _designData.detail.length; d++) {
			if (_designData.detail[d].node_type == "graphic") {
				alrtText += _designData.detail[d].graphic_name + "\n";
			}
		}
		if (confirm(alrtText)) {
			var dz = new designProxy;
			var set= dz.setSVGStatus(_designData.design_id,0);
			if (set == 1) alert("successfully set");
			else alert("unsuccessful");
		}
	}
/*
	function toggleAddBackDesignOld(cbAddBackDesign) {
		if (cbAddBackDesign.checked) {
			if (typeof currentBackDesign === 'undefined') {
				cbAddBackDesign.checked = false;
				if (cbAddBackDesign.id == 'addback') showCartPageTwo();
			} else {
				setAddbackCheckboxes(true);
				initControls();
				setPrice();
			}
		} else {
			setAddbackCheckboxes(false);
			initControls();
			setPrice();
		}
	}
*/
	function toggleAddBackDesign(showHide) {
			if (typeof(showHide) == "object") {
				if (showHide.checked) {
					showHide = "hide";
				}
			}

			if (showHide == "hide") {
				document.getElementById('zoomDivBackBorder').style.left="-600px";
				document.getElementById('remback').style.left="20px";
				document.getElementById('addback2').checked=true;
			}else{
				document.getElementById('addback').checked=false;
				document.getElementById('addback2').checked=false;
				document.getElementById('zoomDivBackBorder').style.left="24px";
				document.getElementById('remback').style.left="-1700px";
			}


		initControls();
		setPrice();		
		/*
			Set check box to checked
			Set opacity to 0 for border
			Create another hidden div, opacity 0, Remove Back Design with checkbox checked
			Code this function to show/hide based on showHide function
			Clear history before testing
		*/

	}

	function showBack() {
//console.log("Function showBack...");

		if (zoomState==1) {
			toggleZoom();
		}
		if (isExtActSelector && globalShowActivities == '1') {
			document.getElementById('dih-external-activity-selector').style.display='none';
		} else if (globalShowActivities == '1') {
			document.getElementById('dih-internal-activity-selector').style.display='none';
		}
		document.getElementById('dih-back-designs-header').style.display='';
		document.getElementById('back-controls').style.display='';
		document.getElementById('backDesignerDiv').style.opacity=1;
		document.getElementById('designerDiv').style.opacity=0;
		document.getElementById('selectBoxes').style.display='none';
		document.getElementById('svgbacklist-wrapper').style.display='';
		document.getElementById('svglist-wrapper').style.display='none';
		viewShown=2;
		initControls();

		if (typeof currentBackDesign === 'undefined') {
			showDesigns();
		}
	}

	function showFront() {
//console.log("Function showFront...");
		document.getElementById('designer_wait').style.display='none';
		document.getElementById('some_other_div').style.display='none';
		if (zoomState==1) {
			toggleZoom();
		}
		document.getElementById('dih-back-designs-header').style.display='none';
		if (isExtActSelector && globalShowActivities == '1') {
			document.getElementById('dih-external-activity-selector').style.display='';
		} else if (globalShowActivities == '1') {
			document.getElementById('dih-internal-activity-selector').style.display='';
		}
		document.getElementById('back-controls').style.display='none';
		document.getElementById('designerDiv').style.opacity=1;
		document.getElementById('backDesignerDiv').style.opacity=0;
		document.getElementById('selectBoxes').style.display='';
		document.getElementById('svglist-wrapper').style.display='';
		document.getElementById('svgbacklist-wrapper').style.display='none';
		if (!initialLoadDone) {
			initialLoadDone=true;
		}
		viewShown=1;
		initControls();
	}

	function toggleZoom(){
		if (zoomInProgress) return;
		zoom2();
	}

	function zoom2() {
		if (zoomState == 1) {
//console.log("zooming out");
			document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_plus.png')";
			zoomState = 0;
			if (viewShown == 1) {
				document.getElementById('designerDiv').style.OTransformOrigin = "50% 50%";
				document.getElementById('designerDiv').style.OTransform = "none";
				document.getElementById('designerDiv').style.MozTransformOrigin = "50% 50%";
				document.getElementById('designerDiv').style.MozTransform = "none";
				document.getElementById('designerDiv').style.MsTransformOrigin = "50% 50%";
				document.getElementById('designerDiv').style.MsTransform = "none";
				document.getElementById('designerDiv').style.WebkitTransformOrigin = "50% 50%";
				document.getElementById('designerDiv').style.WebkitTransform = "none";
				document.getElementById('designerDiv').style.transformOrigin = "50% 50%";
				document.getElementById('designerDiv').style.transform = "none";
				setTimeout(refreshActiveFront,500);
			} else {
				document.getElementById('backDesignerDiv').style.OTransformOrigin = "50% 50%";
				document.getElementById('backDesignerDiv').style.OTransform = "none";
				document.getElementById('backDesignerDiv').style.MozTransformOrigin = "50% 50%";
				document.getElementById('backDesignerDiv').style.MozTransform = "none";
				document.getElementById('backDesignerDiv').style.MsTransformOrigin = "50% 50%";
				document.getElementById('backDesignerDiv').style.MsTransform = "none";
				document.getElementById('backDesignerDiv').style.WebkitTransformOrigin = "50% 50%";
				document.getElementById('backDesignerDiv').style.WebkitTransform = "none";
				document.getElementById('backDesignerDiv').style.transformOrigin = "50% 50%";
				document.getElementById('backDesignerDiv').style.transform = "none";
				setTimeout(refreshActiveBack,500);
			}
		} else {
			if (viewShown == 1) {
				document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_minus.png')";
				var gws 	= globalWinSize;
				var offx 	= products['prod_'+selectedProduct].designOffsetX;
				var offy 	= products['prod_'+selectedProduct].designOffsetY;
				var imgw 	= products['prod_'+selectedProduct].prodImgWidth;
				var imgh 	= products['prod_'+selectedProduct].prodImgHeight;
//console.log ("front designScale: "+products['prod_'+selectedProduct].designScale / (gws / 385));
				var ds   	= -1 * (products['prod_'+selectedProduct].designScale / (gws / 385)) + 4.1;
//console.log ("NEW designScale: "+ds);
				var rot  	= -1 * products['prod_'+selectedProduct].designRotation;
				var tx 		= -offx*imgw;
				var ty 		= -offy*imgh;
				zoomState = 1;
				document.getElementById('designerDiv').style.OTransformOrigin = "0,0";
				document.getElementById('designerDiv').style.OTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('designerDiv').style.MozTransformOrigin = "0,0";
				document.getElementById('designerDiv').style.MozTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('designerDiv').style.MsTransformOrigin = "0,0";
				document.getElementById('designerDiv').style.MsTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('designerDiv').style.WebkitTransformOrigin = "0,0";
				document.getElementById('designerDiv').style.WebkitTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('designerDiv').style.transformOrigin = "0,0";
				document.getElementById('designerDiv').style.transform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				setTimeout(refreshActiveFront,500);
			} else {
				document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_minus.png')";
				var gws 	= globalWinSize;
				var offx 	= backproducts['prod_'+selectedProduct].designOffsetX;
				var offy 	= backproducts['prod_'+selectedProduct].designOffsetY;
				var imgw 	= backproducts['prod_'+selectedProduct].prodImgWidth;
				var imgh 	= backproducts['prod_'+selectedProduct].prodImgHeight;
//console.log ("back designScale: "+backproducts['prod_'+selectedProduct].designScale / (gws / 385));
				// var ds   = -9.49 * backproducts['prod_'+selectedProduct].designScale + 8.838; // only works when globalWinSize = 250
				var ds   	= -1 * (backproducts['prod_'+selectedProduct].designScale / (gws / 385)) + 4.1;
				var rot  	= -1 * backproducts['prod_'+selectedProduct].designRotation;
				var tx 		= -offx*imgw;
				var ty 		= -offy*imgh;
				zoomState = 1;
				document.getElementById('backDesignerDiv').style.OTransformOrigin = "0,0";
				document.getElementById('backDesignerDiv').style.OTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('backDesignerDiv').style.MozTransformOrigin = "0,0";
				document.getElementById('backDesignerDiv').style.MozTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('backDesignerDiv').style.MsTransformOrigin = "0,0";
				document.getElementById('backDesignerDiv').style.MsTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('backDesignerDiv').style.WebkitTransformOrigin = "0,0";
				document.getElementById('backDesignerDiv').style.WebkitTransform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				document.getElementById('backDesignerDiv').style.transformOrigin = "0,0";
				document.getElementById('backDesignerDiv').style.transform = "scale("+ds+","+ds+") rotate("+rot+"deg) translate("+tx+"px,"+ty+"px)";
				setTimeout(refreshActiveBack,500);
			}
		}
	}

	function zoom1() {
		if (zoomState == 0) {
			zoomState = 1;
			document.getElementById('zoomDiv').style.opacity=1;
			document.getElementById('designerDiv').style.opacity=0;
			document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_minus.png')";
		} else {
			zoomState = 0;
			document.getElementById('zoomDiv').style.opacity=0;
			document.getElementById('designerDiv').style.opacity=1;
			document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_plus.png')";
		}
	}

	function zoom(){
		var frontOp=parseInt(document.getElementById('designerDiv').style.opacity*10);
		var zoomOp=parseInt(document.getElementById('zoomDiv').style.opacity*10);
		if (zoomState == 0) {
			if (zoomOp >= 10){
				zoomState=1;
				zoomInProgress=false;
				//document.getElementById('zoomButText').firstChild.innerHTML='out';
				document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_minus.png')";
				return;
			}
			document.getElementById('designerDiv').style.opacity=((frontOp-2)/10);
			document.getElementById('zoomDiv').style.opacity=((zoomOp+2)/10);
			setTimeout(zoom,10)
		//zoom in	
		} else {
			if (frontOp >= 10){
				zoomState=0;
				zoomInProgress=false;
				//document.getElementById('zoomButText').firstChild.nodeValue='in';
				document.getElementById('zoomBut').style.backgroundImage="url('btn_zoom_plus.png')";
				return;
			}
			document.getElementById('designerDiv').style.opacity=((frontOp+2)/10);
			document.getElementById('zoomDiv').style.opacity=((zoomOp-2)/10);
			setTimeout(zoom,10)
		}
	}

	function toggleMyZoom(zmDiv) {
		var is_chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;
		if (!is_chrome) {
			if (zmDiv.style.WebkitTransform == zmScaleZoomed) {
				zmDiv.style.MozTransform = zmScaleNormal;
				zmDiv.style.MsTransform = zmScaleNormal;
				zmDiv.style.OTransform = zmScaleNormal;
				zmDiv.style.WebkitTransform = zmScaleNormal;
				zmDiv.style.transform = zmScaleNormal;
			} else {
				zmDiv.style.MozTransform = zmScaleZoomed;
				zmDiv.style.MsTransform = zmScaleZoomed;
				zmDiv.style.OTransform = zmScaleZoomed;
				zmDiv.style.WebkitTransform = zmScaleZoomed;
				zmDiv.style.transform = zmScaleZoomed;
			}
		}
	}

	var clearButBorder=function(butid){
		/*
		if (butid.substr(0,1)=='f' && viewShown==1) return;
		if (butid.substr(0,1)=='b' && viewShown==2) return;
		document.getElementById(butid).setAttribute('stroke-width','0');
		*/
	};

	var setButBorder=function(butid){
		/*
		document.getElementById(butid).setAttribute('stroke-width','2');
		*/
	};

	var clearListBorder=function(blockid,designIndex) {
		if (blockid.substr(0,1) == 'b' && currentBackDesign != designIndex) {
			//document.getElementById(blockid+'_'+designIndex+'_backrect').style.stroke='black';
			if (document.getElementById('a'+blockid+'_'+designIndex) !== null)
				document.getElementById('a'+blockid+'_'+designIndex).style.borderColor="#4864a9";
		} else if (blockid.substr(0,1) != 'b' && currentDesign != designIndex) {
			//document.getElementById(blockid+'_'+designIndex+'_backrect').style.stroke='black';
			if (document.getElementById('a'+blockid+'_'+designIndex) !== null)
				document.getElementById('a'+blockid+'_'+designIndex).style.borderColor="#4864a9";
		}
	};
	
	var setListBorder=function(blockid,designIndex) {
//console.log(arguments.callee.caller.name+': setListBorder('+blockid+', '+designIndex+')');
		var lmnt = document.getElementById('a'+blockid+'_'+designIndex);
		if (lmnt !== null) {
			lmnt.style.borderColor='red';
		}
	};
	
	function popCart() {
		toggleCartPageMessages('off');
		showCartPageOne();
		if (isPriceDetailVisible) togglePriceDetail();
		document.getElementById('pop-cart').style.top='0';
	}

	function closeCart() {
		document.getElementById('pop-cart').style.top='530px';
		document.getElementById("div-btn-bulk-add-to-cart").style.display = "none";	//Added to hide add to cart image	
	}

	function showCartPageOne() {
		document.getElementById("div-btn-bulk-add-to-cart").style.display = "block"; //Added to display add to cart image				
		document.getElementById('cart-page-2').style.left='100%';
		document.getElementById('cart-page-1').style.left='0';
	}

	function showCartPageTwo() {
		if (navigator.userAgent.toLowerCase().indexOf('chrome') > -1 && navigator.userAgent.toLowerCase().indexOf('android') > -1) // Chrome-Android fucks this up if we move it left
			document.getElementById('cart-page-1').style.left='0';
		else 
			document.getElementById('cart-page-1').style.left='-100%';
		document.getElementById('cart-page-2').style.left='0';
	}


	function setActivity(s,scId,pCat) {
		var tmpurl=url;
		docCookies.setItem('_mlda',s.value,null,'/');
		url = base_designs_url;
		url += '&frontDesignTypeId=' + products['prod_'+selectedProduct].designTypeId;
		url += '&designTypeId=' + products['prod_'+selectedProduct].designTypeId;
		url += '&productCategoryId=' + globalProdCat;
		url += '&activityid='+s.value;
		currentActivityId = (s.selectedIndex > 0) ? s.options[s.selectedIndex].value : 0;
//console.log("designURL: "+url);
		setPersonalizations(s,scId,pCat);
		designList=[];
		
		var designsNode = document.getElementById('svglist');
		deleteChildren(designsNode);
		reloadXMLDoc();
		url=tmpurl;
	}

	window.externalSetActivity = function(a,atext) {
		if (!isNaN(a) && atext.length > 0) {
			if (designsLoading) {
				setTimeout(function() { externalSetActivity(a,atext);},1000);
			} 
			var tmpurl = url;
			document.getElementById('dih-activity-name').innerHTML = he.escape(decodeURIComponent(atext));
			addActivityOption(a,atext);
			url = base_designs_url;
			url += '&frontDesignTypeId=' + products['prod_'+selectedProduct].designTypeId;
			url += '&designTypeId=' + products['prod_'+selectedProduct].designTypeId;
			url += '&productCategoryId=' + globalProdCat;
			url += '&activityid=' + a;
			currentActivityId = a;
			docCookies.setItem('_mlda',currentActivityId,null,'/');
			try {
				setPersonalizations(document.getElementById('activityList'),globalScId,globalShopCategoryId);
			} catch (e) {};
			designList = [];
			var designsNode = document.getElementById('svglist');
			deleteChildren(designsNode);
			reloadXMLDoc();
			url = tmpurl; // puts it back to base_designs_url
		}
	}

	function addActivityOption(a,atext) {
		var aSelect = document.getElementById('activityList');
		var needToAddActivity = true;
		for (var i=0;i<aSelect.options.length;i++) {
			//if (aSelect.options[i].value == a && aSelect.options[i].text == atext) {
			if (aSelect.options[i].value == a) {
				aSelect.selectedIndex = i;
				needToAddActivity = false;
				break;
			}
		}
		if (needToAddActivity) {
            var opt = document.createElement('option');
            opt.value = a;
            opt.innerHTML = he.escape(decodeURIComponent(atext));
			aSelect.appendChild(opt);
			aSelect.selectedIndex = aSelect.options.length-1;
		}
	}

	function setPersonalizations(actList,scId,pCat) {
		//scId and pCat set in CFM file.
		var defaultActivity='';
		var pz = new persProxy;
		var personalizations=pz.newlist(scId,pCat,actList.value);
		var lastResort = (actList.selectedIndex > 0) ? actList.options[actList.selectedIndex].text : (globalDefaultActivityText.length > 0) ? globalDefaultActivityText : " ";

		plist=document.getElementById('personalizations');

		//Just leave default option 'Personalize it'
		plist.options.length=1;

		for (var i=0;i<personalizations.DATA.length;i++){
			if (personalizations.DATA[i][0] != 0 && personalizations.DATA[i][2]==0){
				plist.options[plist.options.length] = new Option(personalizations.DATA[i][1], personalizations.DATA[i][1]);	
			}
		}	
		if (plist.options.length == 1){
			plist.options[plist.options.length] = new Option(lastResort, lastResort);
		}
		personalizationNameChoices = getPersonalizations();
	}

	window.externalCustomLogoComplete = function(arg) {
//console.log("arg: "+arg);
		var tmpurl = url;
		url = base_designs_url;
		url += '&frontDesignTypeId=' + globalDesignTypeID;
		url += '&designTypeId=' + globalDesignTypeID;
		url += '&productCategoryId=' + globalProdCat;
		url += currentActivityId !== 0 ? '&activityid=' + currentActivityId : '';

		designList=[];
		var designsNode = document.getElementById('svglist');
		deleteChildren(designsNode);
		reloadXMLDoc();

		url = tmpurl;

		if (numBackProducts > 0) {
			backurl = base_backurl;
			backurl += '&frontDesignTypeId=' + globalDesignTypeID;
			reloadBackXMLDoc();
		} 
	}

	function reloadXMLDoc() {
		document.getElementById('progress_text').innerHTML = "Loading Designs...";
		document.getElementById('some_other_div').style.display = '';
		var xmlhttp;
		var x;
		if (window.XMLHttpRequest) {				// code for IE7+, Firefox, Chrome, Opera, Safari
	  		xmlhttp=new XMLHttpRequest();
	  	} else {									// code for IE6, IE5 - waste, because they don't support SVG anyway.
	  		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	  	}
	  	xmlhttp.addEventListener("progress", updateProgress, false);
		xmlhttp.onreadystatechange=function() {
	  		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
				x=xmlhttp.responseText;
				reLoadDesigns(x);
	    	}
	  	}
		xmlhttp.open("GET",url,true);
		xmlhttp.send();
	}

	function reLoadDesigns(xmlString) {
		var parseXML;
		if (typeof window.DOMParser != "undefined") {
		    parseXML = function(xmlStr) {
		        return ( new window.DOMParser() ).parseFromString(xmlStr, "text/xml");
		    };
		} else if (typeof window.ActiveXObject != "undefined" && new window.ActiveXObject("Microsoft.XMLDOM")) {
		    parseXML = function(xmlStr) {
		        var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
		        xmlDoc.async = "false";
		        xmlDoc.loadXML(xmlStr);
		        return xmlDoc;
		    };
		} else {
		    throw new Error("No XML parser found");
		}
		myDesigns = parseXML(xmlString);
		myDesigns=XMLObjectifier.xmlToJSON(myDesigns);

		loadDesignList(myDesigns);
	}

	function reloadBackXMLDoc() {
//console.log(backurl);
		//document.getElementById('progress_text').innerHTML = "Loading Designs...";
		//document.getElementById('some_other_div').style.display = '';
		var xmlhttp;
		var x;
		if (window.XMLHttpRequest) {				// code for IE7+, Firefox, Chrome, Opera, Safari
	  		xmlhttp=new XMLHttpRequest();
	  	} else {									// code for IE6, IE5 - waste, because they don't support SVG anyway.
	  		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	  	}
	  	xmlhttp.addEventListener("progress", updateProgress, false);
		xmlhttp.onreadystatechange=function() {
	  		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
				x=xmlhttp.responseText;
				reLoadBackDesigns(x);
	    	}
	  	}
		xmlhttp.open("GET",backurl,true);
		xmlhttp.send();
	}

	function reLoadBackDesigns(xmlString) {
		var parseXML;
		if (typeof window.DOMParser != "undefined") {
		    parseXML = function(xmlStr) {
		        return ( new window.DOMParser() ).parseFromString(xmlStr, "text/xml");
		    };
		} else if (typeof window.ActiveXObject != "undefined" && new window.ActiveXObject("Microsoft.XMLDOM")) {
		    parseXML = function(xmlStr) {
		        var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
		        xmlDoc.async = "false";
		        xmlDoc.loadXML(xmlStr);
		        return xmlDoc;
		    };
		} else {
		    throw new Error("No XML parser found");
		}
		backDesigns = parseXML(xmlString);
		backDesigns=XMLObjectifier.xmlToJSON(backDesigns);

		backDesignList=[];
		backDesignListCart=[];

		var designsNode = document.getElementById('svgbacklist');
		var cartDesignsNode = document.getElementById('cart-svgbacklist');
		deleteChildren(designsNode);
		deleteChildren(cartDesignsNode);

		loadBackDesignList(backDesigns);
	}

	function setFrontDesignByClick(designIndex) {
		if (!isNaN(designIndex)) {
			var cookiedDesignIDs=[];
			if (docCookies.hasItem('_mldd')) cookiedDesignIDs = docCookies.getItem('_mldd').split(',');
			else cookiedDesignIDs=['0','0','0','0','0'];
			cookiedDesignIDs[globalDesignTypeID-1]=myDesigns.design[designIndex].design_id;
			docCookies.setItem('_mldd',cookiedDesignIDs.toString(),null,'/');
		}
		setFrontDesign(designIndex,update_mldg);
	}

	function setFrontDesign(designIndex,callback){
//console.log("Function setFrontDesign...");
		var prevDesign=currentDesign;
		currentDesign=designIndex; //hang on to this globally
		currentFrontDesignId=myDesigns.design[designIndex].design_id;
		//clear border from previous square
		if ( typeof prevDesign != "undefined") clearListBorder('design',prevDesign);
		var prodViewSettings=products['prod_'+selectedProduct];
		var dCustomizations = designList[designIndex].customizations;
		var lCustomizations = customizations;
		lCustomizations.topText = dCustomizations.topText;
		lCustomizations.bottomText = dCustomizations.bottomText;
		if (designIndex == 0 && globalT !== '') {
			if (globalTValues[2] !== '') lCustomizations.yearText = dCustomizations.yearText;
			if (globalTValues[3] !== '') lCustomizations.teamName = dCustomizations.teamName;
			if (globalTValues[4] !== '') lCustomizations.teamNum = dCustomizations.teamNum;
		}
		//lCustomizations.yearText = dCustomizations.yearText;
		//lCustomizations.teamName = dCustomizations.teamName;
		//lCustomizations.teamNum = dCustomizations.teamNum;
		dm = new mylDesign(
				document.getElementById('svg'),
				'Designer',
				myDesigns.design[designIndex],
				prodViewSettings,
				lCustomizations,
				document.getElementById('activityList'),
				'',
				document.getElementById('personalizations')
			);
		dm.drawDesign();

		var viewSettings={ //to pass paramaters to designer with desired window properties and product View Properties
			height 				: globalWinSize,
			width 				: globalWinSize,
			centerOffsetX 		: 0,
			centerOffsetY 		: 0,
			designOffsetX 		: 0,
			designOffsetY 		: 0,
			designScale 		: 3 * globalWinSize / 385,
			designRotation		: 0,
			designTypeId		: products['prod_'+selectedProduct].designTypeId,
			backgroundColor		: products['prod_'+selectedProduct].backgroundColor,
			showBackColor		: true,
			prodImgHeight		: globalWinSize,
			prodImgWidth		: globalWinSize
		}; 

		zoomDM = new mylDesign(
				document.getElementById('zoomsvgfront'),
				'zoomFrontDesigner',
				myDesigns.design[designIndex],
				viewSettings,
				customizations,
				document.getElementById('activityList'),
				document.getElementById('personalizations')
			);
		zoomDM.drawDesign({bottomText:dm.customizations.bottomText,
							topText:dm.customizations.topText,
							yearText:dm.customizations.yearText});


		initControls();

		if (callback && typeof(callback) === "function") {
			callback(designIndex);
		}

	}

	function update_mldg(designIndex) {
		var gf = dm.isLogoDesign() ? dm.getGraphicName() : '';
		docCookies.setItem('_mldg',gf,null,'/');
	}

	//Load design passed in designer along with prodViewSettings for selectedProduct	
	function setBackDesign(designIndex,callback){
//console.log("Function setBackDesign...");
		var prevDesign=currentBackDesign;
		currentBackDesign=designIndex; //hang on to this globally
		currentBackDesignId=backDesigns.design[designIndex].design_id;
		//clear border from previous square
		if ( typeof prevDesign != "undefined") clearListBorder('backdesign',prevDesign);
		
		var prodViewSettings=backproducts['prod_'+selectedProduct];

		backdm = new mylDesign(
				document.getElementById('backsvg'),
				'BackDesigner',
				backDesigns.design[designIndex],
				prodViewSettings,
				customizations,
				document.getElementById('activityList'),
				'',
				document.getElementById('personalizations'),
				1,
				1,
				'back'
			);
		backdm.drawDesign();

		var viewSettings={ //to pass paramaters to designer with desired window properties and product View Properties
			height 				: globalWinSize,
			width 				: globalWinSize,
			centerOffsetX 		: 0,
			centerOffsetY 		: 0,
			designOffsetX 		: 0,
			designOffsetY 		: 0,
			designScale 		: 3 * globalWinSize / 385,
			designRotation		: 0,
			designTypeId		: products['prod_'+selectedProduct].designTypeId,
			backgroundColor		: products['prod_'+selectedProduct].backgroundColor,
			showBackColor		: true,
			prodImgHeight		: globalWinSize,
			prodImgWidth		: globalWinSize
		}; 

		backZoomDM = new mylDesign(
				document.getElementById('zoomsvgback'),
				'zoomBackDesigner',
				backDesigns.design[designIndex],
				viewSettings,
				backdm.customizations,
				document.getElementById('activityList'),
				document.getElementById('personalizations'),
				1,
				1,
				'back'
			);
		backZoomDM.drawDesign({	teamName : backdm.customizations.teamName,
								teamNum : backdm.customizations.teamNum});

		//document.getElementById('addback').checked = true;
		initControls();
		//setPrice();

		if (callback && typeof(callback) === "function") {
			// we ARE in the cart, and the user just selected a back design, so we want to check the addbackdesigns checkbox
			// toggleAddBackDesign(document.getElementById('addback'));
			callback(0);
		} else if (document.getElementById('teamname').value.toLowerCase() == 'my name') {
			// we are not in the cart, this is the first time a back design has been selected, or use has not entered a name, so switch to edit text view
			showTextEdit(false);
			hideDesigns();
		} else {
			hideDesigns();
		}

	}

	function setAddbackCheckboxes(val) {
		if (typeof val !== 'boolean') {
			return;
		}
		//cb1 = document.getElementById('addback');
		cb2 = document.getElementById('addback2');
		//cb1.checked = val;
		cb2.checked = val;
	}

	function refreshNameOrNumber(options,calledFromCart) {
//console && console.log("refresh name or number");
		calledFromCart = (typeof calledFromCart === 'boolean') ? calledFromCart : false;
		if (calledFromCart) {
			if (typeof options.teamName !== 'undefined') document.getElementById('teamname').value = options.teamName;
			else document.getElementById('teamnum').value = options.teamNum; 
			refreshActiveFront(options);
			refreshActiveBack(options);
			if (!document.getElementById('addback2').checked) {
				document.getElementById('addback2').checked = true;
				toggleAddBackDesign(document.getElementById('addback2'));
			}
			setPrice();
		} else {
			if (typeof options.teamName !== 'undefined') document.getElementById('cart-name-field-0').value = options.teamName;
			else if (typeof options.teamNum !== 'undefined') document.getElementById('cart-number-field-0').value = options.teamNum; 

			refreshActiveFront(options);
			refreshActiveBack(options);
			if (viewShown !== 1) {
				if (!document.getElementById('addback2').checked) {
					document.getElementById('addback2').checked = true;
					toggleAddBackDesign(document.getElementById('addback2'));
				}
			}
			//initControls();
			setPrice();
		}
	}

	function refreshActiveFront(newCustomizations,newProdViewSettings) {
//console.log("Function refreshActiveFront...");
//console.log(newProdViewSettings);
		if (typeof currentDesign !== 'undefined') {
			for (var n in newCustomizations) { 
				customizations[n] = newCustomizations[n]; 
			}
			dm.drawDesign(newCustomizations,newProdViewSettings);
			if (typeof newProdViewSettings !== 'undefined' && typeof newProdViewSettings.backgroundColor !== 'undefined') 
				zoomDM.setBackGroundColor(newProdViewSettings.backgroundColor); 
			zoomDM.drawDesign(newCustomizations);
			if (topTextEdited || bottomTextEdited || yearTextEdited || nameTextEdited || numberTextEdited) {
				var ctt = document.getElementById('toptext').value;
				var cbt = document.getElementById('bottomtext').value;
				var cyt = document.getElementById('yeartext').value;
				var cnt = document.getElementById('teamname').value;
				var cmt = document.getElementById('teamnum').value;
				var mldt = ctt+'~+_|'+cbt+'~+_|'+cyt+'~+_|'+cnt+'~+_|'+cmt;
				docCookies.setItem('_mldt',mldt,null,'/');
			}
		}
	}

	function refreshActiveBack(newCustomizations,newProdViewSettings){
//console.log("Function refreshActiveBack...");
		if (typeof currentBackDesign !== 'undefined') {
			for (var n in newCustomizations) { 
				customizations[n] = newCustomizations[n]; 
			}
			backdm.drawDesign(newCustomizations,newProdViewSettings);
			if (typeof newProdViewSettings !== 'undefined' && typeof newProdViewSettings.backgroundColor !== 'undefined') 
				backZoomDM.setBackGroundColor(newProdViewSettings.backgroundColor); 
			backZoomDM.drawDesign(newCustomizations);
		}
	}

	function showColor(clrDiv,prodid){
		document.getElementById('pcDesc').innerHTML=products['prod_'+prodid].desc;
		//clrDiv.style.border='1px solid red';
		clrDiv.className='colorSwatch border-red';
	}

	function hideColor(clrDiv,prodid){
		document.getElementById('pcDesc').innerHTML=products['prod_'+selectedProduct].desc;
		if (prodid == selectedProduct) return;
		//clrDiv.style.border='1px solid white';
		clrDiv.className='colorSwatch border-white';
	}

	function setProduct(clrDiv,prodid){
		if (zoomState == 1) zoom2();
		// turn on the spinner
		//document.getElementById('designer_wait').style.visibility='visible';

		// Set the product color description text
		document.getElementById('pcDesc').innerHTML=products['prod_'+prodid].desc;

		// Set the src in products so that the onload function will execute
		products['prod_'+prodid].frontImg.src = products['prod_'+prodid].frontImgPath;

		//Show Product Image
		document.getElementById('designerDiv').style.backgroundImage= "url('"+products['prod_'+prodid].frontImgPath+"')";

		// Do the same for back images
		if (numBackProducts > 0) {
			backproducts['prod_'+prodid].frontImg.src = backproducts['prod_'+prodid].frontImgPath;
			document.getElementById('backDesignerDiv').style.backgroundImage= "url('"+backproducts['prod_'+prodid].frontImgPath+"')";
		}
		
		if (document.getElementById('pcs_'+selectedProduct) !== null) {
			//clrDiv.className='cpso-on';
			document.getElementById('pcs_'+selectedProduct).className = "cpso";
		}

		if (document.getElementById('colorsquare_'+selectedProduct) !== null) {
			//clrDiv.className='cpso-on';
			document.getElementById('colorsquare_'+selectedProduct).className='colorSwatch border-white';
		}

		//set this product as the selected one
		selectedProduct=prodid;

		if (document.getElementById('pcs_'+selectedProduct) !== null) document.getElementById('pcs_'+selectedProduct).className = "cpso-on";

		if (document.getElementById('colorsquare_'+selectedProduct) !== null) document.getElementById('colorsquare_'+selectedProduct).className='colorSwatch border-red';

		//get the recommended text color for this product
		setPrintColorsNew(products['prod_'+selectedProduct].backgroundColor);

		if (viewShown != 1) showFront();

		var ft=null;
		var bt=null;

		function waitOnFrontImage() {
			clearTimeout(ft);

			if (products['prod_'+selectedProduct].prodImgWidth == 0) {
				ft = setTimeout(waitOnFrontImage,50);
			} else {
				refreshActiveFront({primary:customizations.primary,second:customizations.second},products['prod_'+selectedProduct]);
			}
		}

		function waitOnBackImage() {
			clearTimeout(bt);

			if (backproducts['prod_'+selectedProduct].frontImgPath != '' && backproducts['prod_'+selectedProduct].prodImgWidth == 0) {
				bt = setTimeout(waitOnBackImage,50);
			} else {
				refreshActiveBack({primary:customizations.primary,second:customizations.second},backproducts['prod_'+selectedProduct]);
			}
		}

		waitOnFrontImage();
		if (numBackProducts > 0) {
			waitOnBackImage();
		}

		setSizes();
		setDiscounts();
		
	}

	function setPrintColors(_prodColor) {
//console.log("ORIGINAL color 1: " + customizations.primary + " color 2: " + customizations.second);
		_prodColor=_prodColor.substr(_prodColor.length-6,6);
		var primContrast = contrast(_prodColor, globalPrimary.substr(4,6));
		var secoContrast = contrast(_prodColor, globalSecond.substr(4,6));
		var thirContrast = contrast(_prodColor, globalThird.substr(4,6));
		var np,ns;
		if ( globalPrimary.substr(4,6) != _prodColor && primContrast > 60 ) {
			np = globalPrimary.substr(4,6);
			if ( globalSecond.substr(4,6) != _prodColor && secoContrast > 30 ) {
				ns = globalSecond.substr(4,6);
			} else {
				ns = globalThird.substr(4,6);
			}
		} else if ( globalSecond.substr(4,6) != _prodColor && secoContrast > 60 ) {
			np = globalSecond.substr(4,6);
			if ( globalPrimary.substr(4,6) != _prodColor && primContrast > 30 ) {
				ns = globalPrimary.substr(4,6);
			} else {
				ns = globalThird.substr(4,6);
			}
		} else {
			np = globalThird.substr(4,6);
			if ( globalPrimary.substr(4,6) != _prodColor && primContrast > 30 ) {
				ns = globalPrimary.substr(4,6);
			} else {
				ns = globalSecond.substr(4,6);
			}
		}
		if (np != selectedDC1Hex) {
			try {
			document.getElementById('primary_'+customizations.primary).className='cpso';
			document.getElementById('primary_'+np).className='cpso-on';
			document.getElementById('primaryDC').innerHTML = dc['hex_'+np];
			} catch(e) {}
			customizations.primary = np;
			selectedDC1Hex = np;
			selectedDC1 = dc['hex_'+np];
		}
		if (ns != selectedDC2Hex) {
			try {
			document.getElementById('second_'+customizations.second).className='cpso';
			document.getElementById('second_'+ns).className='cpso-on';
			document.getElementById('secondDC').innerHTML = dc['hex_'+ns];
			} catch(e) {}
			customizations.second = ns;
			selectedDC2Hex = ns;
			selectedDC2 = dc['hex_'+ns];
		}
//console.log("NEW color 1: " + customizations.primary + " color 2: " + customizations.second);
	}

	function setPrintColorsNew(_prodColor,isInitialLoad) {
		var _isInitialLoad = (typeof isInitialLoad === 'boolean') ? isInitialLoad : false; 
		_prodColor=_prodColor.substr(_prodColor.length-6,6);
		if (_prodColor == '#0') _prodColor = '000000';
		var gp = globalPrimary.substr(globalPrimary.length-6,6);
		var gs = globalSecond.substr(globalSecond.length-6,6);
		var gt = globalThird.substr(globalThird.length-6,6);
		var black = '000000';
		var gray = '808285';
		var white = 'EEEEEE';
		if (globalIsDev == "1") {
			gray = '9FA5AF';
			white = 'FFFFFF';
		}
		var bc = contrast(_prodColor, black);
		var gc = contrast(_prodColor, gray);
		var wc = contrast(_prodColor, white);
		var primContrast = contrast(_prodColor, gp);
		var secoContrast = contrast(_prodColor, gs);
		var thirContrast = contrast(_prodColor, gt);
		var np,ns;	// newPrimary, newSecondary
//window.console && console.log("gp="+gp+", gs="+gs+", product="+_prodColor+", contrasts= "+primContrast+", "+secoContrast+", "+thirContrast+", "+bc+", "+gc+", "+wc);

		if ( primContrast > 60 )
			np = gp;
		else if ( secoContrast > 60 )
			np = gs;
		else if ( thirContrast > 60 )
			np = gt;
		else if ( bc > 60 )
			np = black;
		else if ( gc > 60 )
			np = gray;
		else if ( wc > 60 )
			np = white;
		else 
			np = gp; // sanity to guarantee that a color is picked

		if ( primContrast > 60 && np !== gp )
			ns = gp;
		else if ( secoContrast > 60 && np !== gs )
			ns = gs;
		else if ( thirContrast > 60 && np !== gt )
			ns = gt;
		else if ( bc > 60 && np !== black )
			ns = black;
		else if ( gc > 60 && np !== gray )
			ns = gray;
		else if ( wc > 60 && np !== white )
			ns = white;
		else 
			ns = np == gs ? gp : gs; // sanity to guarantee that a color is picked and to make sure it's not the same as np
//window.console && console.log(np+", "+ns+", "+gray);
		if (isInitialLoad && globalC != '') {
			np = globalCValues[0];
			ns = globalCValues[1];
		}
		
		setSvgFilters(np,1,false);
		setSvgFilters(ns,2,false);

		if (np != selectedDC1Hex) {
			try {
				document.getElementById('primary_'+customizations.primary).className='cpso';
				document.getElementById('primarydc_'+customizations.primary).className='colorPickSquare';
				document.getElementById('primary_'+np).className='cpso-on';
				document.getElementById('primarydc_'+np).className='colorPickSquare border-red';
				document.getElementById('primaryDC').innerHTML = dc['hex_'+np];
			} catch(e) {}
			customizations.primary = np;
			selectedDC1Hex = np;
			selectedDC1 = dc['hex_'+np];
		}
		if (ns != selectedDC2Hex) {
			try {
				document.getElementById('second_'+customizations.second).className='cpso';
				document.getElementById('seconddc_'+customizations.second).className='colorPickSquare';
				document.getElementById('second_'+ns).className='cpso-on';
				document.getElementById('seconddc_'+ns).className='colorPickSquare border-red';
				document.getElementById('secondDC').innerHTML = dc['hex_'+ns];
			} catch(e) {}
			customizations.second = ns;
			selectedDC2Hex = ns;
			selectedDC2 = dc['hex_'+ns];
		}
//console.log("NEW color 1: " + customizations.primary + " color 2: " + customizations.second);
	}

	function colorAverage(_hexValue) {
		if ( _hexValue == '660066' ) _hexValue = '330066';		// make purple be closer to black copied from flash version
		var hexChars = {};
		hexChars['0'] = 0;
		hexChars['1'] = 1;
		hexChars['2'] = 2;
		hexChars['3'] = 3;
		hexChars['4'] = 4;
		hexChars['5'] = 5;
		hexChars['6'] = 6;
		hexChars['7'] = 7;
		hexChars['8'] = 8;
		hexChars['9'] = 9;
		hexChars['A'] = 10;
		hexChars['B'] = 11;
		hexChars['C'] = 12;
		hexChars['D'] = 13;
		hexChars['E'] = 14;
		hexChars['F'] = 15;
		var a = [];
		for ( var i=0; i < _hexValue.length; i++ ) {
			a[i] = _hexValue.substr(i,1).toUpperCase();
		}
		var r = parseInt(hexChars[a[0]]) * 16 + parseInt(hexChars[a[1]]);
		var g = parseInt(hexChars[a[2]]) * 16 + parseInt(hexChars[a[3]]);
		var b = parseInt(hexChars[a[4]]) * 16 + parseInt(hexChars[a[5]]);
		var sum = r + g + b;
		var ave = Math.round(sum/3,0);
		return ave;
	}

	function contrast(_color1, _color2) {
//console.log("contrast: "+_color1+", "+_color2);
		return Math.abs(colorAverage(_color1) - colorAverage(_color2));
	}

	function initInitialColors(_globalC) {
		globalCValues=[];
		if (_globalC !== '') {
			globalCValues = _globalC.split(",");
		}
		for (var i=0; i<2; i++) {
			if (typeof globalCValues[i] == 'undefined') globalCValues[i] = '';
		}
//console.log("globalCValues: "+globalCValues.toString());
	}

	function initInitialText(_globalT) {
		globalTValues=[];
		if (docCookies.hasItem('_mldt') && honorDocCookies == '1') { // cookied values take precedence because it means you have edited something
			globalTValues = docCookies.getItem('_mldt').split('~+_|');
		} else if (_globalT !== '') {
			globalTValues = _globalT.split("~+_|");			// tt, bt, year, name, number ... separated by ~+_|
		}
		for (var i=0; i<5; i++) {
			if (typeof globalTValues[i] == 'undefined') globalTValues[i] = "";
		}
//console.log("globalTValues: "+globalTValues.toString());
	}

	function showDC1(clrDiv,clrText){
		document.getElementById('primaryDC').innerHTML=clrText;
		clrDiv.className='colorPickSquare border-red';
	}

	function hideDC1(clrDiv,clrText){
		document.getElementById('primaryDC').innerHTML=selectedDC1;
		if (clrText == selectedDC1) return;
		clrDiv.className='colorPickSquare border-white';
	}

	function setDC1(clrDiv,hex,clrText){
		if (selectedDC1==clrText) return;

		//set color description text
		document.getElementById('primaryDC').innerHTML=clrText;

		//Make border of square red
		//clrDiv.className='cpso-on';
		document.getElementById('primary_'+hex).className='cpso-on';
		document.getElementById('primarydc_'+hex).className='colorPickSquare border-red';

		//make border of previous selected square white
		document.getElementById('primary_'+selectedDC1Hex).className='cpso';
		document.getElementById('primarydc_'+selectedDC1Hex).className='colorPickSquare border-white';

		if (selectedDC2Hex == hex) {
			document.getElementById('second_'+hex).className='cpso';
			document.getElementById('seconddc_'+hex).className='colorPickSquare border-white';
			document.getElementById('second_'+selectedDC1Hex).className='cpso-on';
			document.getElementById('seconddc_'+selectedDC1Hex).className='colorPickSquare border-red';
			document.getElementById('secondDC').innerHTML = dc['hex_'+selectedDC1Hex];
			selectedDC2Hex = selectedDC1Hex;
			selectedDC2 = dc['hex_'+selectedDC1Hex];
			setSvgFilters(selectedDC2Hex,2,false);
			customizations.second=selectedDC2Hex;
		}
		//set this product as the selected one
		selectedDC1=clrText;
		selectedDC1Hex=hex;
		customizations.primary=hex;
		setSvgFilters(selectedDC1Hex,1,false);

		//redraw design in case this products image requires different parameters
		refreshActiveFront({second:customizations.second, primary:customizations.primary});
		refreshActiveBack({second:customizations.second, primary:customizations.primary});
	}

	function showDC2(clrDiv,clrText){
		document.getElementById('secondDC').innerHTML=clrText;
		clrDiv.className='colorPickSquare border-red';
	}

	function hideDC2(clrDiv,clrText){
		document.getElementById('secondDC').innerHTML=selectedDC2;
		if (clrText == selectedDC2) return;
		clrDiv.className='colorPickSquare border-white';
	}

	function setDC2(clrDiv,hex,clrText){
		if (selectedDC2==clrText) return;

		//set color description text
		document.getElementById('secondDC').innerHTML=clrText;

		//Make border of square red
		//clrDiv.className='cpso-on';
		document.getElementById('second_'+hex).className='cpso-on';
		document.getElementById('seconddc_'+hex).className='colorPickSquare border-red';

		//make border of previous selected square white
		document.getElementById('second_'+selectedDC2Hex).className='cpso';
		document.getElementById('seconddc_'+selectedDC2Hex).className='colorPickSquare border-white';

		if (selectedDC1Hex == hex) {
			document.getElementById('primary_'+hex).className='cpso';
			document.getElementById('primarydc_'+hex).className='colorPickSquare border-white';
			document.getElementById('primary_'+selectedDC2Hex).className='cpso-on';
			document.getElementById('primarydc_'+selectedDC2Hex).className='colorPickSquare border-red';
			document.getElementById('primaryDC').innerHTML = dc['hex_'+selectedDC2Hex];
			selectedDC1Hex = selectedDC2Hex;
			selectedDC1 = dc['hex_'+selectedDC2Hex];
			setSvgFilters(selectedDC1Hex,1,false);
			customizations.primary=selectedDC1Hex;
		}

		//set this product as the selected one
		selectedDC2=clrText;
		selectedDC2Hex=hex;
		customizations.second=hex;
		setSvgFilters(selectedDC2Hex,2,false);

		//redraw design in case this products image requires different parameters
		refreshActiveFront({second:customizations.second, primary:customizations.primary});
		refreshActiveBack({second:customizations.second, primary:customizations.primary});
	}

	function cpsScroll(el){
		var numColors = numDesignColors;
		var parent = el.parentNode;
		var grandparent = parent.parentNode;
		if (grandparent.getAttribute('id') == 'pcDiv') numColors = numProductColors;
		var leftarrow = el.scrollLeft > 20 ?
			document.getElementById(grandparent.getAttribute('id')+'-al').style.visibility='visible' :
			document.getElementById(grandparent.getAttribute('id')+'-al').style.visibility='hidden';
		var rightarrow = el.scrollLeft < numColors * (el.children[0].offsetWidth + 4) - el.offsetWidth - 20 ?
			document.getElementById(grandparent.getAttribute('id')+'-ar').style.visibility='visible' :
			document.getElementById(grandparent.getAttribute('id')+'-ar').style.visibility='hidden';
	}

	function cpScroll(elid,px) {
		var el = document.getElementById(elid);
		el.scrollLeft += px;
	}

	function personalizeText(s){
		document.getElementById('bottomtext').value=bt.setTextCase(s.value);
		refreshAll({bottomText : bt.setTextCase(s.value)})
	}

	function deleteChildren(elem){
		while ( typeof elem.firstChild !== "undefined" ) {
			try {
				elem.removeChild(elem.firstChild);
			} catch(e) {
				break;
			}
		}			
	}

	function ncSetPrice() {
		// size and quan changes happening on the main display
		// we need to mirror the current state of these items in row 0 of the cart display
		var cQ = document.getElementById('cQ');
		var cS = document.getElementById('cS');
		var ncQ = document.getElementById('ncQ');
		var ncS = document.getElementById('ncS');
		cQ.value = ncQ.value;
		cS.selectedIndex = ncS.selectedIndex;
		setPrice();		
	}

	function setPrice() {
		document.getElementById('price-block-totaldiscount').style.display = 'none';
		var divActionColumnPriceStrikethrough = document.getElementById('action-column-price-strikethrough');
		divActionColumnPriceStrikethrough.style.display = 'none';
		var divActionColumnPrice = document.getElementById('action-column-price');
		var acpValue = document.getElementById('acp-value');
		var divActionColumnPriceEach = document.getElementById('action-column-price-each');
		var tQuan=0,tPrice=0,tSizePremium=0,tBackPremium=0,tBackQuan=0;
		var rBasePrice = parseFloat(globalSkuPrice);
		if (rBasePrice == 0.00 || rBasePrice == 0) {
			acpValue.innerHTML = 'FREE';
			divActionColumnPriceEach.style.display = 'none';
		} else {
			acpValue.innerHTML = '$'+rBasePrice;
		}
		var rBackBasePrice = 6.95;
		var backIsLogoDesign = (backdm.isLogoDesign && typeof backdm.isLogoDesign() === 'boolean') ? backdm.isLogoDesign() : false;
		var hasBack = numBackProducts > 0 ? true : false;
		var addBack2 = document.getElementById('addback2').checked;
		var cRows = document.getElementsByClassName('cp-row');
		var cRowsLength = cRows.length-1;	// leave off the "add-row" row
		for (var i=1; i<cRowsLength; i++) {
			var rQuan = isNaN(parseInt(cRows[i].getElementsByClassName('cart-quantity-field')[0].value)) ? 1 : parseInt(cRows[i].getElementsByClassName('cart-quantity-field')[0].value) ;
			tQuan += rQuan;
		}
		var iDiscount = getDiscount(tQuan);
		for (var i=1; i<cRowsLength; i++) {
			var rQuan = isNaN(parseInt(cRows[i].getElementsByClassName('cart-quantity-field')[0].value)) ? 1 : parseInt(cRows[i].getElementsByClassName('cart-quantity-field')[0].value) ;
			var rSKU = cRows[i].getElementsByClassName('cart-size-field')[0][cRows[i].getElementsByClassName('cart-size-field')[0].selectedIndex].value;
			var rSize = cRows[i].getElementsByClassName('cart-size-field')[0][cRows[i].getElementsByClassName('cart-size-field')[0].selectedIndex].label;
			var rName = cRows[i].getElementsByClassName('cart-name-field')[0].value;
			var rNum = cRows[i].getElementsByClassName('cart-number-field')[0].value;
			var rUnitBackPremium = (hasBack && addBack2 && ((rName.length || rNum.length) || backIsLogoDesign)) ? rBackBasePrice : 0;
			var rUnitSizePremium = rSKU.length > 0 ? parseFloat(skus['sku_'+rSKU].sizePremium) : 0;
			var rUnitPrice = rBasePrice + rUnitBackPremium + rUnitSizePremium;
			var rUnitDiscounted = (1-iDiscount)*rUnitPrice;
			if (i == 1 && rBasePrice > 0) {
				document.getElementById('acps-value').innerHTML = "$"+parseFloat(rUnitPrice).toFixed(2).toString();
				document.getElementById('acp-value').innerHTML = "$"+parseFloat(rUnitDiscounted).toFixed(2).toString();
			}
			if (rUnitPrice !== rUnitDiscounted) {
				if (i == 1) divActionColumnPriceStrikethrough.style.display = '';
				cRows[i].getElementsByClassName('cart-price-field')[0].innerHTML = "<span style=\"color:red;text-decoration:line-through;\"><span style=\"color:#444;\">$"+parseFloat(rUnitPrice).toFixed(2).toString()+"</span></span><span style=\"color:red;font-weight:bold;padding-left:7px;\">$"+parseFloat(rUnitDiscounted).toFixed(2).toString()+"</span>";
			} else {
				cRows[i].getElementsByClassName('cart-price-field')[0].innerHTML = "<span>$"+parseFloat(rUnitDiscounted).toFixed(2).toString()+"</span>";
			}
			var rTotal = rUnitPrice * rQuan;
			var rTotalBackPremium = rUnitBackPremium * rQuan;
			var rBackQuan = (rUnitBackPremium == 0) ? 0 : rQuan;
			var rTotalSizePremium = rUnitSizePremium * rQuan;
			tPrice += rTotal;
			tSizePremium += rTotalSizePremium;
			tBackPremium += rTotalBackPremium;
			tBackQuan += rBackQuan;
			var passProdName = he.escape(products['prod_'+selectedProduct].prodName);
		}
		//Check the quantity, if greater than 6 change red text
		var tDiscount = tPrice * iDiscount;
		var oTotal = tPrice - tDiscount;
		var oSizePremium = tSizePremium;
		var oSizePremiumDiscounted = (1-iDiscount)*tSizePremium;
		var oBackPremium = tBackPremium;
		var oBackPremiumDiscounted = (1-iDiscount)*tBackPremium;
		var rBasePriceDiscounted = (1-iDiscount)*rBasePrice;
		var rBackBasePriceDiscounted = (1-iDiscount)*rBackBasePrice;
		setDiscountText(tQuan, passProdName);
		blankDiscounts();
		drawDiscounts();

		document.getElementById('back-base-price').innerHTML = parseFloat(rBackBasePriceDiscounted).toFixed(2).toString();
		document.getElementById('back-base-price2').innerHTML = parseFloat(rBackBasePriceDiscounted).toFixed(2).toString();

		//document.getElementById('quantity-total').innerHTML = tQuan.toString(); //To Remove

		//document.getElementById('price-each').innerHTML = parseFloat((1-iDiscount)*globalSkuPrice).toFixed(2).toString(); //To Remove

		//document.getElementById('size-premium').innerHTML = parseFloat(oSizePremiumDiscounted).toFixed(2).toString(); //To Remove

		//document.getElementById('back-premium').innerHTML = parseFloat(oBackPremiumDiscounted).toFixed(2).toString(); //To Remove
		document.getElementById('back-premium-bottom').innerHTML = parseFloat(oBackPremiumDiscounted).toFixed(2).toString();
		//document.getElementById('quan-back-designs').innerHTML = tBackQuan.toString(); //To Remove
		document.getElementById('quan-back-designs-bottom').innerHTML = tBackQuan.toString();
		if (!numBackProducts) document.getElementById('price-block-backpremium').style.display = 'none';
		else document.getElementById('price-block-backpremium').style.display = '';

		//document.getElementById('total').innerHTML = parseFloat(tPrice).toFixed(2).toString(); //To Remove

		//document.getElementById('total-discount').innerHTML = parseFloat(tDiscount).toFixed(2).toString(); //To Remove
		if (tDiscount > 0) document.getElementById('price-block-totaldiscount').style.display = '';
		if (tDiscount > 0) {
			document.getElementById('you-save').style.display = 'block';
			document.getElementById('you-save-val').innerHTML = '$' + parseFloat(tDiscount).toFixed(2).toString();
		}else{
			document.getElementById('you-save').style.display = 'none';
		}


		//document.getElementById('order-total').innerHTML = parseFloat(oTotal).toFixed(2).toString(); //To Remove
		document.getElementById('order-total-bottom').innerHTML = parseFloat(oTotal).toFixed(2).toString();

		var cQ = document.getElementById('cQ');
		var cS = document.getElementById('cS');
		var ncQ = document.getElementById('ncQ');
		var ncS = document.getElementById('ncS');
		ncQ.value = cQ.value;
		ncS.selectedIndex = cS.selectedIndex;
	}

	function togglePriceDetail() {
		if (isPriceDetailVisible) {
			document.getElementById('cart-page-cover').style.display = 'none';
			document.getElementById('toggle-price-detail').className = "v-triangle-down";
			document.getElementById('price-block').style.height = '75px';
		} else {
			document.getElementById('cart-page-cover').style.display = '';
			document.getElementById('toggle-price-detail').className = "v-triangle-up";
			document.getElementById('price-block').style.height = '275px';
		}
		isPriceDetailVisible = !isPriceDetailVisible;
	}

	function ncAddToCart() {
		if (ncVerifySizeQtyNameNumber()) {
			popCart();
			//document.getElementById('atc').click();
			addToCart();
		}
		return false;
	}

	function addToCart() {
		if (verifySizeQtyNameNumber()) {
			submitCart();
			document.getElementById("div-btn-bulk-add-to-cart").style.display = "none";	//Added to hide add to cart image
		} else {
			toggleCartPageMessages('on');
		}
		return false;
	}

	function submitCart() {
		document.getElementById('cartPopup').style.display='block';
		document.getElementById('cartPopupOverlay').style.display='block';
//console.log(arrCartRows);
		var pId = selectedProduct;
		var dId = currentFrontDesignId;
		var bdId = (document.getElementById('addback2').checked && numBackProducts) ? currentBackDesignId : '';
//console.log("bdid: "+bdId);
		var tt=document.getElementById('toptext').value;
		var bt=document.getElementById('bottomtext').value;
		var yt=document.getElementById('yeartext').value;
		var cp1=selectedDC1Hex;
		var cp2=selectedDC2Hex;
		var ce1=cp2;
		var ce2=cp1;
		var gf = dm.isLogoDesign() ? dm.getGraphicName() : '';
		var bgf='';
		if (bdId) bgf = backdm.isLogoDesign() ? backdm.getGraphicName() : '';
//console.log("bgf: "+bgf);
		var arrProductDiscountLevels=discounts;
		function cartProxyCallback(retval) {
//console.log(retval);
			if (typeof retval == 'object') {
				// update cart display on the parent
				if (parent.updateCartDisplay) parent.updateCartDisplay(retval.CART_TOTAL_ITEMS,retval.CART_TOTAL_PRICE);

				if (globalSkuPrice == "" || globalSkuPrice == "0.00") window.parent.location=globalCartHost+'/showcart.cfm?sc_id='+globalScId+'&redirecFlag=1';


				document.getElementById('cartPopup').style.display='none';
				document.getElementById('cartPopupOverlay').style.display='none';
				toggleCartPageMessages('on');
				showCartErrorMessage('cart-submit-message');
			} else {
				showCartErrorMessage('cart-submit-message');
				//document.getElementById('divCartMessage').innerHTML = '<p>There was an error adding your item(s) to your cart.</p>';
				//document.getElementById('divCartMessage').innerHTML += '<p>You can close this message, and try again.</p>';
			}
		};

		// In the CFC, call the addToCartMobile() method.
		var pcCart = new cartProxy;
		pcCart.setCallbackHandler(cartProxyCallback);
		pcCart.setHTTPMethod("POST");

		var addToCart = pcCart.AddToCartMobile(	arrProductDiscountLevels,
												arrCartRows,
												pId,
												dId,
												bdId,
												tt,
												bt,
												yt,
												gf,
												cp1,
												cp2,
												ce1,
												ce2,
												tQuantity,
												globalScId,
												bgf
											);
	}

	function showCartErrorMessage(element) {
		document.getElementById('single-size-error').style.display = 'none';
		document.getElementById('multiple-size-error').style.display = 'none';
		document.getElementById('name-number-error').style.display = 'none';
		document.getElementById('cart-submit-message').style.display = 'none';
		var el = document.getElementById(element);
		if (typeof el === 'object') el.style.display = 'inline-block';
		toggleCartPageMessages('on');
	}

	function ncVerifySizeQtyNameNumber() {
		var rSizeField = document.getElementById('ncS');
		var rQuanField = document.getElementById('ncQ');
		var rSKU = rSizeField[rSizeField.selectedIndex].value;
		var rQuan = isNaN(rQuanField.value) ? 1 : parseInt(rQuanField.value);
		if (!rSKU.length) {
			flashSelect('ncS');
			rSizeField.style.border = '1px solid red';
			rSizeField.onfocus = function() { this.style.border = ''; };
			return false;
		}
		return true;
	}

	function verifySizeQtyNameNumber() {
		document.getElementById('single-size-error').style.display = 'none';
		document.getElementById('multiple-size-error').style.display = 'none';
		document.getElementById('name-number-error').style.display = 'none';
		document.getElementById('cart-submit-message').style.display = 'none';

		var sizeError = 0;
		var nameOrNumberError = 0;
		var cRows = document.getElementsByClassName('cp-row');
		var cRowsLength = cRows.length-1;	// leave off the "add-row" row
		arrCartRows.length = 0;				// clear the array of cart row information
		tQuantity = 0;
		for (var i=1; i<cRowsLength; i++) {
			var rQuanField = cRows[i].getElementsByClassName('cart-quantity-field')[0];
			var rSizeField = cRows[i].getElementsByClassName('cart-size-field')[0];
			var rNameField = cRows[i].getElementsByClassName('cart-name-field')[0];
			var rNumberField = cRows[i].getElementsByClassName('cart-number-field')[0];
			var rQuan = isNaN(rQuanField.value) ? 1 : parseInt(rQuanField.value);
			var rSKU = rSizeField[rSizeField.selectedIndex].value;
			var rSize = rSizeField[rSizeField.selectedIndex].label;
			var rName = rNameField.value;
			var rNum = rNumberField.value;
			var objCartRow={quan: 	rQuan,
							sku: 	rSKU,
							name: 	rName,
							num: 	rNum};
			arrCartRows.push(objCartRow);
			tQuantity += rQuan;
			if (!rSKU.length) {
				rSizeField.style.border='1px solid red';
				rSizeField.onfocus = function() { this.style.border = ''; };
				sizeError += 1;
			}
			if (!rName.length && rNameField.style.display !== 'none') {
				rNameField.style.border = '1px solid red';
				rNameField.onfocus = function() { this.style.border = ''; };
				nameOrNumberError += 1;
			}
			if (!rNum.length && rNumberField.style.display !== 'none') {
				rNumberField.style.border = '1px solid red';
				rNumberField.onfocus = function() { this.style.border = ''; };
				nameOrNumberError += 1;
			}
		}
		if (sizeError) {
			if (sizeError == 1) document.getElementById('single-size-error').style.display = 'inline-block';
			else document.getElementById('multiple-size-error').style.display = 'inline-block';
		} else if (nameOrNumberError) {
			document.getElementById('name-number-error').style.display = 'inline-block';
		}
		if (sizeError || nameOrNumberError) return false;
		return true;
	}

	function toggleCartPageMessages(s) {
		s = typeof s !== 'undefined' ? s : 'off';
		var cartPageMessages = document.getElementById('cart-page-messages');
		if (s == 'on') cartPageMessages.style.display = 'block';
		else cartPageMessages.style.display = 'none';
	}
	
	function hideBulk(){
		bulkShown=0;
		document.getElementById('bulkCartSummary').style.display='none';
		document.getElementById('bulkSizeQtyInputs').style.display='none';
		document.getElementById('bulkSizeChartLink').style.display='none';
		document.getElementById('step5').style.display='';
		document.getElementById('cartSummary').style.display='';
		document.getElementById('divSingleNameNum').style.display='';
		document.getElementById('bulk').style.display='none';
		document.getElementById('bulkBack').style.display='none';
		if (viewShown == 2)
			document.getElementById('frontlink2').style.display='';
		if (viewShown == 2 || (numBackProducts < 1 && (dm.hasTeamNum || dm.hasTeamName)))
			if (isBulkEnabled) document.getElementById('addMore').style.display='';
		if (numBackProducts < 1) 
			initControls();
		setTimeout(toggleBulkBorder,100);
	}

	function showBulk(){
		bulkShown=1;
		document.getElementById('step5').style.display='none';
		document.getElementById('cartSummary').style.display='none';
		document.getElementById('divSingleNameNum').style.display='none';
		document.getElementById('addMore').style.display='none';
		document.getElementById('frontlink2').style.display='none';
		document.getElementById('bulkCartSummary').style.display='';
		document.getElementById('bulk').style.display='';
		document.getElementById('bulkSizeQtyInputs').style.display='';
		document.getElementById('bulkSizeChartLink').style.display='';
		if (viewShown == 2 || (numBackProducts < 1 && (dm.hasTeamNum || dm.hasTeamName))) 
			document.getElementById('bulkBack').style.display='';
		if (numBackProducts < 1) 
			initControls();
		setTimeout(toggleBulkBorder,100);
	}

	function toggleBulkBorder(){
		if (bulkBorderState==1) {
			hideBulkBorder();
			borderToggle+=1;
		}
		else{
			showBulkBorder();
			borderToggle+=1;	
		}
		if (borderToggle < 7) setTimeout(toggleBulkBorder,100);
		else borderToggle=1;
	}
	function showBulkBorder(){
			document.getElementById('bulkborder').style.border='1px solid #d9d9d9';	
			document.getElementById('bulktext').style.color='#d9d9d9';
			bulkBorderState=1;	
	}
	function hideBulkBorder(){
			document.getElementById('bulkborder').style.border='1px solid transparent';
			document.getElementById('bulktext').style.color='transparent';
			bulkBorderState=0;	
	}
	function focusBulkText(t){
		if (t.value=='0') t.value='';
		t.select();
		if (bulkBorderState==1){
			//hideBulkBorder();
		}
		//document.getElementById('bulkMin').style.display='none';
	}
	function blurBulkText(t){
		if(!String.prototype.trim) {
			String.prototype.trim = function () {
		    	return this.replace(/^\s+|\s+$/g,'');
		  	};
		}
		if (!t.value.trim().length) t.value = '0';
	}
	function processBulk(index){
		t=document.getElementById('bulksizeQty_'+index);
		t.value=t.value.replace(/[^\d]/,'')
		if (bulkBorderState==1){
			//hideBulkBorder();
		}
		//document.getElementById('bulkMin').style.display='none';
		updateBackText(index);
		setPrice();
	}
	function updateBackText(index){
		var newBulkBackText=[];
		var j,sizediv,cursize,d,a,numrows;
		//determine which boxes have qty and build an array that show what text boxes we should have
		for (var i=0;i<8;i++){
			cursize=document.getElementById('bulksizeQty_'+i)
			if (cursize != null) {
				if (cursize.value.length && cursize.value !== "0") {
					var sizeAbbr=document.getElementById('bulksizeTitle_'+i).innerHTML;
					//Show div for this size in case not already shown
					sizediv=document.getElementById('bulkBackRow_'+i);
					if (sizediv.children.length < cursize.value){
						numrows=cursize.value-sizediv.children.length
						for (j=0;j<numrows;j++){
							d=document.createElement('div');
							a='<div class="bulkBackDiv" style="width:22px"><input class="bulktext" style="width:22px" name="bulkBackSize_'+ numBackBoxes +'" id="bulkBackSize_'+ numBackBoxes +'" type="text" value="'+ sizeAbbr +'" readonly="readonly"/></div>';
							a+='<div class="bulkBackDiv" style="width:117px"><input class="bulktext" style="width:117px" name="bulkBackName_'+ numBackBoxes +'" id="bulkBackName_'+ numBackBoxes +'" type="text" onkeyup="/*this.value=tn.setTextCase(this.value);*/refreshNameOrNumber({teamName : this.value});/*refreshActiveFront({teamName : this.value});*/setPrice()"/></div>';
							a+='<div class="bulkBackDiv" style="width:39px"><input class="bulktext" style="width:39px" name="bulkBackNum_'+ numBackBoxes +'" id="bulkBackNum_'+ numBackBoxes +'" type="text" onkeyup="/*this.value=tm.setTextCase(this.value);*/refreshNameOrNumber({teamNum : this.value});/*refreshActiveFront({teamNum : this.value});*/setPrice()"/></div>';
							d.innerHTML=a;
							sizediv.appendChild(d);
							/*
							if (viewShown==1){
								if (!dm.hasTeamNum) document.getElementById('bulkBackNum_'+ numBackBoxes).style.display='none';
								if (!dm.hasTeamName) document.getElementById('bulkBackName_'+ numBackBoxes).style.display='none';
							}
							else{
								if (!backdm.hasTeamNum) document.getElementById('bulkBackNum_'+ numBackBoxes).style.display='none';
								if (!backdm.hasTeamName) document.getElementById('bulkBackName_'+ numBackBoxes).style.display='none';
							}
							*/
							numBackBoxes+=1;
						}
					}
					else if (sizediv.children.length > cursize.value){
						numrows=sizediv.children.length-cursize.value;
						for (j=0;j<numrows;j++) {
							var removedNode = sizediv.removeChild(sizediv.lastChild);
							if (removedNode != null) numBackBoxes-=1;
						}
					}
				} else {
					sizediv=document.getElementById('bulkBackRow_'+i);
					deleteChildren(sizediv);
				}
			}
		}
	}

	function toggleCartView() {
		if (cartView == 'single') {
			document.getElementById('single-size-block').className = '';
			document.getElementById('multiple-sizes-block').style.maxHeight = multipleSizesBlockMaxHeight+'px';
			document.getElementById('cart-view-toggle').innerHTML = 'Single Size Order';
			cartView = 'multiple';
			return false;
		}
		if (cartView == 'multiple') {
			document.getElementById('single-size-block').className = 'expanded';
			document.getElementById('multiple-sizes-block').style.maxHeight = '0';
			document.getElementById('cart-view-toggle').innerHTML = 'Order Multiple Sizes or Use A Roster';
			cartView = 'single';
			return false;
		}
	}

	function verifySizeNQty(){
		///Make sure size and qty selected
		if (bulkShown == 0){
			if (document.getElementById('sku').value==''){
				flashSelect('sku');
				return false;	
			}
			else if (document.getElementById('qty').value==''){
				flashSelect('qty');
				return false;	
			}
		}
		else if (bulkShown == 1){
			var qtyFound=false;
			for (var i=0;i<17;i++){
				cursize=document.getElementById('bulksizeQty_'+i)
				if (cursize.value.length && cursize.value != 0){
					qtyFound=true;
					break;
				}		
			}
			if (!qtyFound){
				setTimeout(toggleBulkBorder,100);
				return false;
			}
		}
		return true;
	}				

	function flashSelect(s){
		if (selectToggle < 7){
			if (selectState == 1) {
				document.getElementById(s).style.backgroundColor='red';	
				selectState=2;
			}
			else {
				document.getElementById(s).style.backgroundColor='white';	
				selectState=1;
			}
			selectToggle++
			setTimeout('flashSelect("'+s+'")',100);
		}
		else selectToggle=1;
	}

	function initInternalOrExternalActivitySelector() {
		var divExternalActivitySelector = document.getElementById('dih-external-activity-selector');
		var divInternalActivitySelector = document.getElementById('dih-internal-activity-selector');
		var aExternalActivitySelector 	= document.getElementById('dih-external-activity-selector-link');
		if (externalActivitySelector() && globalSkuPrice !== '0.00' && globalShowActivities == '1' && globalScId == '0') {
			isExtActSelector = true;
			divExternalActivitySelector.style.display = 'block';
			divInternalActivitySelector.style.display = 'none';
			if (globalShowActivities == '1') aExternalActivitySelector.style.display = 'block';
			else aExternalActivitySelector.style.display = 'none';
		} else if (globalShowActivities == '1') {
			divExternalActivitySelector.style.display = 'none';
			divInternalActivitySelector.style.display = 'block';
		}
	}

	function externalActivitySelector() {
		retval = false;
		if (window.parent.$) {
			if (window.parent.$('#activity_selector_overlay').overlay) {
				if (window.parent.$('#activity_selector_overlay').overlay().load) {
					retval = true;
				}
			}
		}
		return retval;
	}

	function openDesignIdeas() {
		if (externalActivitySelector()) window.parent.toggleDesignIdeas();
		else console.log('External function does not exist.');
	}

	function showMoreProductsOverlay() {
		document.getElementById('chooseProduct').style.display='';
		document.getElementById('chooseProductOverlay').style.display='';
	}

	var getSportNameChoices = function() {
	//['Football','Baseball','Soccer','Hockey'];
		var s = [];
		try {
			var l = document.getElementById('activityList');
			if (l.options.length > 1) {
				for (var i=1;i<l.options.length;i++) {
					s.push(l.options[i].text);
				}
			}
		} catch(e) {}
		if (!s.length) {
			s = ['Football','Baseball','Soccer','Hockey'];
		}
		return s;
	}

	var getPersonalizations = function() {
	//['Aunt','Dad','Mom','Uncle'];
		var s = [];
		try {
			var l = document.getElementById('personalizations');
			if (l.options.length > 1) {
				for (var i=1;i<l.options.length;i++) {
					s.push(l.options[i].text);
				}
			}
		} catch(e) {}
		if (!s.length) {
			s = ['Aunt','Dad','Mom','Uncle'];
		}
		return s;
	}

	function setSvgFilters(hex,c,t) {
	    t = (typeof t === 'boolean') ? t : false;
	    var feTintValues    = "";
	    var feSolidValues   = "";
	    var amt             = 1;
	    var r               = hexToRgb(hex).r / 255;
	    var g               = hexToRgb(hex).g / 255;
	    var b               = hexToRgb(hex).b / 255;

	    feSolidValues = "0 0 0 0 "+r+" 0 0 0 0 "+g+" 0 0 0 0 "+b+" 0 0 0 1 0";

	    var m = colorize(r,g,b,amt);
	    for (var i=0; i<m.length; i++) {
	        feTintValues += m[i];
	        if (i + 1 < m.length) {
	            feTintValues += " ";
	        }
	    }

	    if (!isNaN(c)) {
	        var fids = { solid : 'c'+c+'sm', tint  : 'c'+c+'tm' }
	        if (t) {
	        	fids.solid += '_thumb';
	        	fids.tint += '_thumb';
	        }
	        document.getElementById(fids.solid).setAttribute("values",feSolidValues);
	        document.getElementById(fids.tint).setAttribute("values",feTintValues);
	    }
	}

	function colorize(r,g,b, amount) {
	    var LUMA_R          = 0.212671;     // RGB to Luminance conversion constants as found on
	    var LUMA_G          = 0.71516;      // Charles A. Poynton's colorspace-faq:
	    var LUMA_B          = 0.072169;     // http://www.faqs.org/faqs/graphics/colorspace-faq/
	    var im = [1,0,0,0,0,
	              0,1,0,0,0,
	              0,0,1,0,0,
	              0,0,0,1,0];               // we will be colorizing this starting from an identity matrix
	    var inv_amount      = (1 - amount);
	    return concat([(inv_amount + ((amount * r) * LUMA_R)), ((amount * r) * LUMA_G), ((amount * r) * LUMA_B), 0, 0, 
	    		((amount * g) * LUMA_R), (inv_amount + ((amount * g) * LUMA_G)), ((amount * g) * LUMA_B), 0, 0, 
	    		((amount * b) * LUMA_R), ((amount * b) * LUMA_G), (inv_amount + ((amount * b) * LUMA_B)), 0, 0, 
	    		0, 0, 0, 1, 0],im);
	}

	function concat(mat,im) {
	    var temp = [];
	    var i = 0;
	    for (var y=0; y<4; y++) {
	        for (var x=0; x<5; x++) {
	            temp[ parseInt(i + x) ] =   parseFloat(mat[i  ]) * parseFloat(im[x]) + 
	                                        parseFloat(mat[parseInt(i+1)]) * parseFloat(im[parseInt(x +  5)]) + 
	                                        parseFloat(mat[parseInt(i+2)]) * parseFloat(im[parseInt(x + 10)]) + 
	                                        parseFloat(mat[parseInt(i+3)]) * parseFloat(im[parseInt(x + 15)]) +
	                                        (x == 4 ? parseFloat(mat[parseInt(i+4)]) : 0);
	        }
	        i+=5;
	    }
	    return temp;
	}

	function hexToRgb(hex) {
	    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
	    return result ? {
	        r: parseInt(result[1], 16),
	        g: parseInt(result[2], 16),
	        b: parseInt(result[3], 16)
	    } : {
	    	r: 255,
	    	g: 255,
	    	b: 255
	    };
	}
