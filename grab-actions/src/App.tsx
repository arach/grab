import { useState, useEffect, useMemo, useCallback } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { convertFileSrc } from "@tauri-apps/api/tauri";
import { CaptureFile, CaptureTypeFilter, CaptureMetadata } from "./types";
import { Header } from "./components/Header";
import { CaptureGrid } from "./components/CaptureGrid";
import { ActionView } from "./components/ActionView";
import { LoadingSkeleton } from "./components/LoadingSkeleton";

function App() {
  const [captures, setCaptures] = useState<CaptureFile[]>([]);
  const [selectedCapture, setSelectedCapture] = useState<CaptureFile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedMetadata, setSelectedMetadata] = useState<CaptureMetadata | null>(null);
  const [selectedTextContent, setSelectedTextContent] = useState<string>('');
  const [filters, setFilters] = useState<CaptureTypeFilter>({
    screen: true,
    window: true,
    selection: true,
    clipboard: true,
  });

  useEffect(() => {
    loadCaptures();
  }, []);

  useEffect(() => {
    if (selectedCapture) {
      loadSelectedCaptureData();
    }
  }, [selectedCapture]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setSelectedCapture(null);
      } else if (selectedCapture && captures.length > 0) {
        const currentIndex = captures.findIndex(c => c.path === selectedCapture.path);
        if (e.key === 'ArrowLeft' && currentIndex > 0) {
          setSelectedCapture(captures[currentIndex - 1]);
        } else if (e.key === 'ArrowRight' && currentIndex < captures.length - 1) {
          setSelectedCapture(captures[currentIndex + 1]);
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedCapture, captures]);

  const loadCaptures = async () => {
    try {
      setLoading(true);
      setError(null);
      const capturesList = await invoke<CaptureFile[]>("list_captures");
      setCaptures(capturesList);
    } catch (err) {
      setError(err as string);
    } finally {
      setLoading(false);
    }
  };

  const deleteCapture = async (captureToDelete: CaptureFile) => {
    try {
      await invoke('delete_capture', { filename: captureToDelete.name });
      setCaptures(captures.filter(c => c.path !== captureToDelete.path));
      if (selectedCapture && selectedCapture.path === captureToDelete.path) {
        setSelectedCapture(null);
      }
    } catch (error) {
      console.error('Failed to delete capture:', error);
    }
  };

  const copyToClipboard = async (content: string) => {
    try {
      await navigator.clipboard.writeText(content);
    } catch (error) {
      console.error('Failed to copy to clipboard:', error);
    }
  };

  const loadSelectedCaptureData = async () => {
    if (!selectedCapture) return;

    try {
      if (selectedCapture.has_metadata) {
        const metadata = await invoke<CaptureMetadata>('get_capture_metadata', {
          filename: selectedCapture.name
        });
        setSelectedMetadata(metadata);
      } else {
        setSelectedMetadata(null);
      }

      if (selectedCapture.capture_type === 'text') {
        const content = await invoke<string>('get_text_content', {
          filename: selectedCapture.name
        });
        setSelectedTextContent(content);
      } else {
        setSelectedTextContent('');
      }
    } catch (error) {
      console.error('Failed to load capture data:', error);
    }
  };

  const filteredCaptures = useMemo(() => {
    return captures.filter(capture => {
      if (!capture.has_metadata) {
        if (capture.capture_type === 'text') {
          return filters.clipboard;
        }
        return filters.screen;
      }
      return true;
    });
  }, [captures, filters]);

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  };

  const formatDate = (timestamp: number): string => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-900">
      <Header
        onRefresh={loadCaptures}
        onFilterChange={setFilters}
        filters={filters}
        totalCaptures={filteredCaptures.length}
      />
      
      <div className="flex h-[calc(100vh-140px)]">
        {/* Captures Grid/List */}
        <div className="flex-1 overflow-auto">
          {loading && (
            <LoadingSkeleton />
          )}
          
          {error && (
            <div className="flex items-center justify-center h-full">
              <div className="text-center">
                <div className="text-red-400 text-lg mb-2">Error loading captures</div>
                <div className="text-white/60">{error}</div>
                <button
                  onClick={loadCaptures}
                  className="mt-4 px-4 py-2 bg-red-500/20 text-red-400 rounded-lg hover:bg-red-500/30 transition-colors"
                >
                  Try Again
                </button>
              </div>
            </div>
          )}
          
          {!loading && !error && (
            <CaptureGrid
              captures={filteredCaptures}
              onCaptureSelect={setSelectedCapture}
              selectedCapture={selectedCapture}
            />
          )}
        </div>

        {/* Action Panel */}
        {selectedCapture && (
          <ActionView
            capture={selectedCapture}
            metadata={selectedMetadata}
            textContent={selectedTextContent}
            onClose={() => setSelectedCapture(null)}
            onDelete={deleteCapture}
            onCopyToClipboard={copyToClipboard}
            formatDate={formatDate}
            formatFileSize={formatFileSize}
          />
        )}
      </div>
    </div>
  );
}

export default App;