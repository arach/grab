#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::fs;
use std::path::PathBuf;
use tauri::{Manager, WindowEvent};
use serde::{Deserialize, Serialize};
use base64::engine::Engine;

#[derive(Debug, Serialize, Deserialize)]
struct CaptureFile {
    name: String,
    path: String,
    modified: u64,
    size: u64,
    capture_type: String,
    has_metadata: bool,
    metadata: Option<CaptureMetadata>,
}

#[derive(Debug, Serialize, Deserialize)]
struct CaptureMetadata {
    id: String,
    timestamp: String,
    #[serde(rename = "type")]
    capture_type: String,
    filename: String,
    #[serde(rename = "fileExtension")]
    file_extension: String,
    #[serde(rename = "fileSize")]
    file_size: i64,
    metadata: MetadataDetails,
}

#[derive(Debug, Serialize, Deserialize)]
struct MetadataDetails {
    dimensions: Option<Dimensions>,
    #[serde(rename = "applicationName")]
    application_name: Option<String>,
    #[serde(rename = "windowTitle")]
    window_title: Option<String>,
    #[serde(rename = "clipboardType")]
    clipboard_type: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Dimensions {
    width: f64,
    height: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct AppSettings {
    capture_folder: String,
    default_capture_folder: String,
}

#[tauri::command]
fn get_captures_dir() -> Result<String, String> {
    // Try to get custom folder from settings, fallback to default
    match get_app_settings_internal() {
        Ok(settings) => {
            let custom_path = PathBuf::from(&settings.capture_folder);
            if custom_path.exists() {
                Ok(settings.capture_folder)
            } else {
                // Fallback to default
                let default_path = get_default_captures_dir()?;
                Ok(default_path.to_string_lossy().to_string())
            }
        },
        Err(_) => {
            let default_path = get_default_captures_dir()?;
            Ok(default_path.to_string_lossy().to_string())
        }
    }
}

#[tauri::command]
fn list_captures() -> Result<Vec<CaptureFile>, String> {
    let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
    let captures_path = home_dir.join("Library/Application Support/Grab/captures");
    
    if !captures_path.exists() {
        return Ok(vec![]);
    }

    let mut captures = Vec::new();
    
    let entries = fs::read_dir(&captures_path)
        .map_err(|e| format!("Failed to read captures directory: {}", e))?;
    
    for entry in entries {
        let entry = entry.map_err(|e| format!("Failed to read directory entry: {}", e))?;
        let path = entry.path();
        
        if path.is_file() {
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                let is_image = name.to_lowercase().ends_with(".png") || 
                              name.to_lowercase().ends_with(".jpg") || 
                              name.to_lowercase().ends_with(".jpeg") ||
                              name.to_lowercase().ends_with(".gif") ||
                              name.to_lowercase().ends_with(".bmp") ||
                              name.to_lowercase().ends_with(".webp");
                let is_text = name.ends_with(".txt");
                
                if is_image || is_text {
                    let file_metadata = entry.metadata()
                        .map_err(|e| format!("Failed to read file metadata: {}", e))?;
                    
                    let modified = file_metadata
                        .modified()
                        .unwrap_or(std::time::UNIX_EPOCH)
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs();
                    
                    // Check for corresponding JSON metadata file
                    let json_filename = format!("{}.json", name);
                    let json_path = captures_path.join(&json_filename);
                    let has_metadata = json_path.exists();
                    
                    // Try to load metadata if it exists
                    let capture_metadata = if has_metadata {
                        match load_capture_metadata(&json_path) {
                            Ok(metadata) => Some(metadata),
                            Err(_) => None, // Continue without metadata if parsing fails
                        }
                    } else {
                        None
                    };
                    
                    let capture_type = if is_image {
                        "image".to_string()
                    } else {
                        "text".to_string()
                    };
                    
                    captures.push(CaptureFile {
                        name: name.to_string(),
                        path: path.to_string_lossy().to_string(),
                        modified,
                        size: file_metadata.len(),
                        capture_type,
                        has_metadata,
                        metadata: capture_metadata,
                    });
                }
            }
        }
    }
    
    // Sort by modified time (newest first)
    captures.sort_by(|a, b| b.modified.cmp(&a.modified));
    
    Ok(captures)
}

fn load_capture_metadata(json_path: &PathBuf) -> Result<CaptureMetadata, String> {
    let content = fs::read_to_string(json_path)
        .map_err(|e| format!("Failed to read metadata file: {}", e))?;
    
    serde_json::from_str::<CaptureMetadata>(&content)
        .map_err(|e| format!("Failed to parse metadata: {}", e))
}

#[tauri::command]
fn get_capture_metadata(filename: String) -> Result<CaptureMetadata, String> {
    let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
    let captures_path = home_dir.join("Library/Application Support/Grab/captures");
    let json_filename = format!("{}.json", filename);
    let json_path = captures_path.join(&json_filename);
    
    if !json_path.exists() {
        return Err("Metadata file not found".to_string());
    }
    
    load_capture_metadata(&json_path)
}

#[tauri::command]
fn get_text_content(filename: String) -> Result<String, String> {
    let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
    let captures_path = home_dir.join("Library/Application Support/Grab/captures");
    let file_path = captures_path.join(&filename);
    
    if !file_path.exists() {
        return Err("Text file not found".to_string());
    }
    
    fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read text file: {}", e))
}

#[tauri::command]
fn get_image_content(filename: String) -> Result<String, String> {
    println!("🖼️ get_image_content called with filename: {}", filename);
    
    // Use the configurable captures directory
    let captures_dir_str = get_captures_dir()?;
    let captures_path = PathBuf::from(captures_dir_str);
    let file_path = captures_path.join(&filename);
    
    println!("🔍 Looking for image at: {}", file_path.display());
    println!("📂 Captures directory: {}", captures_path.display());
    
    if !file_path.exists() {
        println!("❌ Image file not found at: {}", file_path.display());
        return Err(format!("Image file not found: {}", file_path.display()));
    }
    
    let image_data = fs::read(&file_path)
        .map_err(|e| {
            println!("❌ Failed to read image file: {}", e);
            format!("Failed to read image file: {}", e)
        })?;
    
    println!("✅ Successfully read {} bytes of image data", image_data.len());
    
    let base64_data = base64::engine::general_purpose::STANDARD.encode(&image_data);
    println!("✅ Generated base64 data with length: {}", base64_data.len());
    
    Ok(base64_data)
}

#[tauri::command]
fn check_clipboard_event() -> Result<Option<serde_json::Value>, String> {
    let app_support = dirs::home_dir()
        .ok_or("Failed to get home directory")?
        .join("Library/Application Support/Grab");
    
    let clipboard_event_file = app_support.join("clipboard_event.json");
    
    if !clipboard_event_file.exists() {
        return Ok(None);
    }
    
    let content = fs::read_to_string(&clipboard_event_file)
        .map_err(|e| format!("Failed to read clipboard event file: {}", e))?;
    
    let clipboard_event: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse clipboard event JSON: {}", e))?;
    
    // Delete the file after reading to avoid processing the same event multiple times
    let _ = fs::remove_file(&clipboard_event_file);
    
    Ok(Some(clipboard_event))
}

fn get_default_captures_dir() -> Result<PathBuf, String> {
    let home_dir = dirs::home_dir().ok_or("Failed to get home directory")?;
    let captures_dir = home_dir
        .join("Library")
        .join("Application Support")
        .join("Grab")
        .join("captures");
    
    if !captures_dir.exists() {
        fs::create_dir_all(&captures_dir)
            .map_err(|e| format!("Failed to create captures directory: {}", e))?;
    }
    
    Ok(captures_dir)
}

fn get_settings_file_path() -> Result<PathBuf, String> {
    let home_dir = dirs::home_dir().ok_or("Failed to get home directory")?;
    let settings_dir = home_dir
        .join("Library")
        .join("Application Support")
        .join("Grab");
    
    if !settings_dir.exists() {
        fs::create_dir_all(&settings_dir)
            .map_err(|e| format!("Failed to create settings directory: {}", e))?;
    }
    
    Ok(settings_dir.join("settings.json"))
}

fn get_app_settings_internal() -> Result<AppSettings, String> {
    let settings_path = get_settings_file_path()?;
    
    if !settings_path.exists() {
        // Create default settings
        let default_folder = get_default_captures_dir()?
            .to_string_lossy()
            .to_string();
        
        let default_settings = AppSettings {
            capture_folder: default_folder.clone(),
            default_capture_folder: default_folder,
        };
        
        let settings_json = serde_json::to_string_pretty(&default_settings)
            .map_err(|e| format!("Failed to serialize default settings: {}", e))?;
        
        fs::write(&settings_path, settings_json)
            .map_err(|e| format!("Failed to write default settings: {}", e))?;
        
        return Ok(default_settings);
    }
    
    let settings_content = fs::read_to_string(&settings_path)
        .map_err(|e| format!("Failed to read settings file: {}", e))?;
    
    let settings: AppSettings = serde_json::from_str(&settings_content)
        .map_err(|e| format!("Failed to parse settings: {}", e))?;
    
    Ok(settings)
}

#[tauri::command]
fn get_app_settings() -> Result<AppSettings, String> {
    get_app_settings_internal()
}

#[tauri::command]
fn save_app_settings(settings: AppSettings) -> Result<(), String> {
    let settings_path = get_settings_file_path()?;
    
    // Validate that the capture folder exists or can be created
    let capture_path = PathBuf::from(&settings.capture_folder);
    if !capture_path.exists() {
        fs::create_dir_all(&capture_path)
            .map_err(|e| format!("Failed to create capture folder: {}", e))?;
    }
    
    let settings_json = serde_json::to_string_pretty(&settings)
        .map_err(|e| format!("Failed to serialize settings: {}", e))?;
    
    fs::write(&settings_path, settings_json)
        .map_err(|e| format!("Failed to write settings file: {}", e))?;
    
    Ok(())
}

#[tauri::command]
fn copy_image_to_clipboard(filename: String) -> Result<(), String> {
    // Use the configurable captures directory
    let captures_dir_str = get_captures_dir()?;
    let captures_path = PathBuf::from(captures_dir_str);
    let file_path = captures_path.join(&filename);
    
    if !file_path.exists() {
        return Err("Image file not found".to_string());
    }
    
    // On macOS, we can use the `osascript` command to copy image to clipboard
    use std::process::Command;
    
    let output = Command::new("osascript")
        .arg("-e")
        .arg(format!(
            "set the clipboard to (read file POSIX file \"{}\") as JPEG picture",
            file_path.to_string_lossy()
        ))
        .output()
        .map_err(|e| format!("Failed to execute osascript: {}", e))?;
    
    if !output.status.success() {
        let error_msg = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Failed to copy image to clipboard: {}", error_msg));
    }
    
    Ok(())
}

fn handle_capture_id(app_handle: tauri::AppHandle, capture_id: &str) {
    // Emit event to frontend with capture ID
    app_handle.emit_all("capture-id", capture_id).unwrap_or_else(|e| {
        eprintln!("Failed to emit capture-id event: {}", e);
    });
}

fn parse_command_line_args() -> Option<String> {
    let args: Vec<String> = std::env::args().collect();
    
    for arg in args.iter() {
        if arg.starts_with("--capture-id=") {
            let capture_id = arg.trim_start_matches("--capture-id=");
            if !capture_id.is_empty() {
                return Some(capture_id.to_string());
            }
        }
    }
    
    None
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            get_captures_dir, 
            list_captures, 
            get_capture_metadata, 
            get_text_content,
            get_image_content,
            get_app_settings,
            save_app_settings,
            copy_image_to_clipboard,
            check_clipboard_event
        ])
        .setup(|app| {
            // Handle capture ID from command line arguments on app startup
            if let Some(capture_id) = parse_command_line_args() {
                handle_capture_id(app.handle(), &capture_id);
            }
            Ok(())
        })
        .on_window_event(|event| {
            match event.event() {
                WindowEvent::Focused(true) => {
                    // Check for capture ID in command line arguments when window gains focus
                    if let Some(capture_id) = parse_command_line_args() {
                        handle_capture_id(event.window().app_handle(), &capture_id);
                    }
                },
                _ => {}
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}