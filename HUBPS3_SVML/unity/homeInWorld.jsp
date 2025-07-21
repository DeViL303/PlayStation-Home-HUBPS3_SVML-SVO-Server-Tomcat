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

    // Generate the empty SVML XML response
    String xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \r\n" +
                 "<SVML>\r\n\r\n</SVML>";

    // Output the XML
    out.print(xml);
%>