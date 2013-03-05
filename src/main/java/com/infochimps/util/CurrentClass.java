package com.infochimps.util;

public class CurrentClass extends SecurityManager {
  private static CurrentClass SINGLETON = new CurrentClass();

  // must call this directly
  public static Class get() {
    return SINGLETON.getCurrentClass();
  }

  private Class getCurrentClass() {
    return getClassContext()[2];
  }
}