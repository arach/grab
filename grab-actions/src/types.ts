export interface CaptureFile {
  name: string;
  path: string;
  modified: number;
  size: number;
  capture_type: string;
  has_metadata: boolean;
  metadata?: CaptureMetadata;
}

export interface CaptureMetadata {
  id: string;
  timestamp: string;
  captureType: CaptureType;
  contentType: ContentType;
  filename: string;
  fileExtension: string;
  fileSize: number;
  metadata: MetadataDetails;
}

export interface MetadataDetails {
  dimensions?: Dimensions;
  applicationName?: string;
  windowTitle?: string;
  clipboardType?: ClipboardType;
  url?: string;
}

export interface Dimensions {
  width: number;
  height: number;
}

export type CaptureType = 'screen_region' | 'window' | 'clipboard' | 'url';

export type ContentType = 'image' | 'text' | 'url';

export type ClipboardType = 'text' | 'image' | 'url' | 'file' | 'unknown';

export interface CaptureTypeFilter {
  screen_region: boolean;
  window: boolean;
  clipboard: boolean;
  url: boolean;
}