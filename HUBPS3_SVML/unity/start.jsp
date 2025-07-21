<%@ page contentType="text/svml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    Logger logger = Logger.getLogger("start.jsp");
    SimpleDateFormat dateFormat = new SimpleDateFormat("MM-dd-yyyy HH:mm:ss");
    String timestamp = dateFormat.format(new Date());

    String clientIp = request.getRemoteAddr();
    int clientPort = request.getRemotePort();
    String requestPath = request.getRequestURI() + (request.getQueryString() != null ? "?" + request.getQueryString() : "");
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Requested a file : %s", timestamp, clientIp, clientPort, requestPath));

    // Check HTTP method
    if (!"GET".equalsIgnoreCase(request.getMethod())) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid method: %s -> 405", timestamp, clientIp, clientPort, request.getMethod()));
        response.setContentType("text/html; charset=UTF-8");
        response.setStatus(405); // Method Not Allowed
        out.print("<html><body><h1>Error 405: Method Not Allowed</h1><p>Only GET requests are supported for this endpoint.</p></body></html>");
        return;
    }

    // Get client MAC from header
    String clientMac = request.getHeader("X-SVOMac");
    if (clientMac == null || clientMac.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Missing or invalid X-SVOMac header -> 403", timestamp, clientIp, clientPort));
        response.setContentType("text/html; charset=UTF-8");
        response.setStatus(403); // Forbidden
        out.print("<html><body><h1>Error 403: Forbidden</h1><p>Missing or invalid X-SVOMac header. This endpoint requires a valid 32-character X-SVOMac header (e.g., e0cf1794babc4e2c06aca7eb237ebda5).</p></body></html>");
        return;
    }

    String serverMac = SVOMacCalculator.calculateSVOMac(clientMac);
    if (serverMac == null || serverMac.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid X-SVOMac header provided. Provided: %s -> 403", timestamp, clientIp, clientPort, clientMac));
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
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Region set to: %s", timestamp, clientIp, clientPort, region));

    
    boolean svoHttpsBypass = true; // Replace with actual config if needed

    // Generate the SVML XML response
    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n");
    xml.append("<SVML>\r\n");
    xml.append("    <BROWSER_INIT name=\"init\" />\r\n\t");
    xml.append("    \r\n    <SET name=\"nohistory\" neverBackOnto=\"true\"/>\r\n");
    xml.append("    \r\n    <DATA dataType=\"URI\" name=\"SvfsUpload\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/fileservices/UploadFileServlet\"/>\r\n");
    xml.append("    \r\n    <DATA dataType=\"URI\" name=\"SvfsDownload\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/fileservices/Download.jsp\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"SvfsDeleteSubmit\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/fileservices/Delete.jsp\"/>\r\n    \r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpArcadeMachines\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=arcade\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpBowling\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=bowling\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpCharacterCreation\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=characterCustomisation\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpChess\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=chess\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpConversations\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=conversations\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpDoors\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=relocation\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpDraughts\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=draughts\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpEmotes\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=emotes\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpFirstTimeUser\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=firstTimeUsing\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpGameLaunchingCreate\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=gamelaunchingCreate\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpGameLaunchingJoin\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=gamelaunchingJoin\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpGamesRoom\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=gamespace\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpHomeApartment\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=homespace\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpPool\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=pool\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpSafetyInHome\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=stayingsafe\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"HelpSeats\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=seats\"/>\r\n\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityNews\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=news\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityLatestUpdate\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=latestUpdate\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityHandyLinks\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=handyLinks\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityMotd\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=messageoftheday\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityUsagePolicy\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=eula\"/>\r\n\r\n    ");
    xml.append("    <DATA dataType=\"URI\" name=\"GriefReportStart\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/griefreporting/GriefReportWelcome.jsp?region=").append(region).append("\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"ViralProvisioningStart\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/viralprovisioning/HomeInviteWelcome.jsp\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"UserActivityLogUploadServlet\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/tracking/StatTrackingServlet\"/>\r\n    \r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityNewsSummary\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=news\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityNewsDetailed\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=latestUpdate\"/>\r\n");
    xml.append("    <DATA dataType=\"URI\" name=\"CommunityBetaTrialRoadmap\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/home/help/HelpGeneric.jsp?region=").append(region).append("&pageName=handyLinks\"/>\r\n    \r\n");
    xml.append("    <DATA dataType=\"DATA\" name=\"gameFinishURL\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/game/Game_Finish_Submit.jsp\" />\r\n\t\r\n");
    xml.append("    <DATA dataType=\"DATA\" name=\"TicketLoginURI\" value=\"http://homeps3.svo.online.scee.com:10060/HUBPS3_SVML/account/SP_Login_Submit.jsp\" />\r\n\t\r\n\t");
    xml.append("     \r\n    \r\n\t<REDIRECT href=\"eulaCheck.jsp?region=").append(region).append("\" name=\"redirect\"/>\r\n");
    xml.append("      \r\n");
    xml.append("</SVML>");

    // Output the XML
    out.print(xml.toString());

    if (!svoHttpsBypass) {
        // Similar StringBuilder for the else branch XML, replacing http with https where appropriate
        // For brevity, omitted here; add if needed based on config
    }
%>