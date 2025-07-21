package com.svo.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class AccountDAO {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/svo_db"; // Replace 'svo_db' with your database name
    private static final String USER = "root"; // Default XAMPP MySQL username
    private static final String PASS = ""; // Default XAMPP MySQL password (empty)

    public static int getAccountByName(String acctName, int appId) {
        try (Connection conn = DriverManager.getConnection(DB_URL, USER, PASS);
             PreparedStatement ps = conn.prepareStatement("SELECT AccountId FROM accounts WHERE AccountName = ? AND AppId = ?")) {
            ps.setString(1, acctName);
            ps.setInt(2, appId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt("AccountId");
            }
        } catch (SQLException e) {
            // Log error (use System.err for simplicity; replace with logger if set up)
            System.err.println("SQL error in getAccountByName: " + e.getMessage());
        }
        return -1; // Not found
    }
}