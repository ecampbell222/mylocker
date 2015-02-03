<!--- Root path to view templates --->
<cfset vpath="\view\designs">
<!--- strip off the controller prefix --->
<cfset fuseaction=listlast(attributes.t,".")>
<cfif NOT session.isAuth>
	<cflocation url="/?t=h.home" addtoken="no" />
	<cfabort />
</cfif>

<cfset layout.title = "Designs" />

<cfset attributes.nav_top_active = "" />
<cfset attributes.nav_side_active = "Designs" />

<cfswitch expression = "#fuseaction#">
<!------------------------------------------------------------------------------------------------
                 DESIGNS
-------------------------------------------------------------------------------------------------->
	<!-----------------------------------------------------
	----DESIGNS
	-----
	------------------------------------------------------>
	<cfcase value="Designs">
		<cfset layout.end = '<script src="/js/designs.js?v=20141125"></script>' />
		<cfset layout.end &= '<script src="/js/jquery-ui.min.js"></script>' />
		<cfset layout.end &= '<script src="/js/jquery.sortable.min.js"></script>' />

		<cfset designCategories = Factory.Designs().DesignCategories(session.authUser.shop_id) />
		<cfset hasDesigns = Factory.Designs().ShopHasDesigns(session.authUser.shop_id) />
		<!----<cfset showOnlyMyDesigns = Factory.Settings().ShowOnlyMyDesigns(session.authUser.company_id) />----->

		<cfif hasDesigns>
			<cfset myDesignCategories = Factory.Designs().DesignCategories(session.authUser.shop_id, "my") />
		</cfif>
		<cfinclude template="#vpath#\dsp_landing.cfm" />
	</cfcase>
	<!-----------------------------------------------------
	----LoadActivities
	-----
	------------------------------------------------------>
	<cfcase value="LoadActivities">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset activities = Factory.Designs().GetCategoryActivities(session.authUser.shop_id, attributes.cat_id, attributes.cat_id_cust, attributes.is_custom, attributes.list_type) />			
		<cfinclude template="#vpath#\dsp_loadActivities.cfm" />
	</cfcase>
	<!-----------------------------------------------------
	----AddDesigns
	-----
	------------------------------------------------------>
	<cfcase value="AddDesigns">
		<cfset attributes.layout = "layout_ajax.cfm" />

		<cfset addDesigns = Factory.Designs().AddDesigns(session.authUser.shop_id, attributes.pdata1, attributes.pdata2, attributes.pdata3, attributes.is_custom, attributes.level, attributes.cat_cust) />
		
		<cfset designCategories = Factory.Designs().DesignCategories(session.authUser.shop_id, "my") />

		<cfinclude template="#vpath#\dsp_loadDesignCategories.cfm" />
	</cfcase>

	<!-----------------------------------------------------
	----DeleteCustom
	-----
	------------------------------------------------------>
	<cfcase value="DeleteCustom">
		<cfset attributes.layout = "layout_ajax.cfm" />

		<cfset deleteCustom = Factory.Designs().DeleteCustom(session.authUser.shop_id, attributes.cat_id, attributes.cat_cust_id, attributes.activity_id, attributes.is_custom) />
	</cfcase>

	<!-----------------------------------------------------
	----DeleteDesigns
	-----
	------------------------------------------------------>
	<cfcase value="DeleteDesigns">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset delDesigns = Factory.Designs().DeleteDesigns(session.authUser.shop_id, attributes.cat_id, attributes.cat_id_cust, attributes.data, attributes.level, attributes.is_custom) />

		<cfset designCategories = Factory.Designs().DesignCategories(session.authUser.shop_id, "my") />

		<cfinclude template="#vpath#\dsp_loadDesignCategories.cfm" />
	</cfcase>

	<cfdefaultcase>
		<cfthrow message="Unknown action '#attributes.t#'" detail="I don't have a handler for this fuseaction">
	</cfdefaultcase>
</cfswitch>
