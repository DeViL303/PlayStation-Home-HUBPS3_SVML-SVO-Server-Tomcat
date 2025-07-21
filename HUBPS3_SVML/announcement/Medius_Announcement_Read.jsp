<%@ page contentType="text/svml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%
    // Check HTTP method
    if (!"GET".equalsIgnoreCase(request.getMethod())) {
        response.setStatus(405); // Method Not Allowed
        return;
    }

    // Get client MAC from header
    String clientMac = request.getHeader("X-SVOMac");
    String serverMac = SVOMacCalculator.calculateSVOMac(clientMac);
    if (serverMac == null || serverMac.isEmpty()) {
        response.setStatus(403); // Forbidden
        return;
    }
    response.setHeader("X-SVOMac", serverMac);

    // Get region from query parameters (default to en-US if not provided)
    String region = request.getParameter("region");
    if (region == null || region.isEmpty()) {
        region = "en-US";
    }

    // Generate the SVML XML response (simulate no announcements, redirect to next step)
    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n");
    xml.append("<SVML>\r\n");
    xml.append("    <SET name=\"nohistory\" neverBackOnto=\"true\"/>\r\n");
    xml.append("    <ANNOUNCEMENT name=\"announcement\" mode=\"save\" />\r\n");
    xml.append("    <REDIRECT href=\"../unity/home.jsp?region=").append(region).append("\" name=\"redirect\"/>\r\n"); // Redirect to a home JSP or next endpoint
    xml.append("</SVML>");

    // Output the XML
    out.print(xml.toString());
%>