use chaum_pederson_zkp::{deserialize, exponentiate, random_number, serialize, solve, G, H, P, Q};
use num_bigint::BigUint;
use log::{info, error};  // Import the log macros

pub mod zkp_auth {
    include!("./zkp_auth.rs");
}

use zkp_auth::auth_client::AuthClient;
use zkp_auth::{AuthenticationAnswerRequest, AuthenticationChallengeRequest, RegisterRequest};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();  // Initialize the logger
    info!("Starting client...");

    // Connect to the server using the Docker container name
    info!("Connecting to server at http://zkp-server:50051...");
    let mut client = match AuthClient::connect("http://zkp-server:50051").await {
        Ok(client) => client,
        Err(e) => {
            error!("Failed to connect to server: {:?}", e);
            return Err(e.into());
        }
    };
    info!("Successfully connected to the server.");

    // Hardcoded values for user_id and password
    let user_id = "user123".to_string();
    let password_str = "123456789";  // The password as a big number

    info!("User ID: {}", user_id);

    // Parse the hardcoded password to BigUint
    let x = match password_str.parse::<BigUint>() {
        Ok(val) => val,
        Err(e) => {
            error!("Failed to parse password: {:?}", e);
            return Err(e.into());
        }
    };
    info!("Password parsed successfully.");

    let y1 = exponentiate(&deserialize(G), &x, &deserialize(P));
    let y2 = exponentiate(&deserialize(H), &x, &deserialize(P));
    info!("Generated y1: {:?}, y2: {:?}", y1, y2);

    let register_request = tonic::Request::new(RegisterRequest {
        user: user_id.clone(),
        y1: serialize(&y1),
        y2: serialize(&y2),
    });

    // Register the user
    info!("Sending registration request...");
    match client.register(register_request).await {
        Ok(_) => info!("User registered successfully."),
        Err(e) => {
            error!("Registration failed: {:?}", e);
            return Err(e.into());
        }
    };

    let k = random_number();
    let r1 = exponentiate(&deserialize(G), &k, &deserialize(P));
    let r2 = exponentiate(&deserialize(H), &k, &deserialize(P));
    info!("Generated r1: {:?}, r2: {:?}", r1, r2);

    let auth_challenge_request = tonic::Request::new(AuthenticationChallengeRequest {
        user: user_id.clone(),
        r1: serialize(&r1),
        r2: serialize(&r2),
    });

    // Request authentication challenge
    info!("Requesting authentication challenge...");
    let auth_challenge_response = match client
        .create_authentication_challenge(auth_challenge_request)
        .await
    {
        Ok(response) => {
            info!("Received authentication challenge.");
            response.into_inner()
        }
        Err(e) => {
            error!("Authentication challenge request failed: {:?}", e);
            return Err(e.into());
        }
    };

    let c = deserialize(&auth_challenge_response.c);
    let auth_id = auth_challenge_response.auth_id;
    info!("Received challenge c: {:?}, auth_id: {}", c, auth_id);

    let s = solve(&x, &k, &c, &deserialize(Q));
    info!("Computed s: {:?}", s);

    let auth_answer_request = tonic::Request::new(AuthenticationAnswerRequest {
        auth_id,
        s: serialize(&s),
    });

    // Verify authentication
    info!("Sending authentication answer...");
    let auth_answer_response = match client.verify_authentication(auth_answer_request).await {
        Ok(response) => {
            info!("Authentication successful.");
            response.into_inner()
        }
        Err(e) => {
            error!("Authentication failed: {:?}", e);
            return Err(e.into());
        }
    };

    println!(
        "SessionID={:?}",
        auth_answer_response.session_id
    );

    Ok(())
}
