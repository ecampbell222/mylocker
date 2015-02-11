<cfcomponent displayname="Design" hint="Methods for handling Designs and Design Specs" output="false">

	<cfset dsn 				= "cwdbsql" />							<!--- Datasource name --->
	<cfset Design_Table 	= "Design" />							<!--- Table holding Designs --->
	<cfset Text_Table 		= "Design_Text" />						<!--- Table holding text elements of designs --->
	<cfset Graphic_Table 	= "Design_Graphic" />					<!--- Table holding graphic elements of designs --->
	<cfset host 			= CGI.SERVER_NAME />
	<cfset server_ips 		= "204.12.26.177,76.12.80.110,76.12.154.167" />
<!---
	TODO:
		a. copy tables to dev tbl_school_logo tables
		b. populate some fake data

		rewrite getDesigns queries
		make it so buildXML uses new cases

		1. Check the activity id passed, should be api_designcategory_activity_id
		2. None can also be passed
		3. get all custom and non custom logos (need from Todd, look in db first)
		4. get all possible designs for each logo (need from Todd, look in db first)
		5. combine and generate xml


--->	
	<cffunction access="remote" name="list" hint="returns xml for all designs matching criteria">
		<cfargument name="designTypeId" required="false" default="1" />
		<cfargument name="frontDesignTypeId" required="false" default="1" />
		<cfargument name="activityId" required="false" default="" />
		<cfargument name="schoolsId" required="false" default="" />
		<cfargument name="interest" required="false" default="" />
		<cfargument name="appMode" required="false" default="" />
		<cfargument name="designStatus" required="false" default="-99" />	<!--- only used in manager mode --->
		<cfargument name="isSVG" required="false" default="0" />
		<cfargument name="d" required="false" default="0" hint="design id that will be the top hit (position 1)" />
		<cfargument name="g" required="false" default="" hint="graphic file name to use if 'd' above is a logo or mascot design" />

		<cfset var imagePath = ExpandPath("/BWImages") />
		<cfset mascotImages = ArrayNew(1) />
		<cfset logoImages = ArrayNew(1) />
		<cfset embMascotImages = ArrayNew(1) />
		<cfset embLogoImages = ArrayNew(1) />
		<cfset vcMascotImages = ArrayNew(1) />
		<cfset vcLogoImages = ArrayNew(1) />
		<cfset dImages = ArrayNew(1) />							<!--- filled with 'g' when a 'd' design is being requested --->
		<cfset cImages = ArrayNew(1) />							<!--- filled with temporary cutomer-uploaded images --->
		<cfset doMascot = false />
		<cfset doLogo = false />
		<cfset doEmbMascot = false />
		<cfset doEmbLogo = false />
		<cfset doVcMascot = false />
		<cfset doVcLogo = false />
		
		<!--- are we in "manager" mode, or regular? --->
		<cfif appMode eq "manager">
			<!---Removed for now--->			
		<cfelse>	<!--- appMode is not "manager" --->
		<!--- is activityId undefined, null, empty, or 0? --->
		<!--- then get the default activity for this school --->
		<cfif (activityId is "undefined" or activityId is "" or activityId is 0) and (schoolsId is not "" and schoolsId is not "0")>
			<cfquery name="defaultActivity" datasource="#dsn#">
				SELECT 		CASE WHEN a.activity_id IS NULL THEN 0 ELSE a.activity_id END ACTIVITYID, b.activity ACTIVITY
				FROM		tbl_buildastore b WITH (NOLOCK)
				LEFT JOIN	Activity a WITH (NOLOCK) ON a.name = b.activity
				WHERE		b.id = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#schoolsId#" />
			</cfquery>
			<cfif defaultActivity.RecordCount gt 0>
				<cfset activityId = defaultActivity.ACTIVITYID />
			</cfif>
		</cfif>
		
		<!--- ****** Get Length of Shop's Name ******* --->
		<cfparam name="getShopNameLength.ShortNameLength" default="0" />
		<cfif schoolsId neq "" and schoolsId neq "0">
			<cfquery name="getShopNameLength" datasource="#dsn#">
				SELECT 		LEN(sc.ShortName) ShortNameLength
				FROM 		SchoolColors sc WITH (NOLOCK)
				WHERE 		sc.id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#schoolsId#" />
			</cfquery>
		</cfif>
		
		<!--- ****** Get Shop's Preferences ****** --->
		<cfset shopPreferences = StructNew() />
		<cfstoredproc procedure="usp_getShopPreferences" datasource="#dsn#">
			<cfprocparam cfsqltype="cf_sql_varchar" value="#schoolsId#" />
			<cfprocresult name="getShopPreferences" />
		</cfstoredproc>
		<cfif getShopPreferences.RecordCount gt 0>
			<cfloop query="getShopPreferences">
				<cfset temp = StructInsert(shopPreferences, getShopPreferences.pref_name, getShopPreferences.pref_value) />
			</cfloop>
		<cfelse>
			<!--- this stuff really should just be a bunch of cfparams --->
			<cfset shopPreferences.showOnlyLogoDesignsDigital = 0 />
			<cfset shopPreferences.showOnlyLogoDesignsVersa = 0 />
			<cfset shopPreferences.showOnlyLogoDesignsEmb = 0 />
			<cfset shopPreferences.showOnlyMascotDesignsDigital = 0 />
			<cfset shopPreferences.showOnlyMascotDesignsVersa = 0 />
			<cfset shopPreferences.showOnlyMascotDesignsEmb = 0 />
			<cfset shopPreferences.showGenericDesignsDigital = 1 />
			<cfset shopPreferences.showGenericDesignsVersa = 1 />
			<cfset shopPreferences.showGenericDesignsEmb = 1 />
		</cfif>
		<cfparam name="shopPreferences.showAllBackDesigns" default="1" />
		
		<!--- ********* Get Shop Logos ********* --->
		<cfquery name="getSchoolPic" datasource="#dsn#">
			SELECT 		[name], isDigMascot, isDigLogo, isEmbMascot, isEmbLogo, isVcMascot, isVcLogo, ISNULL(isPhoto,0) isPhoto 
			FROM 		tbl_school_logo WITH (NOLOCK) 
			WHERE 		idschool = <cfqueryparam cfsqltype="cf_sql_varchar" value="#schoolsId#" />
				AND 	(delete_dt IS NULL OR delete_dt = '')
				AND 	logoStatusID >= 20
		</cfquery>

		<!--- ******** get logged-in user's uploaded logos ******** --->
		<cfif isDefined("cookie.session.clientidz") && len(cookie.session.clientidz) 
				&& (designTypeId eq "1" or designTypeId eq "3" or designTypeId eq "4")>
			<cfquery name="userLogos" datasource="#dsn#">
				SELECT 		LogoName, LogoColorType, ISNULL(isPhoto,0) isPhoto
				FROM 		cLogoUploads WITH (NOLOCK)
				WHERE 		cst_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#cookie.session.clientidz#" />
					AND 	logoActive = 1
				ORDER BY 	LogoCreatedDate DESC
			</cfquery>
		</cfif>
		<cfparam name="userLogos.recordcount" default="0" />
		<cfif userLogos.recordcount neq "0">
			<cfloop query="userLogos">
				<cfif 	(designTypeId eq "3" and userLogos.LogoColorType eq "1")
						or (designTypeId eq "1" and userLogos.LogoColorType eq "2")
						or (designTypeId eq "4" and frontDesignTypeId eq "1" and userLogos.LogoColorType eq "2")>
					<cfset temp = structNew() />
					<cfset temp.i = "cuploads/" & Left(userLogos.LogoName, 35) />
					<cfset temp.isphoto = userLogos.isPhoto />
					<cfset arrayAppend(cImages, temp) />
					<!--- <cfset arrayAppend(cImages, "cuploads/" & Left(userLogos.LogoName, 35)) /> --->
				</cfif>
			</cfloop>
		</cfif>

		<!--- ********* if this is a 'd' design ********** --->
		<cfif d neq '0'>
			<!--- TO DO: WE HAVE TO LOOK UP IF THIS IS A PHOTO OR NOT! --->
			<cfset temp = structNew() />
			<cfset temp.i = g />
			<cfset temp.isphoto = 0 />
			<cfset arrayAppend(dImages, temp) />
			<!--- <cfset added = ArrayAppend(dImages,g) /> --->
		</cfif>

		<!--- loop through results in case we have different types of uploads for the same school --->
		<cfloop query="getSchoolPic">
			<cfif len(trim(getSchoolPic.name))>
				<cfset picture = trim(getSchoolPic.name) />			
				<cfif FindLast(".", picture) gt 0 and (Len(picture)-FindLast(".", picture) gt 1)>
					<!--- <cfset picture = LEFT(picture, FindLast(".", picture)-1) & ".swf" /> --->
					<!--- <cfif FileExists("#imagePath#/#picture#")> --->
						<cfif getSchoolPic.isDigMascot eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(mascotImages, temp) />
							<!--- <cfset added = ArrayAppend(mascotImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doMascot = true />
						</cfif>
						<cfif getSchoolPic.isDigLogo eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(logoImages, temp) />
							<!--- <cfset added = ArrayAppend(logoImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doLogo = true />
						</cfif>
						<cfif getSchoolPic.isEmbMascot eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(embMascotImages, temp) />
							<!--- <cfset added = ArrayAppend(embMascotImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doEmbMascot = true />
						</cfif>
						<cfif getSchoolPic.isEmbLogo eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(embLogoImages, temp) />
							<!--- <cfset added = ArrayAppend(embLogoImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doEmbLogo = true />
						</cfif>
						<cfif getSchoolPic.isVcMascot eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(vcMascotImages, temp) />
							<!--- <cfset added = ArrayAppend(vcMascotImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doVcMascot = true />
						</cfif>
						<cfif getSchoolPic.isVcLogo eq 1>
							<cfset temp 		= structNew() />
							<cfset temp.i 		= LEFT(picture, FindLast(".", picture)-1) />
							<cfset temp.isphoto = getSchoolPic.isPhoto />
							<cfset arrayAppend(vcLogoImages, temp) />
							<!--- <cfset added = ArrayAppend(vcLogoImages, LEFT(picture, FindLast(".", picture)-1)) /> --->
							<cfset doVcLogo = true />
						</cfif>
					<!--- </cfif> --->
				</cfif>
			</cfif>
		</cfloop>

		<cftry>
			<cfif 	(shopPreferences.showOnlyLogoDesignsDigital and doLogo and (designTypeId eq 1 or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and frontDesignTypeId eq 1))) or
					(shopPreferences.showOnlyLogoDesignsVersa and doVcLogo and ((designTypeId eq 2 or designTypeId eq 5) or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and (frontDesignTypeId eq 2 or frontDesignTypeId eq 5)))) or
					(shopPreferences.showOnlyLogoDesignsEmb and doEmbLogo and (designTypeId eq 3 or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and frontDesignTypeId eq 3)))>
				<!--- ***** ONLY LOGO DESIGNS ******** --->
				<cfquery name="GetDesigns" datasource="#dsn#">
					SELECT d.*,NULL activity_id,NULL activity,3 orderHelper,'Logo' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = #designTypeId#
						AND d.isLogoDesign = 1
						AND d.isMascotDesign = 0
							<cfif not find("dev", host)>
						AND d.isActive = 1
							</cfif>
							<cfif isSVG eq "1">
						<!--- AND d.SVGStatus = 1 --->
							</cfif>
					<cfif d neq '0'>
					UNION
					SELECT d.*,NULL activity_id,NULL activity,2 orderHelper,'d' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#designTypeId#" />
						AND d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#d#" />
					</cfif>
					<cfif arrayLen(cImages) gt 0>
					UNION
					SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'c' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = #designTypeId#
						AND d.isLogoDesign = 1
						AND d.isMascotDesign = 0
							<cfif not find("dev", host)>
						AND d.isActive = 1
							</cfif>
							<cfif isSVG eq "1">
						<!--- AND d.SVGStatus = 1 --->
							</cfif>
					</cfif>
					<cfif d neq '0' or arrayLen(cImages) gt 0>
					ORDER BY orderHelper, randomHelper
					</cfif>
				</cfquery>
			<cfelseif 	(shopPreferences.showOnlyMascotDesignsDigital and doMascot and (designTypeId eq 1 or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and frontDesignTypeId eq 1))) or
						(shopPreferences.showOnlyMascotDesignsVersa and doVcMascot and ((designTypeId eq 2 or designTypeId eq 5) or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and (frontDesignTypeId eq 2 or frontDesignTypeId eq 5)))) or
						(shopPreferences.showOnlyMascotDesignsEmb and doEmbMascot and (designTypeId eq 3 or (not shopPreferences.showAllBackDesigns and designTypeId eq 4 and frontDesignTypeId eq 3)))>
				<!--- ***** ONLY MASCOT DESIGNS ******** --->
				<cfquery name="GetDesigns" datasource="#dsn#">
					SELECT d.*,NULL activity_id,NULL activity,2 orderHelper,'Mascot' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = #designTypeId#
						AND d.isLogoDesign = 0
						AND d.isMascotDesign = 1
							<cfif not find("dev", host)>
						AND d.isActive = 1
							</cfif>
							<cfif isSVG eq "1">
						<!--- AND d.SVGStatus = 1 --->
							</cfif>
					<cfif d neq '0'>
					UNION
					SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'d' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#designTypeId#" />
						AND d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#d#" />
					</cfif>
					<cfif arrayLen(cImages) gt 0>
					UNION
					SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'c' designGroup,NEWID() randomHelper,dt.max_chars maxChars
					FROM [Design] d WITH (NOLOCK)
					LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
					WHERE d.designType_id = #designTypeId#
						AND d.isLogoDesign = 1
						AND d.isMascotDesign = 0
							<cfif not find("dev", host)>
						AND d.isActive = 1
							</cfif>
							<cfif isSVG eq "1">
						<!--- AND d.SVGStatus = 1 --->
							</cfif>
					</cfif>
					<cfif d neq '0' or arrayLen(cImages) gt 0>
					ORDER BY orderHelper, randomHelper
					</cfif>
				</cfquery>
			<cfelse>
				<!--- grab designs normally --->
				<cfif activityId neq "" and activityId neq "undefined" and activityId neq "0">	<!--- An activity (sport) has been selected --->
					<cfquery name="GetDesigns" datasource="#dsn#">
						SELECT d.*,a.activity_id,a.name activity,6 orderHelper,'activity' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						LEFT JOIN [Design_Activity_Link] da WITH (NOLOCK) ON da.design_id = d.design_id
						LEFT JOIN [Activity] a WITH (NOLOCK) ON a.activity_id = da.activity_id
						WHERE da.activity_id = #activityId#
							AND d.designType_id = #designTypeId#
							AND d.isLogoDesign = 0
							AND d.isMascotDesign = 0
							<cfif not find("dev",host)>
							AND d.isActive = 1
							</cfif>
							<cfif isSVG eq "1">
							<!--- AND d.SVGStatus = 1 --->
							</cfif>
						<cfif 	(shopPreferences.showGenericDesignsDigital and designTypeId eq 1) or
								(shopPreferences.showGenericDesignsVersa and (designTypeId eq 2 or designTypeId eq 5)) or
								(shopPreferences.showGenericDesignsEmb and designTypeId eq 3) or
								(designTypeId eq 4)>
						UNION
						SELECT d.*,NULL activity_id,NULL activity,10 orderHelper,'noActivity' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						WHERE d.designType_id = #designTypeId#
							AND d.isLogoDesign = 0
							AND d.isMascotDesign = 0
								<cfif not find("dev", host)>
							AND d.isActive = 1
								</cfif>
								<cfif isSVG eq "1">
							<!--- AND d.SVGStatus = 1 --->
								</cfif>
							AND NOT EXISTS (
								SELECT da.design_id
								FROM [Design_Activity_Link] da WITH (NOLOCK)
								WHERE da.design_id = d.design_id
								)
						</cfif>
						<cfif (doLogo and (frontDesignTypeId is not "3" and frontDesignTypeId is not "2" and frontDesignTypeId is not "5")) 
								or (doEmbLogo and frontDesignTypeId is "3")
								or (doVcLogo and (frontDesignTypeId is "2" or frontDesignTypeId is "5"))>
						UNION
						SELECT d.*,NULL activity_id,NULL activity,3 orderHelper,'Logo' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						WHERE d.designType_id = #designTypeId#
							AND d.isLogoDesign = 1
							AND d.isMascotDesign = 0
								<cfif not find("dev", host)>
							AND d.isActive = 1
								</cfif>
								<cfif isSVG eq "1">
							<!--- AND d.SVGStatus = 1 --->
								</cfif>
							AND NOT EXISTS (
								SELECT da.design_id
								FROM [Design_Activity_Link] da WITH (NOLOCK)
								WHERE da.design_id = d.design_id
								)
						</cfif>
						<cfif (doMascot and (frontDesignTypeId is not "3" and frontDesignTypeId is not "2" and frontDesignTypeId is not "5")) 
								or (doEmbMascot and frontDesignTypeId is "3") 
								or (doVcMascot and (frontDesignTypeId is "2" or frontDesignTypeId is "5"))>
						UNION
						SELECT d.*,NULL activity_id,NULL activity,4 orderHelper,'Mascot' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						WHERE d.designType_id = #designTypeId#
							AND d.isMascotDesign = 1
							AND d.isLogoDesign = 0
								<cfif not find("dev", host)>
							AND d.isActive = 1
								</cfif>
								<cfif isSVG eq "1">
							<!--- AND d.SVGStatus = 1 --->
								</cfif>
							AND NOT EXISTS (
								SELECT da.design_id
								FROM [Design_Activity_Link] da WITH (NOLOCK)
								WHERE da.design_id = d.design_id
								)
						</cfif>
						<cfif d neq '0'>	<!--- a single design has been requested to be featured --->
						UNION
						SELECT d.*,NULL activity_id,NULL activity,2 orderHelper,'d' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						WHERE d.designType_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#designTypeId#" />
							AND d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#d#" />
						</cfif>
						<cfif arrayLen(cImages) gt 0>
						UNION
						SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'c' designGroup,NEWID() randomHelper,dt.max_chars maxChars
						FROM [Design] d WITH (NOLOCK)
						LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
						WHERE d.designType_id = #designTypeId#
							AND d.isLogoDesign = 1
							AND d.isMascotDesign = 0
								<cfif not find("dev", host)>
							AND d.isActive = 1
								</cfif>
								<cfif isSVG eq "1">
							<!--- AND d.SVGStatus = 1 --->
								</cfif>
						</cfif>
						ORDER BY orderHelper,randomHelper
					</cfquery>
				<cfelse>	<!--- No activity (sport) selected --->
					<cfquery name="GetDesigns" datasource="#dsn#">
						SELECT * FROM (
							<!--- This gets designs that are sport specific --->
							<!---
							SELECT d.*,a.activity_id,a.name activity,10 orderHelper,'activity' designGroup,NEWID() randomHelper
							FROM [Design] d
							LEFT JOIN [Design_Activity_Link] da ON da.design_id = d.design_id
							LEFT JOIN [Activity] a ON a.activity_id = da.activity_id
							WHERE EXISTS (
								SELECT da.design_id
								FROM [Design_Activity_Link] da
								WHERE da.design_id = d.design_id
								)
								AND d.designType_id = #designTypeId#
							UNION
							--->
							SELECT d.*,NULL activity_id,NULL activity,6 orderHelper,'noActivity' designGroup,NEWID() randomHelper,dt.max_chars maxChars
							FROM [Design] d WITH (NOLOCK)
							LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
							WHERE d.designType_id = #designTypeId#
								AND d.isLogoDesign = 0
								AND d.isMascotDesign = 0
								<cfif not find("dev", host)>
								AND d.isActive = 1
								</cfif>
								<cfif isSVG eq "1">
								<!--- AND d.SVGStatus = 1 --->
								</cfif>
								AND NOT EXISTS (
									SELECT da.design_id
									FROM [Design_Activity_Link] da WITH (NOLOCK)
									WHERE da.design_id = d.design_id
									)
							<cfif (doLogo and (frontDesignTypeId is not "3" and frontDesignTypeId is not "2" and frontDesignTypeId is not "5")) 
									or (doEmbLogo and frontDesignTypeId is "3")
									or (doVcLogo and (frontDesignTypeId is "2" or frontDesignTypeId is "5"))>
							UNION
							SELECT d.*,NULL activity_id,NULL activity,3 orderHelper,'Logo' designGroup,NEWID() randomHelper,dt.max_chars maxChars
							FROM [Design] d WITH (NOLOCK)
							LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
							WHERE d.designType_id = #designTypeId#
								AND d.isLogoDesign = 1
								AND d.isMascotDesign = 0
									<cfif not find("dev", host)>
								AND d.isActive = 1
									</cfif>
									<cfif isSVG eq "1">
								<!--- AND d.SVGStatus = 1 --->
									</cfif>
								AND NOT EXISTS (
									SELECT da.design_id 
									FROM [Design_Activity_Link] da WITH (NOLOCK)
									WHERE da.design_id = d.design_id
									)
							</cfif>
							<cfif (doMascot and (frontDesignTypeId is not "3" and frontDesignTypeId is not "2" and frontDesignTypeId is not "5")) 
									or (doEmbMascot and frontDesignTypeId is "3") 
									or (doVcMascot and (frontDesignTypeId is "2" or frontDesignTypeId is "5"))>
							UNION
							SELECT d.*,NULL activity_id,NULL activity,4 orderHelper,'Mascot' designGroup,NEWID() randomHelper,dt.max_chars maxChars
							FROM [Design] d WITH (NOLOCK)
							LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
							WHERE d.designType_id = #designTypeId#
								AND d.isMascotDesign = 1
								AND d.isLogoDesign = 0
									<cfif not find("dev", host)>
								AND d.isActive = 1
									</cfif>
									<cfif isSVG eq "1">
								<!--- AND d.SVGStatus = 1 --->
									</cfif>
								AND NOT EXISTS (
									SELECT da.design_id
									FROM [Design_Activity_Link] da WITH (NOLOCK)
									WHERE da.design_id = d.design_id
									)
							</cfif>
							<cfif d neq '0'>	<!--- a single design has been requested to be featured --->
							UNION
							SELECT d.*,NULL activity_id,NULL activity,2 orderHelper,'d' designGroup,NEWID() randomHelper,dt.max_chars maxChars
							FROM [Design] d WITH (NOLOCK)
							LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
							WHERE d.designType_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#designTypeId#" />
								AND d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#d#" />
							</cfif>
							<cfif arrayLen(cImages) gt 0>
							UNION
							SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'c' designGroup,NEWID() randomHelper,dt.max_chars maxChars
							FROM [Design] d WITH (NOLOCK)
							LEFT JOIN [Design_text] dt WITH (NOLOCK) ON dt.design_id = d.design_id and dt.default_text = 'toptext' and dt.alt_content = 0
							WHERE d.designType_id = #designTypeId#
								AND d.isLogoDesign = 1
								AND d.isMascotDesign = 0
									<cfif not find("dev", host)>
								AND d.isActive = 1
									</cfif>
									<cfif isSVG eq "1">
								<!--- AND d.SVGStatus = 1 --->
									</cfif>
							</cfif>
						) inlineView
							<cfif (designTypeId neq "4")>
						ORDER BY orderHelper,randomHelper
						--ORDER BY design_id				 
							<cfelse>
							    ORDER BY design_id
							</cfif>					 
					</cfquery>
				</cfif>
			</cfif>
			<cfcatch type="Any" >
		
			</cfcatch>
		</cftry>

		</cfif>
		<cfset myResult = buildXML(#designTypeId#) />
		
		<cfreturn myResult />
	</cffunction>

<!-- -->
<!-- -->
<!-- -->
<cffunction access="remote" name="updateDesignsById" hint="updates a design">
	<cfargument name="send_id" required="false" default="1" />
    <cfquery datasource="#dsn#">
    UPDATE 	Design
    SET 	isLogoDesign = 0
    WHERE 	design_id = #send_id#
	</cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->

	<cffunction access="remote" name="getDesignsById" hint="returns xml for single design id">
		<cfargument name="designId" required="false" default="1" />
		<cfargument name="graphicFile" required="false" default="" />
		<cfset mascotImages = ArrayNew(1) />
		<cfset logoImages = ArrayNew(1) />
		<cfset cImages = ArrayNew(1) /> 				<!--- just so that it is defined --->
		<cfset dImages = ArrayNew(1) />					<!--- just so that it is defined --->
		<!--- TO-DO: WE ARE GOING TO HAVE TO LOOK UP IF THIS IS A PHOTO OR NOT! --->
		<cfset temp = structNew() />
		<cfset temp.i = graphicFile />
		<cfset temp.isphoto = 0 />
		<cfset arrayAppend(mascotImages, temp) />
		<cfset arrayAppend(logoImages, temp) />
		<!--- <cfset appendedMascot = ArrayAppend(mascotImages, graphicFile) /> --->
		<!--- <cfset appendedLogo = ArrayAppend(logoImages, graphicFile) /> --->
		
		<cftry>
			<cfquery name="GetDesigns" datasource="#dsn#">
				SELECT d.*,a.activity_id,a.name activity,5 orderHelper,'Plain' designGroup,NEWID() randomHelper
                FROM [Design] d WITH (NOLOCK)
                        LEFT JOIN [Design_Activity_Link] da WITH (NOLOCK) ON da.design_id = d.design_id
                        LEFT JOIN [Activity] a WITH (NOLOCK) ON a.activity_id = da.activity_id
				WHERE d.design_id = #designId#
					AND d.isMascotDesign = 0
					AND d.isLogoDesign = 0
				UNION
				SELECT d.*,NULL activity_id,NULL activity,1 orderHelper,'Logo' designGroup,NEWID() randomHelper
                FROM [Design] d WITH (NOLOCK)
				WHERE d.design_id = #designId#
					AND d.isLogoDesign = 1
					AND d.isMascotDesign = 0
				UNION
				SELECT d.*,NULL activity_id,NULL activity,3 orderHelper,'Mascot' designGroup,NEWID() randomHelper
                FROM [Design] d WITH (NOLOCK)
				WHERE d.design_id = #designId#
					AND d.isMascotDesign = 1
					AND d.isLogoDesign = 0
			</cfquery>
			<cfcatch type="database">
				<!--- To Do: Error Handling --->
			</cfcatch>
		</cftry>

		<cfset myResult = buildXML() />
		
		<cfreturn myResult />
	</cffunction>

	<cffunction name="buildXML" access="private">
		<cfargument name="designTypeId" required="false" default="1" />
		<cfset designsxmlspec = "<?xml version=""1.0"" encoding=""UTF-8"" ?>" />
		<cfset designsxml = "" />
		<cfset newline = Chr(13) & Chr(10) />
		<cfset tabchar = "   " />
				
		<cfif GetDesigns.recordcount gt 0 >
			<cfset designsxml = designsxml & "<designs>" & newline />
			<cfloop query="GetDesigns">					<!--- loop through the designs --->
				<cfif designGroup is 'c' && arrayLen(cImages) gt 0>
					<cfloop index=c from="1" to="#ArrayLen(cImages)#">			<!--- use each one of the images for this design --->
						<cfset designsxml = designsxml & addXMLString(c,'c',#designTypeId#) />
					</cfloop>
				<cfelseif designGroup is 'd' && arrayLen(dImages) gt 0>
					<cfset designsxml = designsxml & addXMLString(1, 'd', #designTypeId#) />
				<cfelseif designGroup is 'Mascot'>
					<cfif designTypeId is not "3" and designTypeId is not "2" and designTypeId is not "5">
						<cfloop index=m from="1" to="#ArrayLen(mascotImages)#">			<!--- use each one of the images for this design --->
							<cfset designsxml = designsxml & addXMLString(m,'Mascot',#designTypeId#) />
						</cfloop>
					<cfelseif designTypeId is "3">
						<cfloop index=m from="1" to="#ArrayLen(embMascotImages)#">
							<cfset designsxml = designsxml & addXMLString(m,'Mascot',#designTypeId#) />
						</cfloop>
					<cfelseif designTypeId is "2" or designTypeId is "5">
						<cfloop index=m from="1" to="#ArrayLen(vcMascotImages)#">
							<cfset designsxml = designsxml & addXMLString(m,'Mascot',#designTypeId#) />
						</cfloop>
					</cfif>
				<cfelseif designGroup is 'Logo'>
					<cfif arrayLen(cImages) gt 0>
						<cfloop index=l from="1" to="#ArrayLen(cImages)#">
							<cfset designsxml = designsxml & addXMLString(l, 'Logo', #designTypeId#) />							
						</cfloop>
					<cfelseif designTypeId is not "3" and designTypeId is not "2" and designTypeId is not "5">
						<cfloop index=l from="1" to="#ArrayLen(logoImages)#">			<!--- use each logo image for the design --->
							<cfset designsxml = designsxml & addXMLString(l,'Logo',#designTypeId#) />
						</cfloop>
					<cfelseif designTypeId is "3">
						<cfloop index=l from="1" to="#ArrayLen(embLogoImages)#">			<!--- use each logo image for the design --->
							<cfset designsxml = designsxml & addXMLString(l,'Logo',#designTypeId#) />
						</cfloop>
					<cfelseif designTypeId is "2" or designTypeId is "5">
						<cfloop index=l from="1" to="#ArrayLen(vcLogoImages)#">			<!--- use each logo image for the design --->
							<cfset designsxml = designsxml & addXMLString(l,'Logo',#designTypeId#) />
						</cfloop>
					</cfif>
				<cfelse>
					<cfset designsxml = designsxml & addXMLString() />
				</cfif>
			</cfloop>
			<cfset designsxml = designsxml & "</designs>" & newline />
		<cfelse>
			<!--- No Designs were found... return an empty xml doc --->
			<cfreturn designsxmlspec & newline & "<designs>" & newline & "</designs>" & newline />
		</cfif>

		<cfreturn designsxmlspec & newline & designsxml />
	</cffunction>
	
	<cffunction name="addXMLString" access="private">
		<cfargument name="myIndex" required="false" default="" />
		<cfargument name="indexType" required="false" default="" />
		<cfargument name="designTypeId" required="false" default="1" />
		<cfset designNode = "" />
		<cfset textNodes = "" />
		<cfset graphicNodes = "" />
		<cfset isSameColor = GetDesigns.graphic_color_matches_text />
		<cfset skipBecauseOfLength = false />
		<cfquery name="t" datasource="#dsn#">
			SELECT class,font,font_size,char_spacing,pos_x,pos_y,arc_rise,SkewedOrRotated,rotation,max_chars,max_height,max_width,fixed_width,default_text,all_caps,layer,doApplyStroke,color_index,stroke_color_index,stroke_size,alt_content
            FROM #Text_Table# WITH (NOLOCK)
			WHERE design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#GetDesigns.design_id#" />
		</cfquery>
		<cfquery name="g" datasource="#dsn#">
			SELECT filename,pos_x,pos_y,full_color,layer,initial_scale,color_index
            FROM #Graphic_Table# WITH (NOLOCK)
			WHERE design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#GetDesigns.design_id#" />
		</cfquery>
		<cfif g.recordcount gt 0 or t.recordcount gt 0 or GetDesigns.designGroup is 'Mascot' or GetDesigns.designGroup is 'Logo'>
			<!--- **** check this design's maxChars against the shop's shortNameLength **** --->
			<cfif isDefined('GetDesigns.maxChars') && GetDesigns.designGroup neq 'd'> <!--- it's not defined when called from the getDesignById method --->
				<cfif t.recordcount gt 0 and isNumeric(GetDesigns.maxChars)>
					<cfif GetDesigns.maxChars gt 0 and GetDesigns.maxChars lt getShopNameLength.ShortNameLength>
						<cfset skipBecauseOfLength = true />
					</cfif>
				</cfif>
			</cfif>
			<cfif not skipBecauseOfLength>
				<cfset designNode = designNode & "#tabchar#<design design_id=""" & GetDesigns.design_id & 
						""" orderHelper=""" & GetDesigns.orderHelper & 
						""" designGroup=""" & GetDesigns.designGroup & 
						""" extraCost=""" & GetDesigns.extraCost & 
						""" activity_id=""" & GetDesigns.activity_id & 
						""" activity=""" & XMLFormat(GetDesigns.activity) & 
						""" numberOfColors=""" & GetDesigns.numberOfColors &
						""" isActive=""" & GetDesigns.isActive & """" />
				<!--- Add text elements to XML spec --->
				<cfloop query="t">
					<cfset textNodes = textNodes & 
						"#tabchar##tabchar#<detail node_type=""text"" " &
						"text_id=""1"" " &
						"text_type=""#t.class#"" " &
						"font_name=""#t.font#"" " &
						"font_size=""#t.font_size#"" " &
						"text_spacing=""#t.char_spacing#"" " &
						"text_x=""#t.pos_x#"" " &
						"text_y=""#t.pos_y#"" " &
						"text_height=""#t.arc_rise#"" " &
						"text_skew_or_rotate=""#t.SkewedOrRotated#"" " &
						"text_rotation=""#t.rotation#"" " &
						"text_max_height=""#t.max_height#"" " &
						"text_max_width=""#t.max_width#"" " &
						"text_fixed_width=""#t.fixed_width#"" " &
						"text_max_chars=""#t.max_chars#"" " &
						"text_field=""#XMLFormat(t.default_text)#"" " &
						"text_all_caps=""#t.all_caps#"" " &
						"text_scale=""1"" " &
						"text_alt_content=""#t.alt_content#"" " &
						"layer=""#t.layer#"" " &
						"doApplyStroke=""#t.doApplyStroke#"" " &
						"color_index=""#t.color_index#"" " &
						"stroke_color_index=""#t.stroke_color_index#"" " &
						"stroke_size=""#t.stroke_size#"" " &
						"/>" & newline />
				</cfloop>
				<!--- Add graphic elements to XML spec --->
				<cfloop query="g">
					<cfset graphicNodes = graphicNodes & 
						"#tabchar##tabchar#<detail node_type=""graphic"" " />
					<cfif indexType is 'c' and g.filename is 'placeHolder'>
						<cfset graphicNodes = graphicNodes &
								"graphic_name=""#XMLFormat(cImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#cImages[myIndex].isphoto#"" " />
						<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(cImages[myIndex].i)# & """" />
					<cfelseif indexType is 'd' and g.filename is 'placeHolder'>
						<cfset graphicNodes = graphicNodes &
								"graphic_name=""#XMLFormat(dImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#dImages[myIndex].isphoto#"" " />
						<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(dImages[myIndex].i)# & """" />
					<cfelseif indexType is 'Mascot' and g.filename is 'placeHolder'>
						<cfif designTypeId is not "3" and designTypeId is not "2" and designTypeId is not "5">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(mascotImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#mascotImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(mascotImages[myIndex].i)# & """" />
						<cfelseif designTypeId is "3">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(embMascotImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#embMascotImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(embMascotImages[myIndex].i)# & """" />					
						<cfelseif designTypeId is "2" or designTypeId is "5">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(vcMascotImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#vcMascotImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(vcMascotImages[myIndex].i)# & """" />					
						</cfif>
					<cfelseif indexType is 'Logo' and g.filename is 'placeHolder'>
						<cfif designTypeId is not "3" and designTypeId is not "2" and designTypeId is not "5">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(logoImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#logoImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(logoImages[myIndex].i)# & """" />
						<cfelseif designTypeId is "3">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(embLogoImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#embLogoImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(embLogoImages[myIndex].i)# & """" />
						<cfelseif designTypeId is "2" or designTypeId is "5">
							<cfset graphicNodes = graphicNodes &
									"graphic_name=""#XMLFormat(vcLogoImages[myIndex].i)#"" logo_graphic=""1"" isPhoto=""#vcLogoImages[myIndex].isphoto#"" " />
							<cfset designNode = designNode & " graphicFile=""" & #XMLFormat(vcLogoImages[myIndex].i)# & """" />
						</cfif>
					<cfelse>
						<cfset graphicNodes = graphicNodes &
								"graphic_name=""#XMLFormat(g.filename)#"" logo_graphic=""0"" isPhoto=""0"" " />
						<!--- <cfset designNode = designNode & " graphicFile=""""" /> --->
					</cfif>
					<cfif g.full_color is 0>
						<cfset isSameColor = 1 />
					<cfelseif g.full_color is 1>
						<cfset isSameColor = 0 />
					<cfelse>
						<cfset isSamecolor = g.full_color />
					</cfif>
					<cfset graphicNodes = graphicNodes &
						"pos_x=""#g.pos_x#"" " &
						"pos_y=""#g.pos_y#"" " &
						"text_scale=""1"" " &
						"text_rotation=""1"" " &
						"layer=""#g.layer#"" " & 
						"initial_scale=""#g.initial_scale#"" " &
						"isSameColor=""#isSameColor#"" " & 
						"color_index=""#g.color_index#"" " & 
						"/>" & newline />
				</cfloop>
				<cfset designNode = designNode & ">" & newline />
				<cfreturn designNode & textNodes & graphicNodes & "#tabchar#</design>" & newline />
			</cfif>
		</cfif>
	</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="addGraphicCategory" access="remote" hint="adds graphic category">
	<cfargument name="send_name" type="string" required="yes" />
        <cfquery datasource="#dsn#">
        INSERT INTO graphics_categories (
                        category_name
                        )
                        
        VALUES (
            '#send_name#'
            )
        </cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getGraphicCategories" access="remote" returntype="query" hint="gets graphic categories">
        <cfquery name="getGraphicCategoriesQuery" datasource="#dsn#">
        SELECT 		*
        FROM 		graphics_categories WITH (NOLOCK)
        ORDER BY 	category_name ASC
        </cfquery>
	<cfreturn getGraphicCategoriesQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getGraphicsByCategory" access="remote" returntype="query" hint="gets graphic categories">
<cfargument name="send_category" type="numeric" required="yes" />
        <cfquery name="getGraphicsByCategoryQuery" datasource="#dsn#">
        SELECT 	id, graphic_link
        FROM 	graphics WITH (NOLOCK)
        WHERE 	category_id = #send_category#
        </cfquery>
	<cfreturn getGraphicsByCategoryQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="addGraphic" access="remote" hint="adds graphic">
	<cfargument name="send_category" type="numeric" required="yes" />
    <cfargument name="send_file" type="string" required="yes" />
        <cfquery datasource="#dsn#">
        INSERT INTO graphics (
                        category_id,
                        graphic_link
                        )
                        
        VALUES (
            #send_category#,
            '#send_file#'
            )
        </cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<!-- -->
<cffunction name="writeDetailsItem" access="remote" returntype="query" hint="writes details item to database">
	<cfargument name="send_type" type="string" required="yes" />
    <cfargument name="send_text_shape" type="string" required="yes" />
    <cfargument name="send_text_shape_value" type="string" required="yes" />
    <cfargument name="send_text" type="string" required="yes" />
    <cfargument name="send_text_type" type="string" required="yes" />
    <cfargument name="send_case" type="numeric" required="yes" />
    
    <cfargument name="send_font" type="string" required="yes" />
    <cfargument name="send_size" type="numeric" required="yes" />
    <cfargument name="send_spacing" type="numeric" required="yes" />
    <cfargument name="send_fill" type="numeric" required="yes" />
    <cfargument name="send_fill_color" type="numeric" required="yes" />
    <cfargument name="send_outline" type="numeric" required="yes" />
    <cfargument name="send_outline_color" type="numeric" required="yes" />
    <cfargument name="send_outline_thickness" type="numeric" required="yes" />
    
	<cfargument name="send_max_chars" type="numeric" required="yes" />
	<cfargument name="send_alt_content" type="numeric" required="yes" />
    
    <cfargument name="send_fixed_width" type="numeric" required="yes" />
    <cfargument name="send_fixed_width_size" type="numeric" required="yes" />
    <cfargument name="send_fixed_height" type="numeric" required="yes" />
    <cfargument name="send_fixed_height_size" type="numeric" required="yes" />
    
    <cfargument name="send_scale_x" type="numeric" required="yes" />
    <cfargument name="send_scale_y" type="numeric" required="yes" />
    
    <cfargument name="send_rotate_x" type="numeric" required="yes" />
    <cfargument name="send_rotate_y" type="numeric" required="yes" />
    <cfargument name="send_rotate_z" type="numeric" required="yes" />
    
    <cfargument name="send_layer" type="numeric" required="yes" />
    <cfargument name="send_graphic" type="string" required="yes" />
    <cfargument name="send_color" type="numeric" required="yes" />
	<cfargument name="send_color_option" required="no" default="0" />
    <cfargument name="send_full_color" type="numeric" required="yes" />
    
    <cfargument name="send_x" type="numeric" required="yes" />
    <cfargument name="send_y" type="numeric" required="yes" />
	
	<cfargument name="send_design_id" type="numeric" required="false" default="0" />
	
	<!--- set up defaults that aren't part of the designer --->
	<cfset this_design_id = 0 />
	<cfset this_class = "ArchedText" />
	<cfset this_pos_x = send_x />
	<cfset this_pos_y = send_y />
	<cfif send_font is "Yearbook Solid">
		<cfset this_font = "myFontBMP" />
	<cfelseif send_font is "Brush Script Std Medium">
		<cfset this_font = "myScript" />
	<cfelseif send_font is "Destroy Regular">
		<cfset this_font = "Destroy" />
	<cfelseif send_font is "Gesso Regular">
		<cfset this_font = "Gesso" />
	<cfelseif send_font is "SF Collegiate Regular">
		<cfset this_font = "SF Collegiate" />
	<cfelse>
		<cfset this_font = send_font />
	</cfif>
	<cfset this_font_size = send_size />
	<cfset this_char_spacing = send_spacing />
	<cfset this_max_chars = send_max_chars />
	<cfset this_alt_content = send_alt_content />
	<cfset this_max_width = send_fixed_width_size />
	<cfset this_max_height = 0 />
	<cfset this_fixed_width = 0 />
	<cfset this_rotation = send_rotate_z />
	<cfif send_case is 0>
		<cfset this_all_caps = 1 />
	<cfelseif send_case is 1>
		<cfset this_all_caps = 2 />
	<cfelse>
		<cfset this_all_caps = 0 />
	</cfif>
	<cfset this_layer = send_layer />
		
	<cfif send_text_type is "toptext">
		<cfset this_description = "Top Text" />
		<cfset this_default_text = "toptext" />
	<cfelseif send_text_type is "bottomtext">
		<cfset this_description = "Bottom Text" />
		<cfset this_default_text = "bottomtext" />
	<cfelseif send_text_type is "year_right">
		<cfset this_description = "Year Right" />
		<cfset this_default_text = "yearright" />
	<cfelseif send_text_type is "year_left">
		<cfset this_description = "Year Left" />
		<cfset this_default_text = "yearleft" />
	<cfelseif send_text_type is "full_year">
		<cfset this_description = "Year Combo" />
		<cfset this_default_text = "yearcombo" />
	<cfelseif send_text_type is "name">
		<cfset this_description = "Name" />
		<cfset this_default_text = "name" />
	<cfelseif send_text_type is "number">
		<cfset this_description = "Number" />
		<cfset this_default_text = "number" />
	<cfelse>
		<cfset this_description = send_text />
		<cfset this_default_text = send_text />	
	</cfif>

	<cfif send_fixed_width is 1>
		<cfset this_fixed_width = 1 />
	</cfif>
	
	<cfif send_fixed_height is 1>
		<cfset this_max_height = send_fixed_height_size />
	</cfif>
	
	<cfif send_type is "text">
		<cfif send_text_shape is "straight" or send_text_shape is "hill">
			<cfset this_class = "ArchedText" />
			<cfset this_arc_rise = send_text_shape_value />
			<cfset this_SkewedOrRotated = 0 />
		<cfelse>
			<cfset this_class = "ArchedText" />
			<cfset this_arc_rise = send_text_shape_value />
			<cfset this_SkewedOrRotated = 1 />
		</cfif>
		
	</cfif>
	<cfset this_doApplyStroke = send_outline />
	<cfset this_stroke_color_index = send_outline_color />
	<cfset this_stroke_size = send_outline_thickness />
	
	<cfif FindNoCase('.swf',send_graphic)>
		<cfset send_graphic = replace(send_graphic,".swf","") />
	</cfif>
    
	<cfif FindNoCase("manager_placeholder", send_graphic, 1) gt 0>
		<cfset send_graphic = "placeHolder" />
	</cfif>
    
	<cfif send_type is "text">
		<cfset this_color_index = send_fill_color />
	    <cfquery datasource="#dsn#" name="insertText" result="insertResult">
	        INSERT INTO Design_text (
	                        design_id,
	                        class,
	                        description,
	                        pos_x,
	                        pos_y,
	                        font,
	                        font_size,
	                        char_spacing,
	                        max_chars,
	                        max_width,
	                        max_height,
	                        arc_rise,
	                        rotation,
	                        default_text,
	                        all_caps,
	                        fixed_width,
	                        layer,
	                        SkewedOrRotated,
	                        doApplyStroke,
							color_index,
							stroke_color_index,
							stroke_size,
							alt_content
	                        )
	                        
	        VALUES (
	            #this_design_id#,
	            '#this_class#',
	            '#this_description#',
	            #this_pos_x#,
	            #this_pos_y#,
	            '#this_font#',
	            #this_font_size#,
	            #this_char_spacing#,
	            #this_max_chars#,
	            #this_max_width#,
	            #this_max_height#,
	            #this_arc_rise#,
	            #this_rotation#,
	            '#this_default_text#',
	            #this_all_caps#,
	            #this_fixed_width#,
	            #this_layer#,
	            #this_SkewedOrRotated#,
	            #this_doApplyStroke#,
				#this_color_index#,
				#this_stroke_color_index#,
				#this_stroke_size#,
				#this_alt_content#
	            )
	    </cfquery>
	<cfelse>
		<cfset this_color_index = send_color />
		<cfquery datasource="#dsn#" name="insertGraphic" result="insertResult">
			INSERT INTO Design_graphic (
							design_id,
							filename,
							pos_x,
							pos_y,
							full_color,
							layer,
							initial_scale,
							color_index
						)
			VALUES		(
							#this_design_id#,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#send_graphic#" />,
							#this_pos_x#,
							#this_pos_y#,
							#send_color_option#,
							#this_layer#,
							#send_scale_x#,
							#this_color_index#
						)
		</cfquery>
	</cfif>
	
    <cfquery name="getMaxDetailsIdQuery" datasource="#dsn#">
        SELECT 	MAX(design_id)
        FROM 	Design_text
    </cfquery>
		
	<cfreturn getMaxDetailsIdQuery />
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getSaveActivities" access="remote" returntype="query" hint="gets all activities">
    <cfquery name="getSaveActivitiesQuery" datasource="#dsn#">
    	SELECT 		a.activity_id,a.name+ ' (' +sc.description+ ')' as name
        FROM 		Activity a WITH (NOLOCK)
        JOIN		shop_category sc WITH (NOLOCK) ON sc.category_id = a.category_id
		ORDER BY 	name
    </cfquery>
	<cfreturn getSaveActivitiesQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->

<cffunction name="saveDesign" access="remote" hint="writes design to database">
	<cfargument name="send_activity" type="numeric" required="yes" />
    <cfargument name="send_items" type="string" required="yes" />
    <cfargument name="send_type" type="numeric" required="yes" />
	<cfargument name="send_num_colors" required="no" default="1" />
	<cfset var isLogoDesign = 0 />
	<cfset var isMascotDesign = 0 />
	<cfif send_activity eq -2>
		<cfset isLogoDesign = 1 />
	<cfelseif send_activity eq -1>
		<cfset isMascotDesign = 1 />
	</cfif>
	<cftransaction>
	    <cfquery datasource="#dsn#" name="insertDesign" result="insertDesignResult">
	        INSERT INTO 	Design (
								designType_id,
		                        full_color,
		                        graphic_color_matches_text,
								numberOfColors,
								isLogoDesign,
								isMascotDesign,
								extraCost,
								isActive
	                        )
	                        
	        VALUES 			(
								#send_type#,
								0,
								0,
								#send_num_colors#,
								#isLogoDesign#,
								#isMascotDesign#,
								0,
								2
	            			)
	    </cfquery>
		<cfset this_design_id = insertDesignResult.IDENTITYCOL />
		<cfif send_activity gt 0>
			<cfquery datasource="#dsn#">
				INSERT INTO		Design_Activity_Link (
									design_id,
									activity_id
								)
				VALUES			(
									#this_design_id#,
									#send_activity#
								)
			</cfquery>
		</cfif>
		<cfquery datasource="#dsn#">
			UPDATE			Design_text
			SET				design_id = #this_design_id#
			WHERE			design_id = 0
		</cfquery>
		<cfquery datasource="#dsn#">
			UPDATE			Design_graphic
			SET				design_id = #this_design_id#
			WHERE			design_id = 0
		</cfquery>
	</cftransaction>
</cffunction>


<cffunction name="saveDesign_carey" access="remote" hint="writes design to database">
	<cfargument name="send_activity" type="numeric" required="yes" />
    <cfargument name="send_items" type="string" required="yes" />
    <cfargument name="send_type" type="numeric" required="yes" />
    <cfquery datasource="#dsn#">
        INSERT INTO designs_table (
                        design_activity,
                        design_items,
                        design_type_id
                        )
                        
        VALUES (
            #send_activity#,
            '#send_items#',
            #send_type#
            )
    </cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getEditActivities" access="remote" returntype="query" hint="gets all activities">
    <cfquery name="getEditActivitiesQuery" datasource="#dsn#">
    	SELECT 		a.activity_id, a.name+ ' (' +sc.description+ ')' as name
        FROM 		Activity a WITH (NOLOCK)
        JOIN		shop_category sc WITH (NOLOCK) ON sc.category_id = a.category_id
		ORDER BY	name
    </cfquery>
	<cfreturn getEditActivitiesQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getDesignTypes" access="remote" returntype="query" hint="gets all design types">
    <cfquery name="getDesignTypesQuery" datasource="#dsn#">
    	SELECT 		designType_id,description as name
    	FROM 		designType WITH (NOLOCK)
		ORDER BY	designType_id
    </cfquery>
	<cfreturn getDesignTypesQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getDesignsByAct" access="remote" returntype="query" hint="gets activities by id">
<cfargument name="send_id" type="numeric" required="yes" />

	<!--- get general designs plus a specific number of randomly dispursed sport designs --->
	<cfif send_id is 0>
		<cfquery name="getDesignsByActQuery" datasource="#dsn#">
			SELECT		design_id,design_activity,design_items,design_type_id, NEWID() randomHelper
			FROM		designs_table WITH (NOLOCK)
			WHERE		design_activity = 0
				AND		design_type_id = 1
			UNION
			SELECT 		design_id,design_activity,design_items,design_type_id, NEWID() randomHelper FROM (
				SELECT		TOP 5 design_id,design_activity,design_items,design_type_id, NEWID() randomizer
				FROM		designs_table WITH (NOLOCK)
				WHERE		design_activity != 0
				AND			design_type_id = 1
				ORDER BY	randomizer
				) as topFourRandomActivityDesigns
			ORDER BY	randomHelper
		</cfquery>
		
	<!--- else, get activity specific designs only --->
	<cfelse>
		<cfquery name="getDesignsByActQuery" datasource="#dsn#">
			SELECT		*, NEWID() randomHelper
			FROM		designs_table WITH (NOLOCK)
			WHERE		design_activity = #send_id#
				AND		design_type_id = 1
			ORDER BY 	randomHelper
		</cfquery>
		
	</cfif>
	<!---
    <cfquery name="getDesignsByActQuery" datasource="#dsn#">
    SELECT *
    FROM designs_table
        
    WHERE design_activity = #send_id#
    OR design_activity = 0
    AND design_type_id = 1
    
    ORDER BY design_activity;
    </cfquery>
	--->
	
	<cfreturn getDesignsByActQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getDesignsByActCP" access="remote" returntype="query" hint="gets activities by id">
<cfargument name="send_id" type="numeric" required="yes" />
    <cfquery name="getDesignsByActQuery" datasource="#dsn#">
    <cfif #send_id# eq 99>
    	SELECT *
        FROM designs_table WITH (NOLOCK)
            
        WHERE design_type_id = 4
    <cfelse>
      	SELECT *
        FROM designs_table WITH (NOLOCK)
            
        WHERE design_activity = #send_id#
        AND design_type_id = 1
        
        ORDER BY design_activity
    </cfif>
    
    </cfquery>

	<cfreturn getDesignsByActQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getBackDesigns" access="remote" returntype="query" hint="gets back designs">
    <cfquery name="getBackDesignsQuery" datasource="#dsn#">
    SELECT *
    FROM designs_table WITH (NOLOCK)
        
    WHERE design_type_id = 4
    </cfquery>
	<cfreturn getBackDesignsQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="getItemDetails" access="remote" returntype="query" hint="get details of design item by id">
<cfargument name="send_id" type="numeric" required="yes" />
    <cfquery name="getItemDetailsQuery" datasource="#dsn#">
    SELECT *
    FROM details_table WITH (NOLOCK)
        
    WHERE item_id = #send_id#
    </cfquery>
	<cfreturn getItemDetailsQuery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="updateDetailsItem" access="remote" returntype="numeric" hint="update details item to database">
	<cfargument name="send_id" type="numeric" required="yes" />
    <cfargument name="send_type" type="string" required="yes" />
    <cfargument name="send_text_shape" type="string" required="yes" />
    <cfargument name="send_text_shape_value" type="string" required="yes" />
    <cfargument name="send_text" type="string" required="yes" />
    <cfargument name="send_text_type" type="string" required="yes" />
    <cfargument name="send_case" type="numeric" required="yes" />
    
    <cfargument name="send_font" type="string" required="yes" />
    <cfargument name="send_size" type="numeric" required="yes" />
    <cfargument name="send_spacing" type="numeric" required="yes" />
    <cfargument name="send_fill" type="numeric" required="yes" />
    <cfargument name="send_fill_color" type="numeric" required="yes" />
    <cfargument name="send_outline" type="numeric" required="yes" />
    <cfargument name="send_outline_color" type="numeric" required="yes" />
    <cfargument name="send_outline_thickness" type="numeric" required="yes" />
    
	<cfargument name="send_max_chars" type="numeric" required="yes" />
    
    <cfargument name="send_fixed_width" type="numeric" required="yes" />
    <cfargument name="send_fixed_width_size" type="numeric" required="yes" />
    <cfargument name="send_fixed_height" type="numeric" required="yes" />
    <cfargument name="send_fixed_height_size" type="numeric" required="yes" />
    
    <cfargument name="send_scale_x" type="numeric" required="yes" />
    <cfargument name="send_scale_y" type="numeric" required="yes" />
    
    <cfargument name="send_rotate_x" type="numeric" required="yes" />
    <cfargument name="send_rotate_y" type="numeric" required="yes" />
    <cfargument name="send_rotate_z" type="numeric" required="yes" />
    
    <cfargument name="send_layer" type="numeric" required="yes" />
    <cfargument name="send_graphic" type="string" required="yes" />
    <cfargument name="send_color" type="numeric" required="yes" />
	<cfargument name="send_color_option" required="no" default="0" />
    <cfargument name="send_full_color" type="numeric" required="yes" />
    
    <cfargument name="send_x" type="numeric" required="yes" />
    <cfargument name="send_y" type="numeric" required="yes" />
    
    <cfset return_num = #send_id# >
    
    <cfquery datasource="#dsn#">
    UPDATE details_table
    
    SET item_type = '#send_type#',
    item_text_shape = '#send_text_shape#',
    item_text_shape_value = '#send_text_shape_value#',
    item_text = '#send_text#',
    item_text_type = '#send_text_type#',
    item_case = #send_case#,
    
    item_font = '#send_font#',
    item_size = #send_size#,
    item_spacing = #send_spacing#,
    item_fill = #send_fill#,
    item_fill_color = #send_fill_color#,
    item_outline = #send_outline#,
    item_outline_color = #send_outline_color#,
    item_outline_thickness = #send_outline_thickness#,
    
    item_fixed_width = #send_fixed_width#,
    item_fixed_width_size = #send_fixed_width_size#,
    item_fixed_height = #send_fixed_height#,
    item_fixed_height_size = #send_fixed_height_size#,
    
    item_scale_x = #send_scale_x#,
    item_scale_y = #send_scale_y#,
    
    item_rotate_x = #send_rotate_x#,
    item_rotate_y = #send_rotate_y#,
    item_rotate_z = #send_rotate_z#,
    
    item_layer = #send_layer#,
    item_graphic = '#send_graphic#',
    item_color = #send_color#,
    no_color = #send_color_option#,
    
    item_x = #send_x#,
    item_y = #send_y#
    
    WHERE item_id = #send_id#
    </cfquery>
	<cfreturn return_num>
</cffunction>
<!-- -->
<!-- -->
<!-- -->

<cffunction name="updateDesign" access="remote" hint="update details item to database">
	<cfargument name="send_id" default=0 />
    <cfargument name="send_items" default="" />
	<cfargument name="send_num_colors" required="no" default="1" />
	
	<!--- delete all the current design_text and design_graphic items --->
	<cfquery datasource="#dsn#">
		DELETE FROM		Design_graphic
		WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
	</cfquery>
	<cfquery datasource="#dsn#">
		DELETE FROM		Design_text
		WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
	</cfquery>
	
	<!--- link the newly inserted details (their design_id was set to 0) --->
	<cfquery datasource="#dsn#">
		UPDATE			Design_text
		SET				design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		WHERE			design_id = 0
	</cfquery>
	<cfquery datasource="#dsn#">
		UPDATE			Design_graphic
		SET				design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		WHERE			design_id = 0
	</cfquery>
	
	<!--- update number of colors in design table --->
	<cfquery name="NumberOfColors" datasource="#dsn#">
		UPDATE			Design
		SET				numberOfColors = <cfqueryparam cfsqltype="cf_sql_tinyint" list="false" null="false" value="#send_num_colors#" />
		WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
	</cfquery>
</cffunction>

<cffunction name="deleteDesign" access="remote" hint="delete design item from database (dev only)">
	<cfargument name="send_id" default=0 />
	<cftransaction>
		<!--- delete all the current design_text and design_graphic items --->
		<cfquery datasource="#dsn#">
			DELETE FROM		Design_graphic
			WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		</cfquery>
		<cfquery datasource="#dsn#">
			DELETE FROM		Design_text
			WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		</cfquery>
		
		<!--- delete the design from the Design table --->
		<cfquery datasource="#dsn#">
			DELETE FROM		Design    
			WHERE 			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		</cfquery>
		
		<!--- delete any links to activities --->
		<cfquery datasource="#dsn#">
			DELETE FROM		Design_Activity_Link
			WHERE			design_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#send_id#" />
		</cfquery>
	</cftransaction>
</cffunction>

<cffunction name="dev_activateDesign_DELETEME" access="remote" hint="move design from dev to live and set it's status on live and dev">
	<cfargument name="send_id" default=0 />
	<!--- we have to move graphics over, move db items over, set the activity, and change the status on the dev design as long as everything went o.k. --->
	<cfmail to="alan@athensohiorealestate.com" from="alan@athensohiorealestate.com" subject="dev_activateDesign Initiated" type="html">
		<cfdump var="#send_id#" />
	</cfmail>
	
	<cfif isNumeric(send_id) and send_id gt 0>
		<!--- get all designs of design type 1 --->
		<cfquery name="qryDesigns" datasource="cwdbsql">
			SELECT			d.*, dal.activity_id
			FROM			Design d WITH (NOLOCK)
			LEFT JOIN		Design_Activity_Link dal WITH (NOLOCK) ON dal.design_id = d.design_id
			WHERE			d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#send_id#" />
		</cfquery>
		
		<!--- loop through the query, and insert the new records --->
		<cfloop query="qryDesigns">
			<cfset originalDesignId = qryDesigns.design_id />
			<cfset newactivity_id = qryDesigns.activity_id />
			<cfset newdesignType_id = qryDesigns.designType_id />
			<cfset newfull_color = 0 />
			<cfset newgraphic_color_matches_text = qryDesigns.graphic_color_matches_text />
			<cfset newdescription = "" />
			<cfset newnumberOfColors = qryDesigns.numberOfColors />
			<cfset newisLogoDesign = qryDesigns.isLogoDesign />
			<cfset newisMascotDesign = qryDesigns.isMascotDesign />
			<cfset newextraCost = 0 />
			<cfset newisActive = 0 />
			
			<cfquery name="textItems" datasource="cwdbsql">
				SELECT			*
				FROM			Design_text WITH (NOLOCK)
				WHERE			design_id = #originalDesignId#
			</cfquery>
			
			<cfquery name="graphicItems" datasource="cwdbsql">
				SELECT			*
				FROM			Design_graphic WITH (NOLOCK)
				WHERE			design_id = #originalDesignId#
			</cfquery>
			
			<!--- ftp the graphics elements over to live --->
			<cfloop query="graphicItems">
				<cfif graphicItems.filename neq 'placeHolder'>
					<cfset localFile  					= "/BWImages/#graphicItems.filename#.swf" />
					<cfset remoteFile 					= "#graphicItems.filename#.swf" />
					<cfset variables.fullFilePathSVGZ 	= "/BWImages/svgz/#graphicItems.filename#.svgz" />
					<cfset variables.fileNameSVGZ 	  	= "#graphicItems.filename#.svgz" />
					<cfset variables.fullFilePathPNG  	= "/BWImages/png/#graphicItems.filename#.png" />
					<cfset variables.fileNamePNG 		= "#graphicItems.filename#.png" />

					<!--- check for PNG file, if it doesn't exist we abort --->
					<cfif not fileExists(expandPath(variables.fullFilePathPNG)) or not fileExists(expandPath(localFile))>
							<cfmail to="alan@athensohiorealestate.com" from="alan@athensohiorealestate.com" subject="dev_activateDesign Error" type="html">
								Some or all of the graphics files did not exist...<br />
								<cfdump var="#variables#" />
							</cfmail>
						<cfreturn />
					</cfif>

					<cftry>
						<cfftp
							action="open"
							connection="objConnection"
							server="www.mylocker.net"
							username="bwimages"
							password="ftplm4gE$"
							passive="yes"
							timeout="#int(60*3)#"
						/>
						<!--- FTP the SWF file --->
						<cfftp
							action="putfile"
							connection="objConnection"
							transfermode="auto"
							failIfExists="no"
							localfile="#expandPath(localFile)#"
							remotefile="#remoteFile#"
							timeout="#int(60*3)#"
						/>
						<!--- FTP the SVGZ file if it exists --->
						<cfif fileExists(expandPath(variables.fullFilePathSVGZ))>
							<cfftp
								action="changedir"
								connection="objConnection"
								directory="svgz"
							/>
							<cfftp
								action="putfile"
								connection="objConnection"
								transfermode="auto"
								failIfExists="no"
								localfile="#expandPath(variables.fullFilePathSVGZ)#"
								remotefile="#variables.fileNameSVGZ#"
								timeout="#int(60*3)#"
							/>
						</cfif>
						<!--- FTP the PNG file if it exists --->
						<cfif fileExists(expandPath(variables.fullFilePathPNG))>
							<cfftp
								action="changedir"
								connection="objConnection"
								directory="../png"
							/>
							<cfftp
								action="putfile"
								connection="objConnection"
								transfermode="auto"
								failIfExists="no"
								localfile="#expandPath(variables.fullFilePathPNG)#"
								remotefile="#variables.fileNamePNG#"
								timeout="#int(60*3)#"
							/>
						</cfif>
						<!--- Close the connection. --->
						<cfftp
							action="close"
							connection="objConnection"
						/>
						<!--- in case it didn't throw an error, but ftp failed --->
						<cfif !cfftp.succeeded>
							<!--- abort! --->
							<cfmail to="alan@athensohiorealestate.com" from="alan@athensohiorealestate.com" subject="dev_activateDesign Error" type="html">
								!cfftp.succeeded...<br />
								<cfdump var="#variables#" />
							</cfmail>
							<cfreturn />
						</cfif>
						<cfcatch type="any">
							<!--- failure is fatal!  abort the entire process --->
							<cfmail to="alan@athensohiorealestate.com" from="alan@athensohiorealestate.com" subject="dev_activateDesign Error" type="html">
								cfcatch error durring cfftp...<br />
								<cfdump var="#cfcatch#" />
								<cfdump var="#variables#" />
							</cfmail>
							<cfreturn />
						</cfcatch>
					</cftry>
					
					<!--- old way...	
						<cftry>
							<cfftp action="PutFile"
								username="bwimages"
								password="ftplm4gE$"
								server="www.mylocker.net"
								passive="yes"
								transferMode="binary"
								failIfExists="no"
								localfile="#ExpandPath(localFile)#"
								remotefile="#remoteFile#" />
							<cfif not cfftp.succeeded>
								<cfreturn />
							</cfif>
							<cfcatch type="any">
								<cfreturn />
							</cfcatch>
						</cftry>
					--->
				</cfif>
			</cfloop>

			<cftransaction>
				<cfquery name="insertDesign" datasource="cwdbsqlLIVE" result="insResult">
					INSERT INTO		Design
									(designType_id,full_color,graphic_color_matches_text,description,numberOfColors,isLogoDesign,isMascotDesign,extraCost,isActive)
					VALUES (		#newdesignType_id#,
									#newfull_color#,
									#newgraphic_color_matches_text#,
									'#newdescription#',
									#newnumberOfColors#,
									#newisLogoDesign#,
									#newisMascotDesign#,
									#newextraCost#,
									#newisActive#
							)
				</cfquery>
				<cfset newDesignId = insResult.IDENTITYCOL />
				<cfif isNumeric(newactivity_id)>
					<cfquery name="insActivity" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_Activity_Link
						VALUES	(		#newDesignId#,
										#newactivity_id#
								)
					</cfquery>
				</cfif>
				<cfloop query="textItems">
					<cfquery name="insTextItem" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_text
						VALUES	(		#newDesignId#,
										'#textItems.class#',
										'#textItems.description#',
										#textItems.pos_x#,
										#textItems.pos_y#,
										'#textItems.font#',
										#textItems.font_size#,
										#textItems.char_spacing#,
										#textItems.max_chars#,
										#textItems.max_width#,
										#textItems.max_height#,
										#textItems.arc_rise#,
										#textItems.rotation#,
										'#textItems.default_text#',
										#textItems.all_caps#,
										#textItems.fixed_width#,
										#textItems.layer#,
										#textItems.SkewedOrRotated#,
										#textItems.doApplyStroke#,
										#textItems.color_index#,
										#textItems.stroke_color_index#,
										#textItems.stroke_size#,
										#textItems.alt_content#
								)
					</cfquery>
				</cfloop>
				<cfloop query="graphicItems">
					<cfquery name="insGraphicItem" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_graphic
										(design_id,filename,pos_x,pos_y,full_color,layer,initial_scale,color_index)
						VALUES (		#newDesignId#,
										'#graphicItems.filename#',
										#graphicItems.pos_x#,
										#graphicItems.pos_y#,
										#graphicItems.full_color#,
										#graphicItems.layer#,
										#graphicItems.initial_scale#,
										#graphicItems.color_index#
								)
					</cfquery>
				</cfloop>
			</cftransaction>
			
			<!--- update design status on DEV side --->
			<cfquery name="updateDesignStatus" datasource="#dsn#">
				UPDATE		Design
				SET			isActive = 1
				WHERE		design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#originalDesignId#" />
			</cfquery>
		</cfloop>
	</cfif>
</cffunction>

<cffunction name="dev_activateDesign" access="remote" hint="move design from dev to live and set it's status on live and dev">
	<cfargument name="send_id" default=0 />
	<!--- we have to move graphics over, move db items over, set the activity, and change the status on the dev design as long as everything went o.k. --->

	<cfmail to="alan.rollins@mylocker.net" from="alan@athensohiorealestate.com" subject="dev_activateDesign Initiated" type="html">
		<cfdump var="#send_id#" />
	</cfmail>
	
	<cfif isNumeric(send_id) and send_id gt 0>
		<!--- get all designs of design type 1 --->
		<cfquery name="qryDesigns" datasource="cwdbsql">
			SELECT			d.*, dal.activity_id
			FROM			Design d WITH (NOLOCK)
			LEFT JOIN		Design_Activity_Link dal WITH (NOLOCK) ON dal.design_id = d.design_id
			WHERE			d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#send_id#" />
		</cfquery>
		
		<!--- loop through the query, and insert the new records --->
		<cfloop query="qryDesigns">
			<cfset originalDesignId = qryDesigns.design_id />
			<cfset newactivity_id = qryDesigns.activity_id />
			<cfset newdesignType_id = qryDesigns.designType_id />
			<cfset newfull_color = 0 />
			<cfset newgraphic_color_matches_text = qryDesigns.graphic_color_matches_text />
			<cfset newdescription = "" />
			<cfset newnumberOfColors = qryDesigns.numberOfColors />
			<cfset newisLogoDesign = qryDesigns.isLogoDesign />
			<cfset newisMascotDesign = qryDesigns.isMascotDesign />
			<cfset newisEMBCollectionDesign = 0>
			<cfset newextraCost = 0 />
			<cfset newisActive = 0 />
			
			<cfquery name="textItems" datasource="cwdbsql">
				SELECT			*
				FROM			Design_text WITH (NOLOCK)
				WHERE			design_id = #originalDesignId#
			</cfquery>
			
			<cfquery name="graphicItems" datasource="cwdbsql">
				SELECT			*
				FROM			Design_graphic WITH (NOLOCK)
				WHERE			design_id = #originalDesignId#
			</cfquery>
			
			<cfquery name="embCompositionDesigns" datasource="cwdbsql">
				SELECT			a.*,b.melcoReferenceID,b.shortTall,b.isactive
				FROM			Melco_CompositionDesigns a WITH (NOLOCK)
				LEFT JOIN		Melco_Compositions b on a.compositionid=b.compositionid
				WHERE			a.design_id = #originalDesignId#
			</cfquery>
			<cfquery name="embTemplates" datasource="cwdbsql">
				SELECT			*
				FROM			Melco_TemplateXref 
				WHERE			design_id = #originalDesignId#
			</cfquery>
			<cfif embCompositionDesigns.recordcount>
				<cfset newfull_color = qryDesigns.full_color>
				<cfset newdescription = qryDesigns.description>
				<cfset newisEMBCollectionDesign = qryDesigns.isEMBCollectionDesign>
			</cfif>
			
			<!--- ftp the graphics elements over to live --->
			<cfif graphicItems.recordCount gt 0>
				<cfif graphicItems['filename'][1] neq 'placeholder'>
					<!--- check for files --->
					<cfloop query="graphicItems">
						<cfset localFile  					= "/BWImages/#graphicItems.filename#.swf" />
						<cfset variables.fullFilePathSVGZ 	= "/BWImages/svgz/#graphicItems.filename#.svgz" />
						<cfset variables.fullFilePathPNG  	= "/BWImages/png/#graphicItems.filename#.png" />
						<cfif not fileExists(expandPath(variables.fullFilePathPNG)) 
								or not fileExists(expandPath(localFile))
								or not fileExists(expandPath(variables.fullFilePathSVGZ))>
							<cfmail to="alan.rollins@mylocker.net" from="alan@athensohiorealestate.com" subject="dev_activateDesign Graphic Files Don't Exist" type="html">
								<cfdump var="#variables#" />
							</cfmail>
							<cfreturn />
						</cfif>
					</cfloop>
					<!--- all files exist, start FTP for server list --->
					<cfloop index="server_ip" list="#server_ips#">
						<cftry>
							<cfftp
								action="open"
								connection="objConnection"
								server="#server_ip#"
								username="bwimages"
								password="ftplm4gE$"
								passive="yes"
								timeout="#int(60*3)#"
							/>
							<cfcatch>
								<cfmail to="alan.rollins@mylocker.net" from="alan@athensohiorealestate.com" subject="dev_activateDesign FTP Open Connection Failed" type="html">
									<cfdump var="#variables#" />
								</cfmail>
								<cfreturn />
							</cfcatch>
						</cftry>
						<!--- connection established, put the files --->
						<cfloop query="graphicItems">
							<cfset localFile  					= "/BWImages/#graphicItems.filename#.swf" />
							<cfset remoteFile 					= "#graphicItems.filename#.swf" />
							<cfset variables.fullFilePathSVGZ 	= "/BWImages/svgz/#graphicItems.filename#.svgz" />
							<cfset variables.fileNameSVGZ 	  	= "#graphicItems.filename#.svgz" />
							<cfset variables.fullFilePathPNG  	= "/BWImages/png/#graphicItems.filename#.png" />
							<cfset variables.fileNamePNG 		= "#graphicItems.filename#.png" />
							<cftry>
								<cfftp
									action="changedir"
									connection="objConnection"
									directory="/bwimages"
								/>
								<cfftp
									action="putfile"
									connection="objConnection"
									transfermode="auto"
									failIfExists="no"
									localfile="#expandPath(localFile)#"
									remotefile="#remoteFile#"
									timeout="#int(60*3)#"
								/>
								<cfftp
									action="changedir"
									connection="objConnection"
									directory="/bwimages/svgz"
								/>
								<cfftp
									action="putfile"
									connection="objConnection"
									transfermode="auto"
									failIfExists="no"
									localfile="#expandPath(variables.fullFilePathSVGZ)#"
									remotefile="#variables.fileNameSVGZ#"
									timeout="#int(60*3)#"
								/>
								<cfftp
									action="changedir"
									connection="objConnection"
									directory="/bwimages/png"
								/>
								<cfftp
									action="putfile"
									connection="objConnection"
									transfermode="auto"
									failIfExists="no"
									localfile="#expandPath(variables.fullFilePathPNG)#"
									remotefile="#variables.fileNamePNG#"
									timeout="#int(60*3)#"
								/>
								<cfcatch>
									<!--- error --->
									<cftry>
										<cfftp
											action="close"
											connection="objConnection"
										/>
										<cfcatch>
											<cfreturn />
										</cfcatch>
									</cftry>
									<cfmail to="alan.rollins@mylocker.net" from="alan@athensohiorealestate.com" subject="dev_activateDesign FTP Upload Failure" type="html">
										<cfdump var="#variables#" />
									</cfmail>
									<cfreturn />
								</cfcatch>
							</cftry>
						</cfloop>
						<cfftp
							action="close"
							connection="objConnection"
						/>						
					</cfloop>
				</cfif>
			</cfif>

			<cftransaction>
				<cfquery name="insertDesign" datasource="cwdbsqlLIVE" result="insResult">
					INSERT INTO		Design
									(designType_id,full_color,graphic_color_matches_text,description,numberOfColors,isLogoDesign,isMascotDesign,extraCost,isActive,isEmbCollectionDesign)
					VALUES (		#newdesignType_id#,
									#newfull_color#,
									#newgraphic_color_matches_text#,
									'#newdescription#',
									#newnumberOfColors#,
									#newisLogoDesign#,
									#newisMascotDesign#,
									#newextraCost#,
									#newisActive#,
									#newisEMBCollectionDesign#
							)
				</cfquery>
				<cfset newDesignId = insResult.IDENTITYCOL />
				<cfif isNumeric(newactivity_id)>
					<cfquery name="insActivity" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_Activity_Link
						VALUES	(		#newDesignId#,
										#newactivity_id#
								)
					</cfquery>
				</cfif>
				<cfloop query="textItems">
					<cfquery name="insTextItem" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_text
						VALUES	(		#newDesignId#,
										'#textItems.class#',
										'#textItems.description#',
										#textItems.pos_x#,
										#textItems.pos_y#,
										'#textItems.font#',
										#textItems.font_size#,
										#textItems.char_spacing#,
										#textItems.max_chars#,
										#textItems.max_width#,
										#textItems.max_height#,
										#textItems.arc_rise#,
										#textItems.rotation#,
										'#textItems.default_text#',
										#textItems.all_caps#,
										#textItems.fixed_width#,
										#textItems.layer#,
										#textItems.SkewedOrRotated#,
										#textItems.doApplyStroke#,
										#textItems.color_index#,
										#textItems.stroke_color_index#,
										#textItems.stroke_size#,
										#textItems.alt_content#
								)
					</cfquery>
				</cfloop>
				<cfloop query="graphicItems">
					<cfquery name="insGraphicItem" datasource="cwdbsqlLIVE">
						INSERT INTO		Design_graphic
										(design_id,filename,pos_x,pos_y,full_color,layer,initial_scale,color_index)
						VALUES (		#newDesignId#,
										'#graphicItems.filename#',
										#graphicItems.pos_x#,
										#graphicItems.pos_y#,
										#graphicItems.full_color#,
										#graphicItems.layer#,
										#graphicItems.initial_scale#,
										#graphicItems.color_index#
								)
					</cfquery>
				</cfloop>
				<cfloop query="embCompositionDesigns">
					<cfquery name="insEmbCompositions" datasource="cwdbsqlLIVE" result="insResult">
						INSERT INTO Melco_Compositions
						           ([melcoReferenceID]
						           ,[created]
						           ,[shortTall]
						           ,[isActive])
						     VALUES
						           ('#melcoReferenceID#'
						           ,getDate()
						           ,#shorttall#
						           ,#isActive#)
					</cfquery>			
					<cfset newCompsitionID = insResult.IDENTITYCOL />
					<cfquery name="insEmbCompositionDesigns" datasource="cwdbsqlLIVE">
						INSERT INTO		Melco_CompositionDesigns
										(design_ID,compositionID)
						VALUES (		#newDesignId#,
										#newCompsitionID#
								)
					</cfquery>
				</cfloop>
				<cfloop query="embTemplates">
					<cfquery name="insEmbTemplates" datasource="cwdbsqlLIVE">
						INSERT INTO [Melco_TemplateXref]
						           ([mediaType_id]
						           ,[design_id]
						           ,[melco_template_name]
						           ,[scaleFactor]
						           ,[rotang])
						     VALUES
						           (#mediaType_id#
						           ,#newDesignId#
						           ,<cfif len(melco_template_name)>'#melco_template_name#'<cfelse>NULL</cfif>
						           ,<cfif len(scaleFactor)>#scaleFactor#<cfelse>NULL</cfif>
						           ,<cfif len(rotang)>#rotang#<cfelse>NULL</cfif>)
					</cfquery>			
				</cfloop>
				
			</cftransaction>
			
			<!--- update design status on DEV side --->
			<cfquery name="updateDesignStatus" datasource="#dsn#">
				UPDATE		Design
				SET			isActive = 1
				WHERE		design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#originalDesignId#" />
			</cfquery>
		</cfloop>
	</cfif>
</cffunction>

<cffunction name="activateDesign" access="remote" hint="activate design (live only)">
	<cfargument name="send_id" default=0 />
	<cftry>
		<cfif isNumeric(send_id) and send_id gt 0>
			<cfquery datasource="#dsn#">
				UPDATE		Design
				SET			isActive = 1
				WHERE		design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#send_id#" />
			</cfquery>
		</cfif>
		<cfcatch>
			<!--- ToDo: error handling --->
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="deactivateDesign" access="remote" hint="deactivate design (live only)">
	<cfargument name="send_id" default=0 />
	<cftry>
		<cfif isNumeric(send_id) and send_id gt 0>
			<cfquery datasource="#dsn#">
				UPDATE		Design
				SET			isActive = 0
				WHERE		design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#send_id#" />
			</cfquery>
		</cfif>
		<cfcatch>
			<!--- ToDo: error handling --->
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="setSVGStatus" access="remote" returntype="numeric" hint="mark design as disabled or enabled for SVG viewers (live only)">
	<cfargument name="send_id" default=0 />
	<cfargument name="send_value" default=1 />
	<cfset var retval = 0 />
	<cftry>
		<cfif isNumeric(send_id) and send_id gt 0 and isNumeric(send_value) and (send_value eq 0 or send_value eq 1)>
			<cfquery datasource="#dsn#">
				UPDATE		Design
				SET			SVGStatus = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#send_value#" />
				WHERE		design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#send_id#" />
			</cfquery>
			<cfset retval = 1 />
		</cfif>
		<cfcatch>
			<!--- ToDo: error handling --->
		</cfcatch>
	</cftry>
	<cfreturn retval />
</cffunction>

<cffunction name="updateDesign_carey" access="remote" hint="update details item to database">
	<cfargument name="send_id" type="numeric" required="yes" />
    <cfargument name="send_items" type="string" required="yes" />
    <cfquery datasource="#dsn#">
    UPDATE designs_table
    
    SET design_items = '#send_items#'
    
    WHERE design_id = #send_id#
    </cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->
<cffunction name="deleteDesignCarey" access="remote" hint="delete design item from database">
	<cfargument name="send_id" type="numeric" required="yes" />
    <cfquery datasource="#dsn#">
    DELETE designs_table
    
    WHERE design_id = #send_id#
    </cfquery>
</cffunction>
<!-- -->
<!-- -->
<!-- -->

	<cffunction name="FindLast" access="private" returntype="Numeric">
		<cfargument name="searchFor" type="String" default="" required="false" />
		<cfargument name="inString" type="String" default="" required="false" />
		<cfset var arrStrings = ArrayNew(1) />
		<cfif searchFor is "" or inString is "">
			<cfreturn -1 />
		</cfif>
		<cfset arrStrings = ListToArray(inString, searchFor, true) />	<!--- this is a CF8 or higher call! --->
		<cfif ArrayLen(arrStrings) gt 0>
			<cfif ArrayLen(arrStrings) eq 1 or ArrayLen(arrStrings) eq 2>
				<cfset position = Find(searchFor, inString) />
			<cfelse>
				<cfset position = Len(arrStrings[1]) + 1 />
				<cfif ArrayLen(arrStrings) gt 2>
					<cfset length = ArrayLen(arrStrings) - 1 />
					<cfloop index="i" from="2" to="#length#">
						<cfset position = position + Len(arrStrings[i]) + 1 />
					</cfloop>
				</cfif>
			</cfif>
			<cfreturn position />
		<cfelse>
			<cfreturn -1 />
		</cfif>
	</cffunction>

</cfcomponent>




