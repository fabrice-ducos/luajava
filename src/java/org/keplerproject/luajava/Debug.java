/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.keplerproject.luajava;

import java.util.Locale;

/**
 *
 * @author Fabrice Ducos
 */
final class Debug {
    static final boolean DEBUG = false;
    
    private static String prefix(int i) {
        Thread th = Thread.currentThread();
        StackTraceElement ste = th.getStackTrace()[i];
        
        String file = ste.getFileName();
        int line = ste.getLineNumber();
        String methodName = ste.getMethodName();
        return file + ":" + methodName + ":" + line + ": ";
    }

    public static String prefix() {
        return prefix(3);
    }
    
    public static void log(final String message) {
        System.err.print(prefix(3));
        System.err.println(message);
    }
    
    public static void log(Exception ex) {
        System.err.print(prefix(3));
        System.err.println(ex.getMessage());
    }
    
    public static void log(Object obj) {
        System.err.print(prefix(3));
        System.err.println(obj.toString());
    }
    
    public static void log(String formatString, Object... arguments) {
        System.err.print(prefix(3));
        System.err.println(String.format(formatString, arguments));
    }
    
    public static void log(Locale locale, String formatString, Object... arguments) {
        System.err.print(prefix(3));
        System.err.println(String.format(locale, formatString, arguments));
    }
}
