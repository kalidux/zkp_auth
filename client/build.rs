fn main() {
    tonic_build::configure()
        .build_server(false)
        .out_dir("src/")
        .compile(&["../proto/zkp_auth.proto"], &["../proto/"])
        .unwrap();
}