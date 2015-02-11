<cfcomponent displayname="Product" hint="Manage Products" output="false">

	<cfset dsn = "cwdbsqlAPI" />						<!--- Datasource name --->

	<cffunction name="getAllCategories" output="false" returntype="query" access="remote">
		<cfquery name="qryCategories" datasource="#variables.dsn#">
			SELECT DISTINCT	pc.category_ID CATEGORYID,
							pc.category_Name CATEGORYNAME,
							pc.category_archive CATEGORYARCHIVE
			FROM			tbl_prdtcategories pc
			ORDER BY		pc.category_Name
		</cfquery>
		<cfreturn qryCategories />
	</cffunction>

	<cffunction name="getAPIProductExists" output="false" returntype="query" access="remote">
		<cfargument name="productCategory_id" required="false" default="1" />
		<cfargument name="sc_id" required="false" default="MI4809166422" />

		<cfquery name="qryAPIProductExists" datasource="#dsn#">
			SELECT count(*) as apiProductExistsCount
			FROM shop_products sp
			INNER JOIN tbl_prdtcat_rel pcr ON pcr.prdt_cat_rel_product_id = sp.product_id
			WHERE pcr.prdt_cat_rel_CAT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#productCategory_id#" />
			AND sp.shop_id = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#sc_id#" />
		</cfquery>
		<cfreturn qryAPIProductExists />
	</cffunction>



	<cffunction access="Remote" name="getProduct" returnType="Query">
		<cfargument name="viewType_id" required="false" default="1" />
		<cfargument name="productCategory_id" required="false" default="1" />
		<cfargument name="prodid" required="false" default="1" />
		<cfargument name="prodid1" required="false" default="0" />
		<cfargument name="prodid2" required="false" default="0" />
		<cfargument name="prodid3" required="false" default="0" />
		<cfargument name="prodid4" required="false" default="0" />
		<cfargument name="prodid5" required="false" default="0" />
		<cfargument name="prodid6" required="false" default="0" />
		<cfargument name="prodid7" required="false" default="0" />
		<cfargument name="prodid8" required="false" default="0" />
		<cfargument name="prodid9" required="false" default="0" />
		<cfargument name="prodid10" required="false" default="0" />
		<cfargument name="apiProductExists" required="false" default="0" />
		<cfargument name="shopID" required="false" default="0" />

		<cfsavecontent variable="tmp">
			<cfdump var="#arguments#">
		</cfsavecontent>

		<!--Used to add inner join and extra conditions to the where condition for the api-->
		<!--Had to pass where condition in the statement due to coldfusion restriction-->
		<cfset sqlvar1 = "" />
		<cfif apiProductExists neq "0">
			<cfset sqlvar1 = " INNER JOIN [shop_products] sp ON p.product_ID = sp.product_id " />
		</cfif>

		<cfquery name="getProductQuery" datasource="#dsn#">
			SELECT 	pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotation DESIGNROTATION,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY,
					p.product_Name PRODUCTNAME,
					pic.colorbox COLORBOX,
					0 ISEXTRA
			FROM [Product_View] pv
			INNER JOIN [tbl_products] p ON p.product_ID = pv.product_id
			INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
			#sqlvar1#
			LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
			LEFT JOIN [pictures] pic WITH (NOLOCK) ON pic.product = pv.product_id
			WHERE pv.productCategory_id = #productCategory_id#
			<cfif apiProductExists neq "0">
				AND sp.shop_id = '#shopID#'
			</cfif>
				AND pv.viewType_id = #viewType_id#
				AND p.product_OnWeb = 1
				AND p.product_Archive = 0
				AND ( pv.product_id = #prodid1#
					  OR pv.product_id = #prodid2#
					  OR pv.product_id = #prodid3#
					  OR pv.product_id = #prodid4#
					  OR pv.product_id = #prodid5#
					  OR pv.product_id = #prodid6#
					  OR pv.product_id = #prodid7#
					  OR pv.product_id = #prodid8#
					  OR pv.product_id = #prodid9#
					  OR pv.product_id = #prodid10# )
			UNION
			SELECT 	pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotation DESIGNROTATION,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY,
					p.product_Name PRODUCTNAME,
					pic.colorbox COLORBOX,
					1 ISEXTRA
			FROM [Product_View] pv
			INNER JOIN [tbl_products] p ON p.product_ID = pv.product_id
			INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
			#sqlvar1#
			LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
			LEFT JOIN [pictures] pic WITH (NOLOCK) ON pic.product = pv.product_id
			WHERE pv.productCategory_id = #productCategory_id#
			<cfif apiProductExists neq "0">
				AND sp.shop_id = '#shopID#'
			</cfif>
				AND pv.viewType_id = #viewType_id#
				AND p.product_OnWeb = 1
				AND p.product_Archive = 0
				AND NOT EXISTS (
					SELECT pv.product_id
					FROM [Product_View]
					WHERE ( pv.product_id = #prodid1#
					  		OR pv.product_id = #prodid2#
					  		OR pv.product_id = #prodid3#
					  		OR pv.product_id = #prodid4#
					  		OR pv.product_id = #prodid5#
					  		OR pv.product_id = #prodid6#
					  		OR pv.product_id = #prodid7#
					  		OR pv.product_id = #prodid8#
					  		OR pv.product_id = #prodid9#
					  		OR pv.product_id = #prodid10# )
					)
			ORDER BY ISEXTRA DESC

		</cfquery>
		<cfreturn getProductQuery />
	</cffunction>

	<cffunction access="Remote" name="getProductDiscountLevels" returnType="Query">
		<cfargument name="product_id" required="false" default="0" />
		<cfquery name="getProductDiscountLevels" datasource="#dsn#">
			SELECT		dl.quantity_start qstart,
						dl.quantity_end qend,
						pdl.discount d1, pdl.discount2 d2, pdl.discount3 d3, pdl.discount4 d4,
						pcdl.discount cd1, pcdl.discount2 cd2, pcdl.discount3 cd3, pcdl.discount4 cd4
			FROM		tbl_prdtcat_rel pcr
			INNER JOIN	prdtcat_Discounts pcdl ON pcdl.category_ID = pcr.prdt_cat_rel_Cat_ID
			INNER JOIN  discount_Levels dl ON dl.level_id = pcdl.level_id
			LEFT JOIN	prdt_Discounts pdl ON pdl.product_id = pcr.prdt_cat_rel_Product_ID AND pdl.level_id = dl.level_id
			WHERE		pcr.prdt_cat_rel_Product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_id#" />
		</cfquery>
		<cfreturn getProductDiscountLevels />
	</cffunction>

	<cffunction access="Remote" name="getProductViewTypes" returnType="Query">
		<cfargument name="productCategory_id" required="false" default="1" />
		<cfquery name="getProductViewTypes" datasource="#dsn#">
			SELECT DISTINCT pv.viewType_id, vt.viewType
			FROM Product_View pv
			INNER JOIN viewType vt ON vt.viewType_id = pv.viewType_id
			WHERE pv.productCategory_id = <cfqueryparam cfsqltype="bigint" null="false" list="false" value="#productCategory_id#" />
		</cfquery>
		<cfreturn getProductViewTypes />
	</cffunction>

	<cffunction access="Remote" name="getProductSizeSKUs" returnType="Query">
		<cfargument name="product_id" required="false" default="0" />
		<cfargument name="globalAPIProductExists" required="false" default="0" />
		<cfargument name="globalScId" required="false" default="" />

		<cfif globalAPIProductExists eq "0">
			<cfquery name="getProductSizeSKUs" datasource="#dsn#">
				SELECT
					s.SKU_ID SKUID,
					s.SKU_MerchSKUID MERCHANTSKU,
					s.SKU_Price PRICE,
					so.option_Name SIZE,
					so.option_Sort SORTORDER
				FROM tbl_skus s
					LEFT OUTER JOIN ((tbl_list_optiontypes ot
					INNER JOIN tbl_skuoptions so ON ot.optiontype_ID = so.option_Type_ID)
					INNER JOIN tbl_skuoption_rel r ON so.option_ID = r.optn_rel_Option_ID) ON s.SKU_ID = r.optn_rel_SKU_ID
				WHERE
					s.SKU_ProductID = #product_id#
					AND s.SKU_ShowWeb = 1
					AND (ot.optiontype_ID = 1 OR ot.optiontype_ID IS NULL)
					AND (so.option_Name NOT IN ('Free S','Free M','Free L','Free XL','Free XXL','Free XXXL') OR so.option_Name IS NULL)
				ORDER BY
				  	so.option_Sort
			</cfquery>
		<cfelse>
			<cfquery name="getProductSizeSKUs" datasource="#dsn#">
				exec spAPILookupPrice
				@ShopID = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#globalScId#" />,
				@ProductID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_id#" />,
				@ShowCost = 0,
				@CalcSizeType = 0
			</cfquery>
		</cfif>
		<cfreturn getProductSizeSKUs />
	</cffunction>

	<cffunction access="Remote" name="setViewSettings" returntype="String">
		<cfargument name="product_id" required="false" default="0" />
		<cfargument name="productCategory_id" required="false" default="0" />
		<cfargument name="centerOffsetX" required="false" default="0" />
		<cfargument name="centerOffsetY" required="false" default="0" />
		<cfargument name="initialScale" required="false" default="1" />
		<cfargument name="designOffsetX" required="false" default="0" />
		<cfargument name="designOffsetY" required="false" default="0" />
		<cfargument name="designScale" required="false" default="1" />
		<cfargument name="designRotation" required="false" default="0" />
		<cfargument name="viewType" required="false" default="front" />
		<cfargument name="saveFullCategory" required="false" default="0" />
		<cftry>
			<cfquery name="getProductViewTypes" datasource="#dsn#">
				UPDATE Product_View
				SET centerOffsetX = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#centerOffsetX#" />,
					centerOffsetY = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#centerOffsetY#" />,
					initialScale = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#initialScale#" />,
					designOffsetX = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designOffsetX#" />,
					designOffsetY = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designOffsetY#" />,
					designScale = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designScale#" />,
					designRotation = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designRotation#" />
				FROM Product_View pv
				INNER JOIN viewType vt ON pv.viewType_id = vt.viewType_id
				WHERE productCategory_id = <cfqueryparam cfsqltype="bigint" null="false" list="false" value="#productCategory_id#" />
					AND vt.viewType = <cfqueryparam cfsqltype="varchar" null="false" list="false" value="#viewType#" />
					<cfif saveFullCategory is not 1>
						AND product_id = <cfqueryparam cfsqltype="bigint" null="false" list="false" value="#product_id#" />
					</cfif>
			</cfquery>
			<cfcatch>
				<cfreturn "fail" />
			</cfcatch>
		</cftry>
		<cfreturn "success" />
	</cffunction>

	<cffunction access="Remote" name="setDesignPositioning" returntype="String">
		<cfargument name="product_id" required="false" default="0" />
		<cfargument name="productCategory_id" required="false" default="0" />
		<cfargument name="designOffsetX" required="false" default="0" />
		<cfargument name="designOffsetY" required="false" default="0" />
		<cfargument name="designScale" required="false" default="1" />
		<cfargument name="designRotationX" required="false" default="0" />
		<cfargument name="designRotationY" required="false" default="0" />
		<cfargument name="designRotationZ" required="false" default="0" />
		<cfargument name="viewType_id" required="false" default="0" />
		<cfargument name="saveFullCategory" required="false" default="0" />
		<cfif product_id is not 0 and productCategory_id is not 0 and viewType_id is not 0>
			<cftry>
				<cfquery name="setProductViewTypes" datasource="#dsn#">
					UPDATE Product_Views
					SET designOffsetX = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designOffsetX#" />,
						designOffsetY = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designOffsetY#" />,
						designScale = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designScale#" />,
						designRotationX = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designRotationX#" />,
						designRotationY = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designRotationY#" />,
						designRotationZ = <cfqueryparam cfsqltype="cf_sql_float" list="false" null="false" value="#designRotationZ#" />
					WHERE productCategory_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#productCategory_id#" />
						AND viewType_id = <cfqueryparam cfsqltype="cf_sql_integer" null="false" list="false" value="#viewType_id#" />
						<cfif saveFullCategory is not 1>
							AND product_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#product_id#" />
						</cfif>
				</cfquery>
				<cfcatch>
					<cfreturn "fail" />
				</cfcatch>
			</cftry>
		<cfelse>
			<cfreturn "fail" />
		</cfif>
		<cfreturn "success" />
	</cffunction>

	<cffunction access="Remote" name="getProductBySKU" returntype="Query">
		<cfargument name="sku_id" required="false" default="0" />
		<cfargument name="viewType_id" required="false" default="1" />
		<cftry>
			<cfquery name="getProductBySKU" datasource="#dsn#">
				SELECT TOP 1
					pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotation DESIGNROTATION,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY
				FROM [Product_View] pv
				INNER JOIN [tbl_skus] s ON s.SKU_ProductID = pv.product_id
				INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
				LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
				WHERE s.sku_id = #sku_id#
					AND pv.viewType_id = #viewType_id#
			</cfquery>
			<cfcatch type="database">
				<!--- Error Handling --->
			</cfcatch>
		</cftry>
		<cfreturn getProductBySKU>
	</cffunction>

	<cffunction access="Remote" name="getProductNew" returnType="Query">
		<cfargument name="viewType_id" required="false" default="1" />
		<cfargument name="productCategory_id" required="false" default="1" />
		<cfargument name="prodid" required="false" default="1" />
		<cfargument name="prodid1" required="false" default="0" />
		<cfargument name="prodid2" required="false" default="0" />
		<cfargument name="prodid3" required="false" default="0" />
		<cfargument name="prodid4" required="false" default="0" />
		<cfargument name="prodid5" required="false" default="0" />
		<cfargument name="prodid6" required="false" default="0" />
		<cfargument name="prodid7" required="false" default="0" />
		<cfargument name="prodid8" required="false" default="0" />
		<cfargument name="prodid9" required="false" default="0" />
		<cfargument name="prodid10" required="false" default="0" />
		<cfquery name="getProductQuery" datasource="#dsn#">
			SELECT 	pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotationX DESIGNROTATIONX,
					pv.designRotationY DESIGNROTATIONY,
					pv.designRotationZ DESIGNROTATIONZ,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY,
					0 ISEXTRA
			FROM [Product_Views] pv
			INNER JOIN [tbl_products] p ON p.product_ID = pv.product_id
			INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
			LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
			WHERE pv.productCategory_id = #productCategory_id#
				AND pv.viewType_id = #viewType_id#
				AND p.product_OnWeb = 1
				AND p.product_Archive = 0
				AND ( pv.product_id = #prodid1#
					  OR pv.product_id = #prodid2#
					  OR pv.product_id = #prodid3#
					  OR pv.product_id = #prodid4#
					  OR pv.product_id = #prodid5#
					  OR pv.product_id = #prodid6#
					  OR pv.product_id = #prodid7#
					  OR pv.product_id = #prodid8#
					  OR pv.product_id = #prodid9#
					  OR pv.product_id = #prodid10# )
			UNION
			SELECT 	pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotationX DESIGNROTATIONX,
					pv.designRotationY DESIGNROTATIONY,
					pv.designRotationZ DESIGNROTATIONZ,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY,
					1 ISEXTRA
			FROM [Product_Views] pv
			INNER JOIN [tbl_products] p ON p.product_ID = pv.product_id
			INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
			LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
			WHERE pv.productCategory_id = #productCategory_id#
				AND pv.viewType_id = #viewType_id#
				AND p.product_OnWeb = 1
				AND p.product_Archive = 0
				AND NOT EXISTS (
					SELECT pv.product_id
					FROM [Product_View]
					WHERE ( pv.product_id = #prodid1#
					  		OR pv.product_id = #prodid2#
					  		OR pv.product_id = #prodid3#
					  		OR pv.product_id = #prodid4#
					  		OR pv.product_id = #prodid5#
					  		OR pv.product_id = #prodid6#
					  		OR pv.product_id = #prodid7#
					  		OR pv.product_id = #prodid8#
					  		OR pv.product_id = #prodid9#
					  		OR pv.product_id = #prodid10# )
					)
			ORDER BY ISEXTRA DESC

		</cfquery>
		<cfreturn getProductQuery />
	</cffunction>

	<cffunction access="Remote" name="getNewProductBySKU" returntype="Query">
		<cfargument name="sku_id" required="false" default="0" />
		<cfargument name="viewType_id" required="false" default="1" />
		<cftry>
			<cfquery name="getProductBySKU" datasource="#dsn#">
				SELECT TOP 1
					pv.product_id PRODUCTID,
					pv.designType_id DESIGNTYPEID,
					pv.imageFilename IMAGEFILENAME,
					pv.centerOffsetX CENTEROFFSETX,
					pv.centerOffsetY CENTEROFFSETY,
					pv.isColorable ISCOLORABLE,
					pv.initialScale INITIALSCALE,
					pv.designScale DESIGNSCALE,
					pv.designRotationX DESIGNROTATIONX,
					pv.designRotationY DESIGNROTATIONY,
					pv.designRotationZ DESIGNROTATIONZ,
					pv.designOffsetX DESIGNOFFSETX,
					pv.designOffsetY DESIGNOFFSETY,
					pv.designBoxedView DESIGNBOXEDVIEW,
					pv.sizeChart SIZECHART,
					c.hex HEXCOLOR,
					c.descr COLORDESCR,
					cSecondary.hex HEXCOLORSECONDARY,
					cSecondary.descr COLORDESCRSECONDARY
				FROM [Product_Views] pv
				INNER JOIN [tbl_skus] s ON s.SKU_ProductID = pv.product_id
				INNER JOIN [Product_Colors] c ON c.color_id = pv.color_id_primary
				LEFT JOIN [Product_Colors] cSecondary ON cSecondary.color_id = pv.color_id_secondary
				WHERE s.sku_id = #sku_id#
					AND pv.viewType_id = #viewType_id#
			</cfquery>
			<cfcatch type="database">
				<!--- Error Handling --->
			</cfcatch>
		</cftry>
		<cfreturn getProductBySKU>
	</cffunction>

	<cffunction access="Remote" name="setFilename" returntype="String">
		<cfargument name="product_id" required="false" default="0" />
		<cfargument name="productCategory_id" required="false" default="0" />
		<cfargument name="filename" required="false" default="" />
		<cfargument name="viewType" required="false" default="" />
		<cfif productCategory_id is not "0" and product_id is not "0" and viewType is not "">
			<cfif filename is not "">
				<cftry>
					<cfquery name="getProductViewTypes" datasource="#dsn#">
						UPDATE Product_View
						SET imageFilename = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#filename#" />,
							designBoxedView = 0
						FROM Product_View pv
						INNER JOIN viewType vt ON pv.viewType_id = vt.viewType_id
						WHERE productCategory_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#productCategory_id#" />
							AND vt.viewType = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" list="false" value="#viewType#" />
							AND product_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#product_id#" />
					</cfquery>
					<cfcatch>
						<cfreturn "fail" />
					</cfcatch>
				</cftry>
			<cfelse>
				<cftry>
					<cfquery name="getProductViewTypes" datasource="#dsn#">
						UPDATE Product_View
						SET imageFilename = <cfqueryparam cfsqltype="cf_sql_varchar" list="false" null="false" value="#filename#" />,
							designBoxedView = 1
						FROM Product_View pv
						INNER JOIN viewType vt ON pv.viewType_id = vt.viewType_id
						WHERE productCategory_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#productCategory_id#" />
							AND vt.viewType = <cfqueryparam cfsqltype="cf_sql_varchar" null="false" list="false" value="#viewType#" />
							AND product_id = <cfqueryparam cfsqltype="cf_sql_bigint" null="false" list="false" value="#product_id#" />
					</cfquery>
					<cfcatch>
						<cfreturn "fail" />
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>
		<cfreturn "success" />
	</cffunction>

	<cffunction access="Remote" name="getCatalogMenu" returnType="Query">
		<cfargument name="schoolsId" required="false" default="0" />
		<cfquery name="catalogMenu" datasource="#dsn#">
			select 		ctc.catalogTopCategory, cc.catalogCategory, cc.catalogCategoryUrl
			from 		catalogCategory cc
			join 		catalogTopCategory ctc ON ctc.catalogTopCategory_id = cc.catalogTopCategory_id
			order by 	ctc.sortOrder,cc.sortOrder
		</cfquery>
		<cfreturn catalogMenu />
	</cffunction>

	<cffunction access="Remote" name="getProductCatalog" returnType="Query">
		<cfargument name="schoolsId" required="true" />
		<cfset productIdArray = ArrayNew(2) />
		<cfset lastColor = '' />
		<cfquery name="schoolCol" datasource="#variables.dsn#">
			SELECT [color1] as col1, color2, color3, EMBROIDERLETTERS, color4
			FROM schoolcolors
			WHERE id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#schoolsId#" null="no" />
		</cfquery>
		<!--- <cfdump var="#schoolCol#" /> --->
		<cfset embletters = schoolcol.embroiderletters />
		<cfset schoolcolor1 = trim(lcase(schoolCol.col1)) />
		<cfset schoolcolor2 = trim(lcase(schoolCol.color2)) />
		<cfset schoolcolor3 = trim(lcase(schoolCol.color3)) />
		<cfset schoolcolor4 = "gray" />
		<cfset schoolcolor5 = "black" />
		<cfset schoolcolor6 = "white" />
		<cfset robcolor1 = "" />
		<cfset robcolor2 = "" />
		<cfset robcolor3 = "" />
		<cfset robcolor1 = schoolcolor1 />
		<cfset robcolor2 = schoolcolor2 />
		<cfset robcolor3 = schoolcolor3 />
		<cfset lastcolor = "" />
		<cfif schoolcolor1 is "old gold">
			<cfset schoolcolor1 = "gold">
		</cfif>

		<cfif schoolcolor2 is "old gold">
			<cfset schoolcolor2 = "gold">
		</cfif>

		<cfif schoolcolor3 is "old gold">
			<cfset schoolcolor3 = "gold">
		</cfif>

		<cfif schoolcolor1 is "athletic gold">
			<cfset schoolcolor1 = "gold">
		</cfif>

		<cfif schoolcolor2 is "athletic gold">
			<cfset schoolcolor2 = "gold">
		</cfif>

		<cfif schoolcolor3 is "athletic gold">
			<cfset schoolcolor3 = "gold">
		</cfif>

		<cfif schoolcolor1 is "vegas gold">
			<cfset schoolcolor1 = "gold">
		</cfif>

		<cfif schoolcolor2 is "vegas gold">
			<cfset schoolcolor2 = "gold">
		</cfif>

		<cfif schoolcolor3 is "vegas gold">
			<cfset schoolcolor3 = "gold">
		</cfif>

		<cfif schoolcolor1 is "forest">
			<cfset schoolcolor1 = "green">
		</cfif>
		<cfif schoolcolor2 is "forest">
			<cfset schoolcolor2 = "green">
		</cfif>
		<cfif schoolcolor3 is "forest">
			<cfset schoolcolor3 = "green">
		</cfif>
		<cfif schoolcolor1 is "burgandy">
			<cfset schoolcolor1 = "maroon">
		</cfif>
		<cfif schoolcolor2 is "burgandy">
			<cfset schoolcolor2 = "maroon">
		</cfif>
		<cfif schoolcolor3 is "burgandy">
			<cfset schoolcolor3 = "maroon">
		</cfif>
		<cfquery name="catCategories" datasource="#variables.dsn#">
			SELECT		cc.catalogCategory_id
			FROM		CatalogCategory cc
			ORDER BY	catalogCategory_id
		</cfquery>
		<!--- <cfdump var="#catCategories#" /> --->
		<cfloop query="catCategories">
			<cfset thisCatalogCategory = catCategories.catalogCategory_id />
			<cfquery name="prodCategories" datasource="#variables.dsn#">
				SELECT 		pcccl.productCategory_id, cc.catalogTopCategory_id
				FROM		productCategory_catalogCategory_Link pcccl
				INNER JOIN	CatalogCategory cc ON cc.catalogCategory_id = pcccl.catalogCategory_id
				WHERE		pcccl.catalogCategory_id = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#catCategories.catalogCategory_id#" />
			</cfquery>
			<cfloop query="prodCategories">
				<cfquery name="products" datasource="#variables.dsn#">
					SELECT 		p.product_Name, pv.product_id, pic.color color1, pic.color2 color2, pic.color3 color3
					FROM		tbl_prdtcat_rel pcr
					INNER JOIN	tbl_prdtcategories pc ON pc.category_ID = pcr.prdt_cat_rel_Cat_ID
					INNER JOIN	tbl_products p ON p.product_ID = pcr.prdt_cat_rel_Product_ID
					INNER JOIN	pictures pic ON pic.product = pcr.prdt_cat_rel_Product_ID
					INNER JOIN	Product_View pv ON pv.product_id = pcr.prdt_cat_rel_Product_ID
					WHERE		pcr.prdt_cat_rel_Cat_ID = <cfqueryparam cfsqltype="cf_sql_bigint" list="false" null="false" value="#prodCategories.productCategory_id#" />
						AND		pv.viewType_id = 1
						AND		p.product_OnWeb = 1
						AND		p.product_Archive = 0
						AND NOT	(pic.color != '#schoolcolor1#' AND
								pic.color != '#schoolcolor2#' AND
								pic.color != '#schoolcolor3#' AND
								pic.color != '#schoolcolor4#' AND
								pic.color != '#schoolcolor5#' AND
								pic.color != '#schoolcolor6#'
								<cfif prodCategories.catalogTopCategory_id eq 2>
									AND pic.color != 'pink'
								</cfif>
								)
						AND (NOT (pic.color2 != '#schoolcolor1#' AND
								pic.color2 != '#schoolcolor2#' AND
								pic.color2 != '#schoolcolor3#' AND
								pic.color2 != '#schoolcolor4#' AND
								pic.color2 != '#schoolcolor5#' AND
								pic.color2 != '#schoolcolor6#'
								<cfif prodCategories.catalogTopCategory_id eq 2>
									AND pic.color2 != 'pink'
								</cfif>
								) or (pic.color2 is null or pic.color2 = ''))
				</cfquery>
				<cfif products.recordcount gt 0>
					<cfset lookForColor = schoolcolor1 />
					<cfif prodCategories.catalogTopCategory_id eq 2>
						<cfset backupColor = 'pink' />
					<cfelse>
						<cfset backupColor = schoolcolor2 />
					</cfif>
					<cfset backupColor2 = 'gray' />
					<cfif lastColor eq schoolcolor1>
						<cfset lookForColor = backupColor />
						<cfset backupColor = 'gray' />
						<cfset backupColor2 = 'white' />
					</cfif>
					<!--- <cfoutput>trying lookForColor #lookForColor#</cfoutput> --->
					<cfquery name="queryProductId" dbtype="query">
						SELECT 	product_id
						FROM	products
						WHERE	color1 = '#lookForColor#' or color2 = '#lookForColor#'
					</cfquery>
					<!--- <cfoutput> results: #queryProductId.recordcount#, #queryProductId.product_id#</cfoutput> --->
					<cfset lastColor = lookForColor />
					<cfif queryProductId.recordcount lt 1>
						<!--- <cfoutput>trying backupcolor #backupColor#</cfoutput> --->
						<cfquery name="queryProductId" dbtype="query">
							SELECT 	product_id
							FROM	products
							WHERE	color1 = '#backupColor#' or color2 = '#backupColor#'
						</cfquery>
						<!--- <cfoutput> results: #queryProductId.recordcount#, #queryProductId.product_id#</cfoutput> --->
						<cfset lastColor = backupColor />
					</cfif>
					<cfif queryProductId.recordcount lt 1>
						<!--- <cfoutput>trying backupcolor2 #backupColor2#</cfoutput> --->
						<cfquery name="queryProductId" dbtype="query">
							SELECT 	product_id
							FROM	products
							WHERE	color1 = '#backupColor2#' or color2 = '#backupColor2#'
						</cfquery>
						<!--- <cfoutput> results: #queryProductId.recordcount#, #queryProductId.product_id#</cfoutput> --->
						<cfset lastColor = backupColor2 />
					</cfif>
					<cfif queryProductId.recordcount lt 1>
						<!--- <cfoutput>last resort</cfoutput> --->
						<cfquery name="queryProductId" dbtype="query">
							SELECT 	product_id
							FROM	products
						</cfquery>
						<!--- <cfoutput> results: #queryProductId.recordcount#, #queryProductId.product_id#</cfoutput> --->
						<cfset lastColor = '' />
					</cfif>
				</cfif>
				<cfset appended = ArrayAppend(productIdArray[thisCatalogCategory],queryProductId.product_id) />
				<!--- <cfdump var="#productIdArray#" /> --->
			</cfloop>
		</cfloop>
		<!--- <cfdump var="#productIdArray#" /> --->
		<cfquery name="queryFinalProducts" datasource="#variables.dsn#">
			<cfloop index="c" from="1" to="22">
				<cfif c gt 1>
					UNION
				</cfif>
				SELECT 	pv.*,p.product_Name,#c# catalogCategory_id,'product-'+SUBSTRING(pic.image,0,LEN(pic.image)-3)+'_'+pic.product+'_'+pic.category+'.html' productURL
				FROM	Product_View pv
				INNER JOIN	tbl_products p ON p.product_Id = pv.product_id
				INNER JOIN	pictures pic ON pic.product = pv.product_id
				WHERE	pv.viewType_id = 1 AND (
					<cfloop index="i" from="1" to="#ArrayLen(productIdArray[c])#">
						<cfif i gt 1> OR </cfif>
						pv.product_id = #productIdArray[c][i]#
					</cfloop>
					)
			</cfloop>
				ORDER BY catalogCategory_id
		</cfquery>
		<cfreturn queryFinalProducts />
	</cffunction>

</cfcomponent>