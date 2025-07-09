import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/tauri';
import { X, Download, Copy, Trash2, ZoomIn, ZoomOut, RotateCw, Share2 } from 'lucide-react';
import { CaptureFile, CaptureMetadata } from '../types';

interface ActionViewProps {
  capture: CaptureFile;
  metadata: CaptureMetadata | null;
  textContent: string;
  onClose: () => void;
  onDelete: (capture: CaptureFile) => Promise<void>;
  onCopyToClipboard: (content: string) => Promise<void>;
  formatDate: (timestamp: number) => string;
  formatFileSize: (bytes: number) => string;
}

export function ActionView({ capture, metadata, textContent, onClose, onDelete, onCopyToClipboard, formatDate, formatFileSize }: ActionViewProps) {
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isCopying, setIsCopying] = useState(false);
  const [imageData, setImageData] = useState<string>('');
  const [imageLoading, setImageLoading] = useState(false);
  const [imageError, setImageError] = useState<string>('');

  // Load image data for image captures
  useEffect(() => {
    console.log('ActionView mounted with capture:', {
      name: capture.name,
      type: capture.capture_type,
      path: capture.path
    });
    if (capture.capture_type === 'image') {
      console.log('Detected image type, loading image data...');
      loadImageData();
    } else {
      console.log('Not an image type, skipping image load');
    }
  }, [capture]);

  const loadImageData = async () => {
    try {
      setImageLoading(true);
      setImageError('');
      console.log('Loading image for capture:', capture.name, 'type:', capture.capture_type);
      const base64Data = await invoke<string>('get_image_content', { filename: capture.name });
      console.log('Received base64 data length:', base64Data.length);
      // Determine the image type from file extension
      const extension = capture.name.split('.').pop()?.toLowerCase() || 'png';
      const mimeType = extension === 'jpg' || extension === 'jpeg' ? 'image/jpeg' : `image/${extension}`;
      const dataUrl = `data:${mimeType};base64,${base64Data}`;
      console.log('Created data URL with mime type:', mimeType);
      setImageData(dataUrl);
    } catch (error) {
      console.error('Failed to load image:', error);
      setImageError(`Failed to load image: ${error}`);
    } finally {
      setImageLoading(false);
    }
  };

  const handleCopy = async () => {
    try {
      setIsCopying(true);
      if (capture.capture_type === 'image') {
        // For images, copy the image file to clipboard
        await invoke('copy_image_to_clipboard', { filename: capture.name });
      } else {
        await onCopyToClipboard(textContent);
      }
      setTimeout(() => setIsCopying(false), 1000);
    } catch (error) {
      console.error('Failed to copy:', error);
      setIsCopying(false);
    }
  };

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this capture?')) {
      setIsDeleting(true);
      try {
        await onDelete(capture);
        onClose();
      } catch (error) {
        console.error('Failed to delete:', error);
        setIsDeleting(false);
      }
    }
  };

  const handleDownload = async () => {
    try {
      if (capture.capture_type === 'image') {
        await invoke('save_capture_to_downloads', { 
          filename: capture.name
        });
      } else {
        const blob = new Blob([textContent], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = capture.name;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch (error) {
      console.error('Failed to download:', error);
    }
  };

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: metadata?.filename || 'Grab Capture',
          text: capture.capture_type === 'text' ? textContent : `Captured ${capture.capture_type}`,
          url: capture.capture_type === 'url' ? textContent : undefined,
        });
      } else {
        // Fallback to copying to clipboard
        await handleCopy();
      }
    } catch (error) {
      console.error('Failed to share:', error);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-4xl max-h-[90vh] w-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <h2 className="text-lg font-semibold text-gray-900">
              {metadata?.filename || `${capture.capture_type.charAt(0).toUpperCase() + capture.capture_type.slice(1)} Capture`}
            </h2>
            <span className="text-sm text-gray-500">
              {formatDate(capture.modified)}
            </span>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-hidden">
          {capture.capture_type === 'image' ? (
            <div className="h-full flex flex-col">
              {/* Image Controls */}
              <div className="flex items-center justify-center space-x-2 p-2 border-b border-gray-200 bg-gray-50">
                <button
                  onClick={() => setZoom(Math.max(0.25, zoom - 0.25))}
                  className="p-2 hover:bg-gray-200 rounded transition-colors"
                  title="Zoom Out"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>
                <span className="text-sm text-gray-600 min-w-[60px] text-center">
                  {Math.round(zoom * 100)}%
                </span>
                <button
                  onClick={() => setZoom(Math.min(3, zoom + 0.25))}
                  className="p-2 hover:bg-gray-200 rounded transition-colors"
                  title="Zoom In"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setRotation((rotation + 90) % 360)}
                  className="p-2 hover:bg-gray-200 rounded transition-colors"
                  title="Rotate"
                >
                  <RotateCw className="w-4 h-4" />
                </button>
                <button
                  onClick={() => { setZoom(1); setRotation(0); }}
                  className="px-3 py-1 text-sm hover:bg-gray-200 rounded transition-colors"
                >
                  Reset
                </button>
              </div>

              {/* Image Actions */}
              <div className="flex-1 overflow-auto bg-gray-100 flex items-center justify-center">
                {imageLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="text-gray-500">Loading image...</div>
                  </div>
                ) : imageError ? (
                  <div className="flex flex-col items-center justify-center text-red-500">
                    <div>{imageError}</div>
                    <button 
                      onClick={loadImageData}
                      className="mt-2 px-3 py-1 bg-red-100 text-red-600 rounded hover:bg-red-200"
                    >
                      Retry
                    </button>
                  </div>
                ) : imageData ? (
                  <img
                    src={imageData}
                    alt="Capture"
                    className="max-w-none transition-transform duration-200"
                    style={{
                      transform: `scale(${zoom}) rotate(${rotation}deg)`,
                      transformOrigin: 'center',
                    }}
                    onLoad={() => console.log('Image loaded successfully')}
                    onError={(e) => {
                      console.error('Image failed to load:', e);
                      setImageError('Image failed to display');
                    }}
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center text-gray-500">
                    <div>No image data available</div>
                    <div className="text-xs mt-1">Capture type: {capture.capture_type}</div>
                    <div className="text-xs">File: {capture.name}</div>
                  </div>
                )}
              </div>
            </div>
          ) : (
            <div className="h-full p-4 overflow-auto">
              <div className="bg-gray-50 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap">
                {textContent}
              </div>
            </div>
          )}
        </div>

        {/* Metadata */}
        {metadata && (
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50">
            <div className="flex flex-wrap gap-4 text-sm text-gray-600">
              {metadata.metadata.applicationName && (
                <span><strong>App:</strong> {metadata.metadata.applicationName}</span>
              )}
              {metadata.metadata.url && (
                <span><strong>URL:</strong> {metadata.metadata.url}</span>
              )}
              {metadata.metadata.dimensions && (
                <span><strong>Size:</strong> {metadata.metadata.dimensions.width} × {metadata.metadata.dimensions.height}</span>
              )}
              <span><strong>File Size:</strong> {formatFileSize(capture.size)}</span>
            </div>
          </div>
        )}

        {/* Available Actions */}
        <div className="flex items-center justify-between p-4 border-t border-gray-200">
          <div className="flex items-center space-x-2">
            <button
              onClick={handleCopy}
              disabled={isCopying}
              className="flex items-center space-x-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
            >
              <Copy className="w-4 h-4" />
              <span>{isCopying ? 'Copied!' : 'Copy'}</span>
            </button>
            <button
              onClick={handleDownload}
              className="flex items-center space-x-2 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Download className="w-4 h-4" />
              <span>Download</span>
            </button>
            <button
              onClick={handleShare}
              className="flex items-center space-x-2 px-3 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
            >
              <Share2 className="w-4 h-4" />
              <span>Share</span>
            </button>
          </div>
          <button
            onClick={handleDelete}
            disabled={isDeleting}
            className="flex items-center space-x-2 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors"
          >
            <Trash2 className="w-4 h-4" />
            <span>{isDeleting ? 'Deleting...' : 'Delete'}</span>
          </button>
        </div>
      </div>
    </div>
  );
}