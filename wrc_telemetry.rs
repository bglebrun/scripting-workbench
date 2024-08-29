#!/usr/bin/env cached-nix-shell
//! ```cargo
//! [dependencies]
//! clearscreen = "2.0.1"
//! ```
/*
#!nix-shell -i rust-script -p pkg-config -p rustc -p rust-script -p cargo
*/

use std::net::UdpSocket;
use clearscreen;

#[repr(C)]
pub struct UDP_Telemetry_Packet {
    packet_uid: u64,                   // 0
    game_total_time: f32,              // 1
    game_delta_time: f32,              // 2
    game_frame_count: u64,             // 3
    shiftlights_fraction: f32,         // 4
    shiftlights_rpm_start: f32,        // 5
    shiftlights_rpm_end: f32,          // 6
    shiftlights_rpm_valid: bool,       // 7
    vehicle_gear_index: u8,            // 8
    vehicle_gear_index_neutral: u8,    // 9
    vehicle_gear_index_reverse: u8,    // 10
    vehicle_gear_maximum: u8,          // 11
    vehicle_speed: f32,                // 12
    vehicle_transmission_speed: f32,   // 13
    vehicle_position_x: f32,           // 14
    vehicle_position_y: f32,           // 15
    vehicle_position_z: f32,           // 16
    vehicle_velocity_x: f32,           // 17
    vehicle_velocity_y: f32,           // 18
    vehicle_velocity_z: f32,           // 19
    vehicle_acceleration_x: f32,       // 20
    vehicle_acceleration_y: f32,       // 21
    vehicle_acceleration_z: f32,       // 22
    vehicle_left_direction_x: f32,     // 23
    vehicle_left_direction_y: f32,     // 24
    vehicle_left_direction_z: f32,     // 25
    vehicle_forward_direction_x: f32,  // 26
    vehicle_forward_direction_y: f32,  // 27
    vehicle_forward_direction_z: f32,  // 28
    vehicle_up_direction_x: f32,       // 29
    vehicle_up_direction_y: f32,       // 30
    vehicle_up_direction_z: f32,       // 31
    vehicle_hub_position_bl: f32,      // 32
    vehicle_hub_position_br: f32,      // 33
    vehicle_hub_position_fl: f32,      // 34
    vehicle_hub_position_fr: f32,      // 35
    vehicle_hub_velocity_bl: f32,      // 36
    vehicle_hub_velocity_br: f32,      // 37
    vehicle_hub_velocity_fl: f32,      // 38
    vehicle_hub_velocity_fr: f32,      // 39
    vehicle_cp_forward_speed_bl: f32,  // 40
    vehicle_cp_forward_speed_br: f32,  // 41
    vehicle_cp_forward_speed_fl: f32,  // 42
    vehicle_cp_forward_speed_fr: f32,  // 43
    vehicle_brake_temperature_bl: f32, // 44
    vehicle_brake_temperature_br: f32, // 45
    vehicle_brake_temperature_fl: f32, // 46
    vehicle_brake_temperature_fr: f32, // 47
    vehicle_engine_rpm_max: f32,       // 48
    vehicle_engine_rpm_idle: f32,      // 49
    vehicle_engine_rpm_current: f32,   // 50
    vehicle_throttle: f32,             // 51
    vehicle_brake: f32,                // 52
    vehicle_clutch: f32,               // 53
    vehicle_steering: f32,             // 54
    vehicle_handbrake: f32,            // 55
    stage_current_time: f32,           // 56
    stage_current_distance: f64,       // 57
    stage_length: f64,                 // 58
}

const UDP_TELEMETRY_PACKET_SIZE: usize = std::mem::size_of::<UDP_Telemetry_Packet>();


fn main() {
    let socket = UdpSocket::bind("127.0.0.1:20777").unwrap();
    // read udp buffer on port 20777
    let mut buf = [0; UDP_TELEMETRY_PACKET_SIZE];
    loop {
        // handle invalid packet size, we may not always be in game
        let (amt, src) = socket.recv_from(&mut buf).unwrap();
        let packet = format_packet(&buf);
        // clear the cli, then print the stats
        clearscreen::clear().unwrap();
        println!("{}", simple_stats_to_string(&packet));

    }
}

fn format_packet(buf: &[u8; UDP_TELEMETRY_PACKET_SIZE]) -> UDP_Telemetry_Packet {
    let packet = unsafe { std::mem::transmute::<[u8; UDP_TELEMETRY_PACKET_SIZE], UDP_Telemetry_Packet>(*buf) };
    packet
}

fn simple_stats_to_string(stats: &UDP_Telemetry_Packet) -> String {
    format!(
        "Game Time: {:.2}\nVehicle Speed: {:.2}\nVehicle Gear: {}\nVehicle RPM: {:.2}\n",
        stats.game_total_time,
        stats.vehicle_speed,
        stats.vehicle_gear_index,
        stats.vehicle_engine_rpm_current
    )
}
