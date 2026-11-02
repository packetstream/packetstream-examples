//! Make two requests through PacketStream and print the exit IP of each.

use std::env;
use std::error::Error;
use std::process::ExitCode;
use std::time::Duration;

use reqwest::Proxy;
use reqwest::blocking::Client;
use serde::Deserialize;

#[derive(Deserialize)]
struct IpInfo {
    ip: Option<String>,
    country: Option<String>,
    city: Option<String>,
    org: Option<String>,
}

struct Settings {
    description: String,
    proxy_url: String,
    user: String,
    password: String,
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<(), String> {
    let settings = settings()?;
    println!("{}", settings.description);
    for request in 1..=2 {
        let info = fetch(&settings).map_err(|error| {
            // Some error messages repeat the proxy URL, so remove the key
            let message = redact(&describe(error.as_ref()), &settings.password);
            format!("Request {request} failed: {message}")
        })?;
        let field = |value: Option<String>| value.unwrap_or_default();
        println!(
            "Request {request}: {}  {}  {}  {}",
            field(info.ip),
            field(info.country),
            field(info.city),
            field(info.org)
        );
    }
    Ok(())
}

fn settings() -> Result<Settings, String> {
    let required = |name: &str| match env::var(name) {
        Ok(value) if !value.is_empty() => Ok(value),
        _ => Err(format!("Set {name}")),
    };
    let optional = |name: &str| env::var(name).ok().filter(|value| !value.is_empty());

    let user = required("PACKETSTREAM_USER")?;
    let mut password = required("PACKETSTREAM_AUTH_KEY")?;
    let host =
        optional("PACKETSTREAM_PROXY_HOST").unwrap_or_else(|| "proxy.packetstream.io".into());
    let protocol = optional("PACKETSTREAM_PROXY_PROTOCOL").unwrap_or_else(|| "https".into());

    // socks5h resolves the destination hostname through the proxy
    let proxy_url = match protocol.as_str() {
        "https" => format!("https://{host}:31111"),
        "http" => format!("http://{host}:31112"),
        "socks5" => format!("socks5h://{host}:31113"),
        _ => {
            return Err(format!(
                "Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} (use https, http, or socks5)"
            ));
        }
    };

    // Targeting and sticky sessions are suffixes on the auth key
    let mut description = format!("Proxy: {proxy_url}");
    if let Some(country) = optional("PACKETSTREAM_COUNTRY") {
        password.push_str(&format!("_country-{country}"));
        description.push_str(&format!(" country={country}"));
    }
    if let Some(session) = optional("PACKETSTREAM_SESSION") {
        password.push_str(&format!("_session-{session}"));
        description.push_str(&format!(" session={session}"));
    }
    Ok(Settings {
        description,
        proxy_url,
        user,
        password,
    })
}

fn fetch(settings: &Settings) -> Result<IpInfo, Box<dyn Error>> {
    let proxy = Proxy::all(&settings.proxy_url)?.basic_auth(&settings.user, &settings.password);
    // A new client per request opens a new proxy connection. Setting a proxy
    // also stops reqwest from reading HTTP_PROXY, HTTPS_PROXY and NO_PROXY.
    let client = Client::builder()
        .proxy(proxy)
        .timeout(Duration::from_secs(30))
        .build()?;
    let info = client
        .get("https://ipinfo.io/json")
        .send()?
        .error_for_status()?
        .json()?;
    Ok(info)
}

/// Join an error with its sources, since reqwest puts the cause in the source chain.
fn describe(error: &dyn Error) -> String {
    let mut message = error.to_string();
    let mut source = error.source();
    while let Some(cause) = source {
        message.push_str(&format!(": {cause}"));
        source = cause.source();
    }
    message
}

fn redact(message: &str, password: &str) -> String {
    message.replace(password, "xxxxx")
}
