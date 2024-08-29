#!/usr/bin/env cached-nix-shell
//! ```cargo
//! [dependencies]
//! libmtp-rs = "0.7.7"
//! anyhow = "1.0.33"
//! ```
/*
#!nix-shell -i rust-script -p pkg-config -p libmtp -p rustc -p rust-script -p cargo
*/
use anyhow::Error;
use libmtp_rs::device::raw::detect_raw_devices; 

fn main() -> Result<(), Error>{
    // get script args
    for argument in std::env::args().skip(1) {
        println!("{}", argument);
    };

    let raw_devices = detect_raw_devices()?;
    let mtp_devices = raw_devices.into_iter()
        .inspect(|raw| println!("Found:\n{:#?}", raw))
        .map(|raw| raw.open_uncached());

    for (i, mtp_device) in mtp_devices.enumerate() {
        if let Some(mtp_device) = mtp_device {
            let name = if let Ok(fname) = mtp_device.get_friendly_name() {
                fname
            } else {
                format!(
                    "{} {}",
                    mtp_device.manufacturer_name()?,
                    mtp_device.model_name()?
                )
            };

            println!("Device {}: {}", i + 1, name);
            } else {
                println!("Couldn't open device {}", i + 1);
            }
        }
    Ok(())
}
// https://unix.stackexchange.com/questions/28548/how-to-run-custom-scripts-upon-usb-device-plug-in
