<%@ page contentType="text/svml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.io.*" %>
<%
    // Check HTTP method
    if (!"GET".equalsIgnoreCase(request.getMethod())) {
        response.setContentType("text/html; charset=UTF-8");
        response.setStatus(405); // Method Not Allowed
        out.print("<html><body><h1>Error 405: Method Not Allowed</h1><p>Only GET requests are supported for this endpoint.</p></body></html>");
        return;
    }

    // Get client MAC from header
    String clientMac = request.getHeader("X-SVOMac");
    if (clientMac == null || clientMac.isEmpty()) {
        response.setContentType("text/html; charset=UTF-8");
        response.setStatus(403); // Forbidden
        out.print("<html><body><h1>Error 403: Forbidden</h1><p>Missing or invalid X-SVOMac header. This endpoint requires a valid 32-character X-SVOMac header (e.g., e0cf1794babc4e2c06aca7eb237ebda5).</p></body></html>");
        return;
    }

    String serverMac = SVOMacCalculator.calculateSVOMac(clientMac);
    if (serverMac == null || serverMac.isEmpty()) {
        response.setContentType("text/html; charset=UTF-8");
        response.setStatus(403); // Forbidden
        out.print("<html><body><h1>Error 403: Forbidden</h1><p>Invalid X-SVOMac header provided. Ensure it's a valid 32-character MAC value. Provided: " + clientMac + "</p></body></html>");
        return;
    }
    response.setHeader("X-SVOMac", serverMac);

    // Get region from query parameters (default to en-US if not provided)
    String region = request.getParameter("region");
    if (region == null || region.isEmpty()) {
        region = "en-US";
    }

    // Generate the SVML XML response based on the log (eulaCheck.jsp response)
    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n");
    xml.append("<SVML>\r\n");
    xml.append("    <EULA name=\"eula\" mode=\"save\" />\r\n");
    xml.append("    <UNITY name=\"login\" type=\"command\" success_href=\"../announcement/Medius_Announcement_Read.jsp?region=").append(region).append("\" success_linkoption=\"NORMAL\" />\r\n");
    xml.append("    <HOMEACTION name=\"FrontEndAction\">\r\n");
    xml.append("        <OnEnterPage event=\"FrontEndEvent\" param1=\"SigningIntoSvo\" param2=\"\" />\r\n");
    xml.append("    </HOMEACTION>\r\n");
    xml.append("    <SET name=\"nohistory\" neverBackOnto=\"true\" />\r\n");
    xml.append("</SVML>");

    // Output the XML
    out.print(xml.toString());
%>