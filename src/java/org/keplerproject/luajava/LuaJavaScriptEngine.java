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

import javax.script.AbstractScriptEngine;
import javax.script.Bindings;
import javax.script.ScriptContext;
import javax.script.ScriptEngineFactory;
import javax.script.ScriptException;
import javax.script.SimpleBindings;

import java.io.BufferedReader;
import java.io.Reader;
import java.io.IOException;

/**
 * LuaJavaScriptEngine is required for compliance with the JSR223
 * (script engine discovery mechanism in Java 6+)
 *
 * @author Fabrice Ducos
 */
public class LuaJavaScriptEngine extends AbstractScriptEngine
{
    
    public LuaJavaScriptEngine(ScriptEngineFactory factory) {
	this.factory = factory;
    }

    @Override
    public Object eval(String script, ScriptContext context) throws ScriptException {
	throw new UnsupportedOperationException("eval(String, ScriptContext) is not yet implemented");
    }

    @Override
    public Object eval(Reader reader, ScriptContext context) throws ScriptException {
	BufferedReader br = new BufferedReader(reader);

	StringBuilder sb = new StringBuilder();
	String line = null;
	try {
	    while ((line = br.readLine()) != null) {
		sb.append(line);
	    }
	}
	catch (IOException ex) {
	    throw new ScriptException(ex);
	}

	return eval(sb.toString(), context);
    }

    @Override
    public Bindings createBindings() {
	return new SimpleBindings();
    }

    @Override
    public ScriptEngineFactory getFactory() {
	return factory;
    }

    private ScriptEngineFactory factory;
}
