package org.keplerproject.luajava;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class NativeLibraryLoader {
    static {
        init();
    }

    public static void init() {
        /* it is needed to print exception messages before throwing them, because jrunscript (a standard JSR223 tool)
	 * doesn't display low level exception messages, making troubleshooting difficult
	 */

        String defaultLibName = "luajava-" + ManifestUtil.getAttributeValue("LuaJava-EngineVersion");
        String debugProperty = System.getProperty(defaultLibName + ".debug");
        final boolean debug = convertToBoolean(debugProperty);

        String libName = System.getProperty(defaultLibName + ".library.name", defaultLibName);
        String defaultLibPath = getDefaultLibraryPath(libName);
	    //String javaLibraryPath = System.getProperty("java.library.path");
        String libPath = System.getProperty(defaultLibName + ".library.path", defaultLibPath); // e.g. "/path/to/libxxxx.so"
        
        if (debug) {
            System.err.println("[DEBUG] debug: " + debugProperty);
            System.err.println("[DEBUG] " + defaultLibName + ".library.path: " + libPath);
            System.err.println("[DEBUG] " + defaultLibName + ".library.name: " + libName);
        }

        try {
            Path tempFile = createTempFile(libPath, libName);
            if (debug) {
                System.err.println("[DEBUG] tempFile: " + tempFile.toAbsolutePath().toString());
	        }

            System.load(tempFile.toAbsolutePath().toString()); // System.loadLibrary(libName) would look for libName in java.library.path

            // Clean up
            deleteTempFile(tempFile);

        } catch (Exception e) {
            System.err.println("Failed to load native library " + libPath + ": " + e);
            throw new RuntimeException("Failed to load native library " + libPath + ": " + e);
        }
    }

    private static String getDefaultLibraryPath(String libName) {
        String os = System.getProperty("os.name").toLowerCase();
        //String arch = System.getProperty("os.arch").toLowerCase();
        String libPath = "/native/";
        if (os.contains("win")) {
            libPath += "windows/" + libName + ".dll";
        } else if (os.contains("nix") || os.contains("nux") || os.contains("mac")) {
            libPath += os.contains("mac") ? "macos/lib" + libName + ".dylib" : "linux/lib" + libName + ".so";
        } else {
            System.err.println("Unsupported OS: " + os);
            throw new UnsupportedOperationException("Unsupported OS: " + os);
        }

        return libPath;
    }

    private static InputStream getInputStream(String libPath) {
        String currentDirectory = System.getProperty("user.dir");
        InputStream in = NativeLibraryLoader.class.getResourceAsStream(libPath);
        if (in == null) {
            System.err.println("Native library not found: " + libPath);
            throw new RuntimeException("Native library not found: " + libPath + " (current directory: " + currentDirectory + ")");
        }
        return in;
    }

    private static Path createTempFile(String libPath, String libName) throws IOException, FileNotFoundException {
        Path tempFile = Files.createTempFile(libName, getExtension(libPath));
        try (InputStream in = getInputStream(libPath);
             OutputStream out = new FileOutputStream(tempFile.toFile())) {
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
        return tempFile;
    }

    private static void deleteTempFile(Path tempFile) {
        tempFile.toFile().deleteOnExit();
    }

    private static String getExtension(String path) {
        int lastDot = path.lastIndexOf('.');
        return (lastDot == -1) ? "" : path.substring(lastDot);
    }

    private static boolean convertToBoolean(final String property, boolean defaultValue) {
        if (property == null) return defaultValue;

        String lowerCase = property.toLowerCase();
        
        if ("true".equals(lowerCase)) {
            return true;
        }
        else if ("yes".equals(lowerCase)) {
            return true;
        }
        else if ("y".equals(lowerCase)) {
            return true;
        }
        else if ("1".equals(lowerCase)) {
            return true;
        }
        else { 
            return false;
        }
    }

    private static boolean convertToBoolean(final String property) {
        return convertToBoolean(property, false);
    }
}
