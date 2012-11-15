<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>

<%--
  - Display the form to refine the simple-search and dispaly the results of the search
  -
  - Attributes to pass in:
  -
  -   scope            - pass in if the scope of the search was a community
  -                      or a collection
  -   scopes 		   - the list of available scopes where limit the search
  -   sortOptions	   - the list of available sort options
  -   availableFilters - the list of filters available to the user
  -
  -   query            - The original query
  -   queryArgs		   - The query configuration parameters (rpp, sort, etc.)
  -   appliedFilters   - The list of applied filters (user input or facet)
  -
  -   search.error     - a flag to say that an error has occurred
  -   qResults		   - the discovery results
  -   items            - the results.  An array of Items, most relevant first
  -   communities      - results, Community[]
  -   collections      - results, Collection[]
  -
  -   admin_button     - If the user is an admin
  --%>

<%@page import="org.dspace.browse.BrowseInfo"%>
<%@page import="org.dspace.browse.BrowseDSpaceObject"%>
<%@page import="org.dspace.discovery.configuration.DiscoverySearchFilterFacet"%>
<%@page import="org.dspace.app.webui.util.UIUtil"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.ArrayList"%>
<%@page import="org.dspace.discovery.DiscoverFacetField"%>
<%@page import="org.dspace.discovery.configuration.DiscoverySearchFilter"%>
<%@page import="org.dspace.discovery.DiscoverFilterQuery"%>
<%@page import="org.dspace.discovery.DiscoverQuery"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="java.util.Map"%>
<%@page import="org.dspace.discovery.DiscoverResult.FacetResult"%>
<%@page import="org.dspace.discovery.DiscoverResult"%>
<%@page import="org.dspace.content.DSpaceObject"%>
<%@page import="java.util.List"%>
<%@page import="it.cilea.hku.authority.model.ACrisObject" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"
    prefix="c" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>
<%@ page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@ page import="java.net.URLEncoder"            %>
<%@ page import="org.dspace.content.Community"   %>
<%@ page import="org.dspace.content.Collection"  %>
<%@ page import="org.dspace.content.Item"        %>
<%@ page import="org.dspace.search.QueryResults" %>
<%@ page import="org.dspace.sort.SortOption" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.Set" %>
<%
    // Get the attributes
    DSpaceObject scope = (DSpaceObject) request.getAttribute("scope" );
    String searchScope = (String) request.getParameter("location" );
    if (searchScope == null)
    {
        searchScope = "";
    }
    List<DSpaceObject> scopes = (List<DSpaceObject>) request.getAttribute("scopes");
    List<String> sortOptions = (List<String>) request.getAttribute("sortOptions");

    String query = (String) request.getAttribute("query");
	if (query == null)
	{
	    query = "";
	}
    Boolean error_b = (Boolean)request.getAttribute("search.error");
    boolean error = (error_b == null ? false : error_b.booleanValue());
    
    DiscoverQuery qArgs = (DiscoverQuery) request.getAttribute("queryArgs");
    String sortedBy = qArgs.getSortField();
    String order = qArgs.getSortOrder().toString();
    String ascSelected = (SortOption.ASCENDING.equalsIgnoreCase(order)   ? "selected=\"selected\"" : "");
    String descSelected = (SortOption.DESCENDING.equalsIgnoreCase(order) ? "selected=\"selected\"" : "");
    String httpFilters ="";
	
    List<DiscoverySearchFilter> availableFilters = (List<DiscoverySearchFilter>) request.getAttribute("availableFilters");
	List<String[]> appliedFilters = (List<String[]>) request.getAttribute("appliedFilters");
	List<String> appliedFilterQueries = (List<String>) request.getAttribute("appliedFilterQueries");
	if (appliedFilters != null && appliedFilters.size() >0 ) 
	{
	    int idx = 1;
	    for (String[] filter : appliedFilters)
	    {
	        httpFilters += "&amp;filter_field_"+idx+"="+URLEncoder.encode(filter[0],"UTF-8");
	        httpFilters += "&amp;filter_type_"+idx+"="+URLEncoder.encode(filter[1],"UTF-8");
	        httpFilters += "&amp;filter_value_"+idx+"="+URLEncoder.encode(filter[2],"UTF-8");
	        idx++;
	    }
	}
    int rpp          = qArgs.getMaxResults();
    int etAl         = ((Integer) request.getAttribute("etal")).intValue();

    String[] options = new String[]{"equals","contains","authority","notequals","notcontains","notauthority"};
    
    // Admin user or not
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());
%>

<c:set var="dspace.layout.head.last" scope="request">
<script type="text/javascript">
	var jQ = jQuery.noConflict();
	jQ(document).ready(function() {
		jQ( "#filterquery" )
			.autocomplete({
				source: function( request, response ) {
					jQ.ajax({
						url: "<%= request.getContextPath() %>/json/discovery/autocomplete?query=<%= URLEncoder.encode(query,"UTF-8")%><%= httpFilters.replaceAll("&amp;","&") %>",
						dataType: "json",
						cache: false,
						data: {
							auto_idx: jQ("#filtername").val(),
							auto_query: request.term,
							auto_sort: 'count',
							auto_type: jQ("#filtertype").val(),
							location: '<%= searchScope %>'	
						},
						success: function( data ) {
							response( jQ.map( data.autocomplete, function( item ) {
								var tmp_val = item.authorityKey;
								if (tmp_val == null || tmp_val == '')
								{
									tmp_val = item.displayedValue;
								}
								return {
									label: item.displayedValue + " (" + item.count + ")",
									value: tmp_val
								};
							}))			
						}
					})
				}
			});
	});
</script>		
</c:set>

<dspace:layout titlekey="jsp.search.title">

    <%-- <h1>Search Results</h1> --%>

<h1><fmt:message key="jsp.search.title"/></h1>

<div class="discovery-search-form">
    <%-- Controls for a repeat search --%>
	<div class="discovery-query">
    <form action="simple-search" method="get">
         <label for="tlocation">
         	<fmt:message key="jsp.search.results.searchin"/>
         </label>
         <select name="location" id="tlocation">
<%
    if (scope == null)
    {
        // Scope of the search was all of DSpace.  The scope control will list
        // "all of DSpace" and the communities.
%>
                                    <%-- <option selected value="/">All of DSpace</option> --%>
                                    <option selected="selected" value="site"><fmt:message key="jsp.general.genericScope"/></option>
<%  }
    else
    {
%>
									<option value="site"><fmt:message key="jsp.general.genericScope"/></option>
<%  }
%>
	<optgroup label="Repository">
		<option value="dspacebasic" <%="dspacebasic".equals(searchScope)?"selected=\"selected\"":"" %>>All the repository</option>
<%
    for (DSpaceObject dso : scopes)
    {
%>
                                <option value="<%= dso.getHandle() %>" <%=dso.getHandle().equals(searchScope)?"selected=\"selected\"":"" %>>
                                	<%= dso.getName() %></option>
<%
    }
%>	</optgroup>
	<optgroup label="CRIS">
								<option value="crisrp" <%="crisrp".equals(searchScope)?"selected=\"selected\"":"" %>>Researcher profiles</option>
								<option value="crisou" <%="crisou".equals(searchScope)?"selected=\"selected\"":"" %>>Organization Units</option>
								<option value="crisproject" <%="crisproject".equals(searchScope)?"selected=\"selected\"":"" %>>Projects</option>
	</optgroup>							
                                </select><br/>
                                <label for="query"><fmt:message key="jsp.search.results.searchfor"/></label>
                                <input type="text" size="50" name="query" value="<%= (query==null ? "" : StringEscapeUtils.escapeHtml(query)) %>"/>
                                <input type="submit" value="<fmt:message key="jsp.general.go"/>" />
                                <input type="hidden" value="<%= rpp %>" name="rpp" />
                                <input type="hidden" value="<%= sortedBy %>" name="sort_by" />
                                <input type="hidden" value="<%= order %>" name="order" />
<% if (appliedFilters.size() > 0 ) { %>                                
		<div class="discovery-search-appliedFilters">
		<span><fmt:message key="jsp.search.filter.applied" /></span>
		<%
			int idx = 1;
			for (String[] filter : appliedFilters)
			{
			    boolean found = false;
			    %>
			    <select id="filter_field_<%=idx %>" name="filter_field_<%=idx %>">
				<%
					for (DiscoverySearchFilter searchFilter : availableFilters)
					{
					    String fkey = "jsp.search.filter."+searchFilter.getIndexFieldName();
					    %><option value="<%= searchFilter.getIndexFieldName() %>"<% 
					            if (filter[0].equals(searchFilter.getIndexFieldName()))
					            {
					                %> selected="selected"<%
					                found = true;
					            }
					            %>><fmt:message key="<%= fkey %>"/></option><%
					}
					if (!found)
					{
					    String fkey = "jsp.search.filter."+filter[0];
					    %><option value="<%= filter[0] %>" selected="selected"><fmt:message key="<%= fkey %>"/></option><%
					}
				%>
				</select>
				<select id="filter_type_<%=idx %>" name="filter_type_<%=idx %>">
				<%
					for (String opt : options)
					{
					    String fkey = "jsp.search.filter.op."+opt;
					    %><option value="<%= opt %>"<%= opt.equals(filter[1])?" selected=\"selected\"":"" %>><fmt:message key="<%= fkey %>"/></option><%
					}
				%>
				</select>
				<input type="text" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>" size="45"/>
				<input type="submit" id="submit_filter_remove_<%=idx %>" name="submit_filter_remove_<%=idx %>" value="X" />
				<br/>
				<%
				idx++;
			}
		%>
		</div>
<% } %>
<a href="<%= request.getContextPath()+"/simple-search" %>"><fmt:message key="jsp.search.general.new-search" /></a>	
		</form>
		</div>
<% if (availableFilters.size() > 0) { %>
		<div class="discovery-search-filters">
		<form action="simple-search" method="get">
		<input type="hidden" value="<%= StringEscapeUtils.escapeHtml(searchScope) %>" name="location" />
		<input type="hidden" value="<%= StringEscapeUtils.escapeHtml(query) %>" name="query" />
		<% if (appliedFilterQueries.size() > 0 ) { 
				int idx = 1;
				for (String[] filter : appliedFilters)
				{
				    boolean found = false;
				    %>
				    <input type="hidden" id="filter_field_<%=idx %>" name="filter_field_<%=idx %>" value="<%= filter[0] %>" />
					<input type="hidden" id="filter_type_<%=idx %>" name="filter_type_<%=idx %>" value="<%= filter[1] %>" />
					<input type="hidden" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>" />
					<%
					idx++;
				}
		} %>
		<span class="discovery-search-filters-heading"><fmt:message key="jsp.search.filter.heading" /></span>
		<span class="discovery-search-filters-hint"><fmt:message key="jsp.search.filter.hint" /></span>
		<select id="filtername" name="filtername">
		<%
			for (DiscoverySearchFilter searchFilter : availableFilters)
			{
			    String fkey = "jsp.search.filter."+searchFilter.getIndexFieldName();
			    %><option value="<%= searchFilter.getIndexFieldName() %>"><fmt:message key="<%= fkey %>"/></option><%
			}
		%>
		</select>
		<select id="filtertype" name="filtertype">
		<%
			for (String opt : options)
			{
			    String fkey = "jsp.search.filter.op."+opt;
			    %><option value="<%= opt %>"><fmt:message key="<%= fkey %>"/></option><%
			}
		%>
		</select>
		<input type="text" id="filterquery" name="filterquery" size="45"/>
        <input type="hidden" value="<%= rpp %>" name="rpp" />
        <input type="hidden" value="<%= sortedBy %>" name="sort_by" />
        <input type="hidden" value="<%= order %>" name="order" />
		<input type="submit" value="<fmt:message key="jsp.search.filter.add"/>" />
		</form>
		</div>        
<% } %>
        <%-- Include a component for modifying sort by, order, results per page, and et-al limit --%>
   <div class="discovery-pagination-controls">
   <form action="simple-search" method="get">
   <input type="hidden" value="<%= StringEscapeUtils.escapeHtml(searchScope) %>" name="location" />
   <input type="hidden" value="<%= StringEscapeUtils.escapeHtml(query) %>" name="query" />
	<% if (appliedFilterQueries.size() > 0 ) { 
				int idx = 1;
				for (String[] filter : appliedFilters)
				{
				    boolean found = false;
				    %>
				    <input type="hidden" id="filter_field_<%=idx %>" name="filter_field_<%=idx %>" value="<%= filter[0] %>" />
					<input type="hidden" id="filter_type_<%=idx %>" name="filter_type_<%=idx %>" value="<%= filter[1] %>" />
					<input type="hidden" id="filter_value_<%=idx %>" name="filter_value_<%=idx %>" value="<%= StringEscapeUtils.escapeHtml(filter[2]) %>" />
					<%
					idx++;
				}
	} %>	
           <label for="rpp"><fmt:message key="search.results.perpage"/></label>
           <select name="rpp">
<%
               for (int i = 5; i <= 100 ; i += 5)
               {
                   String selected = (i == rpp ? "selected=\"selected\"" : "");
%>
                   <option value="<%= i %>" <%= selected %>><%= i %></option>
<%
               }
%>
           </select>
           &nbsp;|&nbsp;
<%
           if (sortOptions.size() > 0)
           {
%>
               <label for="sort_by"><fmt:message key="search.results.sort-by"/></label>
               <select name="sort_by">
                   <option value="score"><fmt:message key="search.sort-by.relevance"/></option>
<%
               for (String sortBy : sortOptions)
               {
                   String selected = (sortBy.equals(sortedBy) ? "selected=\"selected\"" : "");
                   String mKey = "search.sort-by." + sortBy;
                   %> <option value="<%= sortBy %>" <%= selected %>><fmt:message key="<%= mKey %>"/></option><%
               }
%>
               </select>
<%
           }
%>
           <label for="order"><fmt:message key="search.results.order"/></label>
           <select name="order">
               <option value="ASC" <%= ascSelected %>><fmt:message key="search.order.asc" /></option>
               <option value="DESC" <%= descSelected %>><fmt:message key="search.order.desc" /></option>
           </select>
           <label for="etal"><fmt:message key="search.results.etal" /></label>
           <select name="etal">
<%
               String unlimitedSelect = "";
               if (etAl < 1)
               {
                   unlimitedSelect = "selected=\"selected\"";
               }
%>
               <option value="0" <%= unlimitedSelect %>><fmt:message key="browse.full.etal.unlimited"/></option>
<%
               boolean insertedCurrent = false;
               for (int i = 0; i <= 50 ; i += 5)
               {
                   // for the first one, we want 1 author, not 0
                   if (i == 0)
                   {
                       String sel = (i + 1 == etAl ? "selected=\"selected\"" : "");
                       %><option value="1" <%= sel %>>1</option><%
                   }

                   // if the current i is greated than that configured by the user,
                   // insert the one specified in the right place in the list
                   if (i > etAl && !insertedCurrent && etAl > 1)
                   {
                       %><option value="<%= etAl %>" selected="selected"><%= etAl %></option><%
                       insertedCurrent = true;
                   }

                   // determine if the current not-special case is selected
                   String selected = (i == etAl ? "selected=\"selected\"" : "");

                   // do this for all other cases than the first and the current
                   if (i != 0 && i != etAl)
                   {
%>
                       <option value="<%= i %>" <%= selected %>><%= i %></option>
<%
                   }
               }
%>
           </select>
           <input type="submit" name="submit_search" value="<fmt:message key="search.update" />" />

<%
    if (admin_button)
    {
        %><input type="submit" name="submit_export_metadata" value="<fmt:message key="jsp.general.metadataexport.button"/>" /><%
    }
%>
</form>
   </div>
</div>   
<% 

DiscoverResult qResults = (DiscoverResult)request.getAttribute("queryresults");
Item      [] items       = (Item[]      )request.getAttribute("items");
Community [] communities = (Community[] )request.getAttribute("communities");
Collection[] collections = (Collection[])request.getAttribute("collections");
Map<Integer, BrowseDSpaceObject[]> mapOthers = (Map<Integer, BrowseDSpaceObject[]>) request.getAttribute("resultsMapOthers"); 
if( error )
{
 %>
	<p align="center" class="submitFormWarn">
		<fmt:message key="jsp.search.error.discovery" />
	</p>
	<%
}
else if( qResults != null && qResults.getTotalSearchResults() == 0 )
{
 %>
    <%-- <p align="center">Search produced no results.</p> --%>
    <p align="center"><fmt:message key="jsp.search.general.noresults"/></p>
<%
}
else if( qResults != null)
{
    long pageTotal   = ((Long)request.getAttribute("pagetotal"  )).longValue();
    long pageCurrent = ((Long)request.getAttribute("pagecurrent")).longValue();
    long pageLast    = ((Long)request.getAttribute("pagelast"   )).longValue();
    long pageFirst   = ((Long)request.getAttribute("pagefirst"  )).longValue();
    
    // create the URLs accessing the previous and next search result pages
    String baseURL =  request.getContextPath()                    
                    + "/simple-search?query="
                    + URLEncoder.encode(query,"UTF-8")
                    + "&amp;location="+ searchScope
                    + httpFilters
                    + "&amp;sort_by=" + sortedBy
                    + "&amp;order=" + order
                    + "&amp;rpp=" + rpp
                    + "&amp;etal=" + etAl
                    + "&amp;start=";

    String nextURL = baseURL;
    String firstURL = baseURL;
    String lastURL = baseURL;

    String prevURL = baseURL
            + (pageCurrent-2) * qResults.getMaxResults();

    nextURL = nextURL
            + (pageCurrent) * qResults.getMaxResults();
    
    firstURL = firstURL +"0";
    lastURL = lastURL + (pageTotal-1) * qResults.getMaxResults();


%>
<hr/>
<div class="discovery-result-pagination">
<%
	long lastHint = qResults.getStart()+qResults.getMaxResults() <= qResults.getTotalSearchResults()?
	        qResults.getStart()+qResults.getMaxResults():qResults.getTotalSearchResults();
%>
    <%-- <p align="center">Results <//%=qResults.getStart()+1%>-<//%=qResults.getStart()+qResults.getHitHandles().size()%> of --%>
	<h2 class="info"><fmt:message key="jsp.search.results.results">
        <fmt:param><%=qResults.getStart()+1%></fmt:param>
        <fmt:param><%=lastHint%></fmt:param>
        <fmt:param><%=qResults.getTotalSearchResults()%></fmt:param>
        <fmt:param><%=(float) qResults.getSearchTime() / 1000%></fmt:param>
    </fmt:message></h2>
    <ul class="links">
<%
if (pageFirst != pageCurrent)
{
    %><li><a href="<%= prevURL %>"><fmt:message key="jsp.search.general.previous" /></a></li><%
}

if (pageFirst != 1)
{
    %><li><a href="<%= firstURL %>">1</a></li><li>...</li><%
}

for( long q = pageFirst; q <= pageLast; q++ )
{
    String myLink = "<li><a href=\""
                    + baseURL;


    if( q == pageCurrent )
    {
        myLink = "<li class=\"current-page-link\">" + q + "</li>";
    }
    else
    {
        myLink = myLink
            + (q-1) * qResults.getMaxResults()
            + "\">"
            + q
            + "</a></li>";
    }
%>

<%= myLink %>

<%
}

if (pageTotal > pageLast)
{
    %><li>...</li><li><a href="<%= lastURL %>"><%= pageTotal %></a></li><%
}
if (pageTotal > pageCurrent)
{
    %><li><a href="<%= nextURL %>"><fmt:message key="jsp.search.general.next" /></a></li><%
}
%>
</ul>
<!-- give a content to the div -->
</div>
<div class="discovery-result-results">
<%
	Set<Integer> otherTypes = mapOthers.keySet();
	if (otherTypes != null && otherTypes.size() > 0)
	{
	    for (Integer otype : otherTypes)
	    {
	        %>
	        <c:set var="typeName"><%= ((ACrisObject) mapOthers.get(otype)[0].getBrowsableDSpaceObject()).getPublicPath() %></c:set>
	        <%-- <h3>Community Hits:</h3> --%>
	        <h3><fmt:message key="jsp.search.results.cris.${typeName}"/></h3>
	        <dspace:browselist config="cris${typeName}" items="<%= mapOthers.get(otype) %>" />
	    <% 	        
	    }
	}
%>
<% if (communities.length > 0 ) { %>
    <%-- <h3>Community Hits:</h3> --%>
    <h3><fmt:message key="jsp.search.results.comhits"/></h3>
    <dspace:communitylist  communities="<%= communities %>" />
<% } %>

<% if (collections.length > 0 ) { %>
    <%-- <h3>Collection hits:</h3> --%>
    <h3><fmt:message key="jsp.search.results.colhits"/></h3>
    <dspace:collectionlist collections="<%= collections %>" />
<% } %>

<% if (items.length > 0) { %>
    <%-- <h3>Item hits:</h3> --%>
    <h3><fmt:message key="jsp.search.results.itemhits"/></h3>
    <dspace:itemlist items="<%= items %>" authorLimit="<%= etAl %>" />
<% } %>
</div>
<%-- if the result page is enought long... --%>
<% if ((communities.length + collections.length + items.length) > 10) {%>
<%-- show again the navigation info/links --%>
<div class="discovery-result-pagination">
    <%-- <p align="center">Results <//%=qResults.getStart()+1%>-<//%=qResults.getStart()+qResults.getHitHandles().size()%> of --%>
	<p class="info"><fmt:message key="jsp.search.results.results">
        <fmt:param><%=qResults.getStart()+1%></fmt:param>
        <fmt:param><%=lastHint%></fmt:param>
        <fmt:param><%=qResults.getTotalSearchResults()%></fmt:param>
        <fmt:param><%=(float) qResults.getSearchTime() / 1000 %></fmt:param>
    </fmt:message></p>
    <ul class="links">
<%
if (pageFirst != pageCurrent)
{
    %><li><a href="<%= prevURL %>"><fmt:message key="jsp.search.general.previous" /></a></li><%
}

if (pageFirst != 1)
{
    %><li><a href="<%= firstURL %>">1</a></li><li>...</li><%
}

for( long q = pageFirst; q <= pageLast; q++ )
{
    String myLink = "<li><a href=\""
                    + baseURL;


    if( q == pageCurrent )
    {
        myLink = "<li class=\"current-page-link\">" + q + "</li>";
    }
    else
    {
        myLink = myLink
            + (q-1) * qResults.getMaxResults()
            + "\">"
            + q
            + "</a></li>";
    }
%>

<%= myLink %>

<%
}

if (pageTotal > pageLast)
{
    %><li>...</li><li><a href="<%= lastURL %>"><%= pageTotal %></a></li><%
}
if (pageTotal > pageCurrent)
{
    %><li><a href="<%= nextURL %>"><fmt:message key="jsp.search.general.next" /></a></li><%
}
%>
</ul>
<!-- give a content to the div -->
</div>
<% } %>
</div>
<% } %>
<dspace:sidebar>
<%
	boolean brefine = false;
	
	List<DiscoverySearchFilterFacet> facetsConf = (List<DiscoverySearchFilterFacet>) request.getAttribute("facetsConfig");
	Map<String, Boolean> showFacets = new HashMap<String, Boolean>();
		
	for (DiscoverySearchFilterFacet facetConf : facetsConf)
	{
	    String f = facetConf.getIndexFieldName();
	    List<FacetResult> facet = qResults.getFacetResult(f);
	    if (facet.size() == 0)
	    {
	        facet = qResults.getFacetResult(f+".year");
		    if (facet.size() == 0)
		    {
		        showFacets.put(f, false);
		        continue;
		    }
	    }
	    boolean showFacet = false;
	    for (FacetResult fvalue : facet)
	    { 
			if(!appliedFilterQueries.contains(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery()))
		    {
		        showFacet = true;
		        break;
		    }
	    }
	    showFacets.put(f, showFacet);
	    brefine = brefine || showFacet;
	}
	if (brefine) {
%>

<h3 class="facets"><fmt:message key="jsp.search.facet.refine" /></h3>
<div id="facets" class="facetsBox">

<%
	for (DiscoverySearchFilterFacet facetConf : facetsConf)
	{
	    String f = facetConf.getIndexFieldName();
	    if (!showFacets.get(f))
	        continue;
	    List<FacetResult> facet = qResults.getFacetResult(f);
	    if (facet.size() == 0)
	    {
	        facet = qResults.getFacetResult(f+".year");
	    }
	    int limit = facetConf.getFacetLimit()+1;
	    
	    String fkey = "jsp.search.facet.refine."+f;
	    %><div id="facet_<%= f %>" class="facet">
	    <span class="facetName"><fmt:message key="<%= fkey %>" /></span>
	    <ul><%
	    int idx = 1;
	    int currFp = UIUtil.getIntParameter(request, f+"_page");
	    if (currFp < 0)
	    {
	        currFp = 0;
	    }
	    if (currFp > 0)
	    {
	        %><li class="facet-previous"><a href="<%= request.getContextPath()	                
	                + "/simple-search?query="
	                + URLEncoder.encode(query,"UTF-8")
	                + "&amp;location=" + searchScope
	                + "&amp;sort_by=" + sortedBy
	                + "&amp;order=" + order
	                + "&amp;rpp=" + rpp
	                + httpFilters
	                + "&amp;etal=" + etAl  
	                + "&amp;"+f+"_page="+(currFp-1) %>"><fmt:message key="jsp.search.facet.refine.previous" /></a></li>
            <%
	    }
	    for (FacetResult fvalue : facet)
	    { 
	        if (idx == limit)
	        {
	            %><li class="facet-next"><a href="<%= request.getContextPath()	            
                + "/simple-search?query="
                + URLEncoder.encode(query,"UTF-8")
                + "&amp;location=" + searchScope
                + "&amp;sort_by=" + sortedBy
                + "&amp;order=" + order
                + "&amp;rpp=" + rpp
                + httpFilters
                + "&amp;etal=" + etAl  
                + "&amp;"+f+"_page="+(currFp+1) %>"><fmt:message key="jsp.search.facet.refine.next" /></a></li>
	            <%
	            idx++;
	        }
	        else if(!appliedFilterQueries.contains(f+"::"+fvalue.getFilterType()+"::"+fvalue.getAsFilterQuery()))
	        {
	        %><li><a href="<%= request.getContextPath()
                + "/simple-search?query="
                + URLEncoder.encode(query,"UTF-8")
                + "&amp;location=" + searchScope
                + "&amp;sort_by=" + sortedBy
                + "&amp;order=" + order
                + "&amp;rpp=" + rpp
                + httpFilters
                + "&amp;etal=" + etAl
                + "&amp;filtername="+URLEncoder.encode(f,"UTF-8")
                + "&amp;filterquery="+URLEncoder.encode(fvalue.getAsFilterQuery(),"UTF-8")
                + "&amp;filtertype="+URLEncoder.encode(fvalue.getFilterType(),"UTF-8") %>"
                title="<fmt:message key="jsp.search.facet.narrow"><fmt:param><%=fvalue.getDisplayedValue() %></fmt:param></fmt:message>">
                <%= StringUtils.abbreviate(fvalue.getDisplayedValue(),32) + " (" + fvalue.getCount()+")" %></a></li><%
                idx++;
	        }
	        if (idx > limit)
	        {
	            break;
	        }
	    }
	    %></ul></div><%
	}

%>

</div>
<% } %>
</dspace:sidebar>
</dspace:layout>
