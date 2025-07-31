
use mlua::{Lua};
use mlua::prelude::*;

#[derive(Debug, Clone)]
pub struct LspItem {
    pub label: String,
    pub kind: u32,
    pub word: String
}

#[unsafe(no_mangle)]
pub extern "C" fn add_old(a: i32, b: i32) -> i32 {
    a + b
}

// 输出一个简单的字符串
fn hello(_: &Lua, (a,b) : (String, String)) -> LuaResult<String> {
    Ok(a.to_string() + &b.to_string())
}

// 返回一个数组形式的 Table
fn return_table(lua: &Lua, _: ()) -> LuaResult<LuaTable> {
    let label: &str = "label";
    let word: &str = "word";
    let table = lua.create_table()?;
    let data = vec![10, 20, 30];
    for (i, value) in data.iter().enumerate() {
        table.set(i + 1, *value)?; // Lua 索引从 1 开始
    }
    Ok(table)
}

// 返回一个键值对的 Table
fn return_kv_table(lua: &Lua, _: ()) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set("aaa",1)?;
    table.set("bbb","new_string")?;
    Ok(table)
}


#[mlua::lua_module]
fn easycomplete_rust_util(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    
    exports.set("hello", lua.create_function(hello)?)?;
    exports.set("return_table", lua.create_function(return_table)?)?;
    exports.set("return_kv_table", lua.create_function(return_kv_table)?)?;
    
    Ok(exports)
}


