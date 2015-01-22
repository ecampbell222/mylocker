<!---
  --- Designs
  --- -------
  ---
  --- author: tim
  --- date:   11/25/14
  --->
<cfcomponent accessors="true" output="false" persistent="false" extends="BaseObject">
	<!--- Author: tim - Date: 11/25/2014 --->
	<cffunction name="DesignCategories" output="false" access="public" returntype="any" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="MyLocker" />

		<cfset var local = {} />

		<cfquery name="local.getShopCategories" datasource="cwdbsql">
			SELECT group_id, [name] as group_name
			FROM shop_group g
			<cfif arguments.list_type IS NOT "MyLocker">
				INNER JOIN api_designcategories dc WITH (NOLOCK) ON g.group_id = dc.shop_group AND dc.company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />
			</cfif>
			WHERE name <> 'Custom'
			ORDER BY top_category desc, order_by
		</cfquery>

		<cfreturn local.getShopCategories />
	</cffunction>
	<!--- Author: tim - Date: 11/25/2014 --->
	<cffunction name="CompanyHasDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="company_id" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.checkDesigns" datasource="cwdbsql">
			SELECT COUNT(category_id) as hasDesigns
			FROM api_designcategories WITH (NOLOCK)
			WHERE company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />
		</cfquery>

		<cfreturn local.checkDesigns.hasDesigns />
	</cffunction>
	<!--- Author: tim - Date: 11/25/2014 --->
	<cffunction name="GetGroupActivities" output="false" access="public" returntype="any" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="group_id" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="MyLocker" />

		<cfset var local = {} />

		<cfquery name="local.getActivities" datasource="cwdbsql">
			SELECT DISTINCT a.activity_id, a.name as activity_name
		    FROM shop_group g WITH (NOLOCK)
	            INNER JOIN shop_group_category_link cl WITH (NOLOCK) ON g.group_id = cl.group_id
	            INNER JOIN shop_Category_Activity_link al WITH (NOLOCK) ON cl.category_id = al.category_id
	            INNER JOIN activity a WITH (NOLOCK) ON al.activity_id = a.activity_id and a.isActive = 1
				<cfif arguments.list_type IS NOT "MyLocker">
					INNER JOIN api_designcategories dc WITH (NOLOCK) ON g.group_id = dc.shop_group AND dc.company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />
					INNER JOIN api_designcategory_activities da WITH (NOLOCK) ON da.activity_id = a.activity_id AND dc.category_id = da.category_id
				</cfif>
			WHERE g.group_id = <cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_bigint" />
			ORDER BY a.name
		</cfquery>

		<cfreturn local.getActivities />
	</cffunction>
	<!--- Author: tim - Date: 11/25/2014 --->
	<cffunction name="AddDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="group_id" type="string" required="true" />
		<cfargument name="data" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.insertGroup" datasource="cwdbsql">
			begin tran
			if not exists (select category_id from api_designcategories with (updlock,serializable) where shop_group = <cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_bigint" /> AND company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />)
			begin
			  INSERT INTO api_designcategories(shop_group, company_id)
			  VALUES (<cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_bigint" />,
			  		  <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />)
			end
			commit tran
		</cfquery>

		<cfquery name="local.activitiesToAdd" datasource="cwdbsql">
			SELECT DISTINCT dc.category_id, a.activity_id, a.name as activity_name
		    FROM shop_group g WITH (NOLOCK)
	            INNER JOIN shop_group_category_link cl WITH (NOLOCK) ON g.group_id = cl.group_id
	            INNER JOIN shop_Category_Activity_link al WITH (NOLOCK) ON cl.category_id = al.category_id
	            INNER JOIN activity a WITH (NOLOCK) ON al.activity_id = a.activity_id and a.isActive = 1
	            INNER JOIN api_designcategories dc WITH (NOLOCK) ON dc.shop_group = g.group_id AND dc.company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_bigint" />
	            LEFT OUTER JOIN api_designcategory_activities da WITH (NOLOCK) ON da.activity_id = a.activity_id AND dc.category_id = da.category_id
			WHERE g.group_id = <cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_bigint" />
				AND da.activity_id IS NULL
				<cfif arguments.level IS "activity">
					AND a.activity_id = <cfqueryparam value="#arguments.data#" cfsqltype="cf_sql_bigint" />
				</cfif>
			ORDER BY a.name
		</cfquery>

		<cfloop query="local.activitiesToAdd">
			<cfquery name="local.addActivity" datasource="cwdbsql">
				INSERT INTO api_designcategory_activities (
					category_id,
					activity_id)
				VALUES (
					<cfqueryparam value="#local.activitiesToAdd.category_id#" cfsqltype="cf_sql_bigint" />,
					<cfqueryparam value="#local.activitiesToAdd.activity_id#" cfsqltype="cf_sql_bigint" />
				)
			</cfquery>
		</cfloop>

		<cfreturn true />
	</cffunction>
	<!--- Author: tim - Date: 11/25/2014 --->
	<cffunction name="DeleteDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="group_id" type="string" required="true" />
		<cfargument name="data" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.getCategory" datasource="cwdbsql">
			SELECT category_id
			FROM api_designcategories WITH (NOLOCK)
			WHERE shop_group = <cfqueryparam value="#group_id#" cfsqltype="cf_sql_bigint" />
				AND company_id = <cfqueryparam value="#company_id#" cfsqltype="cf_sql_bigint" />
		</cfquery>

		<cfif arguments.level IS "group">
			<cfquery name="local.deleteActivities" datasource="cwdbsql">
				DELETE
				FROM api_designcategory_activities
				WHERE category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
			</cfquery>
			<cfquery name="local.deleteGroup" datasource="cwdbsql">
				DELETE
				FROM api_designcategories
				WHERE shop_group = <cfqueryparam value="#group_id#" cfsqltype="cf_sql_bigint" />
					AND company_id = <cfqueryparam value="#company_id#" cfsqltype="cf_sql_bigint" />
			</cfquery>
		<cfelse>
			<cfquery name="local.deleteActivity" datasource="cwdbsql">
				DELETE
				FROM api_designcategory_activities
				WHERE activity_id = <cfqueryparam value="#arguments.data#" cfsqltype="cf_sql_bigint" />
					AND category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
			</cfquery>
			<!---Check to see if there are any activities still assigned to the group---->
			<cfquery name="local.checkIfActivities" datasource="cwdbsql">
				SELECT count(activity_id) as numActivities
				FROM api_designcategory_activities
				WHERE category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
			</cfquery>
			<!---If there are not any activities delete the group too---->
			<cfif local.checkIfActivities.numActivities IS 0>
				<cfquery name="local.deleteGroup" datasource="cwdbsql">
					DELETE
					FROM api_designcategories
					WHERE category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
						AND company_id = <cfqueryparam value="#company_id#" cfsqltype="cf_sql_bigint" />
				</cfquery>
			</cfif>
		</cfif>

		<cfreturn true />
	</cffunction>
    <!--- Author: Todd - Date: 12/09/2014 --->
	<cffunction name="UploadLogos" output="false" access="public" returntype="void" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="school_id" type="string" required="true" />
        <cfargument name="upload_path" type="string" required="true" />
        <cfargument name="file" type="struct" required="true" />
        
		<cffile action="UPLOAD" filefield="file" destination="#upload_path#" nameconflict="MAKEUNIQUE">  
	</cffunction>

</cfcomponent>