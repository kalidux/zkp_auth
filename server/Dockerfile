# Stage 1: Build the server
FROM rust:1.78.0-bullseye as builder

WORKDIR /usr/src/server

# Copy Cargo files
COPY ./server/Cargo.toml ./server/Cargo.lock ./

# Copy source code
COPY ./server/src ./src
COPY ./proto ./proto

# Build the server
RUN RUST_LOG=info cargo build --release --bin server

# Stage 2: Run the server
FROM debian:bullseye-slim as runner

WORKDIR /usr/src/server

# Install wget for downloading grpc_health_probe
RUN apt-get update && apt-get install -y wget

# Copy the compiled server from the builder stage
COPY --from=builder /usr/src/server/target/release/server /usr/local/bin/server

# Expose the gRPC port
EXPOSE 50051

CMD ["server"]
