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

    // Generate SVML response with lobby data (from log)
    String xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n" +
                 "<SVML>\r\n\r\n" +
                 "    <HUB type=\"AutoChangeMode\" textColor=\"#FF7381BA\" highlightTextColor=\"#FF7381BA\" x=\"20\" y=\"200\" width=\"200\" height=\"40\"\r\n" +
                 "      align=\"center\" border=\"true\" href=\"EnterLobby\" extra=\"Central Lobby\" skipOn=\"6\"></HUB>\r\n\r\n" +
                 "       <REDIRECT name=\"toBlankPage\" href=\"homeInWorld.jsp\" linkOption=\"NORMAL\"/>\r\n\r\n" +
                 "</SVML>";

    // Output the XML
    out.print(xml);
%>