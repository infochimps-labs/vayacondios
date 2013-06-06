package com.infochimps.util;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.zip.GZIPInputStream;

import org.apache.commons.codec.binary.Base64;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static java.util.Map.Entry;

public class HttpHelper {
  private static final Base64 BASE64 = new Base64();
  private static final boolean USE_CHARLES = false;

  // opens or returns a null reader
  public static BufferedReader openOrNull(Logger log,
                                          String urlString,
                                          Charset inputCharset) {
    return openOrNull(log, urlString, inputCharset, 0);
  }

  // opens or returns a null reader
  public static BufferedReader openOrNull(Logger log,
                                          String urlString,
                                          Charset inputCharset,
                                          int timeout) {
    try { return open(log, urlString, inputCharset, timeout); }
    catch (IOException e) {
      log.warn("Got an exception trying to open {}: {}", urlString, e);
      return null;
    }
  }

  //----------------------------------------------------------------------------

  public static BufferedReader open(Logger log,
                                    String urlString,
                                    Charset inputCharset) throws IOException {
    return open(log, urlString, inputCharset, 0);
  }

  public static BufferedReader open(Logger log,
                                    String urlString,
                                    HashMap<String,String> extraHeaders,
                                    Charset inputCharset) throws IOException {
    return open(log, urlString, extraHeaders, inputCharset, 0);
  }
  
  public static BufferedReader open(Logger log,
                                    String urlString,
                                    Charset inputCharset,
                                    int timeout) throws IOException {
    HttpURLConnection con = getConnection(urlString, log, timeout);
    return getReader(con, log, inputCharset);
  }

  public static BufferedReader open(Logger log,
                                    String urlString,
                                    HashMap<String,String> extraHeaders,
                                    Charset inputCharset,
                                    int timeout) throws IOException {

    HttpURLConnection con = getConnection(urlString, log, timeout);
    for (Entry<String,String> header : extraHeaders.entrySet())
      con.setRequestProperty(header.getKey(), header.getValue());
    return getReader(con, log, inputCharset);
  }

  //----------------------------------------------------------------------------

  public static InputStream openStream(Logger log,
                                       String urlString) throws IOException {
    return openStream(log, urlString, 0);
  }

  public static InputStream openStream(Logger log,
                                       String urlString,
                                       HashMap<String,String> extraHeaders)
    throws IOException {
    return openStream(log, urlString, extraHeaders, 0);
  }
  
  public static InputStream openStream(Logger log,
                                       String urlString,
                                       int timeout) throws IOException {
    HttpURLConnection con = getConnection(urlString, log, timeout);
    return getStream(con, log);
  }

  public static InputStream openStream(Logger log,
                                       String urlString,
                                       HashMap<String,String> extraHeaders,
                                       int timeout) throws IOException {

    HttpURLConnection con = getConnection(urlString, log, timeout);
    for (Entry<String,String> header : extraHeaders.entrySet())
      con.setRequestProperty(header.getKey(), header.getValue());
    return getStream(con, log);
  }

  //----------------------------------------------------------------------------

  private static HttpURLConnection getConnection(String urlString,
                                                 Logger log,
                                                 int timeout)
    throws IOException {
    URL url = null;
    try { url = new URL(urlString); }
    catch (MalformedURLException e) {
      log.warn("malformed URL: {}", url);
      throw new IOException(e);
    }

    HttpURLConnection con = (HttpURLConnection)(USE_CHARLES ?
                                                url.openConnection(DebugUtil.useCharles()) :
                                                url.openConnection());

    String userInfo = url.getUserInfo();
    if (userInfo != null) {
      userInfo = URLDecoder.decode(userInfo, "US-ASCII");
      con.setRequestProperty("Authorization", "Basic " + new String(BASE64.encodeBase64(userInfo.getBytes())));
    }
    con.setRequestProperty("Accept-Encoding", "gzip,deflate");
    if (timeout != 0) con.setReadTimeout(timeout);
    return con;
  }

  private static BufferedReader getReader(HttpURLConnection con,
                                          Logger log,
                                          Charset inputCharset) throws IOException {
    BufferedReader reader =
      new BufferedReader(
        new InputStreamReader(getStream(con, log), inputCharset));

    log.info("successfully opened connection to {} with character encoding {}",
             con.getURL().toString(),
             inputCharset);

    return reader;
  }

  private static InputStream getStream(HttpURLConnection con,
                                       Logger log) throws IOException {
    InputStream in;
    try { in = con.getInputStream(); }
    catch (IOException e) {
      // Some HTTP responses will raise an exception, but the
      // useful information is in the error stream.

      log.warn("Exception opening {}", con.getURL().toString());

      InputStream errorStream = con.getErrorStream();
      if (errorStream != null) {
        BufferedReader r = new BufferedReader(new InputStreamReader(errorStream));
        try { for (String line; (line = r.readLine()) != null; log.error(line)); }
        catch (IOException nested_exc) {
          log.error("Got an exception in the exception handler: {}", nested_exc);
          throw e;
        }
      }
      throw e;
    }

    String encoding = con.getContentEncoding();
    log.debug("Got HTTP stream with content encoding type '" + encoding + "'");

    return (encoding != null && encoding.equals("gzip")) ?
      new GZIPInputStream(in) : in;
  }
}
