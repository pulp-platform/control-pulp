fn main() {
    println!("cargo:rustc-link-arg=-Tmemory.x");
    println!("cargo:rustc-link-arg=-Tint_link.x");
    println!("cargo:rustc-link-arg=-Tlink.x");
}
