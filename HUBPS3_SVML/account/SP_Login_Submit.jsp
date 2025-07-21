<%@ page contentType="text/xml; charset=UTF-8" %>
<%@ page import="com.svo.util.SVOMacCalculator" %>
<%@ page import="java.io.*, java.util.regex.Pattern, java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="javax.servlet.http.Cookie" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    Logger logger = Logger.getLogger("SP_Login_Submit.jsp");
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
        out.print("<xml><error>Method Not Allowed. Only POST supported.</error></xml>");
        return;
    }

    // Get client MAC from header
    String clientMac = request.getHeader("X-SVOMac");
    String serverMac = SVOMacCalculator.calculateSVOMac(clientMac);
    if (serverMac == null || serverMac.isEmpty()) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid X-SVOMac -> 403", timestamp, clientIp, clientPort));
        response.setStatus(403); // Forbidden
        out.print("<xml><error>Invalid or missing X-SVOMac header.</error></xml>");
        return;
    }
    response.setHeader("X-SVOMac", serverMac);

    // Parse applicationID from query, default to 0 if missing or invalid
    int appId = 0; // Default value
    String appIdStr = request.getParameter("applicationID");
    try {
        if (appIdStr != null) {
            appId = Integer.parseInt(appIdStr);
        }
    } catch (NumberFormatException e) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid applicationID: %s, using default 0", timestamp, clientIp, clientPort, appIdStr));
    }

    // Read the POST body as binary bytes
    byte[] bytes = null;
    try {
        InputStream is = request.getInputStream();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int len;
        while ((len = is.read(buffer)) > -1) {
            baos.write(buffer, 0, len);
        }
        baos.flush();
        bytes = baos.toByteArray();
        logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Received %d bytes in POST body", timestamp, clientIp, clientPort, bytes.length));
    } catch (IOException e) {
        logger.log(Level.SEVERE, String.format("[%s] error: [0] [HTTP] - %s:%d Failed to read request body: %s", timestamp, clientIp, clientPort, e.getMessage()));
        response.setStatus(500); // Internal Server Error
        out.print("<xml><error>Failed to read request body.</error></xml>");
        return;
    }

    if (bytes == null || bytes.length < 82 + 32) { // Ensure at least 82 + 32 bytes for fixed extraction
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Insufficient request body (expected at least 114 bytes, got %d) -> 403", timestamp, clientIp, clientPort, bytes != null ? bytes.length : 0));
        response.setStatus(403); // Forbidden
        out.print("<xml><error>No or insufficient request body provided (expected at least 114 bytes).</error></xml>");
        return;
    }

    // Extract with fixed length of 32
    String acctName;
    try {
        acctName = new String(bytes, 82, 32, StandardCharsets.UTF_8).trim(); // Fixed 32 chars, trim spaces
        logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Raw acctName (fixed 32 chars): %s", timestamp, clientIp, clientPort, acctName));
    } catch (IndexOutOfBoundsException e) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid body format: Unable to extract account name -> 400", timestamp, clientIp, clientPort));
        response.setStatus(400); // Bad Request
        out.print("<xml><error>Invalid body format: Unable to extract account name.</error></xml>");
        return;
    }

    String acctNameREX = acctName.replaceAll("[^a-zA-Z0-9]", ""); // Clean non-alphanumeric
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Cleaned acctNameREX: %s", timestamp, clientIp, clientPort, acctNameREX));

    // Proceed with logging and DB query using acctNameREX...
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d Logging user %s into SVO...", timestamp, clientIp, clientPort, acctNameREX));

    // Database connection details (adjust if needed)
    String dbUrl = "jdbc:mysql://localhost:3306/svo_db?useSSL=false&serverTimezone=UTC";
    String dbUser = "root";
    String dbPass = ""; // Default blank in XAMPP

    // Query DB for accountId
    int accountId = 0; // Default if DB query fails
    String langId = "1"; // Default as in log
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        String sql = "SELECT AccountId FROM accounts WHERE AccountName = ? AND AppId = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, acctNameREX);
        stmt.setInt(2, appId);
        ResultSet rs = stmt.executeQuery();
        if (rs.next()) {
            accountId = rs.getInt("AccountId");
        }
        rs.close();
        stmt.close();
        conn.close();
        logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d DB query found accountId: %d for %s", timestamp, clientIp, clientPort, accountId, acctNameREX));
    } catch (Exception e) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d DB query failed for %s: %s, using default accountId 0", timestamp, clientIp, clientPort, acctNameREX, e.getMessage()));
    }

    // Parse sig from query
    String sig = request.getParameter("sig");
    if (sig == null) sig = "";

    // Language ID from query (default to 1 as in log)
    try {
        langId = request.getParameter("languageID"); // From query in log
        if (langId == null) {
            langId = "1";
        }
    } catch (Exception e) {
        logger.log(Level.WARNING, String.format("[%s] warn: [0] [HTTP] - %s:%d Invalid languageID, using default 1", timestamp, clientIp, clientPort));
        langId = "1";
    }

    // Set cookies
    Cookie langIdCookie = new Cookie("LangID", langId);
    langIdCookie.setPath("/");
    response.addCookie(langIdCookie);

    Cookie acctIdCookie = new Cookie("AcctID", String.valueOf(accountId));
    acctIdCookie.setPath("/");
    response.addCookie(acctIdCookie);

    Cookie npCountryCookie = new Cookie("NPCountry", "us");
    npCountryCookie.setPath("/");
    response.addCookie(npCountryCookie);

    Cookie clanIdCookie = new Cookie("ClanID", "-1");
    clanIdCookie.setPath("/");
    response.addCookie(clanIdCookie);

    Cookie authKeyTimeCookie = new Cookie("AuthKeyTime", "03-31-202316:03:41"); // Removed spaces
    authKeyTimeCookie.setPath("/");
    response.addCookie(authKeyTimeCookie);

    Cookie npLangCookie = new Cookie("NPLang", "1");
    npLangCookie.setPath("/");
    response.addCookie(npLangCookie);

    Cookie moderateModeCookie = new Cookie("ModerateMode", "false");
    moderateModeCookie.setPath("/");
    response.addCookie(moderateModeCookie);

    Cookie timeZoneCookie = new Cookie("TimeZone", "PST");
    timeZoneCookie.setPath("/");
    response.addCookie(timeZoneCookie);

    Cookie clanIdDuplicateCookie = new Cookie("ClanID", "-1");
    clanIdDuplicateCookie.setPath("/");
    response.addCookie(clanIdDuplicateCookie);

    Cookie npContentRatingCookie = new Cookie("NPContentRating", "201326592");
    npContentRatingCookie.setPath("/");
    response.addCookie(npContentRatingCookie);

    Cookie authKeyCookie = new Cookie("AuthKey", "nRqnf97f~UaSANLErurJIzq9GXGWqWCADdA3TfqUIVXXisJyMnHsQ34kA&C^0R#&~JULZ7xUOY*rXW85slhQF&P&Eq$7kSB&VBtf`V8rb^BC`53jGCgIT");
    authKeyCookie.setPath("/");
    response.addCookie(authKeyCookie);

    Cookie acctNameCookie = new Cookie("AcctName", acctNameREX);
    acctNameCookie.setPath("/");
    response.addCookie(acctNameCookie);

    Cookie ownerIdCookie = new Cookie("OwnerID", "-255");
    ownerIdCookie.setPath("/");
    response.addCookie(ownerIdCookie);

    Cookie sigCookie = new Cookie("Sig", sig + "==");
    sigCookie.setPath("/");
    response.addCookie(sigCookie);

    // Generate XML response
    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n");
    xml.append("<XML action=\"http://">\r\n");
    xml.append("    <SP_Login>\r\n");
    xml.append("        <status>\r\n");
    xml.append("            <id>20600</id>\r\n");
    xml.append("            <message>ACCT_LOGIN_SUCCESS</message>\r\n");
    xml.append("        </status>\r\n");
    xml.append("       <accountID>").append(accountId).append("</accountID>\r\n");
    xml.append("        <userContext>0</userContext>\r\n");
    xml.append("    </SP_Login>\r\n");
    xml.append("</XML>");

    // Log response
    logger.log(Level.INFO, String.format("[%s] info: [0] [HTTP] - %s:%d -> 200", timestamp, clientIp, clientPort));
    logger.log(Level.INFO, String.format("[%s] info: [0] [Webserver http://*:10060/] %s:%d POST http://173.225.107.46:10060/HUBPS3_SVML/account/SP_Login_Submit.jsp?applicationID=%d: 200 [time ms]", timestamp, clientIp, clientPort, appId));

    // Output the XML
    out.print(xml.toString());
%>