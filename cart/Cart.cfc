<cfcomponent displayname="Cart" hint="Cart Functions" output="false">
	
	<cfset dsn 					= "cwdbsql" />
	<cfset frontFlashFile 		= "sv-2.1.3.swf" />
	<cfset backFlashFile 		= "backcart_sv-2.1.3.swf" />
	<cfset freeFlashFile 		= "free_sv-2.1.3.swf" />
	<cfset logoSetupFeeSKU 		= "15962" />
	<cfset logoSetupFeePrice	= "14.99" />
	<cfset addFeeDigital 		= true />
	<cfset addFeeEmbroidery 	= true />
	<cfset addFeePhoto			= false />
	
	<cffunction access="remote" name="AddToCartWholesale" returntype="Struct">
		<cfargument name="arrProductSizes" default=[] required="false" />
		<cfargument name="arrProductSizesSKUs" default=[] required="false" />
		<cfargument name="arrProductSizesQuantities" default=[] required="false" />
		<cfargument name="arrProductDiscountLevels" default=[] required="false" />
		<cfargument name="arrProductSizesWithUpcharges" default=[] required="false" />
		<cfargument name="arrSizeNameValuesSingle" default=[] required="false" />
		<cfargument name="arrSizeNumberValuesSingle" default=[] required="false" />
		<cfargument name="structSizeNameValues" default=[] required="false" />
		<cfargument name="structSizeNumberValues" default=[] required="false" />
		<cfargument name="arrFrontDesignFields" default=[] required="false" />
		<cfargument name="arrBackDesignFields" default=[] required="false" />
		<cfargument name="lbSizeValue" hint="selected value in the size drop-down" default="" required="false" />
		<cfargument name="lbSizeLength" hint="size list length" default=0 required="false" />
		<cfargument name="lbQuanValue" hint="selected value in the quantity drop-down" default="" required="false" />
		<cfargument name="bWholesaleMode" hint="Was Flash in Wholesale Mode" default=0 required="false" />
		<cfargument name="scId" hint="School ID" default="" required="false" />
		<cfargument name="pId" hint="Product ID" default=0 required="false" />
		<cfargument name="pCat" hint="Product Category" default=0 required="false" />
		<cfargument name="dId" hint="Front Design ID" default="" required="false" />
		<cfargument name="bdId" hint="Back Design ID" default="" required="false" />
		<cfargument name="tt" hint="Top Text" default="" required="false" />
		<cfargument name="bt" hint="Bottom Text" default="" required="false" />
		<cfargument name="yt" hint="Year" default="" required="false" />
		<cfargument name="tn" hint="Name in Front Design" default="" required="false" />
		<cfargument name="tm" hint="Number in Front Design" default="" required="false" />
		<cfargument name="gf" hint="Graphic File Name" default="" required="false" />
		<cfargument name="cp1" hint="Print Color 1" default="" required="false" />
		<cfargument name="cp2" hint="Print Color 2" default="" required="false" />
		<cfargument name="ce1" hint="Embroidery Color 1" default="" required="false" />
		<cfargument name="ce2" hint="Embroidery Color 2" default="" required="false" />
		<cfargument name="costring" hint="Pre-Escaped Custom Order String" default="co=0" required="false" />
		<cfargument name="bgf" hint="Back Graphic File Name" default="" required="false" />
		
		<cfset d 						= 0 />				<!--- discount percent --->
		<cfset bd 						= 0 />				<!--- back discount percent --->
		<cfset tq 						= 0 />				<!--- total quantity --->
		<cfset isBack 					= false />			<!--- are back prints included? --->
		<cfset wholesaleHash 			= "" />				<!--- hash of design elements and product so all items can be searched --->
		<cfset backname 				= "" />
		<cfset backnum 					= "" />
		<cfset backprint 				= "0" />
		<cfset insertedCount 			= 0 />				<!--- count of rows insterted into cart --->
		<cfset doInsertBack 			= false />
		
		<cfset retVal = StructNew() />
		<cfset retVal.returnCode = 0 />
		
		<cfset wholesaleHash = Hash(pId & dId & tt & bt & yt & gf) />
		
		<!--- Set boolean for including back designs (can be overwritten if name/number are blank for a particular item) --->
		<cfif bdId is not "">
			<cfset isBack = true />				<!--- we have a back design ID, so there are backs to be printed --->
			<cfset wholesaleHash = Hash(pId & dId & bdId & tt & bt & yt & gf) />
		</cfif>
		
		<!--- Calculate total quantity (tq) ordered --->
		<cfif lbSizeLength gt 1 and bWholesaleMode>
			<cfloop array="#arrProductSizes#" index="size">
				<cftry>
					<cfset q = Evaluate("arrProductSizesQuantities[""" & #size# & """]") />
					<cfcatch>
						<cfset q = 0 />
					</cfcatch>
				</cftry>
				<cfif q gt 0>
					<cfset tq = tq + q />
				</cfif>
			</cfloop>
		<cfelse>
			<cfset tq = lbQuanValue />
		</cfif>
		
		<!--- Set discount (d) and back discount (bd) values based on tq --->
		<cfloop from="1" to="#ArrayLen(arrProductDiscountLevels)#" index="i">
			<cfif tq gte arrProductDiscountLevels[i].qstart and tq lte arrProductDiscountLevels[i].qend>
				<cfset d = arrProductDiscountLevels[i].d1 />
				<cfset bd = arrProductDiscountLevels[i].d4 />
			</cfif>
		</cfloop>
		
		<cfif bWholesaleMode>
			<!--- Loop through products and add each to the cart --->
			<cfset rowClip = 0 />
			<cfloop array="#arrProductSizes#" index="size">
				<cftry>
					<cfset q = Evaluate("arrProductSizesQuantities[""" & #size# & """]") />
					<cfcatch>
						<cfset q = 0 />
					</cfcatch>
				</cftry>
				<cfif isNumeric(q)>
					<cfif q gt 0>
						<cftry>
							<cfset thisSKU = Evaluate("arrProductSizesSKUs[""" & #size# & """]") />
							<cfcatch>
								<cfset thisSKU = "" />
							</cfcatch>
						</cftry>
						
						<cfif isNumeric(thisSKU)>
							<!--- get this sku's price --->
							<cfquery name="getSKUInfo" datasource="#dsn#">
								SELECT 	s.sku_price, p.product_name
								FROM	tbl_skus s
								JOIN	tbl_products p ON p.product_id = s.sku_productid
								WHERE	s.sku_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />
							</cfquery>
							
							<!--- piece together the cart_notes value --->
							<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
												
							<!--- loop through quantity and insert into tbl_cart --->
							<cfif isBack>	<!--- do the back thing (forces 1 entry per item) --->
								<cfloop index="j" from=1 to=#q#>
									<cfset rowClip = rowClip + 1 />
									<cfset insertedCount = insertedCount + 1 />
									<cfset doInsertBack = false />	<!--- not going to insert back without actual data, this way it can skip blank backs --->
									<!--- check to see if there is a back name and/or back number --->
									<cftry>
										<cfset backname = Evaluate("structSizeNameValues[""" & #size# & """][""_name" & rowClip & """]") />
										<cfcatch>
											<cfset backname = "" />
										</cfcatch>
									</cftry>
									<cftry>
										<cfset backnum = Evaluate("structSizeNumberValues[""" & #size# & """][""_name" & rowClip & """]") />
										<cfcatch>
											<cfset backnum = "" />
										</cfcatch>
									</cftry>
									
									<!--- we know we have back info, but we should check the design to see which info is required --->
									<cfif (ListFindNoCase(ArrayToList(arrBackDesignFields), "name") and Len(backname) gt 0) or (ListFindNoCase(ArrayToList(arrBackDesignFields), "number") and Len(backnum) gt 0) or (not ListFindNoCase(ArrayToList(arrBackDesignFields),"number") and not (ListFindNoCase(ArrayToList(arrBackDesignFields),"name")))>
										<cfset doInsertBack = true />
										<cfset backprint = "1" />
									</cfif>
									
									<!--- back fields win, so replace the front name & number fields in the cart_notes --->
									<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
									
									<!--- insert the front into the cart --->
									<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
									<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />
									
									<cftransaction>
										<cfquery name="insertFront" datasource="#dsn#">
											INSERT INTO 	tbl_cart (
																cart_custcart_ID, 
																cart_sku_ID, 
																cart_sku_qty, 
																cart_dateadded, 
																cart_notes, 
																sc_id_cart, 
																prod_name, 
																cart_backname, 
																cart_backnum,
																backprint,
																cart_wholesale_price,
																cart_wholesale_hash
															)
											VALUES 			(
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
																<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
																<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
																<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#backname#" />, 
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#backnum#" />,
																<cfqueryparam cfsqltype="cf_sql_bit" value="#backprint#" />,
																<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
																<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
															)
										</cfquery>
										
										<cfif doInsertBack>
											<!--- piece together the cart_notes value --->
											<cfset back_cart_notes = #backFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&bdId=" & #URLEncodedFormat(bdId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(bgf)# & "&bv=true" & "&" & #costring#/>
											
											<cfset wholesaleBackPrice = 6.95 - ((d*0.01) * 6.95) />
											<cfset wholesaleBackPrice = Round(javacast("float",wholesaleBackPrice * 100)) / 100 />
											
											<cfquery name="insertBack" datasource="#dsn#">
												INSERT INTO 	tbl_cart (
																	cart_custcart_ID, 
																	cart_sku_ID, 
																	cart_sku_qty, 
																	cart_dateadded, 
																	cart_notes, 
																	sc_id_cart, 
																	prod_name, 
																	cart_backname, 
																	cart_backnum,
																	backprint,
																	cart_wholesale_price,
																	cart_wholesale_hash
																)
												VALUES 			(
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
																	<cfqueryparam cfsqltype="cf_sql_integer" value="1350" />,
																	<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
																	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="#back_cart_notes#" />, 
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="T-Shirt Back Design" />, 
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
																	<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
																	<cfqueryparam cfsqltype="cf_sql_float" value="#wholesaleBackPrice#" />,
																	<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
																)
											</cfquery>
										</cfif>
										
									</cftransaction>
								</cfloop>
							<cfelseif ListFindNoCase(ArrayToList(arrFrontDesignFields), "name") or ListFindNoCase(ArrayToList(arrFrontDesignFields), "number")>
								<!--- no backs... but we have front design with name or number --->
								<cfloop index="j" from=1 to=#q#>
									<cfset rowClip = rowClip + 1 />
									<cfset insertedCount = insertedCount + 1 />
									<!--- check to see if there are bulk name and/or number --->
									<cftry>
										<cfset backname = Evaluate("structSizeNameValues[""" & #size# & """][""_name" & rowClip & """]") />
										<cfcatch>
											<cfset backname = tn />
										</cfcatch>
									</cftry>
									<cftry>
										<cfset backnum = Evaluate("structSizeNumberValues[""" & #size# & """][""_name" & rowClip & """]") />
										<cfcatch>
											<cfset backnum = tm />
										</cfcatch>
									</cftry>
									
									<!--- back fields win, so replace the front name & number fields in the cart_notes --->
									<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
									
									<!--- insert the front into the cart --->
									<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
									<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />
									
									<cfquery name="insertFront" datasource="#dsn#">
										INSERT INTO 	tbl_cart (
															cart_custcart_ID, 
															cart_sku_ID, 
															cart_sku_qty, 
															cart_dateadded, 
															cart_notes, 
															sc_id_cart, 
															prod_name, 
															cart_backname, 
															cart_backnum,
															backprint,
															cart_wholesale_price,
															cart_wholesale_hash
														)
										VALUES 			(
															<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
															<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
															<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
															<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
															<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
															<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
															<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
															<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
															<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
															<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
															<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
															<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
														)
									</cfquery>
								</cfloop>
							<cfelse>	<!--- no backs and no names or numbers in the front design, so add quantity on sigle line --->
								<cfset insertedCount = insertedCount + 1 />
								<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
								<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />
								
								<cfquery name="insertFront" datasource="#dsn#">
									INSERT INTO 	tbl_cart (
														cart_custcart_ID, 
														cart_sku_ID, 
														cart_sku_qty, 
														cart_dateadded, 
														cart_notes, 
														sc_id_cart, 
														prod_name, 
														cart_backname, 
														cart_backnum,
														backprint,
														cart_wholesale_price,
														cart_wholesale_hash
													)
									VALUES 			(
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
														<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
														<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
														<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
													)
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
		<cfelse>	<!--- not bWholesaleMode --->
			<!--- single sku, may have backs, or front names or numbers --->
			<cfset thisSKU = lbSizeValue />
			<cfif isNumeric(thisSKU)>	<!--- continue only if valid SKU --->
				<!--- get this sku's price --->
				<cfquery name="getSKUInfo" datasource="#dsn#">
					SELECT 	s.sku_price, p.product_name
					FROM	tbl_skus s
					JOIN	tbl_products p ON p.product_id = s.sku_productid
					WHERE	s.sku_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />
				</cfquery>
				<cfset q = lbQuanValue />
				<cfif isNumeric(q)>
					<!--- piece together the cart_notes value --->
					<cfif getSKUInfo.sku_price eq 0>
						<cfset cart_notes = #freeFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
					<cfelse>	
						<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
					</cfif>
					<cfif isBack>  <!--- we have a back design id, so we need to deal with that --->
						<cfset doInsertBack = false />	<!--- not going to insert back without actual data, this way it can skip blank backs --->
						<!--- check to see if there is a back name and/or back number --->
						<cfset backname = tn />
						<cfset backnum = tm />
						<!--- we know we have back info, but we should check the design to see which info is required --->
						<cfif (ListFindNoCase(ArrayToList(arrBackDesignFields), "name") and Len(backname) gt 0) or (ListFindNoCase(ArrayToList(arrBackDesignFields), "number") and Len(backnum) gt 0) or (not ListFindNoCase(ArrayToList(arrBackDesignFields),"number") and not (ListFindNoCase(ArrayToList(arrBackDesignFields),"name")))>
							<cfset doInsertBack = true />
							<cfset backprint = "1" />
						</cfif>
						
						<!--- insert the front into the cart --->
						<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
						<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

						<cfset insertedCount = insertedCount + 1 />
						
						<cftransaction>
							<cfquery name="insertFront" datasource="#dsn#">
								INSERT INTO 	tbl_cart (
													cart_custcart_ID, 
													cart_sku_ID, 
													cart_sku_qty, 
													cart_dateadded, 
													cart_notes, 
													sc_id_cart, 
													prod_name, 
													cart_backname, 
													cart_backnum,
													backprint,
													cart_wholesale_price,
													cart_wholesale_hash
												)
								VALUES 			(
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
													<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#backname#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#backnum#" />,
													<cfqueryparam cfsqltype="cf_sql_bit" value="#backprint#" />,
													<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
												)
							</cfquery>
							
							<cfif doInsertBack>
								<!--- piece together the cart_notes value --->
								<cfset back_cart_notes = #backFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&bdId=" & #URLEncodedFormat(bdId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(bgf)# & "&bv=true" & "&" & #costring#/>
								
								<cfset wholesaleBackPrice = 6.95 - ((d*0.01) * 6.95) />
								<cfset wholesaleBackPrice = Round(javacast("float",wholesaleBackPrice * 100)) / 100 />
								
								<cfquery name="insertBack" datasource="#dsn#">
									INSERT INTO 	tbl_cart (
														cart_custcart_ID, 
														cart_sku_ID, 
														cart_sku_qty, 
														cart_dateadded, 
														cart_notes, 
														sc_id_cart, 
														prod_name, 
														cart_backname, 
														cart_backnum,
														backprint,
														cart_wholesale_price,
														cart_wholesale_hash
													)
									VALUES 			(
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="1350" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
														<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#back_cart_notes#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="T-Shirt Back Design" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
														<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
														<cfqueryparam cfsqltype="cf_sql_float" value="#wholesaleBackPrice#" />,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
													)
								</cfquery>
							</cfif>
							
						</cftransaction>
					<cfelseif ListFindNoCase(ArrayToList(arrFrontDesignFields), "name") or ListFindNoCase(ArrayToList(arrFrontDesignFields), "number")>
						<!--- no backs... but we have front design with name or number --->
						<cfloop index="j" from=1 to=#q#>
							<cfif q gt 1>
								<!--- check to see if there are bulk name and/or number --->
								<cftry>
									<cfset backname = Evaluate("arrSizeNameValuesSingle[""_name" & j & """]") />
									<!--- <cfset backname = arrSizeNameValuesSingle[j-1] /> --->
									<cfcatch>
										<cfset backname = tn />
									</cfcatch>
								</cftry>
								<cftry>
									<cfset backnum = Evaluate("arrSizeNumberValuesSingle[""_name" & j & """]") />
									<!--- <cfset backnum = arrSizeNumberValuesSingle[j-1] /> --->
									<cfcatch>
										<cfset backnum = tm />
									</cfcatch>
								</cftry>
							<cfelse>
								<!--- quantity is only 1, so force us to use tn and tm (they may have entered a bunch of names, but are only ordering 1) --->
								<cfset backname = tn />
								<cfset backnum = tm />
							</cfif>
							
							<!--- back fields win, so replace the front name & number fields in the cart_notes --->
							<!--- is this the free-t?  if it is, then switch-out the frontFlashFile for freeFlashFile --->
							<cfif getSKUInfo.sku_price eq 0>
								<cfset cart_notes = #freeFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
							<cfelse>
								<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(gf)# & "&" & #costring# />
							</cfif>
							
							<!--- insert the front into the cart --->
							<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
							<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

							<cfset insertedCount = insertedCount + 1 />
							
							<cfquery name="insertFront" datasource="#dsn#">
								INSERT INTO 	tbl_cart (
													cart_custcart_ID, 
													cart_sku_ID, 
													cart_sku_qty, 
													cart_dateadded, 
													cart_notes, 
													sc_id_cart, 
													prod_name, 
													cart_backname, 
													cart_backnum,
													backprint,
													cart_wholesale_price,
													cart_wholesale_hash
												)
								VALUES 			(
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
													<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
													<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
													<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
												)
							</cfquery>
						</cfloop>
					<cfelse> <!--- not isBack and not a bulk-able design --->
						<cfset insertedCount = insertedCount + 1 />
						<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
						<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />
						
						<cfquery name="insertFront" datasource="#dsn#">
							INSERT INTO 	tbl_cart (
												cart_custcart_ID, 
												cart_sku_ID, 
												cart_sku_qty, 
												cart_dateadded, 
												cart_notes, 
												sc_id_cart, 
												prod_name, 
												cart_backname, 
												cart_backnum,
												backprint,
												cart_wholesale_price,
												cart_wholesale_hash
											)
							VALUES 			(
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
												<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
												<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
												<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
											)
						</cfquery>
					</cfif> <!--- isBack --->
				</cfif>	<!--- isNumeric(q) --->
			</cfif> <!--- isNumeric(thisSKU) --->
			
		</cfif> <!--- is bWholesaleMode --->
		
		<cfif insertedCount>
			<!--- See if we need to add logo setup fee --->
			<cfset isLogoSetupFeeNeeded	= false />
			<cfif left(gf, 9) eq 'cuploads/'>
				<!--- check the status of the upload, if it's at 1 then add the setup fee --->
				<cfquery name="uploadInfo" datasource="#dsn#">
					SELECT 			logoActive, LogoColorType, isPhoto
					FROM 			cLogoUploads WITH (NOLOCK)
					WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(gf,35)#" cfsqltype="cf_sql_varchar" />
				</cfquery>
				<cfif uploadInfo.recordcount gt 0>
					<cfif uploadInfo.logoActive[1] eq "1" and ( 
							(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
							(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
							(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
						<!--- make sure we don't already have the setup fee for this logo in the cart --->
						<cfquery name="qryAlreadyInCart" datasource="#dsn#">
							SELECT 			*
							FROM 			tbl_cart WITH (NOLOCK)
							WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
								AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
								AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />
						</cfquery>
						<cfif qryAlreadyInCart.recordcount lte 0>
							<cfset isLogoSetupFeeNeeded = true />
						</cfif>
					</cfif>
				</cfif>
			</cfif>
			<!--- Done checking if we need to add logo setup fee --->
			<cfif isLogoSetupFeeNeeded>
				<cfquery name="insertLogoSetupFee" datasource="#dsn#">
					INSERT INTO 	tbl_cart (
										cart_custcart_ID, 
										cart_sku_ID, 
										cart_sku_qty, 
										cart_dateadded, 
										cart_notes, 
										sc_id_cart, 
										prod_name, 
										cart_backname, 
										cart_backnum,
										backprint,
										cart_wholesale_price,
										cart_wholesale_hash
									)
					VALUES 			(
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
										<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
										<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
										<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
									)
				</cfquery>
			</cfif>

			<cfset isLogoSetupFeeNeeded = false />
			<cfif doInsertBack>
				<cfif left(bgf, 9) eq 'cuploads/'>
					<!--- check the status of the upload, if it's at 1 then add the setup fee --->
					<cfquery name="uploadInfo" datasource="#dsn#">
						SELECT 			logoActive, LogoColorType, isPhoto
						FROM 			cLogoUploads WITH (NOLOCK)
						WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(bgf,35)#" cfsqltype="cf_sql_varchar" />
					</cfquery>
					<cfif uploadInfo.recordcount gt 0>
						<cfif uploadInfo.logoActive[1] eq "1" and ( 
								(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
								(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
								(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
							<!--- make sure we don't already have the setup fee for this logo in the cart --->
							<cfquery name="qryAlreadyInCart" datasource="#dsn#">
								SELECT 			*
								FROM 			tbl_cart WITH (NOLOCK)
								WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
									AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
									AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />
							</cfquery>
							<cfif qryAlreadyInCart.recordcount lte 0>
								<cfset isLogoSetupFeeNeeded = true />
							</cfif>
						</cfif>
					</cfif>
				</cfif>
				<!--- Done checking if we need to add logo setup fee --->
				<cfif isLogoSetupFeeNeeded>
					<cfquery name="insertLogoSetupFee" datasource="#dsn#">
						INSERT INTO 	tbl_cart (
											cart_custcart_ID, 
											cart_sku_ID, 
											cart_sku_qty, 
											cart_dateadded, 
											cart_notes, 
											sc_id_cart, 
											prod_name, 
											cart_backname, 
											cart_backnum,
											backprint,
											cart_wholesale_price,
											cart_wholesale_hash
										)
						VALUES 			(
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
											<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
											<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
											<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
										)
					</cfquery>
				</cfif>
			</cfif>
			<!--- done adding setup fee --->
			<!--- done adding setup fee --->
		</cfif>

		<cfset retVal.d = d />
		<cfset retVal.bd = bd />
		<cfset retVal.tq = tq />
		<cfset retVal.bdid = bdId />
		<cfset retVal.backname = backname />
		<cfset retVal.backnum = backnum />
		<cfset retVal.fFields = arrFrontDesignFields />
		<cfset retVal.bFields = arrBackDesignFields />
		<cfset retVal.cart_notes = cart_notes />
		<cfset retVal.wholesaleHash = wholesaleHash />
		<cfset retVal.CART_TOTAL_ITEMS = 0 />
		<cfset retVal.CART_TOTAL_PRICE = "$0.00" />

		<cfif isdefined("Client.CartID")>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
			<cftry>
				<cfquery name="cartQuanQry" datasource="#dsn#">
					select
						SUM(cart_sku_qty) as cartCount
					from 
						tbl_cart WITH (NOLOCK)
					where 
						prod_name != 'T-Shirt Back Design'
						and cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
				<cfquery name="cartPriceQry" datasource="#dsn#">
					select
						SUM(cart_wholesale_price * cart_sku_qty) as cartPrice
					from
						tbl_cart WITH (NOLOCK)
					where
						cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
				
                <cfif cartQuanQry.recordcount>
					<cfset CartQuantity = Trim(LSNumberFormat(cartQuanQry.cartCount, ",999,999")) />
                    <cfcookie name="cart.CartQuantity" value="#cartQuanQry.cartCount#" expires="30">
				</cfif>
				<cfif cartPriceQry.recordcount>
					<cfset CartPrice = "$" & Trim(LSNumberFormat(cartPriceQry.cartPrice, '999,999.00')) />
                    <cfcookie name="cart.CartPrice" value="#cartPriceQry.cartPrice#" expires="30" />
				</cfif>                
				
				<cfcatch type="any">
					<!--- error handling --->
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
		</cfif>

		<cfset retVal.CART_TOTAL_ITEMS = CartQuantity />
		<cfset retVal.CART_TOTAL_PRICE = CartPrice />

		<cfreturn retVal />

	</cffunction>
	
	<cffunction name="AddToCartSingle" access="remote" hint="non-wholesale add-to-cart procedure" returntype="Struct">
		<cfargument name="arrProductDiscountLevels" default=[] required="false" />
		<cfargument name="lbSizeValue" hint="selected value in the size drop-down" default="" required="false" />
		<cfargument name="lbSizeLength" hint="size list length" default=0 required="false" />
		<cfargument name="lbQuanValue" hint="selected value in the quantity drop-down" default="" required="false" />
		<cfargument name="bWholesaleMode" hint="Was Flash in Wholesale Mode" default=0 required="false" />
		<cfargument name="scId" hint="School ID" default="" required="false" />
		<cfargument name="pId" hint="Product ID" default=0 required="false" />
		<cfargument name="pCat" hint="Product Category" default=0 required="false" />
		<cfargument name="dId" hint="Front Design ID" default="" required="false" />
		<cfargument name="bdId" hint="Back Design ID" default="" required="false" />
		<cfargument name="tt" hint="Top Text" default="" required="false" />
		<cfargument name="bt" hint="Bottom Text" default="" required="false" />
		<cfargument name="yt" hint="Year" default="" required="false" />
		<cfargument name="tn" hint="Name in Front Design" default="" required="false" />
		<cfargument name="tm" hint="Number in Front Design" default="" required="false" />
		<cfargument name="gf" hint="Graphic File Name" default="" required="false" />
		<cfargument name="cp1" hint="Print Color 1" default="" required="false" />
		<cfargument name="cp2" hint="Print Color 2" default="" required="false" />
		<cfargument name="ce1" hint="Embroidery Color 1" default="" required="false" />
		<cfargument name="ce2" hint="Embroidery Color 2" default="" required="false" />
		<cfargument name="bgf" hint="Back Graphic File Name" default="" required="false" />
		
		<cfset d = 0 />								<!--- discount percent --->
		<cfset bd = 0 />							<!--- back discount percent --->
		<cfset tq = 0 />							<!--- total quantity --->
		<cfset isBack = false />					<!--- are back prints included? --->
		<cfset wholesaleHash = "" />				<!--- hash of design elements and product so all items can be searched --->
		<cfset backname = "" />
		<cfset backnum = "" />
		<cfset backprint = "0" />
		<cfset insertedCount = 0 />					<!--- count of rows inserted into cart --->
		<cfset doInsertBack = false />
		
		<cfset cp1 = "0x" & cp1 />
		<cfset cp2 = "0x" & cp2 />
		<cfset ce1 = "0x" & ce1 />
		<cfset ce2 = "0x" & ce2 />
		
		<cfset retVal = StructNew() />
		<cfset retVal.returnCode = 0 />
		
		<cfset wholesaleHash = Hash(pId & dId & tt & bt & yt & gf) />
		
		<!--- Set boolean for including back designs (can be overwritten if name/number are blank for a particular item) --->
		<cfif bdId is not "">
			<cfset isBack = true />				<!--- we have a back design ID, so there are backs to be printed --->
			<cfset wholesaleHash = Hash(pId & dId & bdId & tt & bt & yt & gf) />
		</cfif>
		
		<cfset tq = lbQuanValue />

		<!--- Set discount (d) and back discount (bd) values based on tq --->
		<cfloop from="1" to="#ArrayLen(arrProductDiscountLevels)#" index="i">
			<cfif tq gte arrProductDiscountLevels[i].qstart and tq lte arrProductDiscountLevels[i].qend>
				<cfset d = arrProductDiscountLevels[i].discount />
				<cfset bd = arrProductDiscountLevels[i].discount />
			</cfif>
		</cfloop>		
		
		<!--- single sku, may have backs, or front names or numbers --->
		<cfset thisSKU = lbSizeValue />
		<cfif isNumeric(thisSKU)>	<!--- continue only if valid SKU --->
			<!--- get this sku's price --->
			<cfquery name="getSKUInfo" datasource="#dsn#">
				SELECT 	s.sku_price, p.product_name
				FROM	tbl_skus s
				JOIN	tbl_products p ON p.product_id = s.sku_productid
				WHERE	s.sku_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />
			</cfquery>
			<cfset q = lbQuanValue />
			<cfif isNumeric(q)>
				<!--- piece together the cart_notes value --->
				<cfif getSKUInfo.sku_price eq 0>
					<cfset cart_notes = #freeFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&iPad=1" />
				<cfelse>	
					<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&iPad=1" />
				</cfif>
				
				<cfif isBack>  <!--- we have a back design id, so we need to deal with that --->
					<cfset doInsertBack = false />	<!--- not going to insert back without actual data, this way it can skip blank backs --->
					<!--- check to see if there is a back name and/or back number --->
					<cfset backname = tn />
					<cfset backnum = tm />
					<!--- we know we have back info, but we should check the design to see which info is required --->
					<!--- <cfif (ListFindNoCase(ArrayToList(arrBackDesignFields), "name") and Len(backname) gt 0) or (ListFindNoCase(ArrayToList(arrBackDesignFields), "number") and Len(backnum) gt 0)> --->
						<cfset doInsertBack = true />
						<cfset backprint = "1" />
					<!--- </cfif> --->
					
					<!--- insert the front into the cart --->
					<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
					<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

					<cfset insertedCount = insertedCount + 1 />
					
					<cftransaction>
						<cfquery name="insertFront" datasource="#dsn#">
							INSERT INTO 	tbl_cart (
												cart_custcart_ID, 
												cart_sku_ID, 
												cart_sku_qty, 
												cart_dateadded, 
												cart_notes, 
												sc_id_cart, 
												prod_name, 
												cart_backname, 
												cart_backnum,
												backprint,
												cart_wholesale_price,
												cart_wholesale_hash
											)
							VALUES 			(
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
												<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#backname#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#backnum#" />,
												<cfqueryparam cfsqltype="cf_sql_bit" value="#backprint#" />,
												<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
											)
						</cfquery>
						
						<cfif doInsertBack>
							<!--- piece together the cart_notes value --->
							<cfset back_cart_notes = #backFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&bdId=" & #URLEncodedFormat(bdId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(bgf)# & "&bv=true&iPad=1"/>
							
							<cfset wholesaleBackPrice = 6.95 - ((d*0.01) * 6.95) />
							<cfset wholesaleBackPrice = Round(javacast("float",wholesaleBackPrice * 100)) / 100 />
							
							<cfquery name="insertBack" datasource="#dsn#">
								INSERT INTO 	tbl_cart (
													cart_custcart_ID, 
													cart_sku_ID, 
													cart_sku_qty, 
													cart_dateadded, 
													cart_notes, 
													sc_id_cart, 
													prod_name, 
													cart_backname, 
													cart_backnum,
													backprint,
													cart_wholesale_price,
													cart_wholesale_hash
												)
								VALUES 			(
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="1350" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
													<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#back_cart_notes#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="T-Shirt Back Design" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
													<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
													<cfqueryparam cfsqltype="cf_sql_float" value="#wholesaleBackPrice#" />,
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
												)
							</cfquery>
						</cfif>
						
					</cftransaction>
				<cfelse> <!--- not isBack and not a bulk-able design --->
					<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
					<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

					<cfset insertedCount = insertedCount + 1 />
					
					<cfquery name="insertFront" datasource="#dsn#">
						INSERT INTO 	tbl_cart (
											cart_custcart_ID, 
											cart_sku_ID, 
											cart_sku_qty, 
											cart_dateadded, 
											cart_notes, 
											sc_id_cart, 
											prod_name, 
											cart_backname, 
											cart_backnum,
											backprint,
											cart_wholesale_price,
											cart_wholesale_hash
										)
						VALUES 			(
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
											<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
											<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
											<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
										)
					</cfquery>
				</cfif> <!--- isBack --->
			</cfif>	<!--- isNumeric(q) --->
		</cfif> <!--- isNumeric(thisSKU) --->

		<cfif insertedCount>
			<!--- See if we need to add logo setup fee --->
			<cfset isLogoSetupFeeNeeded	= false />
			<cfif left(gf, 9) eq 'cuploads/'>
				<!--- check the status of the upload, if it's at 1 then add the setup fee --->
				<cfquery name="uploadInfo" datasource="#dsn#">
					SELECT 			logoActive, LogoColorType, isPhoto
					FROM 			cLogoUploads WITH (NOLOCK)
					WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(gf,35)#" cfsqltype="cf_sql_varchar" />
				</cfquery>
				<cfif uploadInfo.recordcount gt 0>
					<cfif uploadInfo.logoActive[1] eq "1" and ( 
							(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
							(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
							(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
						<!--- make sure we don't already have the setup fee for this logo in the cart --->
						<cfquery name="qryAlreadyInCart" datasource="#dsn#">
							SELECT 			*
							FROM 			tbl_cart
							WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
								AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
								AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />
						</cfquery>
						<cfif qryAlreadyInCart.recordcount lte 0>
							<cfset isLogoSetupFeeNeeded = true />
						</cfif>
					</cfif>
				</cfif>
			</cfif>
			<!--- Done checking if we need to add logo setup fee --->
			<cfif isLogoSetupFeeNeeded>
				<cfquery name="insertLogoSetupFee" datasource="#dsn#">
					INSERT INTO 	tbl_cart (
										cart_custcart_ID, 
										cart_sku_ID, 
										cart_sku_qty, 
										cart_dateadded, 
										cart_notes, 
										sc_id_cart, 
										prod_name, 
										cart_backname, 
										cart_backnum,
										backprint,
										cart_wholesale_price,
										cart_wholesale_hash
									)
					VALUES 			(
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
										<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
										<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
										<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
									)
				</cfquery>
			</cfif>
			<!--- done adding setup fee for front --->

			<cfset isLogoSetupFeeNeeded = false />
			<cfif doInsertBack>
				<cfif left(bgf, 9) eq 'cuploads/'>
					<!--- check the status of the upload, if it's at 1 then add the setup fee --->
					<cfquery name="uploadInfo" datasource="#dsn#">
						SELECT 			logoActive, LogoColorType, isPhoto
						FROM 			cLogoUploads WITH (NOLOCK)
						WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(bgf,35)#" cfsqltype="cf_sql_varchar" />
					</cfquery>
					<cfif uploadInfo.recordcount gt 0>
						<cfif uploadInfo.logoActive[1] eq "1" and ( 
								(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
								(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
								(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
							<!--- make sure we don't already have the setup fee for this logo in the cart --->
							<cfquery name="qryAlreadyInCart" datasource="#dsn#">
								SELECT 			*
								FROM 			tbl_cart WITH (NOLOCK)
								WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
									AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
									AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />
							</cfquery>
							<cfif qryAlreadyInCart.recordcount lte 0>
								<cfset isLogoSetupFeeNeeded = true />
							</cfif>
						</cfif>
					</cfif>
				</cfif>
				<!--- Done checking if we need to add logo setup fee --->
				<cfif isLogoSetupFeeNeeded>
					<cfquery name="insertLogoSetupFee" datasource="#dsn#">
						INSERT INTO 	tbl_cart (
											cart_custcart_ID, 
											cart_sku_ID, 
											cart_sku_qty, 
											cart_dateadded, 
											cart_notes, 
											sc_id_cart, 
											prod_name, 
											cart_backname, 
											cart_backnum,
											backprint,
											cart_wholesale_price,
											cart_wholesale_hash
										)
						VALUES 			(
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
											<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
											<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
											<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
										)
					</cfquery>
				</cfif>
			</cfif>
			<!--- done adding setup fee --->
		</cfif>

		<cfset retVal.d = d />
		<cfset retVal.bd = bd />
		<cfset retVal.tq = tq />
		<cfset retVal.arrProductDiscountLevels = arrProductDiscountLevels />
		<cfset retVal.bWholesaleMode = bWholesaleMode />
		<cfset retVal.scId = scId />
		<cfset retVal.pId = pId />
		<cfset retVal.pCat = pCat />
		<cfset retVal.did = dId />
		<cfset retVal.bdid = bdId />
		<cfset retVal.tt = tt />
		<cfset retVal.bt = bt />
		<cfset retVal.yt = yt />
		<cfset retVal.tn = tn />
		<cfset retVal.tm = tm />
		<cfset retVal.gf = gf />
		<cfset retVal.cp1 = cp1 />			<!--- Note: sending '000000' looks like just a '0' to the javascript --->
		<cfset retVal.cp2 = cp2 />
		<cfset retVal.ce1 = ce1 />
		<cfset retVal.ce2 = ce2 />
		<cfset retVal.wholesaleHash = wholesaleHash />
		<cfset retVal.CART_TOTAL_ITEMS = 0 />
		<cfset retVal.CART_TOTAL_PRICE = "$0.00" />

		<cfif isdefined("Client.CartID")>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
			<cftry>
				<cfquery name="cartQuanQry" datasource="#dsn#">
					select
						SUM(cart_sku_qty) as cartCount
					from 
						tbl_cart WITH (NOLOCK)
					where 
						prod_name != 'T-Shirt Back Design'
						and cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
				<cfquery name="cartPriceQry" datasource="#dsn#">
					select
						SUM(cart_wholesale_price * cart_sku_qty) as cartPrice
					from
						tbl_cart WITH (NOLOCK)
					where
						cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
								                
                <cfif cartQuanQry.recordcount>
					<cfset CartQuantity = Trim(LSNumberFormat(cartQuanQry.cartCount, ",999,999")) />
                    <cfcookie name="cart.CartQuantity" value="#cartQuanQry.cartCount#" expires="30">
				</cfif>
				<cfif cartPriceQry.recordcount>
					<cfset CartPrice = "$" & Trim(LSNumberFormat(cartPriceQry.cartPrice, '999,999.00')) />
                    <cfcookie name="cart.CartPrice" value="#cartPriceQry.cartPrice#" expires="30" />
				</cfif>      
                
				<cfcatch type="any">
					<!--- error handling --->
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
		</cfif>

		<cfset retVal.CART_TOTAL_ITEMS = CartQuantity />
		<cfset retVal.CART_TOTAL_PRICE = CartPrice />

		<cfreturn retVal />
	
	</cffunction>

	<cffunction name="AddToCartMobile" access="remote" hint="Latest, Mobile Version add-to-cart procedure" returntype="Struct">
		<cfargument name="arrProductDiscountLevels" default=[] required="false" />
		<cfargument name="arrCartRows" hint="Rows of structures with qty,sku,name,number" default=[] required="false" />
		<cfargument name="pId" hint="Product ID" default="" required="false" />
		<cfargument name="dId" hint="Front Design ID" default="" required="false" />
		<cfargument name="bdId" hint="Back Design ID" default="" required="false" />
		<cfargument name="tt" hint="Top Text" default="" required="false" />
		<cfargument name="bt" hint="Bottom Text" default="" required="false" />
		<cfargument name="yt" hint="Year" default="" required="false" />
		<cfargument name="gf" hint="Graphic File Name" default="" required="false" />
		<cfargument name="cp1" hint="Print Color 1" default="" required="false" />
		<cfargument name="cp2" hint="Print Color 2" default="" required="false" />
		<cfargument name="ce1" hint="Embroidery Color 1" default="" required="false" />
		<cfargument name="ce2" hint="Embroidery Color 2" default="" required="false" />
		<cfargument name="tq" hint="total Quantity used to get discount level" default=0 required="false" />
		<cfargument name="scId" hint="shop ID" default="" required="false" />
		<cfargument name="bgf" hint="Back Graphic File Name" default="" required="false" />
		
		<cfset d = 0 />								<!--- discount percent --->
		<cfset bd = 0 />							<!--- back discount percent --->
		<cfset isBack = false />					<!--- are back prints included? --->
		<cfset wholesaleHash = "" />				<!--- hash of design elements and product so all items can be searched --->
		<cfset backname = "" />
		<cfset backnum = "" />
		<cfset backprint = "0" />
		<cfset insertedCount = 0 />					<!--- count of rows inserted into cart --->
		<cfset doInsertBack 	= false />
		
		<cfset cp1 = "0x" & cp1 />
		<cfset cp2 = "0x" & cp2 />
		<cfset ce1 = "0x" & ce1 />
		<cfset ce2 = "0x" & ce2 />
		
		<cfset retVal = StructNew() />
		<cfset retVal.returnCode = 0 />
		
		<cfset wholesaleHash = Hash(pId & dId & tt & bt & yt & gf) />
		
		<!--- Set boolean for including back designs (can be overwritten if name/number are blank for a particular item) --->
		<cfif bdId is not "">
			<cfset isBack = true />				<!--- we have a back design ID, so there are backs to be printed --->
			<cfquery name="bdInfo" datasource="#dsn#">
				SELECT		CASE WHEN dt_name.description IS NULL THEN 0 ELSE 1 END hasName,
							CASE WHEN dt_number.description IS NULL THEN 0 ELSE 1 END hasNumber 
				FROM 		design d WITH (NOLOCK)
				LEFT JOIN 	design_text dt_name WITH (NOLOCK) ON dt_name.design_id = d.design_id AND dt_name.description='Name'
				LEFT JOIN 	design_text dt_number WITH (NOLOCK) ON dt_number.design_id = d.design_id AND dt_number.description='Number'
				WHERE 		d.design_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#bdId#" />
			</cfquery>
			<cfset wholesaleHash = Hash(pId & dId & bdId & tt & bt & yt & gf) />
		</cfif>

		<!--- Set discount (d) and back discount (bd) values based on tq --->
		<cfloop from="1" to="#ArrayLen(arrProductDiscountLevels)#" index="i">
			<cfif tq gte arrProductDiscountLevels[i].qstart and tq lte arrProductDiscountLevels[i].qend>
				<cfset d = arrProductDiscountLevels[i].discount />
				<cfset bd = arrProductDiscountLevels[i].discount />
			</cfif>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(arrCartRows)#" index="i">
			<cfset thisSKU = arrCartRows[i].sku />
			<cfif isNumeric(thisSKU)>	<!--- continue only if valid SKU --->
				<!--- get this sku's price --->
				<cfquery name="getSKUInfo" datasource="#dsn#">
					SELECT 	s.sku_price, p.product_name
					FROM	tbl_skus s WITH (NOLOCK)
					JOIN	tbl_products p WITH (NOLOCK) ON p.product_id = s.sku_productid
					WHERE	s.sku_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />
				</cfquery>
				<cfset q = arrCartRows[i].quan />
				<cfif isNumeric(q)>
					<!--- piece together the cart_notes value --->
					<cfset tn = arrCartRows[i].name />
					<cfset tm = arrCartRows[i].num />
					<cfif getSKUInfo.sku_price eq 0>
						<cfset cart_notes = #freeFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&mobile=1" />
					<cfelse>	
						<cfset cart_notes = #frontFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(tn)# & "&tm=" & #URLEncodedFormat(tm)# & "&gf=" & #URLEncodedFormat(gf)# & "&mobile=1" />
					</cfif>
					
					<cfif isBack>  <!--- we have a back design id, so we need to deal with that --->
						<cfset doInsertBack = false />	<!--- not going to insert back without actual data, this way it can skip blank backs --->
						<!--- check to see if there is a back name and/or back number --->
						<cfset backname = tn />
						<cfset backnum = tm />
						<!--- we know we have back info, but we check the design to see which info is required --->
						<cfif ((bdInfo.hasName[1] and Len(backname) gt 0) or (bdInfo.hasNumber[1] and Len(backnum) gt 0) or (!bdInfo.hasName[1] and !bdInfo.hasNumber[1]))>
							<cfset doInsertBack = true />
							<cfset backprint = "1" />
						</cfif>
						<!--- </cfif> --->
						
						<!--- insert the front into the cart --->
						<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
						<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

						<cfset insertedCount = insertedCount + 1 />
						
						<cftransaction>
							<cfquery name="insertFront" datasource="#dsn#">
								INSERT INTO 	tbl_cart (
													cart_custcart_ID, 
													cart_sku_ID, 
													cart_sku_qty, 
													cart_dateadded, 
													cart_notes, 
													sc_id_cart, 
													prod_name, 
													cart_backname, 
													cart_backnum,
													backprint,
													cart_wholesale_price,
													cart_wholesale_hash
												)
								VALUES 			(
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
													<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
													<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(backname,50)#" />, 
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(backnum,3)#" />,
													<cfqueryparam cfsqltype="cf_sql_bit" value="#backprint#" />,
													<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
													<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
												)
							</cfquery>
							
							<cfif doInsertBack>
								<!--- piece together the cart_notes value --->
								<cfset back_cart_notes = #backFlashFile# & "?dId=" & #URLEncodedFormat(dId)# & "&bdId=" & #URLEncodedFormat(bdId)# & "&tt=" & #URLEncodedFormat(tt)# & "&bt=" & #URLEncodedFormat(bt)# & "&yt=" & #URLEncodedFormat(yt)# & "&cp1=" & #URLEncodedFormat(cp1)# & "&cp2=" & #URLEncodedFormat(cp2)# & "&ce1=" & #URLEncodedFormat(ce1)# & "&ce2=" & #URLEncodedFormat(ce2)# & "&sku=" & #URLEncodedFormat(thisSKU)# & "&tn=" & #URLEncodedFormat(backname)# & "&tm=" & #URLEncodedFormat(backnum)# & "&gf=" & #URLEncodedFormat(bgf)# & "&bv=true&mobile=1"/>
								
								<cfset wholesaleBackPrice = 6.95 - ((d*0.01) * 6.95) />
								<cfset wholesaleBackPrice = Round(javacast("float",wholesaleBackPrice * 100)) / 100 />
								
								<cfquery name="insertBack" datasource="#dsn#">
									INSERT INTO 	tbl_cart (
														cart_custcart_ID, 
														cart_sku_ID, 
														cart_sku_qty, 
														cart_dateadded, 
														cart_notes, 
														sc_id_cart, 
														prod_name, 
														cart_backname, 
														cart_backnum,
														backprint,
														cart_wholesale_price,
														cart_wholesale_hash
													)
									VALUES 			(
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="1350" />,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
														<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#back_cart_notes#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="T-Shirt Back Design" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
														<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
														<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
														<cfqueryparam cfsqltype="cf_sql_float" value="#wholesaleBackPrice#" />,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
													)
								</cfquery>
							</cfif>
							
						</cftransaction>
					<cfelse> <!--- not isBack and not a bulk-able design --->
						<cfset wholesalePrice = getSKUInfo.sku_price - ((d*0.01) * getSKUInfo.sku_price) />
						<cfset wholesalePrice = Round(javacast("float",wholesalePrice * 100)) / 100 />

						<cfset insertedCount = insertedCount + 1 />
						
						<cfquery name="insertFront" datasource="#dsn#">
							INSERT INTO 	tbl_cart (
												cart_custcart_ID, 
												cart_sku_ID, 
												cart_sku_qty, 
												cart_dateadded, 
												cart_notes, 
												sc_id_cart, 
												prod_name, 
												cart_backname, 
												cart_backnum,
												backprint,
												cart_wholesale_price,
												cart_wholesale_hash
											)
							VALUES 			(
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#thisSKU#" />,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#q#" />,
												<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#cart_notes#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#getSKUInfo.product_name#" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
												<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
												<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
												<cfqueryparam cfsqltype="cf_sql_float" value="#wholesalePrice#" />,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#wholesaleHash#" />
											)
						</cfquery>
					</cfif> <!--- isBack --->
				</cfif>	<!--- isNumeric(q) --->
			</cfif> <!--- isNumeric(thisSKU) --->
		</cfloop>

		<cfif insertedCount>
			<!--- See if we need to add logo setup fee --->
			<cfset isLogoSetupFeeNeeded	= false />
			<cfif left(gf, 9) eq 'cuploads/'>
				<!--- check the status of the upload, if it's at 1 then add the setup fee --->
				<cfquery name="uploadInfo" datasource="#dsn#">
					SELECT 			logoActive, LogoColorType, isPhoto
					FROM 			cLogoUploads WITH (NOLOCK)
					WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(gf,35)#" cfsqltype="cf_sql_varchar" />
				</cfquery>
				<cfif uploadInfo.recordcount gt 0>
					<cfif uploadInfo.logoActive[1] eq "1" and ( 
							(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
							(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
							(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
						<!--- make sure we don't already have the setup fee for this logo in the cart --->
						<cfquery name="qryAlreadyInCart" datasource="#dsn#">
							SELECT 			*
							FROM 			tbl_cart WITH (NOLOCK)
							WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
								AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
								AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />
						</cfquery>
						<cfif qryAlreadyInCart.recordcount lte 0>
							<cfset isLogoSetupFeeNeeded = true />
						</cfif>
					</cfif>
				</cfif>
			</cfif>
			<!--- Done checking if we need to add logo setup fee --->
			<cfif isLogoSetupFeeNeeded>
				<cfquery name="insertLogoSetupFee" datasource="#dsn#">
					INSERT INTO 	tbl_cart (
										cart_custcart_ID, 
										cart_sku_ID, 
										cart_sku_qty, 
										cart_dateadded, 
										cart_notes, 
										sc_id_cart, 
										prod_name, 
										cart_backname, 
										cart_backnum,
										backprint,
										cart_wholesale_price,
										cart_wholesale_hash
									)
					VALUES 			(
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
										<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
										<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#gf#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
										<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
										<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
										<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
									)
				</cfquery>
			</cfif>
			<cfset isLogoSetupFeeNeeded = false />
			<cfif doInsertBack>
				<cfif left(bgf, 9) eq 'cuploads/'>
					<!--- check the status of the upload, if it's at 1 then add the setup fee --->
					<cfquery name="uploadInfo" datasource="#dsn#">
						SELECT 			logoActive, LogoColorType, isPhoto
						FROM 			cLogoUploads WITH (NOLOCK)
						WHERE 			LEFT(LogoName,35) = <cfqueryparam value="#right(bgf,35)#" cfsqltype="cf_sql_varchar" />
					</cfquery>
					<cfif uploadInfo.recordcount gt 0>
						<cfif uploadInfo.logoActive[1] eq "1" and ( 
								(uploadInfo.LogoColorType[1] eq "1" and addFeeEmbroidery) or
								(uploadInfo.LogoColorType[1] eq "2" and addFeeDigital) or
								(uploadInfo.isPhoto[1] eq "1" and addFeePhoto)) >
							<!--- make sure we don't already have the setup fee for this logo in the cart --->
							<cfquery name="qryAlreadyInCart" datasource="#dsn#">
								SELECT 			*
								FROM 			tbl_cart WITH (NOLOCK)
								WHERE 			cart_custcart_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />
									AND 		cart_sku_id = <cfqueryparam value="#logoSetupFeeSKU#" cfsqltype="cf_sql_integer" />
									AND 		cart_notes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />
							</cfquery>
							<cfif qryAlreadyInCart.recordcount lte 0>
								<cfset isLogoSetupFeeNeeded = true />
							</cfif>
						</cfif>
					</cfif>
				</cfif>
				<!--- Done checking if we need to add logo setup fee --->
				<cfif isLogoSetupFeeNeeded>
					<cfquery name="insertLogoSetupFee" datasource="#dsn#">
						INSERT INTO 	tbl_cart (
											cart_custcart_ID, 
											cart_sku_ID, 
											cart_sku_qty, 
											cart_dateadded, 
											cart_notes, 
											sc_id_cart, 
											prod_name, 
											cart_backname, 
											cart_backnum,
											backprint,
											cart_wholesale_price,
											cart_wholesale_hash
										)
						VALUES 			(
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#client.cartid#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="#logoSetupFeeSKU#" />,
											<cfqueryparam cfsqltype="cf_sql_integer" value="1" />,
											<cfqueryparam cfsqltype="cf_sql_timestamp" value="#CreateODBCDateTime(Now())#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#bgf#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="#scId#" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="Logo Upload Setup Fee" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />, 
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />,
											<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
											<cfqueryparam cfsqltype="cf_sql_float" value="#logoSetupFeePrice#" />,
											<cfqueryparam cfsqltype="cf_sql_varchar" value="" />
										)
					</cfquery>
				</cfif>
			</cfif>
			<!--- done adding setup fee --->
		</cfif>

		<cfset retval.pId = pId />
		<cfset retval.dId = dId />
		<cfset retval.bdId = bdId />
		<cfset retval.tt = tt />
		<cfset retval.bt = bt />
		<cfset retval.yt = yt />
		<cfset retval.gf = gf />
		<cfset retval.cp1 = cp1 />
		<cfset retval.cp2 = cp2 />
		<cfset retval.tq = tq />
		<cfset retval.d = d />
		<cfset retval.bd = bd />
		<cfset retval.scId = scId />
		<cfset retval.arrCartRows = arrCartRows />
		<cfset retVal.CART_TOTAL_ITEMS = 0 />
		<cfset retVal.CART_TOTAL_PRICE = "$0.00" />

		<cfif isdefined("Client.CartID")>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
			<cftry>
				<cfquery name="cartQuanQry" datasource="#dsn#">
					select
						SUM(cart_sku_qty) as cartCount
					from 
						tbl_cart WITH (NOLOCK)
					where 
						prod_name != 'T-Shirt Back Design'
						and cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
				<cfquery name="cartPriceQry" datasource="#dsn#">
					select
						SUM(cart_wholesale_price * cart_sku_qty) as cartPrice
					from
						tbl_cart WITH (NOLOCK)
					where
						cart_custcart_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Client.CartID#" />
				</cfquery>
								                
                <cfif cartQuanQry.recordcount>
					<cfset CartQuantity = Trim(LSNumberFormat(cartQuanQry.cartCount, ",999,999")) />
                    <cfcookie name="cart.CartQuantity" value="#cartQuanQry.cartCount#" expires="30">
				</cfif>
				<cfif cartPriceQry.recordcount>
					<cfset CartPrice = "$" & Trim(LSNumberFormat(cartPriceQry.cartPrice, '999,999.00')) />
                    <cfcookie name="cart.CartPrice" value="#cartPriceQry.cartPrice#" expires="30" />
				</cfif>      
                
				<cfcatch type="any">
					<!--- error handling --->
                  
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset CartQuantity = 0 />
            <cfset CartPrice = "$0.00" />
		</cfif>

		<cfset retVal.CART_TOTAL_ITEMS = CartQuantity />
		<cfset retVal.CART_TOTAL_PRICE = CartPrice />

		<cfreturn retVal />

	</cffunction>

</cfcomponent>