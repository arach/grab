#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::fs;
use std::path::PathBuf;
use tauri::Manager;
use serde::{Deserialize, Serialize};

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

#[tauri::command]
fn get_captures_dir() -> Result<String, String> {
    if let Some(home_dir) = dirs::home_dir() {
        let captures_path = home_dir.join("Library/Application Support/Grab/captures");
        if captures_path.exists() {
            Ok(captures_path.to_string_lossy().to_string())
        } else {
            Err("Captures directory not found".to_string())
        }
    } else {
        Err("Could not find home directory".to_string())
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
                let is_image = name.ends_with(".png") || name.ends_with(".jpg") || name.ends_with(".jpeg");
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
    let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
    let captures_path = home_dir.join("Library/Application Support/Grab/captures");
    let file_path = captures_path.join(&filename);
    
    if !file_path.exists() {
        return Err("Image file not found".to_string());
    }
    
    let image_data = fs::read(&file_path)
        .map_err(|e| format!("Failed to read image file: {}", e))?;
    
    let base64_data = base64::encode(&image_data);
    Ok(base64_data)
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            get_captures_dir, 
            list_captures, 
            get_capture_metadata, 
            get_text_content,
            get_image_content
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}