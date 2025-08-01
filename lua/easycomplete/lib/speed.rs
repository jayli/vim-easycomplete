use mlua::{Lua, Value};
use mlua::prelude::*;
use unicode_segmentation::UnicodeSegmentation;
use std::convert::TryInto;

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

// 读取 lua 中的全局变量
fn get_global_vars(lua: &Lua, _: ()) -> LuaResult<i32> {
    let globals = lua.globals();
    lua.globals().set("my_global_var", "Hello from Lua!")?;
    let my_global_var: i32 = globals.get("easycomplete_pum_maxlength")?;
    Ok(my_global_var)
}

// 先更新全局变量，然后读取全局变量
fn get_first_complete_hit(lua: &Lua, _:()) -> LuaResult<i32> {
    let globals = lua.globals();
    let init_global_vars: mlua::Function = globals.get("init_global_vars_for_rust")?;
    init_global_vars.call("x")?;
    let ret: i32 = globals.get("easycomplete_first_complete_hit")?;
    Ok(ret)
}


// 模拟 Lua 版本的 `util.parse_abbr`
// 
// 参数:
// - `abbr`: 要处理的字符串
// - `max_length`: 最大显示长度 (对应 vim.g.easycomplete_pum_maxlength)
// - `fix_width`: 是否固定宽度 (对应 vim.g.easycomplete_pum_fix_width == 1)
//
// 返回: 处理后的字符串

fn parse_abbr(lua: &Lua, abbr: String) -> LuaResult<String> {
    let globals = lua.globals();
    let init_global_vars: mlua::Function = globals.get("init_global_vars_for_rust")?;
    // init_global_vars.call("default")?; // 好像不用做这一步
    let max_length_i32: i32 = globals.get("easycomplete_pum_maxlength")?;
    let fix_width_i32: i32 = globals.get("easycomplete_pum_fix_width")?;
    let max_length: usize = max_length_i32.try_into().expect("i32 value cannot fit in usize");
    let fix_width: bool = match fix_width_i32 {
        1 => true,
        0 => false,
        _ => panic!("fix_width must be 0 or 1!"),
    };
    let ret: String = _parse_abbr(&abbr, max_length, fix_width);

    Ok(ret)
}

fn _parse_abbr(abbr: &str, max_length: usize, fix_width: bool) -> String {
    let abbr_chars: Vec<char> = abbr.chars().collect();
    let abbr_len = abbr_chars.len();

    if abbr_len <= max_length {
        if fix_width {
            // 右填充空格到 max_length
            let spaces = " ".repeat(max_length - abbr_len);
            format!("{}{}", abbr, spaces)
        } else {
            abbr.to_string()
        }
    } else {
        // 截取前 max_length - 1 个字符，加上 "…"
        let truncated: String = abbr_chars.into_iter().take(max_length - 1).collect();
        format!("{}…", truncated)
    }
}

// 重写了 lua 版本的 util.replacement()
// 参数：
// - abbr: 对应 item 的 abbr, String 类型
// - positions: matchfuzzy 的 position 数组，LuaTable 类型
// - wrap_char: 包裹字符，char 类型
//
// 返回：返回根据 positions 里所示位置的字符加上了
// 包裹wrap_char的结果字符串
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


// complete_menu_filter 主函数：Rust 版本的 complete_menu_filter
// lua → util.complete_menu_filter(matching_res, word)

// fn complete_menu_filter(
//     lua: &Lua,
//     (matching_res, word): (LuaTable, String)
// ) -> LuaResult<Vec<LuaTable>> {
//     let mut fuzzymatching = Vec::new();
//     let mut fuzzy_position = Vec::new();
//     let mut fuzzy_scores = Vec::new()

//     // 遍历 Lua 表中的所有键值对
//     for pair in matching_res.pairs::<mlua::Integer, mlua::LuaTable>() {
//         let (key, value) = pair?;
//         if key >= 1 {
//             // 将 Lua Integer 转换为 usize 并添加到 Vec 中
//             vec.push(value as usize);
//         }
//         if k == 1 {
//             fuzzymatching = value as Vec<LuaTable>;
//         }
//         if k == 2 {
//             fuzzy_position = value as Vec<mlua::Interger>;
//         }
//         if k == 3 {
//             fuzzy_scores = value as Vec<i32>;
//         }
//     }

//     Ok()
// }

#[mlua::lua_module]
fn easycomplete_rust_speed(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    // 调试用
    exports.set("hello", lua.create_function(hello)?)?;
    exports.set("return_table", lua.create_function(return_table)?)?;
    exports.set("return_kv_table", lua.create_function(return_kv_table)?)?;
    exports.set("parse_table", lua.create_function(parse_table)?)?;
    exports.set("get_global_vars", lua.create_function(get_global_vars)?)?;
    exports.set("get_first_complete_hit", lua.create_function(get_first_complete_hit)?)?;

    // rust 重写的 lua 函数
    exports.set("replacement", lua.create_function(replacement)?)?;
    exports.set("parse_abbr", lua.create_function(parse_abbr)?)?;

    Ok(exports)
}

