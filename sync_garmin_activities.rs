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
use libmtp_rs::device::StorageSort;
use libmtp_rs::object::filetypes::Filetype;
use libmtp_rs::storage::Parent;
use libmtp_rs::util::{CallbackReturn, HandlerReturn};

use std::io::Write;
use text_io::read;
// https://github.com/quebin31/libmtp-rs/blob/002b8080dff2e95ce66ae331780fa32a38842dd3/examples/list_folders.rs
// https://docs.rs/libmtp-rs/0.7.7/libmtp_rs/index.html
fn main() -> Result<(), Error> {
    let raw_devices = detect_raw_devices()?;
    let mtp_device = if let Some(raw) = raw_devices.get(0) {
        // this should check for Garmin Tactix 7
        /*
        Device 0 (VID=091e and PID=5027) is a Garmin Tactix 7.
        Found:
        RawDevice {
            bus_number: 3,
            dev_number: 17,
            device_entry: DeviceEntry {
                vendor: "Garmin",
                vendor_id: 2334,
                product: "Tactix 7",
                product_id: 20519,
                device_flags: 402686214,
            },
        }
        Device 1: tactix 7
         */
        raw.open_uncached()
    } else {
        println!("No devices");
        return Ok(());
    };

    if let Some(mut mtp_device) = mtp_device {
        mtp_device.update_storage(StorageSort::ByFreeSpace)?;

        let storage_pool = mtp_device.storage_pool();
        let (_, storage) = storage_pool.iter().next().expect("No storage");

        let root_contents: Vec<_> = storage
            .files_and_folders(Parent::Root)
            .into_iter()
            .filter(|file| !matches!(file.ftype(), Filetype::Folder))
            .collect();

        let no_digits = root_contents.len().to_string().len();

        for (idx, file) in root_contents.iter().enumerate() {
            println!("{:>d$}) {}", idx, file.name(), d = no_digits);
        } 

        print!("Choose a file (type a number): ");
        std::io::stdout().lock().flush()?;
        let choosen: usize = read!();

        if let Some(file) = root_contents.get(choosen) {
            storage.get_file_to_path_with_callback(file, file.name(), |sent, total| {
                print!("\rProgress {}/{}", sent, total);
                std::io::stdout().lock().flush().expect("Failed to flush");
                CallbackReturn::Continue
            })?;

            storage.get_file_to_handler(file, |data| {
                println!("data: {:?}", data);
                HandlerReturn::Cancel
            })?;
            println!();
        } else {
            println!("Invalid choice");
        }
    } else {
        println!("Couldn't open device");
    }

    Ok(())
}