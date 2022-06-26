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
import java.io.Closeable;

import java.util.List;

/**
 * LuaJavaScriptEngine is required for compliance with the JSR223
 * (script engine discovery mechanism in Java 6+)
 *
 * @author Fabrice Ducos
 */
public class LuaJavaScriptEngine extends AbstractScriptEngine implements Closeable
{   
    public LuaJavaScriptEngine(ScriptEngineFactory factory) {
	this.factory = factory;
        
        luaState = LuaStateFactory.newLuaState();
        luaState.openLibs();
	//localBindings = new SimpleBindings();
    }
    
    public void close() {
        luaState.close();
    }

    public void stackDump() {
	int top = luaState.getTop();

	System.out.println("Lua stack size: " + top);
	
	for (int i = top ; i >= 1 ; i--) {
	    int t = luaState.type(i);

	    if (t == LuaState.LUA_TSTRING) {
		System.out.println("  <" + i + "> " + luaState.toString(i));
	    }
	    else if (t == LuaState.LUA_TBOOLEAN) {
		System.out.println("  <" + i + "> " + luaState.toBoolean(i));
	    }
	    else if (t == LuaState.LUA_TNUMBER) {
		System.out.println("  <" + i + "> " + luaState.toNumber(i));
	    }
	    else {
		System.out.println("  <" + i + "> " + luaState.typeName(t));
	    }
	}
    }

    private boolean isDefaultBinding(String key) {
	return "javax.script.argv".equals(key)
	    || "javax.script.filename".equals(key)
	    || "engine".equals(key)
	    || "arguments".equals(key);
    }
    
    private String convertJavaToLua(Object javaValue) {
	// incomplete implementation for quick testing (only strings are implemented)
	
	if (javaValue == null) return "nil";
	return "\"" + javaValue.toString() + "\"";
    }
    
    private String getInitializationSnippet(int scope) {
	StringBuilder sb = new StringBuilder();
	Bindings bindings = getBindings(scope);
	for (String key: bindings.keySet()) {
	    if (isDefaultBinding(key)) continue; // skip default bindings
	    Object javaValue = bindings.get(key);
	    String luaValue = convertJavaToLua(javaValue);
	    sb.append("local " + key + " = " + luaValue + "\n");
	}
	return sb.toString();
    }
    
    @Override
    public Object eval(String script, ScriptContext context) throws ScriptException {
	final boolean debug = false;
	String globalInitializationSnippet = getInitializationSnippet(ScriptContext.GLOBAL_SCOPE);
	String engineInitializationSnippet = getInitializationSnippet(ScriptContext.ENGINE_SCOPE);
	script = globalInitializationSnippet + "\n" + engineInitializationSnippet + "\n" + script;
        int ret = luaState.LloadString(script);

	if (debug) { Debug.log("script:\n" + script); }
	
	if (ret != 0) {
	    String errorMessage = luaState.toString(-1);
	    luaState.pop(1); // pop error message from the stack
	    throw new ScriptException(Debug.prefix() + ": " + errorMessage);
	}
	
	synchronized(luaState) {
	    if (debug) { Debug.log(""); stackDump(); }
	    ret = luaState.pcall(0, 1, 0); // asks for one result
	    if (debug) { Debug.log(""); stackDump(); }
	    if (ret != 0) {
		if (debug) { Debug.log(""); stackDump(); }
		String errorMessage = luaState.toString(-1);
		luaState.pop(1); // pop error message from the stack
		if (debug) { Debug.log(""); stackDump(); }
		throw new ScriptException(Debug.prefix() + ": " + errorMessage);
	    }
        }
	
	int type = luaState.type(-1);

	if (debug) {
	    Debug.log(""); stackDump();
	    Debug.log("type of expression: " + luaState.typeName(type));
	}
	
	Object result;
	try {
	    result = luaState.toJavaObject(-1);
	    luaState.pop(1);
	}
	catch (LuaException ex) {
	    throw new ScriptException(ex);
	}

	return result;
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

    // normally provided by AbstractScriptEngine
    /*
    @Override
    public void setBindings(Bindings bindings, int scope) {
	if (scope == ScriptContext.ENGINE_SCOPE) {
	    this.localBindings = bindings;
	}
	else if (scope == ScriptContext.GLOBAL_SCOPE) {
	    throw new RunTimeException("GLOBAL_SCOPE not implemented yet in LuaJava's setBindings");
	    //this.globalBindings = bindings;
	}
	else {
	    throw new IllegalArgumentException("invalid value for scope: " + scope);
	}
    }

    @Override
    public void put(String key, Object value) {
	getBindings(ScriptContext.ENGINE_SCOPE).put(key, value);
    }

    @Override
    public Object get(String key) {
	return getBindings(ScriptContext.ENGINE_SCOPE).get(key);
    }
    */

    @Override
    public ScriptEngineFactory getFactory() {
	return factory;
    }

    private ScriptEngineFactory factory;
    private final LuaState luaState;
    //private final Bindings localBindings;
}
