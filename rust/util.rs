use core::error::Error;
use mlua::{Lua, Value};
use mlua::prelude::*;
use unicode_segmentation::UnicodeSegmentation;

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

// 传入一个 lua table
fn parse_table(lua: &Lua, table: LuaTable) -> LuaResult<LuaTable> {
    let ret_str : String = String::from("abc");
    table.set("xxx", ret_str);
    Ok(table)
}

// 返回一个键值对的 Table
fn return_kv_table(lua: &Lua, _: ()) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set("aaa",1)?;
    table.set("bbb","new_string")?;
    Ok(table)
}

fn lua_table_to_usize_slice(lua: &Lua, table: LuaTable) -> Result<Vec<usize>, LuaError> {
    // 创建一个 Vec 来存储 usize 值
    let mut vec = Vec::new();

    // 遍历 Lua 表中的所有键值对
    for pair in table.pairs::<mlua::Integer, mlua::Integer>() {
        let (key, value) = pair?;
        if key >= 1 && value >= 0 {
            // 将 Lua Integer 转换为 usize 并添加到 Vec 中
            vec.push(value as usize);
        }
    }

    Ok(vec)
}

// util.replacement()
fn replacement(lua: &Lua, (abbr, positions, wrap_char) : (mlua::String, LuaTable, char)) -> LuaResult<String> {
    let t_abbr: String = abbr.to_string_lossy();
    let result_positions: Result<Vec<usize>, LuaError> = lua_table_to_usize_slice(lua, positions);
    let mut t_positions: Vec<usize> = result_positions.unwrap();
    let ret_str: String = _replacement(&t_abbr, &t_positions, wrap_char);
    Ok(ret_str)
}

fn _replacement(abbr: &str, positions: &[usize], wrap_char: char) -> String {
    // 将字符串按 Unicode 字符（grapheme clusters）拆分为 Vec<String>
    let chars: Vec<&str> = abbr
        .graphemes(true)
        .collect();

    // 检查 positions 是否越界
    if chars.is_empty() {
        return abbr.to_string();
    }

    let mut result_chars: Vec<String> = chars.iter().map(|&s| s.to_string()).collect();

    // 对每个指定的位置进行包裹
    for &idx in positions {
        if idx < result_chars.len() {
            result_chars[idx] = format!("{}{}{}", wrap_char, result_chars[idx], wrap_char);
        }
    }

    // 合并成一个字符串
    let mut result = result_chars.concat();

    // 移除连续的 wrap_char（如 **）
    let double_wrap = format!("{}{}", wrap_char, wrap_char);
    result = result.replace(&double_wrap, "");

    result
}

#[mlua::lua_module]
fn easycomplete_rust_util(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    
    exports.set("hello", lua.create_function(hello)?)?;
    exports.set("return_table", lua.create_function(return_table)?)?;
    exports.set("return_kv_table", lua.create_function(return_kv_table)?)?;
    exports.set("parse_table", lua.create_function(parse_table)?)?;
    exports.set("replacement", lua.create_function(replacement)?)?;
    
    Ok(exports)
}


