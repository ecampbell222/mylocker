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
		<cfif attributes.is_custom EQ "1">
			<cfset activities = Factory.Designs().GetCategoryActivities(session.authUser.shop_id, attributes.cat_id_cust, attributes.is_custom, attributes.list_type) />			
		<cfelse>
			<cfset activities = Factory.Designs().GetCategoryActivities(session.authUser.shop_id, attributes.cat_id, attributes.is_custom, attributes.list_type) />
		</cfif>
		<cfinclude template="#vpath#\dsp_loadActivities.cfm" />
	</cfcase>
	<!-----------------------------------------------------
	----AddDesigns
	-----
	------------------------------------------------------>
	<cfcase value="AddDesigns">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset addDesigns = Factory.Designs().AddDesigns(session.authUser.shop_id, attributes.group, attributes.data, attributes.level) />

		<cfset designCategories = Factory.Designs().DesignCategories(session.authUser.shop_id, "my") />

		<cfinclude template="#vpath#\dsp_loadDesignCategories.cfm" />
	</cfcase>
	<!-----------------------------------------------------
	----DeleteDesigns
	-----
	------------------------------------------------------>
	<cfcase value="DeleteDesigns">
		<cfset attributes.layout = "layout_ajax.cfm" />
		<cfset addDesigns = Factory.Designs().DeleteDesigns(session.authUser.shop_id, attributes.group, attributes.data, attributes.level) />

		<cfset designCategories = Factory.Designs().DesignCategories(session.authUser.shop_id, "my") />

		<cfinclude template="#vpath#\dsp_loadDesignCategories.cfm" />
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Unknown action '#attributes.t#'" detail="I don't have a handler for this fuseaction">
	</cfdefaultcase>
</cfswitch>
