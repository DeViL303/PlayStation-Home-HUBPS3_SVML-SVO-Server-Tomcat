<%@ page contentType="application/octet-stream" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.UUID" %>
<%
    Logger logger = Logger.getLogger("DownloadFileServlet.jsp");
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
    String filename = request.getParameter("fileNameBeginsWith");
    if (filename == null || filename.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Missing fileNameBeginsWith -> 400", timestamp, clientIp, clientPort));
        response.setStatus(400); // Bad Request
        return;
    }

    // Database connection details
    String dbUrl = "jdbc:mysql://localhost:3306/svo_db?useSSL=false&serverTimezone=UTC";
    String dbUser = "root";
    String dbPass = ""; // Default blank in XAMPP

    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Connecting to DB at %s with user %s for filename %s", timestamp, clientIp, clientPort, dbUrl, dbUser, filename));

    // Fetch file data from DB
    byte[] fileData = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        String sql = "SELECT data FROM uploaded_files WHERE filename = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, filename);
        ResultSet rs = stmt.executeQuery();
        if (rs.next()) {
            Blob blob = rs.getBlob("data");
            fileData = blob.getBytes(1, (int) blob.length());
            logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Fetched %d bytes from DB for %s", timestamp, clientIp, clientPort, fileData.length, filename));
        } else {
            logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d No data found in DB for %s", timestamp, clientIp, clientPort, filename));
        }
        rs.close();
        stmt.close();
        conn.close();
    } catch (Exception e) {
        logger.log(Level.SEVERE, String.format("[%s] error: [0] [HTTP] - %s:%d DB fetch failed for %s: %s", timestamp, clientIp, clientPort, filename, e.getMessage()));
        // Continue to fallback
    }

    if (fileData == null || fileData.length == 0) {
        // Fallback to default content
        if (filename.endsWith(".xml") && filename.startsWith("Inventory-")) {
            String defaultInventoryContent = "<inventory><object uuid=\"00000000-00000000-00000000-0000000F\"></object><object uuid=\"00000000-00000000-00000000-00040031\"></object><object uuid=\"00000000-00000000-00000000-00050031\"></object><object uuid=\"00000000-00000000-00000001-0000000C\"></object><object uuid=\"00000000-00000000-00000001-0000003A\"></object><object uuid=\"00000000-00000000-00000001-0000003F\"></object><object uuid=\"00000000-00000000-00000002-00000006\"></object><object uuid=\"05BF361F-178449C7-97D8E87D-1A583712\"></object><object uuid=\"1F03C805-CC164AFD-B9C5E663-B36D9F14\"></object><object uuid=\"2519FAC0-18AA4FCB-A1214F6B-65F5F001\"></object><object uuid=\"41C13270-23EF4EF0-96ED63C3-4354E4FA\"></object><object uuid=\"689EC8A7-0C314606-AA97922F-7610E03A\"></object><object uuid=\"9C27D8C9-D9494CBA-A172198B-040EB0CD\"></object><object uuid=\"A277CFA3-DDBC4FB0-BFCC40B2-E1D8A83D\"></object><object uuid=\"C3BEC489-C8CA450D-B2764EF3-E87D5FE2\"></object><object uuid=\"CDDD4894-4CE0469C-9B0EF69B-DF98B710\"></object><object uuid=\"E1C19A1E-DD23477E-A808D807-6EBFB56C\"></object><object uuid=\"FB2E623F-AD5248D3-85806D83-51CB2ECB\"></object><object uuid=\"00000000-00000000-00000000-01050034\"></object><object uuid=\"A828590A-B604470E-967736DC-534E8CB8\"></object><object uuid=\"09CD4E59-D97B4A1F-AE1B0E29-112F3EB3\"></object><object uuid=\"112EF0DF-3BD04D45-B6251ABC-BF5A48D3\"></object><object uuid=\"7C9ED226-16A34DDD-BA305579-200CC3BC\"></object><object uuid=\"00000000-00000000-00000000-00030042\"></object><object uuid=\"6E5C8CDF-2FCB4880-B0BE7923-80085B36\"></object><object uuid=\"00000000-00000000-00000001-00000015\"></object><object uuid=\"00000000-00000000-00000001-0000002B\"></object><object uuid=\"00000000-00000000-00000002-00000015\"></object><object uuid=\"00000000-00000000-00000001-0000001E\"></object><object uuid=\"00000000-00000000-00000001-0000000F\"></object><object uuid=\"B2D008DE-B3AE4C6F-B849871F-C1D6CB6B\"></object></inventory>";
            fileData = defaultInventoryContent.getBytes(StandardCharsets.UTF_8);
            logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Using default inventory content for %s", timestamp, clientIp, clientPort, filename));
        } else if (filename.contains("Profile-")) {
            String defaultProfileContent = "<profile></profile>";
            fileData = defaultProfileContent.getBytes(StandardCharsets.UTF_8);
            logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Using default profile content for %s", timestamp, clientIp, clientPort, filename));
        } else if (filename.endsWith(".jpg")) {
            // Load default.jpg
            fileData = null;
            String defaultAvatarPath = application.getRealPath("default.jpg");
            if (defaultAvatarPath != null) {
                try (FileInputStream fis = new FileInputStream(defaultAvatarPath);
                     ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[1024];
                    int len;
                    while ((len = fis.read(buffer)) > -1) {
                        baos.write(buffer, 0, len);
                    }
                    fileData = baos.toByteArray();
                    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Using default.jpg (%d bytes) for %s", timestamp, clientIp, clientPort, fileData.length, filename));
                } catch (IOException e) {
                    logger.log(Level.SEVERE, String.format("[%s] error: [0] [HTTP] - %s:%d Failed to load default.jpg for fallback: %s", timestamp, clientIp, clientPort, e.getMessage()));
                }
            }
            if (fileData == null) {
                fileData = new byte[0];
                logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Using empty data for %s", timestamp, clientIp, clientPort, filename));
            }
        } else {
            fileData = new byte[0];
            logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Unknown file type, using empty data for %s", timestamp, clientIp, clientPort, filename));
        }
    }

    // Set headers based on file type
    if (filename.endsWith(".jpg")) {
        response.setContentType("image/jpeg");
    } else if (filename.endsWith(".xml") || filename.contains("Profile")) {
        response.setContentType("text/xml;charset=UTF-8");
    } else {
        response.setContentType("application/octet-stream");
    }

    response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
    response.setHeader("Accept-Ranges", "bytes");
    response.setHeader("Cache-Control", "private");
    response.setHeader("ETag", UUID.randomUUID().toString().substring(0, 4) + "-" + UUID.randomUUID().toString().substring(0, 12));
    response.setContentLength(fileData.length);

    // Stream the file data
    OutputStream os = response.getOutputStream();
    os.write(fileData);
    os.flush();

    // Log response
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d -> 200", timestamp, clientIp, clientPort));
    logger.log(Level.INFO, String.format("[%s] info: [0] [Webserver http://*:10060/] %s:%d GET http://173.225.107.46:10060/HUBPS3_SVML/fileservices/DownloadFileServlet?fileNameBeginsWith=%s: 200 [time ms]", timestamp, clientIp, clientPort, filename));
%>