package com.infochimps.vayacondios;

import static com.infochimps.util.CurrentClass.getLogger;

import com.infochimps.util.CurrentClass;
import com.infochimps.util.HttpHelper;

import java.io.IOException;
import java.io.BufferedReader;
import java.nio.charset.Charset;
import java.util.HashMap;

import org.slf4j.Logger;

/**
 * VayacondiosClient is the root of the Vayacondios hierarchy. It
 * communicates with a Vayacondios server via its HTTP API. Currently
 * only Vayacondios itemsets are supported.
 */
public class VayacondiosClient extends PathBuilder {
  public VayacondiosClient(PathBuilder delegate) { super(delegate); }

  public VayacondiosClient(String serverName, int port) {
    _serverName = serverName;
    _port       = port;
  }

  //----------------------------------------------------------------------------
  // next in path hierarchy
  //----------------------------------------------------------------------------

  /**
   * @param organization Vayacondios organization. see Vayacondios
   *                     documentation for details.
   * @return new Organization path builder for this server with the
   *         specified orgnanization name
   *
   */
  public Organization organization(String organization) {
    return new Organization(this, organization);
  }

  //----------------------------------------------------------------------------
  // API HTTP path components
  //----------------------------------------------------------------------------

  protected String urlString(String organization,
                             String type,
                             String topic,
                             String id) {
    return new StringBuilder().
      append("http://").
      append(getServerName()).
      append(":").
      append(getPort()).
      append("/v1/").
      append(organization).
      append("/").
      append(type).
      append("/").
      append(topic).
      append("/").
      append(id)
      .toString();
  }

  protected int    getPort()       { return _port;       }
  protected String getServerName() { return _serverName; }

  //----------------------------------------------------------------------------
  // fields
  //----------------------------------------------------------------------------

  private String _serverName;
  private int    _port;

  private static final Logger LOG = getLogger();
}