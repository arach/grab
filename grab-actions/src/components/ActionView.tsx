import { useState } from 'react';
import { writeText } from '@tauri-apps/api/clipboard';
import { invoke } from '@tauri-apps/api/tauri';
import { X, Download, Copy, Trash2, ZoomIn, ZoomOut, RotateCw, Share2, Tag } from 'lucide-react';

interface ActionViewProps {
  capture: {
    id: string;
    type: 'screenshot' | 'text' | 'link';
    content: string;
    timestamp: string;
    tags?: string[];
    metadata?: {
      title?: string;
      url?: string;
      app?: string;
      size?: string;
    };
  };
  onClose: () => void;
  onDelete: (id: string) => void;
}

export function ActionView({ capture, onClose, onDelete }: ActionViewProps) {
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isCopying, setIsCopying] = useState(false);

  const handleCopy = async () => {
    try {
      setIsCopying(true);
      if (capture.type === 'screenshot') {
        // For images, we'd need to copy the image data
        await invoke('copy_image_to_clipboard', { path: capture.content });
      } else {
        await writeText(capture.content);
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
        await invoke('delete_capture', { id: capture.id });
        onDelete(capture.id);
        onClose();
      } catch (error) {
        console.error('Failed to delete:', error);
        setIsDeleting(false);
      }
    }
  };

  const handleDownload = async () => {
    try {
      if (capture.type === 'screenshot') {
        await invoke('save_capture_to_downloads', { 
          id: capture.id, 
          filename: `grab-${capture.id}.png` 
        });
      } else {
        const blob = new Blob([capture.content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `grab-${capture.id}.txt`;
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
          title: capture.metadata?.title || 'Grab Capture',
          text: capture.type === 'text' ? capture.content : `Captured ${capture.type}`,
          url: capture.type === 'link' ? capture.content : undefined,
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
              {capture.metadata?.title || `${capture.type.charAt(0).toUpperCase() + capture.type.slice(1)} Capture`}
            </h2>
            <span className="text-sm text-gray-500">
              {new Date(capture.timestamp).toLocaleString()}
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
          {capture.type === 'screenshot' ? (
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
                <img
                  src={capture.content}
                  alt="Capture"
                  className="max-w-none transition-transform duration-200"
                  style={{
                    transform: `scale(${zoom}) rotate(${rotation}deg)`,
                    transformOrigin: 'center',
                  }}
                />
              </div>
            </div>
          ) : (
            <div className="h-full p-4 overflow-auto">
              <div className="bg-gray-50 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap">
                {capture.content}
              </div>
            </div>
          )}
        </div>

        {/* Metadata */}
        {capture.metadata && (
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50">
            <div className="flex flex-wrap gap-4 text-sm text-gray-600">
              {capture.metadata.app && (
                <span><strong>App:</strong> {capture.metadata.app}</span>
              )}
              {capture.metadata.url && (
                <span><strong>URL:</strong> {capture.metadata.url}</span>
              )}
              {capture.metadata.size && (
                <span><strong>Size:</strong> {capture.metadata.size}</span>
              )}
            </div>
          </div>
        )}

        {/* Tags */}
        {capture.tags && capture.tags.length > 0 && (
          <div className="px-4 py-2 border-t border-gray-200">
            <div className="flex items-center space-x-2">
              <Tag className="w-4 h-4 text-gray-500" />
              <div className="flex flex-wrap gap-1">
                {capture.tags.map((tag, index) => (
                  <span
                    key={index}
                    className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full"
                  >
                    {tag}
                  </span>
                ))}
              </div>
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