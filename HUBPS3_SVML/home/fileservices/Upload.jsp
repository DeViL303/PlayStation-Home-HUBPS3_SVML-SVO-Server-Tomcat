<%@ page contentType="text/xml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="java.io.*" %>
<%@ page import="org.apache.commons.lang3.StringEscapeUtils" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    Logger logger = Logger.getLogger("Upload.jsp");
    SimpleDateFormat dateFormat = new SimpleDateFormat("MM-dd-yyyy HH:mm:ss");
    String timestamp = dateFormat.format(new Date());

    String clientIp = request.getRemoteAddr();
    int clientPort = request.getRemotePort();
    String requestPath = request.getRequestURI() + (request.getQueryString() != null ? "?" + request.getQueryString() : "");
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Requested a file : %s", timestamp, clientIp, clientPort, requestPath));

    // Check HTTP method
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
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
    String toUpload = request.getParameter("fileNameBeginsWith");
    if (toUpload == null || toUpload.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Missing fileNameBeginsWith -> 400", timestamp, clientIp, clientPort));
        response.setStatus(400); // Bad Request
        return;
    }

    // Read the input stream
    InputStream inputStream = request.getInputStream();
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    byte[] buffer = new byte[4096];
    int bytesRead;
    while ((bytesRead = inputStream.read(buffer)) != -1) {
        baos.write(buffer, 0, bytesRead);
    }
    byte[] fileData = baos.toByteArray();

    // Database connection details
    String dbUrl = "jdbc:mysql://localhost:3306/svo_db?useSSL=false&serverTimezone=UTC";
    String dbUser = "root";
    String dbPass = ""; // Default blank in XAMPP

    // Insert or update the file data in DB
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        String sql = "REPLACE INTO uploaded_files (filename, data) VALUES (?, ?)";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, toUpload);
        stmt.setBytes(2, fileData);
        stmt.executeUpdate();
        stmt.close();
        conn.close();
        logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Uploaded file %s to DB", timestamp, clientIp, clientPort, toUpload));
    } catch (Exception e) {
        logger.log(Level.SEVERE, String.format("[%s] error: [0] [HTTP] - %s:%d DB upload failed for %s: %s", timestamp, clientIp, clientPort, toUpload, e.getMessage()));
        response.setStatus(500); // Internal Server Error
        return;
    }

    // Escape filename for XML
    String encodedFilename = StringEscapeUtils.escapeXml10(toUpload);

    // Generate XML response
    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"utf-8\" ?>\r\n");
    xml.append("<XML>\r\n\r\n");
    xml.append("<XMLSVOFILETRANSFER direction=\"upload\" filename=\"").append(encodedFilename).append("\"/>\r\n");
    xml.append("</XML>");

    // Log response
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d -> 200", timestamp, clientIp, clientPort));
    logger.log(Level.INFO, String.format("[%s] info: [0] [Webserver http://*:10060/] %s:%d POST http://173.225.107.46:10060/HUBPS3_SVML/fileservices/UploadFileServlet?fileNameBeginsWith=%s: 200 [time ms]", timestamp, clientIp, clientPort, toUpload));

    // Output the XML
    out.print(xml.toString());
%>