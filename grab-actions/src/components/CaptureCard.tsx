import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/tauri';
import { convertFileSrc } from '@tauri-apps/api/tauri';
import { CaptureFile, CaptureMetadata } from '../types';

interface CaptureCardProps {
  capture: CaptureFile;
  isSelected: boolean;
  onClick: () => void;
}

export function CaptureCard({ capture, isSelected, onClick }: CaptureCardProps) {
  const [metadata, setMetadata] = useState<CaptureMetadata | null>(null);
  const [textContent, setTextContent] = useState<string>('');
  const [imagePreview, setImagePreview] = useState<string>('');

  useEffect(() => {
    if (capture.has_metadata) {
      loadMetadata();
    }
    if (capture.capture_type === 'text') {
      loadTextContent();
    } else if (capture.capture_type === 'image') {
      setImagePreview(convertFileSrc(capture.path));
    }
  }, [capture]);

  const loadMetadata = async () => {
    try {
      const meta = await invoke<CaptureMetadata>('get_capture_metadata', { 
        filename: capture.name 
      });
      setMetadata(meta);
    } catch (error) {
      console.error('Failed to load metadata:', error);
    }
  };

  const loadTextContent = async () => {
    try {
      const content = await invoke<string>('get_text_content', { 
        filename: capture.name 
      });
      setTextContent(content);
    } catch (error) {
      console.error('Failed to load text content:', error);
    }
  };

  const formatDate = (timestamp: number): string => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getCaptureTypeIcon = () => {
    if (metadata?.captureType) {
      switch (metadata.captureType) {
        case 'screen_region':
          return '🖥️';
        case 'window':
          return '🪟';
        case 'clipboard':
          return '📋';
        case 'url':
          return '🔗';
        default:
          return capture.capture_type === 'image' ? '🖼️' : '📄';
      }
    }
    return capture.capture_type === 'image' ? '🖼️' : '📄';
  };

  const getTypeColor = () => {
    if (metadata?.captureType) {
      switch (metadata.captureType) {
        case 'screen_region':
          return 'bg-blue-500/20 text-blue-300';
        case 'window':
          return 'bg-green-500/20 text-green-300';
        case 'clipboard':
          return 'bg-orange-500/20 text-orange-300';
        case 'url':
          return 'bg-purple-500/20 text-purple-300';
        default:
          return 'bg-gray-500/20 text-gray-300';
      }
    }
    return 'bg-gray-500/20 text-gray-300';
  };

  const truncateText = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div
      className={`relative group cursor-pointer transition-all duration-200 ${
        isSelected
          ? 'ring-2 ring-blue-400 bg-white/10'
          : 'hover:bg-white/5'
      }`}
      onClick={onClick}
    >
      <div className="bg-black/20 backdrop-blur-md border border-white/10 rounded-xl p-4 h-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center space-x-2">
            <span className="text-lg">{getCaptureTypeIcon()}</span>
            <span className={`px-2 py-1 rounded text-xs font-medium ${getTypeColor()}`}>
              {metadata?.captureType || capture.capture_type}
            </span>
          </div>
          <div className="text-xs text-white/50">
            {formatDate(capture.modified)}
          </div>
        </div>

        {/* Preview */}
        <div className="mb-3">
          {capture.capture_type === 'image' && imagePreview && (
            <div className="aspect-video bg-black/30 rounded-lg overflow-hidden">
              <img
                src={imagePreview}
                alt={capture.name}
                className="w-full h-full object-cover"
              />
            </div>
          )}
          
          {capture.capture_type === 'text' && textContent && (
            <div className="bg-black/30 rounded-lg p-3 min-h-[120px] font-mono text-sm">
              <pre className="text-white/80 whitespace-pre-wrap overflow-hidden">
                {truncateText(textContent, 200)}
              </pre>
            </div>
          )}
        </div>

        {/* Metadata */}
        {metadata && (
          <div className="space-y-2 text-xs text-white/60">
            {metadata.metadata.applicationName && (
              <div className="flex items-center space-x-2">
                <span className="text-white/40">App:</span>
                <span>{metadata.metadata.applicationName}</span>
              </div>
            )}
            {metadata.metadata.windowTitle && (
              <div className="flex items-center space-x-2">
                <span className="text-white/40">Window:</span>
                <span className="truncate">{metadata.metadata.windowTitle}</span>
              </div>
            )}
            {metadata.metadata.dimensions && (
              <div className="flex items-center space-x-2">
                <span className="text-white/40">Size:</span>
                <span>
                  {Math.round(metadata.metadata.dimensions.width)} × {Math.round(metadata.metadata.dimensions.height)}
                </span>
              </div>
            )}
          </div>
        )}

        {/* Footer */}
        <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between">
          <div className="text-xs text-white/50 truncate">
            {capture.name}
          </div>
          <div className="text-xs text-white/40">
            {formatFileSize(capture.size)}
          </div>
        </div>
      </div>
    </div>
  );
}