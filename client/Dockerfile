# Stage 1: Build the client
FROM rust:1.78.0-bullseye as builder

WORKDIR /usr/src/client

# Copy Cargo files
COPY ./client/Cargo.toml ./client/Cargo.lock ./

# Copy source code
COPY ./client/src ./src
COPY ./proto ./proto

# Build the client
RUN RUST_LOG=info cargo build --release --bin client

# Stage 2: Run the client
FROM debian:bullseye-slim as runner

WORKDIR /usr/src/client

# Copy the compiled client from the builder stage
COPY --from=builder /usr/src/client/target/release/client /usr/local/bin/client

CMD ["client"]
