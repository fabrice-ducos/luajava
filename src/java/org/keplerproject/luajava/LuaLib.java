/*
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package org.keplerproject.luajava;

import java.util.jar.Attributes;
import java.util.jar.Manifest;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;

/**
 * LuaLib is a utility class that retrieves the version of the
 * library from the Manifest file.
 * 
 * @author Fabrice Ducos
 */
public class LuaLib
{
    static {
	try {
	    LUAJAVA_LIB = getManifestAttributeValue("Manifest-Version");
	}
	catch (IOException ex) {
	    System.err.println(ex.getMessage());
	    LUAJAVA_LIB = "unknown";
	}
    }
    
    private LuaLib() {}

    private static String LUAJAVA_LIB;

    public static String getLuaJavaVersion() {
	return LUAJAVA_LIB;
    }
    
    private static String getManifestAttributeValue(String attributeName) throws MalformedURLException, IOException {
	// credit: https://stackoverflow.com/questions/1272648/reading-my-own-jars-manifest
	String value = "unknown";
	
	Class clazz = LuaLib.class;
	String className = clazz.getSimpleName() + ".class";
	String classPath = clazz.getResource(className).toString();
	if (!classPath.startsWith("jar")) {
	    // Class not from JAR
	    return value;
	}
	String manifestPath = classPath.substring(0, classPath.lastIndexOf("!") + 1) + 
	    "/META-INF/MANIFEST.MF";
	
	try (InputStream stream = new URL(manifestPath).openStream()) {
	    Manifest manifest = new Manifest(stream);
	    Attributes attr = manifest.getMainAttributes();
	    value = attr.getValue(attributeName);
	}
	return value;
    }
}
