<!--- Root path to view templates --->
<cfset vpath="\view\account">
<!--- strip off the controller prefix --->
<cfset fuseaction=listlast(attributes.t,".")>
<cfif NOT session.isAuth>
	<cflocation url="/?t=h.home&redirect=#attributes.t#" addtoken="no" />
	<cfabort />
</cfif>

<cfset layout.title = "Account" />
<cfset attributes.nav_top_active = "Account" />

<cfswitch expression = "#fuseaction#">
<!------------------------------------------------------------------------------------------------
                 Account
-------------------------------------------------------------------------------------------------->
	<!-----------------------------------------------------
	----Account
	------List account information and allows for updates
	------------------------------------------------------>
	<cfcase value="Account">
		<cfset account_info = Factory.Account().AccountInfo(session.authUser.shop_id) />
		<cfset colors = Factory.Util().GetColors() />
		<cfinclude template="#vpath#\dsp_landing.cfm" />
	</cfcase>
	<!-----------------------------------------------------
	----SaveAccountInfonstance
	------Updates the shop's information
	------------------------------------------------------>
	<cfcase value="SaveAccountInfo">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset variables.shop_id = Factory.Account().SaveAccountInfo(session.authUser.shop_id, attributes.name, attributes.address, attributes.city, attributes.state, attributes.zip, attributes.color1, attributes.color2, attributes.color3, attributes.website, attributes.cart_callback) />

	</cfcase>
	<!-----------------------------------------------------
	----SaveNewInstance
	------Adds a new shop
	------------------------------------------------------>
	<cfcase value="SaveNewInstance">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset variables.shop_id = Factory.Account().AddNewShop(session.authUser.company_id, attributes.name, attributes.address, attributes.city, attributes.state, attributes.zip, attributes.website, session.authUser.default_tier_id) />

		<cfset session.authUser.shop_id = variables.shop_id />
		<cfset session.authUser.shop_name = attributes.name />

		<cfset arrayAppend(session.authUser.shops, {shop_id=session.authUser.shop_id,shop_name=session.authUser.shop_name}) />
	</cfcase>
	<!-----------------------------------------------------
	----ChangeAPIInstance
	------Switches the active shop
	------------------------------------------------------>
	<cfcase value="ChangeAPIInstance">
		<cfset attributes.layout = "layout_ajax.cfm" />

		<cfset session.authUser.shop_id = attributes.shop_id />
		<cfset session.authUser.shop_name = attributes.shop_name />
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Unknown action '#attributes.t#'" detail="I don't have a handler for this fuseaction">
	</cfdefaultcase>
</cfswitch>
