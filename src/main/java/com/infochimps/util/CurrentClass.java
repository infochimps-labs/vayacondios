package com.infochimps.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CurrentClass extends SecurityManager {
  private static CurrentClass SINGLETON = new CurrentClass();

  // must call this directly. behavior is dependent on call stack
  public static Class get() {
    return SINGLETON.getCurrentClass();
  }

  // must call this directly. behavior is dependent on call stack
  public static Logger getLogger() {
    return LoggerFactory.getLogger(SINGLETON.getCurrentClass(2));
  }

  private Class getCurrentClass(int i) {
    return getClassContext()[i];
  }

  private Class getCurrentClass() {
    return getCurrentClass(3);
  }
}