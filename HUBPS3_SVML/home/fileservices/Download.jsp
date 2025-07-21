<%@ page contentType="text/xml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="org.apache.commons.lang3.StringEscapeUtils" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    Logger logger = Logger.getLogger("Download.jsp");
    SimpleDateFormat dateFormat = new SimpleDateFormat("MM-dd-yyyy HH:mm:ss");
    String timestamp = dateFormat.format(new Date());

    String clientIp = request.getRemoteAddr();
    int clientPort = request.getRemotePort();
    String requestPath = request.getRequestURI() + (request.getQueryString() != null ? "?" + request.getQueryString() : "");
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Requested a file : %s", timestamp, clientIp, clientPort, requestPath));

    // Check HTTP method
    if (!"GET".equalsIgnoreCase(request.getMethod())) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid method: %s -> 405", timestamp, clientIp, clientPort, request.getMethod()));
        response.setStatus(405); // Method Not Allowed
        return;
    }

    // Get client MAC from header
    String clientMac = request.getHeader("X-SVOMac");
    String serverMac = SVOMacCalculator.calculateSVOMac(clientMac);
    if (serverMac == null || serverMac.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid X-SVOMac -> 403", timestamp, clientIp, clientPort));
        response.setStatus(403); // Forbidden
        return;
    }
    response.setHeader("X-SVOMac", serverMac);

    // Get filename from query parameters
    String filename = request.getParameter("filename");
    if (filename == null || filename.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Missing filename -> 400", timestamp, clientIp, clientPort));
        response.setStatus(400); // Bad Request
        return;
    }

    // Database connection details
    String dbUrl = "jdbc:mysql://localhost:3306/svo_db?useSSL=false&serverTimezone=UTC";
    String dbUser = "root";
    String dbPass = ""; // Default blank in XAMPP

    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Connecting to DB at %s with user %s", timestamp, clientIp, clientPort, dbUrl, dbUser));

    // Check if file exists in DB
    boolean fileExists = false;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        String sql = "SELECT COUNT(*) FROM uploaded_files WHERE filename = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, filename);
        ResultSet rs = stmt.executeQuery();
        if (rs.next() && rs.getInt(1) > 0) {
            fileExists = true;
        }
        rs.close();
        stmt.close();
        conn.close();
        logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d DB check for %s: %s", timestamp, clientIp, clientPort, filename, fileExists ? "Exists" : "Does not exist"));
    } catch (Exception e) {
        logger.log(Level.SEVERE, String.format("[%s] error: [0] [HTTP] - %s:%d DB check failed for %s: %s", timestamp, clientIp, clientPort, filename, e.getMessage()));
        response.setStatus(500); // Internal Server Error
        return;
    }

    String encodedFilename = StringEscapeUtils.escapeXml10(filename);

    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n");
    xml.append("<XML>\r\n");

    if (fileExists) {
        String fileId = "1"; 
        String encodedFileName = URLEncoder.encode(filename, "UTF-8");
        String src = "http://173.225.107.46:10060/HUBPS3_SVML/fileservices/DownloadFileServlet.jsp?fileID=" + fileId + "&fileNameBeginsWith=" + encodedFileName;
        String escapedSrc = StringEscapeUtils.escapeXml10(src);
        xml.append("    <XMLSVOFILETRANSFER direction=\"download\" filename=\"").append(encodedFilename).append("\" errorCode=\"None\" src=\"").append(escapedSrc).append("\"/>\r\n");
    } else {
        xml.append("    <XMLSVOFILETRANSFER direction=\"download\" filename=\"").append(encodedFilename).append("\" errorCode=\"FileDoesNotExist\" src=\"\"/>\r\n");
    }

    xml.append("</XML>");

    // Log response
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d -> %d", timestamp, clientIp, clientPort, fileExists ? 200 : 200)); // Always 200, but errorCode in XML
    logger.log(Level.INFO, String.format("[%s] info: [0] [Webserver http://*:10060/] %s:%d GET http://173.225.107.46:10060/HUBPS3_SVML/home/fileservices/Download.jsp?filename=%s: 200 [time ms]", timestamp, clientIp, clientPort, filename));

    // Output the XML
    out.print(xml.toString());
%>