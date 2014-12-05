<!--testing-->
<cfcontent type="application/xhtml+xml" /><?xml version="1.0"?>
<cfsilent>
	<cfset adminIps = "12.160.24.66" />			<!--- separate multiple ip addresses by commas --->
	<!--- configure js proxies for commonly used components --->
	<cfajaxproxy jsclassname="prodProxy" cfc="com.products.product" />
	<cfajaxproxy jsclassname="persProxy" cfc="com.mylocker.personalization" />
	<cfajaxproxy jsclassname="cartProxy" cfc="cart.cart" />
	<cfajaxproxy jsclassname="designProxy" cfc="com.designs.design" />

	<cfparam name="url.prodid" 						default="1" />
	<cfparam name="url.category" 					default="1" />
	<cfparam name="url.sc_id" 						default="MI4809166422" />
	<cfparam name="url.shop_category_id" 			default="32" />
	<cfparam name="url.prodid1" 					default="0" />
	<cfparam name="url.prodid2" 					default="0" />
	<cfparam name="url.prodid3" 					default="0" />
	<cfparam name="url.prodid4" 					default="0" />
	<cfparam name="url.prodid5" 					default="0" />
	<cfparam name="url.prodid6" 					default="0" />
	<cfparam name="url.prodid7" 					default="0" />
	<cfparam name="url.prodid8" 					default="0" />
	<cfparam name="url.prodid9" 					default="0" />
	<cfparam name="url.prodid10" 					default="0" />
	<cfparam name="url.primary" 					default="0xFF000000" />
	<cfparam name="url.second" 						default="0xFFFEBD11" />
	<cfparam name="url.third" 						default="0xFFCED6D2" />
	<cfparam name="url.school" 						default="Farragut" />
	<cfparam name="url.initials" 					default="FHS" />
	<cfparam name="url.defaultActivity" 			default="0" />
	<cfparam name="url.defaultActivityText" 		default="" />
	<cfparam name="url.showActivities" 				default="1" />
	<cfparam name="url.showPersonalize" 			default="1" />
	<cfparam name="url.yearSel" 					default="2012" />
	<cfparam name="url.bottomtext" 					default="Admirals" />
	<cfparam name="url.mascot" 						default="Admirals" />
	<cfparam name="url.skuprice" 					default="" />
	<cfparam name="url.design_type_id" 				default="1" />
	<cfparam name="url.p" 							default="" />				<!--- product id default (NOT USED) --->
	<cfparam name="url.d" 							default="" />				<!--- design id default --->
	<cfparam name="url.c" 							default="" />				<!--- design color defaults delimited by , --->
	<cfparam name="url.t" 							default="" />				<!--- design text-field defaults delimited by ~+_| --->
	<cfparam name="url.g" 							default="" />				<!--- graphic file default --->
	<cfparam name="url.showLogoUploadThumb" 		default="0" />
	<cfparam name="url.logoUploadThumbPosition" 	default="1" />
	<cfparam name="url.honorDocCookies" 			default="0" />				<!--- 0 = DO NOT honor cookies for activity, design-id, text, etc. --->
	<cfparam name="url.mapping_school" 				default="" />
	<cfparam name="url.mapping_state" 				default="" />
	<cfparam name="url.mapping_city" 				default="" />
	<cfparam name="url.fullSizeProductImagesOnly"	default="1" />
	<cfparam name="url.qs"							default="" />

	<!--- fix missing colors --->
	<cfif len(url.primary) neq 10 or len(url.second) neq 10>
		<cfset url.primary = "0xFF000000" />
		<cfset url.second = "0xFFFEBD11" />
		<cfset url.third = "0xFFCED6D2" />
	</cfif>

	<!--- datasource --->
	<cfset dsn = "cwdbsql" />

	<!--- domain and protocol settings --->
	<!--- <cfset dPrefix = Left(CGI.SERVER_NAME,3) /> --->
	<cfset dPrefix = listFirst(CGI.SERVER_NAME,".") />
	<cfset ht = "http" />
	<cfif CGI.SERVER_PORT eq "443">
		<cfset ht = "https" />
	</cfif>
	<cfif dPrefix eq "dev">
		<cfset cartHost = "http://dev.mylocker.net" />
		<cfset mylDesign = "_lib/mylDesign.js?v=1.7" />
		<cfset dbmobile = "_lib/ml-designer.js?v=4.5" />
	<cfelse>
		<cfset cartHost = "https://www.mylocker.net" />
		<cfset mylDesign = "_lib/mylDesign-min.js?v=1.7" />
		<cfset dbmobile = "_lib/ml-designer-min.js?v=4.5" />
	</cfif>

	<!--- Window settings --->
	<cfset winSize=385 />

	<cfset prod=createobject("component","com.products.product") />
	<cfset acts=createobject("component","com.mylocker.activity").list_v2(url.sc_id,url.shop_category_id) />
	<cfset productViews=prod.getProductViewTypes(url.category) />
	<cfset clrs=createobject("component","com.mylocker.color").getColorsOrdered('','','','','','','','','','','','',url.primary,url.second,url.third,url.design_type_id) />
	<cfset products=prod.getProduct(1,url.category,url.prodid,url.prodid1,url.prodid2,url.prodid3,url.prodid4,url.prodid5,url.prodid6,url.prodid7,url.prodid8,url.prodid9,url.prodid10) />
	<cfset backproducts=prod.getProduct(2,url.category,url.prodid,url.prodid1,url.prodid2,url.prodid3,url.prodid4,url.prodid5,url.prodid6,url.prodid7,url.prodid8,url.prodid9,url.prodid10) />
	
	<cfquery dbtype="query" name="front">
		Select * from products where productid=#url.prodid#
	</cfquery>
	<cfquery dbtype="query" name="back">
		Select * from backproducts where productid=#url.prodid#
	</cfquery>

	<cfset colors = QueryNew("hex,descr,isextra","CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_INTEGER") />
	<cfset tmpColors = StructNew() />
	<cfloop query="clrs">
		<cfif not StructKeyExists(tmpColors,clrs.hex)>
			<cfset tmp = StructInsert(tmpColors,clrs.hex,clrs.descr) />
			<cfset tmp = QueryAddRow(colors) />
			<cfset tmp = QuerySetCell(colors, "hex", clrs.hex) />
			<cfset tmp = QuerySetCell(colors, "descr", clrs.descr) />
			<cfset tmp = QuerySetCell(colors, "isextra", clrs.isextra) />
		</cfif>
	</cfloop>
	<cfset priColor = right(url.primary, 6) />
	<cfset secColor = right(url.second, 6) />
	<cfset selectedDC1 = StructFind(tmpColors,priColor) />
	<cfset selectedDC2 = StructFind(tmpColors,secColor) />

	<cfquery dbtype="query" name="productColors">
		SELECT 		*
		FROM 		products
	</cfquery>
	<cfset initialProductColorDescr = front.colordescr />
	<cfif front.colordescrsecondary neq ''>
		<cfset initialProductColorDescr = initialProductColorDescr & " / " & front.colordescrsecondary />
	</cfif>
	<cfquery dbtype="query" name="PriColorData">
		SELECT 		*
		FROM 		colors
		WHERE 		hex = '#priColor#'
	</cfquery>
	<cfquery dbtype="query" name="SecColorData">
		SELECT 		*
		FROM 		colors
		WHERE 		hex = '#secColor#'
	</cfquery>
	<cfquery name="topcats" datasource="#dsn#">
		SELECT ctc.*
		FROM 
		CatalogTopCategory ctc
		ORDER BY ctc.sortOrder
	</cfquery>

	<cfif isDefined("url.qs") and len(url.qs)>
		<cfset uqs = StructNew() />
		<cfloop list="#url.qs#" index="key" delimiters="&">
			<cfset uqs["#listFirst(key,'=')#"] = urlDecode(listLast(key,"="))>
		</cfloop>
		<cfif isDefined("uqs.d")>
			<cfset url.d = uqs.d />
		</cfif>
		<cfif isDefined("uqs.t")>
			<cfset url.t = uqs.t />
		</cfif>
		<cfif isDefined("uqs.c")>
			<cfset url.c = uqs.c />
		</cfif>
		<cfif isDefined("uqs.g")>
			<cfset url.g = uqs.g />
		</cfif>
	</cfif>
	
</cfsilent><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html 	xmlns="http://www.w3.org/1999/xhtml"
		xmlns:svg="http://www.w3.org/2000/svg" 
		xmlns:xul="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
		xmlns:xlink="http://www.w3.org/1999/xlink"
		xmlns:ev="http://www.w3.org/2001/xml-events">
<head>
<title>MyLocker Designer version 3.0</title>
<link rel="stylesheet" type="text/css" media="all" href="ml-designer.css?v=20140915" />
<!--- NOTE: the order of the following script tags IS important... we need to set these variables, and then load the other scripts before continuing --->
<script type="text/javascript">
	//<![CDATA[
	/* document.domain 					= "mylocker.net"; */
	var globalSkuPrice 					= '<cfoutput>#url.skuprice#</cfoutput>';
	var globalYearText 					= '<cfoutput>#url.yearSel#</cfoutput>';
	var globalNameText 					= 'My Name';
	var globalNumText 					= '35';
	var globalScId						= '<cfoutput>#url.sc_id#</cfoutput>';
	var globalCartHost					= '<cfoutput>#cartHost#</cfoutput>';
	var globalIsDev						= '<cfif cartHost eq "http://dev.mylocker.net">1<cfelse>0</cfif>';
	var globalShopCategoryId 			= '<cfoutput>#url.shop_category_id#</cfoutput>';
	var globalDesignTypeID 				= '<cfoutput>#url.design_type_id#</cfoutput>';
	var globalProdCat 					= '<cfoutput>#url.category#</cfoutput>';
	var globalDefaultActivity  			= '<cfoutput>#url.defaultActivity#</cfoutput>';
	var globalDefaultActivityText 		= '<cfoutput>#jsstringformat(url.defaultActivityText)#</cfoutput>';
	var globalShowActivities 			= '<cfoutput>#url.showActivities#</cfoutput>';
	var globalShowPersonalize 			= '<cfoutput>#url.showPersonalize#</cfoutput>';
	var globalD 						= '<cfoutput>#url.d#</cfoutput>';
	var globalT 						= '<cfoutput>#url.t#</cfoutput>';
	var globalC 						= '<cfoutput>#url.c#</cfoutput>';
	var globalG 						= '<cfoutput>#url.g#</cfoutput>';
	var globalShowLogoUploadThumb 		= '<cfoutput>#url.showLogoUploadThumb#</cfoutput>';
	var globalLogoUploadThumbPosition 	= '<cfoutput>#url.logoUploadThumbPosition#</cfoutput>';
	var honorDocCookies 				= '<cfoutput>#url.honorDocCookies#</cfoutput>';
	var fullSizeProductImagesOnly 		= '<cfoutput>#url.fullSizeProductImagesOnly#</cfoutput>';
	//]]>
</script>

<script type="text/javascript" src="_lib/cookie-min.js"></script>					<!--- Mozilla cookie library --->
<script type="text/javascript" src="<cfoutput>#mylDesign#</cfoutput>"></script>		<!--- designer-mobile --->
<script type="text/javascript" src="_lib/saXMLUtils-min.js?build=20141119"></script><!--- XML Parser --->
<script type="text/javascript" src="<cfoutput>#dbmobile#</cfoutput>"></script>		<!--- design-builder-mobile --->
<script type="text/javascript" src="_lib/he-min.js"></script> 						<!--- HTML Entities encoder/decoder --->

<!--- remote debugging using WeInRe --->
<!--- <script src="http://jaba.homeip.net:8080/target/target-script-min.js#anonymous"></script> --->

<!--- dynamic JS --->
<script type="text/javascript">
	//<![CDATA[
	var productViews 	= [<cfloop query="productViews">'<cfoutput>#LCase(viewType)#</cfoutput>'<cfif currentrow neq recordcount>,</cfif></cfloop>];
	var prodNavTarget 	= window.parent.location.href + '#product-nav';
	var selectedProduct = <cfoutput>#url.prodid#</cfoutput>;
	var selectedDC1 	= '<cfoutput>#selectedDC1#</cfoutput>';
	var selectedDC2 	= '<cfoutput>#selectedDC2#</cfoutput>';
	var selectedDC1Hex	= '<cfoutput>#priColor#</cfoutput>';
	var selectedDC2Hex	= '<cfoutput>#secColor#</cfoutput>';
	var globalPrimary 	= '<cfoutput>#url.primary#</cfoutput>';
	var globalSecond 	= '<cfoutput>#url.second#</cfoutput>';
	var globalThird 	= '<cfoutput>#url.third#</cfoutput>';
	var globalWinSize 	= <cfoutput>#winSize#</cfoutput>;
	var pip 			= '/products';
	if (fullSizeProductImagesOnly == "0") {
		pip 			= globalWinSize < 186 ? '/products/catalogsize' : globalWinSize < 221 ? '/products/cartsize' : '/products';
	}
	
	<cfset randnum=randrange(40000,80000)>
	var base_designs_url = "<cfoutput>#ht#://#dPrefix#.mylocker.net/com/designs/Designs.cfm?schoolsId=#urlEncodedFormat(url.sc_id)#&isSVG=1&nocache=#randnum#</cfoutput>";
	//var url = base_designs_url;
	<!--- <cfif len(url.d)>url += "<cfoutput>&d=#url.d#&g=#urlEncodedFormat(url.g)#</cfoutput>";</cfif> --->
	var base_backurl = "<cfoutput>#ht#://#dPrefix#.MyLocker.net/com/designs/Designs.cfm?schoolsId=#urlEncodedFormat(url.sc_id)#&isSVG=1&nocache=#randnum#&designTypeId=4</cfoutput>";
	<!--- Copy products to javascript structure --->
	<cfoutput>
	var products={
		<cfloop query="products">
			prod_#productid#:{ 
								height 				: globalWinSize,
								width 				: globalWinSize,
								desc				:'#jsstringformat(COLORDESCR)#<cfif colordescrsecondary neq ""> / #jsstringformat(COLORDESCRSECONDARY)#</cfif>',
						 		frontImg			: new Image(),
						 		frontImgPath		: <cfif designboxedview neq '1'>pip + '/' + '#REReplaceNoCase(ImageFileName,"\.jpg$","\.png")#'<cfelse>''</cfif>,
								centerOffsetX 		: #centeroffsetx#,
								centerOffsetY 		: #centeroffsety#,
								designOffsetX 		: #designOffsetX#,
								designOffsetY 		: #designOffsetY#,
								designScale 		: #designScale# * globalWinSize / 385,
								prodImgHeight		: 0,
								prodImgWidth		: 0,
								designRotation		: #designRotation#,
								backgroundColor		: '###hexcolor#',
								designTypeId		: '#designTypeID#',
								showBackColor		: <cfif designboxedview neq '1'>false<cfelse>true</cfif>,
								showFrontImage		: false,
								prodID 				: #productid#,
								prodName 			: '#jsstringformat(HighAsciiSafe(PRODUCTNAME))#'
				}<cfif currentrow neq recordcount>,</cfif>
		</cfloop>
		}	
		<cfloop query="products">
			products.prod_#productid#.frontImg.onload=function() {
				var ls = (this.height >= this.width) ? this.height : this.width;
				products.prod_#productid#.prodImgHeight=this.height * globalWinSize / ls;
				products.prod_#productid#.prodImgWidth=this.width * globalWinSize / ls;
			}
			<!--- Only load selected product initially --->
			<cfif productid eq url.prodid>
				try{products.prod_#productid#.frontImg.src = products.prod_#productid#.frontImgPath;}catch(e){}
			</cfif>
		</cfloop>
	
	<!--- Copy products to javascript structure --->
	var numBackProducts=#backproducts.recordcount#;
	var backproducts={
		<cfloop query="backproducts">
			prod_#productid#:{ 
								height 				: globalWinSize,
								width 				: globalWinSize,
								desc				:'#jsstringformat(COLORDESCR)#',
						 		frontImg			: new Image(),
						 		frontImgPath		: <cfif designboxedview neq '1'>pip + '/' + '#REReplaceNoCase(ImageFileName,"\.jpg$","\.png")#'<cfelse>''</cfif>,
								centerOffsetX 		: #centeroffsetx#,
								centerOffsetY 		: #centeroffsety#,
								prodImgHeight		: 0,
								prodImgWidth		: 0,
								designOffsetX 		: #designOffsetX#,
								designOffsetY 		: #designOffsetY#,
								designScale 		: #designScale# * globalWinSize / 385,
								designRotation		: #designRotation#,
								backgroundColor		: '###hexcolor#',
								showBackColor		: <cfif designboxedview neq '1'>false<cfelse>true</cfif>,
								showFrontImage		: false,
								prodID 				: #productid#,
								prodName 			: '#jsstringformat(HighAsciiSafe(PRODUCTNAME))#'
								
				}<cfif currentrow neq recordcount>,</cfif>
		</cfloop>
		}	
		<cfloop query="backproducts">
			backproducts.prod_#productid#.frontImg.onload=function() {
				var ls = (this.height >= this.width) ? this.height : this.width;
				backproducts.prod_#productid#.prodImgHeight=this.height * globalWinSize / ls;
				backproducts.prod_#productid#.prodImgWidth=this.width * globalWinSize / ls;
			}
			<!--- Only load selected product initially --->
			<cfif productid eq url.prodid>
				try{backproducts.prod_#productid#.frontImg.src = backproducts.prod_#productid#.frontImgPath;}catch(e){}
			</cfif>
		</cfloop>

	var customizationDefaults={ //to pass in toptext,bottomtext,etc to designer
			topText 	: 'notSet', 
			initials 	: '#JSStringFormat(url.initials)#',
			mascot 		: '#JSStringFormat(url.mascot)#',
			schoolName 	: '#jsstringformat(url.school)#', 
			bottomText 	: 'notSet',
			yearText 	: '#jsstringformat(url.yearSel)#',
			teamNum		: '35',
			teamName 	: 'My Name',
			primary 	: '#JSStringFormat(Right(url.primary,6))#',
			second 		: '#JSStringFormat(Right(url.second,6))#'
	};

	var customizations=customizationDefaults;
	var numDesignColors=#colors.recordcount#;
	var numProductColors=#productColors.recordcount#;

	var dc={
		<cfloop query="colors">hex_#hex#	: '#descr#'<cfif currentrow neq recordcount>,</cfif>
		</cfloop>
	};

	var sizeChartName = '#front.sizechart#';

	</cfoutput>

	//]]>
</script>
</head>
<body onload="setStage();">
	<div id="ml-designer-wrapper">
	 	<div id="leftcol">	<!--- left column, fixed width of 320 px --->
			<div style="/*margin:0 0 10px 0; height:60px; */">
				<div style="margin-top:1px;text-align:center;display:none;">
					<svg class="stepNumber" xmlns="http://www.w3.org/2000/svg" version="1.1">
						<circle cx="12" cy="12" r="12"  fill="#ffcc00"/>
						<text x="7" y="18" fill="#333333" class="stepNumberText">1</text>
					</svg>
					<span class="stepText" id="step1Text">DESIGN YOURS!</span>
					<span class="stepText" id="step1AltText">SELECT A DESIGN</span>
				</div>
				<div id="selectBoxes" style="display:none;">
					<cfset personalizations=createobject("component","com.mylocker.personalization").newlist(url.sc_id,url.shop_category_id,url.defaultActivity) />
					<select id="personalizations" style="width:140px; display:none;" name="person" onchange="personalizeText(this)">
						<option value="- - - - - - - - -">Personalize it...</option>
						<cfoutput query="personalizations">
							<cfif personalization_id neq 0 and isHidden eq 0>
							<option value="#HTMLEditFormat(name)#">#htmleditformat(name)#</option>
							</cfif>
						</cfoutput>
						<cfif personalizations.recordcount eq 0>
							<option value=" "> </option>
						</cfif>
					</select>
				</div>	
			</div>
			<div id="design-ideas-header">
				<div id="dih-internal-activity-selector" style="display:none;">
					<span 	class="activity-callout-left-a" 
							style="color:#ffcb59; font-weight: bold; font-size:20px;">&raquo;&raquo;&raquo;</span>
					<select id="activityList" 
							style="width:60%; max-width:60%; margin-left:4px; margin-right:4px; background-color:#FFFFFF;" 
							name="Activity" 
							onchange="<cfoutput>setActivity(this,'#jsstringformat(url.sc_id)#','#jsstringformat(url.shop_category_id)#')</cfoutput>">
						<option value="">Select Activity...</option>
						<cfoutput query="acts">
							<cfif activity_id gt 0>
								<option value="#activity_id#" <cfif isdefault>selected="selected"</cfif>>#htmleditformat(name)#</option>
							</cfif>
						</cfoutput>	
					</select>
					<span 	class="activity-callout-left-a" 
							style="color:#ffcb59; font-weight: bold; font-size:20px;">&laquo;&laquo;&laquo;</span>
				</div>
				<div id="dih-external-activity-selector" style="display:none;">
					<div id="dih-activity-name"></div>
					<a id="dih-external-activity-selector-link" href="javascript:void(0);" onclick="openDesignIdeas();" style="display:none;" border="0"><img src="_img/btn_design_ideas-107x21.png" alt="" width="107" height="21" style="padding:2px 8px 2px 0; border:none;" /></a>
					<div style="clear:both;" />
				</div>
				<div id="dih-back-designs-header" style="display:none;">
					SELECT YOUR BACK DESIGN
				</div>
			</div>			
			<div id="designListDiv">
				<div id="svglist-wrapper">
					<div id="svglist" style="-webkit-overflow-scrolling:touch;"></div>
				</div>
				<div id="svgbacklist-wrapper">
					<div id="svgbacklist" style="-webkit-overflow-scrolling:touch;"></div>
				</div>
			</div>
			<!---
			<a id="btnDoneChoosingDesign" class="btnLightGray" href="" style="width:250px; position:relative; margin-top:12px;" onclick="hideDesigns();return false;">DONE</a>
			--->
			<div id="fippable-panel-wrapper">
				<div id="fp-front">
					<div id="designColorWrapper">
						<div id="pcDiv">
							<div id="pcDiv-al" onclick="cpScroll('pcpsw',-100);" style="display:none;" />
							<div id="pcDiv-ar" onclick="cpScroll('pcpsw',100);" <cfif productColors.recordcount lt 6>style="visibility:hidden;"<cfelse>style="display:none;"</cfif> />
							<div id="pcTitleDiv">
								<span class="labelText">PRODUCT COLOR:</span>
								<span class="labelTextItalic" id="pcDesc"><cfoutput>#initialProductColorDescr#</cfoutput></span>
							</div>
							<div id="pcTiny" style="text-align:left;">
								<cfloop index="i" from="#productColors.recordCount#" to="1" step="-1">
									<cfoutput><div id="colorsquare_#productColors['productid'][i]#" class="colorSwatch<cfif productColors['productid'][i] eq url.prodid> border-red</cfif>"<cfif productColors['isExtra'][i] eq '1'> style="/* display:none; */"</cfif> onmouseover="showColor(this,#productColors['productid'][i]#)" onmouseout="hideColor(this,#productColors['productid'][i]#)" onclick="setProduct(this,#productColors['productid'][i]#)"><div class="productColorPickSquareInner" style="border-top:14px solid ###productColors['hexcolor'][i]#; border-right:14px solid ##<cfif productColors['hexcolorsecondary'][i] neq ''>#productColors['hexcolorsecondary'][i]#<cfelse>#productColors['hexcolor'][i]#</cfif>;" /></div></cfoutput>
								</cfloop>
							</div>
							<div id="pcTouch" style="height:48px; overflow:hidden; display:none;">
								<div id="pcpsw" class="cpsw" onscroll="cpsScroll(this);">
									<cfloop index="i" from="#productColors.recordCount#" to="1" step="-1">
										<div id="pcs_<cfoutput>#productColors['productid'][i]#</cfoutput>" data-pid="<cfoutput>#productColors['productid'][i]#</cfoutput>" class="cpso<cfif productColors['productid'][i] eq url.prodid>-on</cfif>" onclick="setProduct(this,<cfoutput>#productColors['productid'][i]#</cfoutput>);"><div class="pcpsi" style="<cfif productColors['colorbox'][i] neq ''>width:40px; height:40px; background-size:contain; background-image:url('/<cfoutput>#productColors['colorbox'][i]#</cfoutput>');<cfelse>border-top:40px solid #<cfoutput>#productColors['hexcolor'][i]#</cfoutput>; border-right:40px solid #<cfif productColors['hexcolorsecondary'][i] neq ''><cfoutput>#productColors['hexcolorsecondary'][i]#</cfoutput><cfelse><cfoutput>#productColors['hexcolor'][i]#</cfoutput></cfif>;</cfif>" /></div>
									</cfloop>
									<div style="clear:both;" />
								</div>
							</div>
							<div style="clear:both;" />
							<cfif (findNoCase('safari',CGI.HTTP_USER_AGENT) and findNoCase('mobile',CGI.HTTP_USER_AGENT))
									or (findNoCase('Android',CGI.HTTP_USER_AGENT))>
								<div style="float:right; margin-top:25px;">
									<a href="" onclick="return swapTouchControls();" style="font-size:.73em;" id="touch-control-swap">Touch Friendly</a>
								</div>
							</cfif>
						</div>
					</div>
					<div id="main_designer_buttons" style="clear:both; margin:0 auto; padding:0; padding-top:5px; display:none; width:100%;">
						<a class="btnLightGray" href="" style="width:48%; float:left; position:relative; margin:3px 1%;" onclick="return showTextEdit();">EDIT TEXT</a>
						<a id="btnShowDesigns" class="btnDarkGray" href="" style="width:48%; float:left; position:relative; margin:3px 1%;" onclick="showDesigns(); return false;">VIEW DESIGNS</a>
						<a class="btnLightGray" href="" style="clear:both; width:48%; float:left; position:relative; margin:3px 1%;" onclick="return showColorEdit();">DESIGN COLORS</a>
					</div>
				</div> <!--- #fp-front --->
				<div id="fp-dc" style="display:none;">
					<div id="designColorWrapper">
						<div id="dc1Div">
							<div id="dc1Div-al" onclick="cpScroll('d1cpsw',-100);" style="display:none;" />
							<div id="dc1Div-ar" onclick="cpScroll('d1cpsw',100);" style="display:none;" />
							<div id="dc1TitleDiv">
								<span class="labelText">DESIGN COLOR 1:</span>
								<span class="labelTextItalic" id="primaryDC"><cfoutput>#selectedDC1#</cfoutput></span>
							</div>
							<div id="dc1Tiny" style="text-align:left;">
								<cfloop index="i" from="#colors.recordCount#" to="1" step="-1">
									<cfoutput><div id="primarydc_#colors['hex'][i]#" class="colorPickSquare<cfif colors['descr'][i] eq selectedDC1> border-red</cfif>" onmouseover="showDC1(this,'#jsstringformat(colors['descr'][i])#')" onmouseout="hideDC1(this,'#colors['descr'][i]#')" onclick="setDC1(this,'#colors['hex'][i]#','#colors['descr'][i]#')"><div class="colorPickSquareInner" style="background-color:###colors['hex'][i]#;"/></div></cfoutput>
								</cfloop>
							</div>
							<div id="dc1Touch" style="height:48px; overflow:hidden; display:none;">
								<div id="d1cpsw" class="cpsw" onscroll="cpsScroll(this);">
									<cfloop index="i" from="#colors.recordCount#" to="1" step="-1">
										<div id="primary_<cfoutput>#colors['hex'][i]#</cfoutput>" class="cpso<cfif colors['descr'][i] eq selectedDC1>-on</cfif>" onclick="setDC1(this,'<cfoutput>#colors['hex'][i]#</cfoutput>','<cfoutput>#colors['descr'][i]#</cfoutput>')"><div class="cpsi" style="background-color:#<cfoutput>#colors['hex'][i]#</cfoutput>;" /></div>
									</cfloop>
									<div style="clear:both;" />
								</div>
							</div>
							<div style="clear:both;" />
						</div>
						<div id="dc2Div">
							<div id="dc2Div-al" onclick="cpScroll('d2cpsw',-100);" style="display:none;" />
							<div id="dc2Div-ar" onclick="cpScroll('d2cpsw',100);" style="display:none;" />
							<div id="dc2TitleDiv">
								<span class="labelText">DESIGN COLOR 2:</span>
								<span class="labelTextItalic" id="secondDC"><cfoutput>#selectedDC2#</cfoutput></span>
							</div>
							<div id="dc2Tiny" style="text-align:left;">
								<cfloop index="i" from="#colors.recordCount#" to="1" step="-1">
									<cfoutput><div id="seconddc_#colors['hex'][i]#" class="colorPickSquare<cfif colors['descr'][i] eq selectedDC2> border-red</cfif>" onmouseover="showDC2(this,'#jsstringformat(colors['descr'][i])#')" onmouseout="hideDC2(this,'#colors['descr'][i]#')" onclick="setDC2(this,'#colors['hex'][i]#','#colors['descr'][i]#')"><div class="colorPickSquareInner" style="background-color:###colors['hex'][i]#;"/></div></cfoutput>
								</cfloop>
							</div>
							<div id="dc2Touch" style="height:48px; overflow:hidden; display:none;">
								<div id="d2cpsw" class="cpsw" onscroll="cpsScroll(this);">
									<cfloop index="i" from="#colors.recordCount#" to="1" step="-1">
										<div id="second_<cfoutput>#colors['hex'][i]#</cfoutput>" class="cpso<cfif colors['descr'][i] eq selectedDC2>-on</cfif>" onclick="setDC2(this,'<cfoutput>#colors['hex'][i]#</cfoutput>','<cfoutput>#colors['descr'][i]#</cfoutput>')"><div class="cpsi" style="background-color:#<cfoutput>#colors['hex'][i]#</cfoutput>;" /></div>
									</cfloop>
									<div style="clear:both;" />
								</div>
							</div>
							<div style="clear:both;" />
						</div>
					</div> <!--- #designColorWrapper --->
					<!---
					<a class="btnLightGray" href="" style="width:250px; position:relative; display:inline-block;" onclick="return hideColorEdit();">DONE</a>
					--->
				</div> <!--- #fp-dc --->
				<div id="color-switching-tabs">
					<a id="pct" class="cst-left cst-on" href="javascript:void(0);" onclick="showColorSelectors('product'); return false;">PRODUCT COLORS</a>
					<a id="dct" class="cst-right cst-off" href="javascript:void(0);" onclick="showColorSelectors('design'); return false;">DESIGN COLORS</a>
				</div>
			</div> <!--- #flippable-panel --->
		</div> <!--- #leftcol --->
		<div id="action-column-wrapper">	<!--- right column, fixed width of 160 (but shaded area actually only comes out to 126px) --->
			<a href="javascript:void(0);" id="swap-product" style="display:none;"><img src="_img/btn_view_more_products-109x98.gif" alt="" width="109" height="98" border="0" /></a>
			<div id="action-column" style="margin-top:105px;">	<!--- everything in here is absolute positioned :(  --->
				<div id="action-column-price-strikethrough" style="display:none;"><span style="color:red;text-decoration:line-through;"><span id="acps-value" style="color:#444;"></span></span></div>
				<div id="action-column-price"><span id="acp-value"></span></div>
				<div id="action-column-price-each">
					PRICE EACH
					<a href="javascript:void(0);" onclick="popCart();gaTrackEvent('Wholesale','Bulk Discount Click');" style="padding-top:8px;display:block;"><img src="_img/btn_bulk_pricing-109x26.gif" border="0" width="109" height="26" /></a>
				</div>
				<div id="ncWrapper">
					<div id="ncSize">
						<select id="ncS" name="ncS" style="width:100px;" onchange="ncSetPrice();"></select>
					</div>
					<div id="ncQuan" style="padding-top:10px;">
						<input 	style="width:90px;" 
								name="ncQ"
								id="ncQ" 
								type="number" 
								value="1" 
								pattern="[0-9]*" 
								placeholder="Quan" 
								min="1" 
								step="1" 
								onclick="this.select();" 
								onchange="ncSetPrice();"
								onkeyup="ncSetPrice();" 
								<cfif url.skuprice eq '' or url.skuprice eq '0.00'>disabled="disabled"</cfif>
						/>
					</div>
				</div>
				<a id="btn-add-to-cart" href="javascript:void(0);"><img src="_img/btn_add_to_cart-162x73.png" alt="" border="0" width="162" height="73" /></a>
				<div id="frontViewBut" 
					class="bigButton9" 
					onclick="showFront();"><div style="position:relative;padding-top:9px;">VIEW FRONT</div></div>
				<div id="backViewBut" 
					class="bigButton9" 
					onclick="showBack();"><div style="position:relative;padding-top:9px;">BACK DESIGN</div></div>
				<div id="zoomBut" class="bigButton9" onclick="toggleZoom();">ZOOM</div>
			</div>
		</div> <!--- #action-column-wrapper --->
		<div id="designer_center_section"> 	<!--- fluid width, margin left set to width of left column, margin right set to width of right column --->
			<div id="cntrl_and_design_wrapper" style="margin:0 auto; display:inline-block; position:relative; overflow:hidden;">
				<div id="div_product_holder" style="position:relative;
													height:<cfoutput>#winSize#</cfoutput>px;
													width:<cfoutput>#winSize#</cfoutput>px;
													padding:0;
													float:right;
													margin-left:2px;">
					<div style="position:relative; left:0; top:0; overflow:hidden; height:<cfoutput>#winSize#</cfoutput>px; width:<cfoutput>#winSize#</cfoutput>px; display:block;">
					<div id="backDesignerDiv" 
						style="height:<cfoutput>#winSize#</cfoutput>px;
								width:<cfoutput>#winSize#</cfoutput>px;
								<cfif back.ImageFileName neq "">background-image:url('/products/<cfif winSize lt 186 and not url.fullSizeProductImagesOnly>catalogsize/<cfelseif winsize lt 221 and not url.fullSizeProductImagesOnly>cartsize/</cfif><cfoutput>#REReplaceNoCase(back.ImageFileName,"\.jpg$","\.png")#</cfoutput>');</cfif>
								background-repeat:no-repeat;
								background-position:center center;
								background-size:contain;
								position:absolute;
								top:0;
								left:0;
								-webkit-transition: all .4s ease-in-out;
								-moz-transition: all .4s ease-in-out;
								-o-transition: all .4s ease-in-out;
								transition: all .4s ease-in-out;
								opacity:0;">	
						<svg:svg id="backsvg" 
								version="1.1" 
								style="width:<cfoutput>#winSize#</cfoutput>px; 
										height:<cfoutput>#winSize#</cfoutput>px;
										position:absolute;
										top:0;
										left:0;" 
								viewBox="0 0 <cfoutput>#winSize# #winSize#</cfoutput>" 
								preserveAspectRatio="none" 
								xmlns="http://www.w3.org/2000/svg">
						</svg:svg>
					</div>
					<div id="designerDiv" 
						 style="position:absolute;
								top:0;
								left:0;
								height:<cfoutput>#winSize#</cfoutput>px;
								width:<cfoutput>#winSize#</cfoutput>px;
								background-image:url('/products/<cfif winSize lt 186 and not url.fullSizeProductImagesOnly>catalogsize/<cfelseif winsize lt 221 and not url.fullSizeProductImagesOnly>cartsize/</cfif><cfoutput>#REReplaceNoCase(front.ImageFileName,"\.jpg$","\.png")#</cfoutput>');
								background-repeat:no-repeat;
								background-position:center center;
								background-size:contain;
								-webkit-transition: all .4s ease-in-out;
								-moz-transition: all .4s ease-in-out;
								-o-transition: all .4s ease-in-out;
								transition: all .4s ease-in-out;
								cursor:hand;
								cursor:pointer;
								opacity:0;"	
						onclick="toggleZoom();">	
						<svg:svg id="svg" 
								version="1.1" 
								style="width:<cfoutput>#winSize#</cfoutput>px; 
										height:<cfoutput>#winSize#</cfoutput>px;
										position:absolute;
										top:0;
										left:0;" 
								viewBox="0 0 <cfoutput>#winSize# #winSize#</cfoutput>" 
								preserveAspectRatio="none" 
								onload="svginit(evt);"
							 	xmlns="http://www.w3.org/2000/svg">
							<defs>
								<filter id="txtBlur">
									<feGaussianBlur in="SourceGraphic" stdDeviation="0" />
								</filter>
								<filter id="c1tf_thumb" color-interpolation-filters="sRGB">
									<feColorMatrix id="c1tm_thumb"
									  in="SourceGraphic"
									  type="matrix"
									  values="0.21183699607843137 0.7123554509803922 0.07188598431372549 0 0 0.1576267411764706 0.5300597647058823 0.053489964705882354 0 0 0.014178066666666666 0.047677333333333335 0.004811266666666666 0 0 0 0 0 1 0" />
								</filter>
								<filter id="c1sf_thumb" color-interpolation-filters="sRGB">
									<feColorMatrix id="c1sm_thumb"
									  in="SourceGraphic"
									  type="matrix"
									  values="0 0 0 0 0.996078431372549 0 0 0 0 0.7411764705882353 0 0 0 0 0.06666666666666667 0 0 0 1 0" />
								</filter>
								<filter id="c1tf" color-interpolation-filters="sRGB">
									<feColorMatrix id="c1tm"
									  in="SourceGraphic"
									  type="matrix"
									  values="0.21183699607843137 0.7123554509803922 0.07188598431372549 0 0 0.1576267411764706 0.5300597647058823 0.053489964705882354 0 0 0.014178066666666666 0.047677333333333335 0.004811266666666666 0 0 0 0 0 1 0" />
								</filter>
								<filter id="c1sf" color-interpolation-filters="sRGB">
									<feColorMatrix id="c1sm"
									  in="SourceGraphic"
									  type="matrix"
									  values="0 0 0 0 0.996078431372549 0 0 0 0 0.7411764705882353 0 0 0 0 0.06666666666666667 0 0 0 1 0" />
								</filter>
								<filter id="c2tf_thumb" color-interpolation-filters="sRGB">
									<feColorMatrix id="c2tm_thumb"
									  in="SourceGraphic"
									  type="matrix"
									  values="0.21183699607843137 0.7123554509803922 0.07188598431372549 0 0 0.1576267411764706 0.5300597647058823 0.053489964705882354 0 0 0.014178066666666666 0.047677333333333335 0.004811266666666666 0 0 0 0 0 1 0" />
								</filter>
								<filter id="c2sf_thumb" color-interpolation-filters="sRGB">
									<feColorMatrix id="c2sm_thumb"
									  in="SourceGraphic"
									  type="matrix"
									  values="0 0 0 0 0.996078431372549 0 0 0 0 0.7411764705882353 0 0 0 0 0.06666666666666667 0 0 0 1 0" />
								</filter>
								<filter id="c2tf" color-interpolation-filters="sRGB">
									<feColorMatrix id="c2tm"
									  in="SourceGraphic"
									  type="matrix"
									  values="0.21183699607843137 0.7123554509803922 0.07188598431372549 0 0 0.1576267411764706 0.5300597647058823 0.053489964705882354 0 0 0.014178066666666666 0.047677333333333335 0.004811266666666666 0 0 0 0 0 1 0" />
								</filter>
								<filter id="c2sf" color-interpolation-filters="sRGB">
									<feColorMatrix id="c2sm"
									  in="SourceGraphic"
									  type="matrix"
									  values="0 0 0 0 0.996078431372549 0 0 0 0 0.7411764705882353 0 0 0 0 0.06666666666666667 0 0 0 1 0" />
								</filter>
								<cfif not findNoCase("safari","#CGI.HTTP_USER_AGENT#") or findNoCase("chrome","#CGI.HTTP_USER_AGENT#")>
									<style type="text/css"><![CDATA[
										@font-face {
											font-family: 'yearbooksolid';
										    src: url('assets/yearbooksolid.eot');
										  	src: url('assets/yearbooksolid.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										         url('assets/yearbooksolid.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/yearbooksolid.svgz#yearbooksolid') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										    font-family: 'brushscriptstdregular';
										    src: url('assets/brushscriptstd.eot');
										  	src: url('assets/brushscriptstd.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										         url('assets/brushscriptstd.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/brushscriptstd.svgz#brushscriptstdregular') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										  	font-family: 'DASSportScriptRegular';
										  	src: url('assets/sportscript.eot'); /* IE 5-8 */ 
										  	src: url('assets/sportscript.eot?#iefix') format('embedded-opentype'),
										  		 url('assets/sportscript.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										       	 url('assets/sportscript.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/sportscript.svgz#das~sportscriptregular') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										  	font-family: 'dascollegiatethinregular';
										  	src: url('assets/collegiatethin.eot'); /* IE 5-8 */ 
										  	src: url('assets/collegiatethin.eot?#iefix') format('embedded-opentype'),
										  		 url('assets/collegiatethin.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										       	 url('assets/collegiatethin.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/collegiatethin.svgz#das~collegiatethinregular') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										  	font-family: 'gesso';
										  	src: url('assets/gesso___-webfont.eot'); /* IE 5-8 */ 
										  	src: url('assets/gesso___-webfont.eot?#iefix') format('embedded-opentype'),
										  		 url('assets/gesso___-webfont.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										       	 url('assets/gesso___-webfont.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/gesso.svgz#gesso') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										  	font-family: 'destroyregular';
										  	src: url('assets/destroy_new_6_28.eot'); /* IE 5-8 */ 
										  	src: url('assets/destroy_new_6_28.eot?#iefix') format('embedded-opentype'),
										       	 url('assets/destroy_new_6_28.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										       	 url('assets/destroy_new_6_28.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/destroy.svgz#destroyregular') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
										@font-face {
										  	font-family: 'sfcollegiateregular';
										  	src: url('assets/sf_collegiate-webfont.eot'); /* IE 5-8 */ 
										  	src: url('assets/sf_collegiate-webfont.eot?#iefix') format('embedded-opentype'),
										  		 url('assets/sf_collegiate-webfont.woff') format('woff'),    /* FF 3.6, Chrome 5, IE9, Chrome 38 */
										       	 url('assets/sf_collegiate-webfont.ttf') format('truetype'), /* Opera, Safari */
	        									 url('fonts/sf_collegiate.svgz#sfcollegiateregular') format('svg'); /* iOS */
	        								font-weight:normal;
	        								font-style:normal;
										}
									]]></style>
								<cfelse>
									<font-face font-family="BrushScriptStdRegular">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/brushscriptstd.svgz#BrushScriptStdRegular">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="DASSportScriptRegular">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/sportscript.svgz#DAS~SportScriptRegular">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="DASCollegiateThinRegular">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/collegiatethin.svgz#DAS~CollegiateThinRegular">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="DestroyRegular">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/destroy.svgz?v=20130701">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="Gesso">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/Gesso.svgz#Gesso">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="SFCollegiateRegular">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/sf_collegiate.svgz#SFCollegiateRegular">
											</font-face-uri>
										</font-face-src>
									</font-face>
									<font-face font-family="YearbookSolid">
										<font-face-src>
											<font-face-uri xlink:href="./fonts/YearbookSolid.svgz#YearbookSolid">
											</font-face-uri>
										</font-face-src>
									</font-face>
								</cfif>
							</defs>
							<svg id="designdiv">
							</svg>
						</svg:svg>
					</div>
					</div>
					<div id="designer_wait" 
						style="/* float:left; */
								position:absolute;
								margin-left:-16px;
								margin-top:-16px;
								top:50%;
								left:50%;
								width:32px;
								height:32px;
								/* padding-top:3px; */
								/* display:inline-block; */
								display:block;
								/* border-radius:8px;
								background-image:url('ajax-loader-round.gif');
								background-repeat:no-repeat;
								background-position:center center; */
								/* background-color:rgba(0,0,0,0.09); */">
						<img src="/svg/ajax-loader-round.gif" alt="" width="32" height="32" />
					</div>
				</div> <!--- #div_product_holder ---> 
				<div id="viewControls" 
					 style="float:left;
							/* position:absolute; */
							/* margin-left:-50px; */
							/* margin-top:5px; */
							top:0;
							left:0;
							width:60px;
							padding-top:3px;
							display:none;
							/* display:inline-block; */
							/* display:block; */
							border-radius:8px;
							background-color:rgba(0,0,0,0.09);">
						
				</div> <!--- #viewControls --->
					<!--- <br /><a href="#" onclick="javascript:parent.showMenu('2');return false;" style="display:none;"><img style="margin-top:10px;" src="btn_change_product.png" width="44" height="37" border="0" alt="change product" /></a>
					--->
				<div style="clear:both;" />
			</div> <!--- #cntrl_and_design_wrapper --->
			<div id="fp-t">
				<div id="fp-t-t">CUSTOMIZE YOUR TEXT:</div>
				<div id="textFieldWrapper">
					<div id="topTextSpan">
						<input class="prodText" type="text" name="toptext" id="toptext" value="" maxlength="100" />
					</div>
					<div id="bottomTextSpan">
						<input class="prodText" type="text" name="bottomtext" id="bottomtext" value="" maxlength="100" />
					</div>
					<div id="yearTextSpan" style="width:90px;">
						<input class="prodText" type="text" name="yeartext" id="yeartext" value="<cfoutput>#url.yearSel#</cfoutput>" maxlength="4" />
					</div>
					<div id="nameTextSpan">
						<input class="prodText" type="text" name="teamname" id="teamname" value="My Name" maxlength="50" placeholder="My Name" />
					</div>
					<div id="numberTextSpan" style="width:90px;">
						<input class="prodText" type="text" name="teamnum" id="teamnum" value="35" maxlength="3" placeholder="35" />
					</div>
					<!--- place the disable button only for certain IP addresses --->
					<!---
					<cfif ListFindNoCase(adminIps,cgi.remote_addr) or dPrefix eq 'dev'>
						<div style="color:#888;font-size:.7em;margin-top:10px;">
							<a style="color:#888;" href="javascript:console.log(document.getElementById('designerDiv').innerHTML)">Show me the SVG (JS console)</a>
							&nbsp;&nbsp;|&nbsp;&nbsp;
							<a style="color:#888;" href="javascript:alertGraphics();">Disable this SVG design...</a>
						</div>
					</cfif>
					--->
				</div>
				<!--- <a class="btnLightGray" href="" style="width:250px;position:relative;" onclick="return hideTextEdit();">DONE</a> --->
				<div id="back-controls" style="display:none;">
					<div id="add-my-roster" onclick="popCart();">
						 + Add My Roster
					</div>
					<div id="add-back-checkbox" style="white-space:nowrap;">
						<input type="checkbox" name="addback2" id="addback2" onchange="toggleAddBackDesign(this);" />
						<label for="addback2" style="cursor:pointer;">
							<span style="font-size:.9em;">Add Back Design</span><br /><span style="font-size:.9em;">(only $<span id="back-base-price2">X.XX</span> each)</span>
						</label>
					</div>
					<div style="clear:both;"></div>
				</div>
			</div> <!--- #fp-t --->
		</div> <!--- #designer_center_section --->
		<!---
		<div id="designer_center_section_back">
			<div id="edit_text_wrapper" style="margin:0 auto; position:relative; text-align:center;">
				<div id="frontTextEdit" style="position:relative; height:370px; width:95%; max-width:400px; margin:0 auto;">
					<div style="clear:both;" />
				</div>

				<!--- <a class="btnLightGray" href="" style="width:250px; position:relative; display:inline-block;" onclick="flipPanelToFront();return false;">DONE</a> --->
			</div> <!--- #edit_text_wrapper --->
		</div>
		--->
		<div style="clear:both;" />
		<div id="some_other_div"	style=	"position:absolute;
											 width:100%;
											 height:530px;
											 top:0;
											 left:0;
											 display:block;
											 background-color:rgba(0,0,0,0.5);">
			<h4 id="progress_text" style="display:block; text-align:center; color:white;">Loading Designs ...</h4>
		</div>
		<div id="chooseProductOverlay" style="display:none;">
		</div>
		<div id="chooseProduct" style="display:none;">
			<cfoutput>
			<div style="float:right;">
				<a href="javascript:document.getElementById('chooseProduct').style.display='none';document.getElementById('chooseProductOverlay').style.display='none'"><img src="images/closebut.png" border="0"/></a>
			</div>
			<ul id="topcategory" style="clear:both;margin-top:45px;">
				<cfloop query="topcats">
					<cfquery name="cat" datasource="#dsn#">
					SELECT cc.*
					FROM 
					CatalogCategory cc
					where catalogTopCategory_id=#catalogTopCategory_ID#
					ORDER BY cc.sortOrder
					</cfquery>
					<li class="catlink" id="topcat_#catalogTopCategory_ID#" textval="#htmleditformat(catalogTopCategory)#" caturl="none">
						<span id="topcat_#catalogTopCategory_ID#_text">#catalogTopCategory#</span>
						<br/><br/>
						<ul class="category">
						<cfloop query="cat">
							<li id="cat_#catalogCategory_id#" textval="#htmleditformat(catalogCategory)#" caturl="#htmleditformat(catalogCategoryUrl)#">
								<a class="prodlink" target="_top" href="javascript:parent.setShopSavedTrue();window.parent.location='/#url.mapping_state#/#url.mapping_city#/#url.mapping_school#/p/#cataLogCategoryUrl#.html';">#htmleditformat(catalogCategory)#</a>
							</li>
						</cfloop>
						</ul>
					</li>
				</cfloop>
			</ul>	
			</cfoutput>
		</div>
		<div id="sizeChartOverlay" style="display:none;">
		</div>
		<cfif front.sizechart neq "">
			<div id="sizeChart" style="background-image:url('/size_charts/trimmed/<cfoutput>#front.sizechart#</cfoutput>'); display:none;">
				<div style="float:right;padding-right:5px;">
					<a href="javascript:document.getElementById('sizeChart').style.display='none';document.getElementById('sizeChartOverlay').style.display='none'"><img src="images/closebut.png" border="0"/></a>
				</div>
			</div>
		</cfif>
		<div id="cartPopupOverlay" style="display:none;">
		</div>
		<div id="cartPopup" style="display:none;">
			<div id="btnCloseCartPopup" style="float:right;padding-right:5px;<cfif url.skuprice eq '0.00'>display:none;</cfif>">
				<a href="javascript:document.getElementById('cartPopup').style.display='none';document.getElementById('cartPopupOverlay').style.display='none'"><img src="images/closebut.png" border="0"/></a>
			</div>
			<div style="clear:both;" />
			<div id="divCartMessage" class="cartMessage">
				<p>Hold on a sec, we're adding the items to your cart...</p>
			</div>
			<!---
			<a href="javascript:ContinueShopping();" id="btnContinueShopping" class="btnContinueShopping" style="top:243px; left:135px; width:200px;">Continue Shopping</a>
			<a href="javascript:parent.setShopSavedTrue();window.parent.location='<cfoutput>#cartHost#</cfoutput>/showcart.cfm?sc_id=<cfoutput>#url.sc_id#</cfoutput>';" target="_top" class="btnCheckoutNow" style="top:243px; left:555px; width:250px;">Checkout Now</a>
			--->
		</div>
		<div id="pop-cart">
			<div id="div-btn-bulk-add-to-cart">
				<a href="" id="atc" onclick="return addToCart();" style="position:relative; width:200px; display:inline-block;"><img src="_img/btn_add_to_cart-162x73.png" alt="" border="0" width="162" height="73" /></a>
			</div>
			<div id="cart-page-wrapper">
				<div id="cart-page-1">
					<div id="bulk-savings-start"></div>
					<div class="cp-row-wrapper">
						<div id="size-row-to-clone" class="cp-row" style="display:none;">
							<div class="cp-row-delete-wrapper">
								<!--- <div onclick="return deleteCpRow(this.parentNode.parentNode);" class="cp-row-delete" /> --->
								<img src="btn_trash.png" class="cp-row-img-btn-trash" onclick="deleteCpRow(this.parentNode.parentNode);" />
							</div>
							<div style="width:90%; display:inline-block;">
								<select class="cart-size-field" id="sku" name="sku" onchange="setPrice();"></select>
								<input 	class="cart-quantity-field" 
										name="quan" 
										type="number" 
										value="1" 
										pattern="[0-9]*" 
										placeholder="Quan" 
										min="1" 
										step="1" 
										onclick="this.select();" 
										onchange="setPrice();"
										onkeyup="setPrice();"
								/>
								<div class="cart-price-field"></div>
								<div style="clear:both;"></div>
								<input class="cart-name-field" placeholder="enter name" maxlength="50" onclick="this.select();" />
								<input class="cart-number-field" placeholder="enter number" maxlength="3" onclick="this.select();" />
								<div style="clear:both;"></div>
							</div>
						</div>
						<div id="price-block">
							<center>
								<div id="discount-grid-border">
									<div id="discount-grid">
										<span style="font-size:16px;font-weight:bold;">Bulk Savings</span><br />
										<span style="font-size:12px;color:#CF201D;">PRICE BREAKS</span><br />
										<div id="discount-grid-display" style="padding:4px;"></div>
									</div>			
								</div>					
							</center>
							<div id="zoomDivsHeader" style="margin-top:7px;font-size:12px; font-weight:bold;">
								<div style="width:50%;float:left;font-size:12px;font-weight:bold;text-align:center;">
									<span style="margin-left:0px;">FRONT</span>
									<a href="javascript:void(0);" onclick="closeCart();showFront();" style="text-decoration:none;margin-left:20px;">Edit &raquo;</a>
								</div>
								<div id="cbth" style="margin-left:50%;text-align:center;padding-left:4px;display:none;">
									<span style="margin-right:20px;">BACK</span>
									<a href="javascript:void(0);" onclick="closeCart();showBack();" style="text-decoration:none;margin-right:0px;">Edit &raquo;</a>
								</div>
								<div style="clear:both;"></div>
							</div>
							<div id="designs-div" style="width:100%; height:140px; position:relative;">
								<div id="zoomDivFront" 
									style="height:385px;
											width:385px;
											position:absolute;
											top:0;
											right:200px;
											opacity:1;
											-moz-transition: all .5s ease-in-out;
											-ms-transition: all .5s ease-in-out;
											-o-transition: all .5s ease-in-out;
											-webkit-transition: all .5s ease-in-out;
											transition: all .5s ease-in-out;
											-moz-transform-origin:top right;
											-moz-transform: scale(0.32);
											-ms-transform-origin:top right;
											-ms-transform: scale(0.32);
											-o-transform-origin:top right;
											-o-transform: scale(0.32);
											-webkit-transform-origin:top right;
											-webkit-transform: scale(0.32);
											transform-origin:top right;
											transform: scale(0.32);
											cursor:pointer;" 
									onclick="toggleMyZoom(this);" 
									>	
									<svg:svg id="zoomsvgfront" 
											version="1.1" 
											style="width:385px; 
													height:385px;" 
											viewBox="0 0 385 385" 
											preserveAspectRatio="none" 
											xmlns="http://www.w3.org/2000/svg">
									</svg:svg>
								</div>
								<div id="zoomDivBack" 
									style="height:385px;
											width:385px;
											position:absolute;
											top:0;
											right:24px;
											opacity:0;
											-moz-transition: all .5s ease-in-out;
											-ms-transition: all .5s ease-in-out;
											-o-transition: all .5s ease-in-out;
											-webkit-transition: all .5s ease-in-out;
											transition: all .5s ease-in-out;
											-moz-transform-origin:top right;
											-moz-transform: scale(0.32);
											-ms-transform-origin:top right;
											-ms-transform: scale(0.32);
											-o-transform-origin:top right;
											-o-transform: scale(0.32);
											-webkit-transform-origin:top right;
											-webkit-transform: scale(0.32);
											transform-origin:top right;
											transform: scale(0.32);
											<!--- <cfif not back.recordcount>display:none;</cfif> --->
											cursor:pointer;" 
									onclick="toggleMyZoom(this);" 
									>	
									<svg:svg id="zoomsvgback" 
											version="1.1" 
											style="width:385px; 
													height:385px;" 
											viewBox="0 0 385 385" 
											preserveAspectRatio="none" 
											xmlns="http://www.w3.org/2000/svg">
									</svg:svg>
								</div>
							</div>
							<div id="addback-checkbox" style="width:190px;">
								<div style="display:inline-block;">
									<input type="checkbox" name="addback" id="addback" onclick="toggleAddBackDesign(this);"/>
									<label class="add-back-label" onclick="document.getElementById('addback').click();">
										<span id="addbackLabel">Add A Back Design?<br /><span style="color:#B7B7B7; font-size:12px;">Only $<span id="back-base-price">X.XX</span> Each</span></span>
									</label>
								</div>
							</div>
							<div id="addback-checkbox-replacement" style="width:190px;">
								&nbsp;
							</div>
							<!--This table will go away, I'm keeping this here for now in case I need it-->
							<table id="tbl-price-block" cellpadding="0" cellspacing="0" border="0" align="center" style="display:none;">
								<tr id="price-block-totalqty">
									<td style="text-algin:center;"><a id="toggle-price-detail" class="v-triangle-down" href="javascript:togglePriceDetail();" /></td>
								</tr>
								<tr id="price-block-priceeach" style="display:none;">
									<td style="text-algin:center;"></td>
								</tr>
								<tr id="price-block-sizepremium" style="display:none;">
									<td style="text-algin:center; vertical-align:middle;" valign="middle"></td>
								</tr>
								<tr id="price-block-backpremium" style="">
									<td style="text-algin:center; vertical-align:middle;" valign="middle"></td>
								</tr>
								<tr id="price-block-totaldiscount" style="">
									<td style="text-align:right; padding-right:12px; padding-bottom:10px;">You Save! </td>
									<td style="text-align:right; padding-right:12px; padding-bottom:10px;">-$<span id="total-discount">XX.XX</span></td>
									<td style="text-algin:center; vertical-align:middle; padding-bottom:10px;" valign="middle"></td>
								</tr>
								<tr id="price-block-ordertotal">
									<td style="text-algin:center;"></td>
								</tr>
								<tr id="price-block-total" style="display:none;">
									<td style="text-align:right; padding-right:12px;">Total:</td>
									<td style="text-align:right; padding-right:12px;">$<span id="total">XX.XX</span></td>
									<td style="text-algin:center; vertical-align:middle;" valign="middle"></td>
								</tr>
							</table>
						</div>

						<div id="sizes-block-wrapper">
							<div id="sizes-block-header" style="display:block;position:relative;font-size:10px;padding:3px 0;background-color:#ECECEC;">
								<div style="display:inline-block; width:90%; position:relative;">
									<div style="float:left; width:116px;">Size</div>
									<div style="float:left; width:60px;">Quantity</div>
									<div style="float:right; width:126px;">Price (each)</div>
								</div>
							</div>
							<div id="sizes-block" style="display:block;">
								<div class="cp-row" id="cr_0">
									<div style="display:inline-block; width:90%;">
										<select class="cart-size-field" name="sku" onchange="setPrice();" id="cS"></select>
										<input 	class="cart-quantity-field"
												id="cQ" 
												name="quan" 
												type="number" 
												value="1" 
												pattern="[0-9]*" 
												placeholder="Quan" 
												min="1" 
												step="1" 
												onclick="this.select();" 
												onchange="setPrice();"
												onkeyup="setPrice();"
												<cfif url.skuprice eq '' or url.skuprice eq '0.00'>disabled="disabled"</cfif>
										/>
										<div class="cart-price-field"></div>
										<div style="clear:both;"></div>
										<input id="cart-name-field-0" class="cart-name-field" placeholder="enter name" maxlength="50" onclick="this.select();" />
										<input id="cart-number-field-0" class="cart-number-field" placeholder="enter number" maxlength="3" onclick="this.select();" />
										<div style="clear:both;"></div>
									</div>
								</div>
							</div>

						
							<div id="add-row" class="cp-row short" onclick="cloneSizeBlock();" style="text-align:left;border-bottom:0;<cfif url.skuprice eq '' or url.skuprice eq '0.00'>display:none;</cfif>">
								<div id="cart-view-toggle">+ Buy More</div>
							</div>
						</div>	<!--- #sizes-block-wrapper --->
						<div id="totals-block-wrapper">
							<div id="totals-block-header" style="height:41px;display:block;position:relative;font-size:10px;padding:3px 0;background-color:#ECECEC;">
								<div style="display:inline-block; width:90%; position:relative;">
									<div style="float:right;margin-right:30px;">
										<table>
											<tr><td valign="top" style="font-size:12px;" align="right">Back Designs(<span id="quan-back-designs-bottom">0</span>):</td><td width="20">
											</td><td valign="top" style="font-size:12px;" align="left">$<span id="back-premium-bottom">0.00</span></td></tr>
											<tr><td valign="top" style="font-size:14px; color:#333333; font-weight: bold;" align="right">ORDER TOTAL:</td><td width="20">
											</td><td valign="top" style="font-size:14px; color:#333333; font-weight: bold;" align="left">$<span id="order-total-bottom">0.00</span></td></tr>
										</table>										
									</div>
								</div>
							</div>
						</div>
					</div>
						
					<!---
					<div class="navcircle-outer"><div class="navcircle-on" /></div>
					<div class="navcircle-outer" onclick="showCartPageTwo()"><div class="navcircle-off" /></div>
					<div class="navcircle-outer"><div class="navcircle-off" /></div>
					--->
				</div>
				<div id="cart-page-2">
					<div id="cart-back-designs" style="height:335px; display:block; text-align:center;">
						<div id="cart-svgbacklist-wrapper" style="width:298px; height:335px; overflow:hidden; position:absolute; top:10px; left:-149px; margin-left:50%;">
							<div 	id="cart-svgbacklist" 
									style=	"width:345px; 
											height:335px; 
											padding:0; 
											text-align:left; 
											overflow-y:auto; 
											/* opacity: 1; */ 
											/* position:absolute; */ 
											/* top:0; */
											/* display:inline-block; */ 
											/* margin-left:50%; */ 
											/* left:-160px; */ ">
							</div>
						</div>
					</div>
					<a id="cart-btnDoneChoosingDesign" class="btnOrange" href="" style="width:250px; position:relative; margin-top:12px; display:inline-block;" onclick="showCartPageOne();return false;">NO THANKS</a>
					<!---
					<div class="navcircle-outer" onclick="showCartPageOne()"><div class="navcircle-off" /></div>
					<div class="navcircle-outer"><div class="navcircle-on" /></div>
					<div class="navcircle-outer"><div class="navcircle-off" /></div>
					--->
				</div>
				<div id="cart-page-messages">
					<div style="display:block; text-align:center; position:relative; padding-top:30px;">
						<div id="single-size-error" class="cart-error-messages">
							<h3 style="color:red; font-weight:bold; text-shadow:0 1px 2px rgba(0,0,0,0.3);">WAIT!</h3>
							<p>You have not selected a size for your item.</p>
							<p>Please click the "fix it" button below to return to the form and select a size.</p>
							<a href="" class="btnOrange" style="width:200px; display:inline-block;" onclick="toggleCartPageMessages('off'); return false;">Fix it</a>
						</div>
						<div id="multiple-size-error" class="cart-error-messages">
							<h3 style="color:red; font-weight:bold; text-shadow:0 1px 2px rgba(0,0,0,0.3);">WAIT!</h3>
							<p>You have not selected a size for 1 or more of your items.</p>
							<p>Please click the "fix it" button below to return to the form and select the sizes (the sizes missed will be highlighted in red).</p>
							<span class="btnOrange" style="width:200px; display:inline-block;" onclick="toggleCartPageMessages('off'); return false;">Fix it</span>
						</div>
						<div id="name-number-error" class="cart-error-messages">
							<h3 style="color:red; font-weight:bold; text-shadow:0 1px 2px rgba(0,0,0,0.3);">WAIT!</h3>
							<p>You have not entered names or numbers for 1 or more items...</p>
							<p>You can continue and those portions of the design will remain blank, or you can return to the form and fix it.</p>
							<p class="btnOrange" style="width:200px; display:inline-block;" onclick="toggleCartPageMessages('off'); return false;">Fix it</p>
							<p>OR</p>
							<p class="btnGreen" style="width:200px; display:inline-block;" onclick="submitCart(); return false;">Continue</p>
						</div>
						<div id="cart-submit-message" class="cart-error-messages" style="padding: 0px; display: inline-block; margin-top: -20px; width: 98%;">
							<div id="top" style="width:100%;   text-align:center;   margin:0 auto;   box-shadow:0 4px 20px rgba(55, 55, 55, 0.28);   top:0;   position:absolute;   border-top-left-radius:inherit;   border-top-right-radius:inherit;">
								<p>Your item(s) have been added to your cart!</p>
							</div>
							<div id="left" style="width: 90%; height: 100%; float:left; display:inline-block; margin-top:130px; margin-left: 0px; position:relative; box-sizing:border-box; /* height: 390px; */">
								<div style="position: relative;margin: 0 auto;width: 390px;height: 208px;">
								<img id="promoImg" style="position: absolute;top: 15px;left:120px;margin: 0;" src="_img/ATC_circle_withtext.png" />
								<img id="shirtImg" style="position: absolute; top:0; left: 0; margin:0;" src="_img/ATC_tee.png" />
								<p id="promoText" style="position: absolute;top:150px;left:125px;margin: 0;color: rgb(113, 113, 113);font-style: italic;font-size: 14px;">This Promo will load automatically.</p>
								</div>
							</div>
							<div id="right" style="width: 30%; height: 390px; float:right; display:inline-block; margin-top:50px; background-color:rgba(0, 0, 0, 0.17); padding-top:45px; border-bottom-right-radius:inherit;">							
							<a href="javascript:void(0);" class="btnContinueShopping" style="width: 200px; display: inline-block; margin-top:80px;" onclick="continueShopping();">CONTINUE SHOPPING</a>
							<a href="javascript:void(0);" class="btnGreen" style="width: 200px; display: inline-block; margin-top:50px;" onclick="window.parent.location='<cfoutput>#cartHost#/showcart.cfm?sc_id=#url.sc_id#</cfoutput>';">CHECKOUT NOW</a>
							</div>							
							<!---
							<h3 style="color:red; font-weight:bold; text-shadow:0 1px 2px rgba(0,0,0,0.3);">Success</h3>
							<p>Your items have been added to your cart!</p>
							<a href="javascript:void(0);" onclick="window.parent.location='<cfoutput>#cartHost#/showcart.cfm?sc_id=#url.sc_id#</cfoutput>';" class="btnGreen" style="width:200px; display:inline-block;">Check Out</a>
							<p>OR</p>
							<p class="btnOrange" style="width:200px; display:inline-block;" onclick="closeCart(); return false;">Back</p>
							--->
							<a href="javascript:closeCart();" class="cart-close" />
						</div>
					</div>
				</div>
				<div id="cart-page-cover" style="display:none;">	<!--- used as a big button so that you can click anywhere to close something --->
					<a href="#" style="position:absolute; top:0; left:0; display:block; margin:0; padding:0; width:100%; height:100%; background-color:rgba(0,0,0,0)" onclick="togglePriceDetail(); return false;" />
				</div>
			</div>
			<a href="javascript:closeCart();" class="cart-close" />
		</div>
	</div>
</body>
</html>

<cfscript>
	function HighAsciiSafe(text) {
		var i = 0;
		var tmp = '';
		while(ReFind('[^\x00-\x7F]',text,i,false)) {
			i = ReFind('[^\x00-\x7F]',text,i,false); // discover high chr and save it's numeric string position.
			tmp = '&##x#FormatBaseN(Asc(Mid(text,i,1)),16)#;'; // obtain the high chr and convert it to a hex numeric chr.
			text = Insert(tmp,text,i); // insert the new hex numeric chr into the string.
			text = RemoveChars(text,i,1); // delete the redundant high chr from string.
			i = i+Len(tmp); // adjust the loop scan for the new chr placement, then continue the loop.
		}
		return text;
	}
</cfscript>