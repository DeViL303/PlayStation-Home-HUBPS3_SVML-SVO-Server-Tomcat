# PlayStation Home HUBPS3_SVML SVO Server (Tomcat WebApp)

<img width="960" height="915" alt="image" src="https://github.com/user-attachments/assets/2558f2b8-dc1f-48be-a4b7-4e5c6e963b6b" />

Recreated SVO server as a Tomcat java based webapp, Something like it probably was originally. 

This is very basic, proof of concept only. This is enough to get older version of PS Home like 1.32.3 HDK into online mode when used with Horizon from Multiserver for muis/mas/dme etc. 

Credits go mostly to the developers of the original SVO server in Horizon and to the developers of Multiserver - This is based on their work. 

Usage: 
- I use this with XAMPPs built in Tomcat
- Put the HUBPS3_SVML folder into C:\xampp\tomcat\webapps\
- Change server.xml config from port 8080 to port 10060
- Requires JDK or JRE installed. Recommended v8.x (eg. jdk-8u202-windows-x64.exe) Newer versions might have issues.
- Start Tomcat from XAMPP control panel. 

NOTE: Proof of concept only - Would need a lot more work to be used for more than testing. 
