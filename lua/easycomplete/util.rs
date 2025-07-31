
// 必须使用 `extern "C"` 确保 C 兼容 ABI
// 并用 `#[no_mangle]` 防止函数名被编译器修改

#[unsafe(no_mangle)]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[unsafe(no_mangle)]
pub extern "C" fn greet(name: *const u8, len: usize) -> *const u8 {
    // 将 C 字符串转为 Rust 字符串
    let c_str = unsafe { std::slice::from_raw_parts(name, len) };
    let rust_str = std::str::from_utf8(c_str).unwrap_or("invalid");

    // 返回静态字符串（注意：不能返回临时字符串的指针！）
    concat!("Hello, ", env!("USER"), " from Rust!").as_ptr() as *const u8
}
