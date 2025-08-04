use mlua::{Lua, Value, Table};
use mlua::prelude::*;
use unicode_segmentation::UnicodeSegmentation;
use std::convert::TryInto;
use sublime_fuzzy::{best_match, Scoring};

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
fn hello(lua: &Lua, (a,b) : (String, String)) -> LuaResult<String> {
    // println!("xxxxx");
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

// 传入一个 lua table，操作键值对的 table
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

// 将一个数字组成的数组Table 转换为 slice
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
    update_global_lua_vars(lua);
    let ret: i32 = globals.get("easycomplete_first_complete_hit")?;
    Ok(ret)
}

fn update_global_lua_vars(lua: &Lua) -> LuaResult<String> {
    let globals = lua.globals();
    let init_global_vars: mlua::Function = globals.get("init_global_vars_for_rust")?;
    init_global_vars.call("default")?;
    Ok("abc".to_string())
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

// 判断 luatable 中的某个键为 nil
fn is_key_nil(table: LuaTable, key: &str) -> bool {
    // 尝试获取指定键的值
    let ret: bool = table.contains_key(key).unwrap();
    ret
}

// 根据表的word字段进行长度排序
fn sort_table_by_word_len(lua: &Lua, mut table: Table) -> Result<LuaTable, LuaError> {
    // 1. 提取所有元素
    let mut items: Vec<Table> = table
        .sequence_values::<Table>()
        .collect::<Result<Vec<_>, _>>()?;

    // 2. 在 Rust 中排序
    items.sort_by(|a, b| {
        let name_a = a.get::<String>("word").unwrap_or_default();
        let name_b = b.get::<String>("word").unwrap_or_default();
        name_a.len().cmp(&name_b.len()) // 升序
    });

    // 3. 清空原 table
    for i in 1..=table.raw_len() {
        table.set(i, Value::Nil)?;
    }

    // 4. 写回排序后的结果
    for (i, item) in items.into_iter().enumerate() {
        table.set(i + 1, item)?; // Lua 索引从 1 开始
    }

    Ok(table)
}

// complete_menu_filter 主函数：Rust 版本的 complete_menu_filter
// lua → util.complete_menu_filter(matching_res, word)
fn complete_menu_filter(
    lua: &Lua,
    (matching_res, word): (LuaTable, String))
-> LuaResult<LuaTable> {
    let globals = lua.globals();
    let mut fullmatch_result = lua.create_table()?;
    let mut firstchar_result = lua.create_table()?;
    let mut fuzzymatch_result = lua.create_table()?;

    let fuzzymatching: LuaTable = matching_res.get(1)?;
    let fuzzy_position: LuaTable = matching_res.get(2)?;
    let fuzzy_scores: LuaTable = matching_res.get(3)?;

    let mut iter = fuzzymatching.sequence_values::<Table>();
    let mut i: usize = 1;
    while let Some(every_item) = iter.next() {
        let item = every_item?;

        if is_key_nil(item.clone(), "abbr") {
            let t_abbr: String = item.get("abbr")?;
            let t_word: String = item.get("word")?;
            if t_abbr == "" {
                item.set("abbr", t_word)?;
            }
        }

        let o_abbr: String = item.get("abbr")?;
        let abbr_rust_str: String = parse_abbr(lua, o_abbr)?;
        let abbr_lua_str = lua.create_string(&abbr_rust_str)?;
        item.set("abbr", abbr_rust_str)?;
        let p: LuaTable = fuzzy_position.get(i)?;
        let abbr_replacement: String = replacement(lua, (abbr_lua_str, p.clone(), '§'))?;
        let item_score: i32 = fuzzy_scores.get(i)?;

        item.set("abbr_marked", abbr_replacement)?;
        item.set("marked_position", p)?;
        item.set("score", item_score)?;

        let item_word: String = item.get("word")?;
        let item_word_lower: String = item_word.clone().to_lowercase();
        let word_lower: String = word.clone().to_lowercase();

        if item_word_lower.starts_with(&word_lower) {
            fullmatch_result.push(item.clone());
        } else if item_word_lower.chars().next() == word_lower.chars().next() {
            firstchar_result.push(item.clone());
        } else {
            fuzzymatch_result.push(item.clone());
        }

        i += 1;
    }
    // local stunt_items = vim.fn["easycomplete#GetStuntMenuItems"]()
    update_global_lua_vars(lua);
    // 数组形式的 table
    let stunt_items: LuaTable = globals.get("easycomplete_stunt_menuitems")?;
    let stunt_items_len_i64: i64 = stunt_items.len()?;
    let stunt_items_len_i32: i32 = stunt_items_len_i64.try_into().unwrap();
    // 数字
    let first_complete_hit: i32 = globals.get("easycomplete_first_complete_hit")?;
    let mut sorted_fuzzymatch_result: LuaTable;
    if stunt_items_len_i32 == 0 && first_complete_hit == 1 {
        sorted_fuzzymatch_result = sort_table_by_word_len(lua, fuzzymatch_result.clone())?;
    } else {
        sorted_fuzzymatch_result = fuzzymatch_result.clone();
    }
    // local filtered_menu = {}
    // for _, v in ipairs(fullmatch_result) do table.insert(filtered_menu, v) end
    // for _, v in ipairs(firstchar_result) do table.insert(filtered_menu, v) end
    // for _, v in ipairs(fuzzymatch_result) do table.insert(filtered_menu, v) end
    let mut tmp_items = Vec::new();

    // 提取所有元素
    tmp_items.extend(fullmatch_result.sequence_values::<mlua::Value>().collect::<Result<Vec<_>,_>>()?);
    tmp_items.extend(firstchar_result.sequence_values::<mlua::Value>().collect::<Result<Vec<_>,_>>()?);
    tmp_items.extend(fuzzymatch_result.sequence_values::<mlua::Value>().collect::<Result<Vec<_>,_>>()?);

    // 创建新的 Lua table 并写入
    let filtered_menu = lua.create_table()?;
    for (i, item) in tmp_items.into_iter().enumerate() {
        filtered_menu.set(i + 1, item)?; // Lua 索引从 1 开始
    }

    Ok(filtered_menu)
}

// 函数弃用
// util.badboy_vim(item, typing_word) 的 rust 实现
// 这个函数 rust 版本的实现单次执行效率高于 lua，但如果被lua频繁调用，时间多消耗在
// 跨语言调用本身，因此要避免频繁调用 rust，实测频繁被 lua 调用的性能：
// 200 个节点的循环次数：
//  - lua: 稳定在 6ms
//  - rust: 在11ms~8ms 之间浮动
fn badboy_vim(lua: &Lua, (item, typing_word): (LuaTable, String)) -> LuaResult<bool> {
    let mut word: String;
    if is_key_nil(item.clone(), "label") {
        word = item.get("label")?;
    } else {
        word = "".to_string();
    }
    word = item.get("label")?;
    if word.chars().count() == 0 {
        return Ok(true);
    } else if typing_word.chars().count() == 1 {
        let first_char: char = typing_word.chars().next().unwrap_or_default();
        let pos: i32;
        match word.find(first_char) {
            Some(position) => {
                pos = position.try_into().unwrap();
            },
            None => {
                pos = -1;
            },
        }
        if pos >= 0 && pos <= 5 {
            return Ok(false);
        } else {
            return Ok(true);
        }
    } else {
        if fuzzy_search(&typing_word, &word) {
            return Ok(false);
        } else {
            return Ok(true);
        }
    }
}

//fuzzy_search("AsyncController","ac") true
fn fuzzy_search(haystack: &str, needle: &str) -> bool {
    let mut haystack_chars = haystack.chars();

    for n in needle.chars() {
        // 在 haystack 中查找当前 needle 字符
        let mut found = false;
        while let Some(h) = haystack_chars.next() {
            if n.eq_ignore_ascii_case(&h) {
                found = true;
                break;
            }
        }
        if !found {
            return false;
        }
    }
    true
}

// 根据 `word` 的长度，筛选出最短的 n 个元素
// util.trim_array_to_length 的 rust 实现
// arr: 原 all_items_list， 是数组形式的 table
fn trim_array_to_length(lua: &Lua, (arr, n): (LuaTable, i32)) -> Result<LuaTable, LuaError> {
    let n = n as usize;

    // 获取数组长度
    let len = arr.raw_len().try_into().expect("i32 value cannot fit in usize");
    if len <= n {
        return Ok(arr); // 直接返回原表
    }

    // 标准遍历数组形式的 LuaTable 的写法
    let mut indexed = Vec::with_capacity(len);
    let mut iter = arr.sequence_values::<Table>();
    let mut i: usize = 1;
    while let Some(every_item) = iter.next() {
        let item = every_item?;
        let t_word: String = item.get("word")?;
        if let word = t_word {
            indexed.push((i, word.len()));
        } else {
            // 如果没有 word 字段，给一个大长度避免优先选中
            indexed.push((i, usize::MAX));
        }
        i += 1;
    }

    // 按 word 长度升序排序（稳定排序）
    indexed.sort_by_key(|&(_, len)| len);

    // 创建结果表
    let ret = lua.create_table()?;
    for (pos, (orig_idx, _)) in indexed.into_iter().take(n).enumerate() {
        // 使用原始索引从 arr 取出完整元素
        let value: LuaTable = arr.get(orig_idx)?;
        ret.set(pos + 1, value)?; // Lua 表索引从 1 开始
    }

    Ok(ret)
}

// https://crates.io/crates/sublime_fuzzy
fn matchfuzzypos(lua: &Lua, (list, word, opt): (LuaTable, String, LuaTable)) -> Result<LuaTable, LuaError> {

    let mut matchfuzzy = lua.create_table()?;
    let mut positions = lua.create_table()?;
    let mut scores = lua.create_table()?;
    let key: String = opt.get("key")?;
    let limit: i32 = opt.get("limit")?;

    let mut list_iter = list.sequence_values::<Table>();
    let mut i: usize = 1;
    while let Some(every_item) = list_iter.next() {
        let mut item = every_item?;
        let t_word: String = item.get(key.clone())?;
        let mut position: LuaTable = lua.create_table()?;
        let mut score: i32;
        // let m = best_match(&word, &t_word).expect("No match");
        match best_match(&word, &t_word) {
            Some(m) => {
                if m.matched_indices().len() == word.chars().count() {
                    // match
                    // position = m.matched_indices();
                    for p in m.matched_indices() {
                        position.push(*p as i32);
                    }
                    score = m.score() as i32;

                    item.set("score", score.clone());
                    item.set("position", position.clone());
                    matchfuzzy.push(item.clone());
                }
            }
            None => {
                // catch 异常情况
                // do nothing and continue
            }
        }
        i += 1;
    }

    let mut matchfuzzy_vec: Vec<Table> = matchfuzzy
        .sequence_values::<Table>()
        .collect::<Result<Vec<_>, _>>()?;

    matchfuzzy_vec.sort_by(|a, b| {
        let score_a = a.get::<i32>("score").unwrap_or_default();
        let score_b = b.get::<i32>("score").unwrap_or_default();
        score_b.cmp(&score_a)
    });

    let mut new_matchfuzzy = lua.create_table()?;
    let max: usize = limit as usize;

    // 4. 写回排序后的结果
    for (i, item) in matchfuzzy_vec.into_iter().enumerate() {
        let mut p: LuaTable = item.get("position")?;
        let mut s: i32 = item.get("score")?;
        new_matchfuzzy.set(i+1, item)?; // Lua 索引从 1 开始
        positions.set(i+1, p.clone())?;
        scores.set(i+1, s.clone())?;
        if i > max {
            break;
        }
    }

    let mut result = lua.create_table()?;
    result.push(new_matchfuzzy);
    result.push(positions);
    result.push(scores);
    Ok(result)
}

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
    exports.set("badboy_vim", lua.create_function(badboy_vim)?)?;

    // rust 重写的 lua 函数
    exports.set("replacement", lua.create_function(replacement)?)?;
    exports.set("parse_abbr", lua.create_function(parse_abbr)?)?;
    exports.set("complete_menu_filter", lua.create_function(complete_menu_filter)?)?;
    exports.set("trim_array_to_length", lua.create_function(trim_array_to_length)?)?;
    exports.set("matchfuzzypos", lua.create_function(matchfuzzypos)?)?;

    Ok(exports)
}

