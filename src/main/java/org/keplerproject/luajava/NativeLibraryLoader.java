import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class NativeLibraryLoader {
    static {
	String libname = "luajava";
        try {
            // Determine the appropriate native library path
            String os = System.getProperty("os.name").toLowerCase();
            String arch = System.getProperty("os.arch").toLowerCase();
            String libPath = "native/";

            if (os.contains("win")) {
                libPath += "windows/" + libname + ".dll";
            } else if (os.contains("nix") || os.contains("nux") || os.contains("mac")) {
                libPath += os.contains("mac") ? "macos/lib" + libname + ".dylib" : "linux/lib" + libname + ".so";
            } else {
                throw new UnsupportedOperationException("Unsupported OS: " + os);
            }

            // Load the library
	    System.out.println("libPath: " + libPath);
            InputStream in = NativeLibraryLoader.class.getResourceAsStream("/" + libPath);
            if (in == null) {
                throw new RuntimeException("Native library not found: " + libPath);
            }

            Path tempFile = Files.createTempFile(libname, getExtension(libPath));
            try (OutputStream out = new FileOutputStream(tempFile.toFile())) {
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
            }

            System.load(tempFile.toAbsolutePath().toString());

            // Clean up
            tempFile.toFile().deleteOnExit();

        } catch (Exception e) {
            throw new RuntimeException("Failed to load native library", e);
        }
    }

    private static String getExtension(String path) {
        int lastDot = path.lastIndexOf('.');
        return (lastDot == -1) ? "" : path.substring(lastDot);
    }
}
