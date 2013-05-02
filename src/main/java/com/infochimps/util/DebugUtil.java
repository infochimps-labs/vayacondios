package com.infochimps.util;

import java.net.InetSocketAddress;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import java.security.cert.X509Certificate;
import java.security.SecureRandom;
import java.security.GeneralSecurityException;

import java.net.Proxy;

public class DebugUtil {
    public static Proxy useCharles() {
        trustAllCerts();
        return new Proxy(Proxy.Type.HTTP, new InetSocketAddress("127.0.0.1", 8888));
    }

    public static void trustAllCerts() {
        try {
            SSLContext sc = SSLContext.getInstance("SSL"); 
            sc.init(null,
                    new TrustManager[] { 
                        new X509TrustManager() {     
                            public X509Certificate[] getAcceptedIssuers() { return null;} 
                            public void checkClientTrusted(X509Certificate[] certs, String authType) {} 
                            public void checkServerTrusted(X509Certificate[] certs, String authType) {}
                        } 
                    }, new SecureRandom()); 
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        } catch (GeneralSecurityException e) {}
    }
}
