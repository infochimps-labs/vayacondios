package com.infochimps.vayacondios;

class PathBuilder {
  public PathBuilder() {}

  public PathBuilder(PathBuilder delegate) {
    _delegate = delegate;
  }

  protected PathBuilder getDelegate() { return _delegate; }

  private PathBuilder _delegate;
}