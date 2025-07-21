package com.svo.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;

public class SVOMacCalculator {
    public static String calculateSVOMac(String clientSVOMac) {
        if (clientSVOMac == null || clientSVOMac.isEmpty() || clientSVOMac.length() != 32) {
            return null;
        }

        String combined = clientSVOMac + "sp9ck0348sld00000000000000000000";
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] hashBytes = md.digest(combined.getBytes(StandardCharsets.US_ASCII));
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString().toLowerCase();
        } catch (NoSuchAlgorithmException e) {
            // Log error if needed (e.g., using SLF4J or System.out for now)
            System.err.println("MD5 algorithm not found: " + e.getMessage());
            return null;
        }
    }
}