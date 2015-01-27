<!---
  --- Designs
  --- -------
  ---
  --- author: ed
  --- date:   01/26/15
  --->
<cfcomponent accessors="true" output="false" persistent="false" extends="BaseObject">
	<cffunction name="DesignCategories" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="MyLocker" />

		<cfset var local = {} />

		<!---Grabs all shop categories for Select Category side of api--->
		<cfquery name="local.getShopCategories" datasource="cwdbsql">
			SELECT case when isCustom = 0 then category_id else 0 end as cat_id,
			case when isCustom = 1 then category_id else 0 end as custom_cat_id, 
			description, isCustom FROM
			<cfif arguments.list_type IS NOT "MyLocker">
				(SELECT c.category_id, description, 0 as isCustom FROM shop_Category c
				INNER JOIN api_designcategories apd1 ON c.category_id = apd1.category_id
				WHERE description <> 'Custom' 
				AND apd1.shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				UNION
				SELECT cs.category_id, description, 1 as isCustom FROM shop_Category_Custom cs
				INNER JOIN api_designcategories apd2 ON cs.category_id = apd2.category_custom_id
				WHERE apd2.shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				) 
			<cfelse>
				(SELECT category_id, description, 0 as isCustom FROM shop_Category c 
					WHERE description <> 'Custom'
					UNION
					SELECT category_id, description, 1 as isCustom FROM shop_Category_Custom cs
					WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				)
			</cfif>
			AS cat 
			ORDER BY description
		</cfquery>

		<cfreturn local.getShopCategories />
	</cffunction>
	
	<!---Gets a count of categories for a shop--->
	<cffunction name="ShopHasDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.checkDesigns" datasource="cwdbsql">
			SELECT COUNT(category_id) as hasDesigns
			FROM api_designcategories WITH (NOLOCK)
			WHERE shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
		</cfquery>

		<cfreturn local.checkDesigns.hasDesigns />
	</cffunction>
	
	<!---Grabs activities for a category--->
	<cffunction name="GetCategoryActivities" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />
		<cfargument name="list_type" type="string" required="false" default="MyLocker" />

		<cfset var local = {} />

		<cfquery name="local.getActivities" datasource="cwdbsql">
			SELECT activity_id, name FROM
			<cfif arguments.list_type IS NOT "MyLocker">
				<cfif arguments.is_custom EQ "1">
					activity_custom ac
					INNER JOIN api_designcategory_activities adc ON ac.activity_id = adc.activity_id
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />  
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				<cfelse>
					activity ac
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />  
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				</cfif>
			<cfelse>
				<cfif arguments.is_custom EQ "1">
					activity_custom 
					WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />  
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />				
				<cfelse>
					activity 
					WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
				</cfif>
			</cfif>
			ORDER BY name
		</cfquery>

		<cfreturn local.getActivities />
	</cffunction>

	<!---Inserts selected categories or activities--->
	<cffunction name="AddDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="data" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />

		<cfset var local = {} />

		<cfquery name="local.insertCategory" datasource="cwdbsql">
			BEGIN tran
			<cfif arguments.is_custom EQ "1">
				if not exists (SELECT category_custom_id FROM api_designcategories with (updlock,serializable) 
				WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
			<cfelse>
				if not exists (SELECT category_id FROM api_designcategories with (updlock,serializable) 
				WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" /> 
			</cfif>
			AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />)
			BEGIN
		    INSERT INTO api_designcategories(category_id, category_custom_id, shop_id)
		    <cfif arguments.is_custom EQ "1">
				VALUES (0, <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />,
		    <cfelse>
				VALUES (<cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />, 0,
		    </cfif>
		    <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />)
			END
			COMMIT tran
		</cfquery>

		<cfquery name="local.activitiesToAdd" datasource="cwdbsql">
			SELECT a.category_id, a.activity_id, a.name AS activity_name 
			<cfif arguments.level IS "activity">
				<!---Grabbing single activity to insert by id--->
				<cfif arguments.is_custom EQ "1">
					from activity_custom a 
				<cfelse>
					from activity a 
				</cfif>
				where activity_id = <cfqueryparam value="#arguments.data#" cfsqltype="cf_sql_bigint" />
			<cfelse>
				<!---Grabbing activities to insert for last inserted api-store category--->
				<cfif arguments.is_custom EQ "1">
					FROM api_designcategories ad
					INNER JOIN activity_custom a ON ad.category_custom_id = a.category_id				
				<cfelse>
					FROM api_designcategories ad
					INNER JOIN activity a ON ad.category_id = a.category_id
				</cfif>
				WHERE api_designcategory_id IN (SELECT top 1 @@IDENTITY AS LastID FROM api_designcategories)
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				ORDER BY a.name
			</cfif>
		</cfquery>

		<cfloop query="local.activitiesToAdd">
			<cfquery name="local.addActivity" datasource="cwdbsql">
				<cfif arguments.is_custom EQ "1">
					if not exists
					(SELECT category_custom_id FROM api_designcategory_activities 
					WHERE category_custom_id = <cfqueryparam value="#local.activitiesToAdd.category_id#" cfsqltype="cf_sql_bigint" />
					AND activity_id = <cfqueryparam value="#local.activitiesToAdd.activity_id#" cfsqltype="cf_sql_bigint" />
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />)
					BEGIN		
					INSERT INTO api_designcategory_activities (category_id, category_custom_id, activity_id, shop_id, isActive)
					VALUES (
						0,
						<cfqueryparam value="#local.activitiesToAdd.category_id#" cfsqltype="cf_sql_bigint" />,
						<cfqueryparam value="#local.activitiesToAdd.activity_id#" cfsqltype="cf_sql_bigint" />,
						<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />,
						0
					)	
					END		
				<cfelse>
					if not exists
					(SELECT category_id FROM api_designcategory_activities 
					WHERE category_id = <cfqueryparam value="#local.activitiesToAdd.category_id#" cfsqltype="cf_sql_bigint" />
					AND activity_id = <cfqueryparam value="#local.activitiesToAdd.activity_id#" cfsqltype="cf_sql_bigint" />
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />)
					BEGIN						
					INSERT INTO api_designcategory_activities (category_id, category_custom_id, activity_id, shop_id, isActive)
					VALUES (
						<cfqueryparam value="#local.activitiesToAdd.category_id#" cfsqltype="cf_sql_bigint" />,
						0,
						<cfqueryparam value="#local.activitiesToAdd.activity_id#" cfsqltype="cf_sql_bigint" />,
						<cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />,
						0
					)	
					END
				</cfif>
			</cfquery>
		</cfloop>

		<cfreturn true />
	</cffunction>

	<!---Deletes selected categories/activities--->
	<cffunction name="DeleteDesigns" output="false" access="public" returntype="any" hint="">
		<cfargument name="shop_id" type="string" required="true" />
		<cfargument name="category_id" type="string" required="true" />
		<cfargument name="data" type="string" required="true" />
		<cfargument name="level" type="string" required="true" />
		<cfargument name="is_custom" type="string" required="true" />

		<cfset var local = {} />

		<cfif arguments.level IS "group">
			<cfquery name="local.deleteActivities" datasource="cwdbsql">
				DELETE
				FROM api_designcategory_activities
				<cfif arguments.is_custom EQ "1">
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				<cfelse>
					WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				</cfif>
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>
			<cfquery name="local.deleteCategory" datasource="cwdbsql">
				DELETE
				FROM api_designcategories
				<cfif arguments.is_custom EQ "1">
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				<cfelse>
					WHERE category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				</cfif>
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>
		<cfelse>
			<cfquery name="local.deleteActivity" datasource="cwdbsql">
				DELETE
				FROM api_designcategory_activities
				WHERE activity_id = <cfqueryparam value="#arguments.data#" cfsqltype="cf_sql_bigint" />
				<cfif arguments.is_custom EQ "1">
					AND category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
				<cfelse>
					AND category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				</cfif>
				AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
			</cfquery>

			<!---Check to see if there are any activities still assigned to the category---->
			<cfquery name="local.checkIfActivities" datasource="cwdbsql">
				SELECT count(activity_id) as numActivities
				FROM api_designcategory_activities
				<cfif arguments.is_custom EQ "1">
					WHERE category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
				<cfelse>
					WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
				</cfif>				
			</cfquery>

			<!---If there are not any activities delete the category too---->
			<cfif local.checkIfActivities.numActivities IS 0>
				<cfquery name="local.deleteCategory" datasource="cwdbsql">
					DELETE
					FROM api_designcategories
					<cfif arguments.is_custom EQ "1">
						WHERE category_id = <cfqueryparam value="#local.getCategory.category_id#" cfsqltype="cf_sql_bigint" />
					<cfelse>
						WHERE category_custom_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_bigint" />
					</cfif>
					AND shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#arguments.shop_id#" />
				</cfquery>
			</cfif>
		</cfif>

		<cfreturn true />
	</cffunction>

    <!--- Author: Todd - Date: 12/09/2014 --->
    <!--- NOTE: This should be done by shop_id instead of company_id --->
	<cffunction name="UploadLogos" output="false" access="public" returntype="void" hint="">
		<cfargument name="company_id" type="string" required="true" />
		<cfargument name="school_id" type="string" required="true" />
        <cfargument name="upload_path" type="string" required="true" />
        <cfargument name="file" type="struct" required="true" />
        
		<cffile action="UPLOAD" filefield="file" destination="#upload_path#" nameconflict="MAKEUNIQUE">  
	</cffunction>

</cfcomponent>