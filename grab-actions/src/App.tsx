import { useState, useEffect, useMemo, useCallback } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { listen } from "@tauri-apps/api/event";
import { CaptureFile, CaptureMetadata } from "./types";
import { Button } from "./components/ui/button";
import { Input } from "./components/ui/input";
import { Badge } from "./components/ui/badge";
import { formatRelativeTime, formatFileSize } from "./lib/utils";
import {
  Search,
  Grid,
  List,
  Monitor,
  Clipboard,
  Link,
  FileText,
  Calendar,
  MoreHorizontal,
  Copy,
  Trash2,
  X,
  Filter,
  Settings as SettingsIcon,
  ZoomIn,
  ZoomOut,
  RotateCw,
  Download,
} from "lucide-react";

type GrabType = "image" | "text" | "url" | "note";
type ViewMode = "grid" | "list";
type TimeFilter = "all" | "today" | "week";

const typeIcons = {
  image: Monitor,
  text: Clipboard,
  url: Link,
  note: FileText,
};

const typeColors = {
  image: "from-blue-500/12 to-cyan-600/12 border-blue-400/12 text-blue-300/80",
  text: "from-emerald-500/12 to-green-600/12 border-emerald-400/12 text-emerald-300/80",
  url: "from-purple-500/12 to-violet-600/12 border-purple-400/12 text-purple-300/80",
  note: "from-orange-500/12 to-amber-600/12 border-orange-400/12 text-orange-300/80",
};

function App() {
  const [captures, setCaptures] = useState<CaptureFile[]>([]);
  const [selectedCapture, setSelectedCapture] = useState<CaptureFile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [, setSelectedMetadata] = useState<CaptureMetadata | null>(null);
  const [selectedTextContent, setSelectedTextContent] = useState<string>('');
  const [showSettings, setShowSettings] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [viewMode, setViewMode] = useState<ViewMode>("list");
  const [typeFilter, setTypeFilter] = useState<GrabType | "all">("all");
  const [timeFilter, setTimeFilter] = useState<TimeFilter>("all");
  const [imageData, setImageData] = useState<string>('');
  const [imageLoading, setImageLoading] = useState(false);
  const [imageError, setImageError] = useState<string>('');
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [thumbnailCache, setThumbnailCache] = useState<Record<string, string>>({});
  const [clipboardOverlay, setClipboardOverlay] = useState<{
    show: boolean;
    content: string;
    type: 'text' | 'url' | 'code';
    timestamp: number;
  }>({
    show: false,
    content: '',
    type: 'text',
    timestamp: 0,
  });

  useEffect(() => {
    loadCaptures();
    
    // Listen for capture ID events from Tauri
    const unlisten = listen('capture-id', (event) => {
      const captureId = event.payload as string;
      handleDeepLinkCapture(captureId);
    });

    return () => {
      unlisten.then(fn => fn());
    };
  }, []);

  // Clipboard monitoring via file system
  useEffect(() => {
    let lastEventTimestamp = 0;
    
    const checkClipboardFile = async () => {
      try {
        // Call the Tauri backend to check for clipboard events
        const clipboardEvent = await invoke<any>('check_clipboard_event');
        
        if (clipboardEvent && clipboardEvent.timestamp > lastEventTimestamp) {
          lastEventTimestamp = clipboardEvent.timestamp;
          
          setClipboardOverlay({
            show: true,
            content: clipboardEvent.content,
            type: clipboardEvent.type as 'text' | 'url' | 'code',
            timestamp: clipboardEvent.timestamp,
          });
          
          // Auto-hide after 4 seconds
          setTimeout(() => {
            setClipboardOverlay(prev => ({ ...prev, show: false }));
          }, 4000);
        }
      } catch (error) {
        // File might not exist or be accessible
        console.log('Clipboard file monitoring error:', error);
      }
    };

    // Check clipboard file every 500ms
    const interval = setInterval(checkClipboardFile, 500);
    
    return () => clearInterval(interval);
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
      } else if (e.key === 'F12' || (e.metaKey && e.altKey && e.key === 'i')) {
        // Open DevTools with F12 or Cmd+Option+I
        // In debug builds, this will work if DevTools are enabled
        console.log('DevTools shortcut pressed - F12 or Cmd+Option+I should open DevTools');
        // Right-click → Inspect Element to open DevTools in debug builds
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

  const loadImageData = async () => {
    if (!selectedCapture || selectedCapture.capture_type !== 'image') return;
    
    try {
      setImageLoading(true);
      setImageError('');
      const base64Data = await invoke<string>('get_image_content', { filename: selectedCapture.name });
      const extension = selectedCapture.name.split('.').pop()?.toLowerCase() || 'png';
      const mimeType = extension === 'jpg' || extension === 'jpeg' ? 'image/jpeg' : `image/${extension}`;
      const dataUrl = `data:${mimeType};base64,${base64Data}`;
      setImageData(dataUrl);
    } catch (error) {
      setImageError(`Failed to load image: ${error}`);
    } finally {
      setImageLoading(false);
    }
  };

  const loadThumbnail = async (filename: string) => {
    if (thumbnailCache[filename]) return thumbnailCache[filename];
    
    try {
      const base64Data = await invoke<string>('get_image_content', { filename });
      const extension = filename.split('.').pop()?.toLowerCase() || 'png';
      const mimeType = extension === 'jpg' || extension === 'jpeg' ? 'image/jpeg' : `image/${extension}`;
      const dataUrl = `data:${mimeType};base64,${base64Data}`;
      
      setThumbnailCache(prev => ({ ...prev, [filename]: dataUrl }));
      return dataUrl;
    } catch (error) {
      console.error('Failed to load thumbnail:', error);
      return null;
    }
  };

  const handleDeepLinkCapture = useCallback((captureId: string) => {
    // Find the capture by ID (assuming capture ID is part of the filename)
    const targetCapture = captures.find(capture => 
      capture.name.includes(captureId) || 
      capture.metadata?.id === captureId
    );
    
    if (targetCapture) {
      setSelectedCapture(targetCapture);
      console.log('Command line argument opened capture:', captureId);
    } else {
      console.warn('Capture not found for command line argument:', captureId);
      // Optionally show a notification or error message
    }
  }, [captures]);

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
      const matchesSearch =
        capture.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        selectedTextContent.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesType = typeFilter === "all" || capture.capture_type === typeFilter;

      const captureDate = new Date(capture.modified * 1000);
      const matchesTime =
        timeFilter === "all" ||
        (timeFilter === "today" && captureDate > new Date(Date.now() - 86400000)) ||
        (timeFilter === "week" && captureDate > new Date(Date.now() - 604800000));

      return matchesSearch && matchesType && matchesTime;
    });
  }, [captures, searchQuery, typeFilter, timeFilter, selectedTextContent]);

  const handleCopy = async (capture: CaptureFile) => {
    try {
      if (capture.capture_type === 'image') {
        await invoke('copy_image_to_clipboard', { filename: capture.name });
      } else {
        await navigator.clipboard.writeText(selectedTextContent);
      }
    } catch (error) {
      console.error('Failed to copy:', error);
    }
  };

  const EmptyState = () => (
    <div className="flex flex-col items-center justify-center h-96 text-center">
      <div className="text-4xl mb-4 opacity-30 font-mono">-‿¬</div>
      <h3 className="text-sm font-mono text-white/60 mb-2">nothing captured yet</h3>
      <p className="text-xs text-white/30 max-w-md leading-relaxed font-mono">
        start capturing. screenshots, urls, clipboard content will appear here.
      </p>
    </div>
  );

  const ThumbnailImage = ({ capture, className = "w-full h-24" }: { capture: CaptureFile; className?: string }) => {
    const [thumbnailUrl, setThumbnailUrl] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);

    useEffect(() => {
      if (capture.capture_type === 'image') {
        const loadThumb = async () => {
          setLoading(true);
          try {
            const url = await loadThumbnail(capture.name);
            if (url) {
              setThumbnailUrl(url);
            } else {
              setError(true);
            }
          } catch (err) {
            setError(true);
          } finally {
            setLoading(false);
          }
        };
        loadThumb();
      } else {
        setLoading(false);
      }
    }, [capture.name, capture.capture_type]);

    if (capture.capture_type !== 'image') {
      const IconComponent = typeIcons[capture.capture_type as GrabType] || Monitor;
      const typeColor = typeColors[capture.capture_type as GrabType] || typeColors.image;
      return (
        <div className={`${className} bg-gradient-to-br ${typeColor} backdrop-blur-sm rounded flex items-center justify-center shadow-sm`}>
          <IconComponent className="w-6 h-6" />
        </div>
      );
    }

    if (loading) {
      return (
        <div className={`${className} bg-white/[0.03] backdrop-blur-sm rounded flex items-center justify-center shadow-sm`}>
          <div className="w-4 h-4 border-2 border-white/20 border-t-white/60 rounded-full animate-spin"></div>
        </div>
      );
    }

    if (error || !thumbnailUrl) {
      const IconComponent = Monitor;
      const typeColor = typeColors.image;
      return (
        <div className={`${className} bg-gradient-to-br ${typeColor} backdrop-blur-sm rounded flex items-center justify-center shadow-sm`}>
          <IconComponent className="w-6 h-6" />
        </div>
      );
    }

    return (
      <img
        src={thumbnailUrl}
        alt={capture.name}
        className={`${className} object-cover rounded border border-white/[0.04] shadow-sm`}
      />
    );
  };

  const GrabCard = ({ grab }: { grab: CaptureFile }) => {
    const IconComponent = typeIcons[grab.capture_type as GrabType] || Monitor;
    const typeColor = typeColors[grab.capture_type as GrabType] || typeColors.image;

    if (viewMode === "list") {
      return (
        <div
          className="group relative bg-white/[0.015] hover:bg-white/[0.03] backdrop-blur-xl border border-white/[0.04] hover:border-white/[0.08] rounded-lg transition-all duration-150 cursor-pointer overflow-hidden"
          onClick={() => setSelectedCapture(grab)}
        >
          <div className="flex items-center gap-3 p-3">
            <div className="relative flex-shrink-0">
              <div className="w-20 h-12 rounded overflow-hidden">
                <ThumbnailImage capture={grab} className="w-20 h-12" />
              </div>
              <div className="absolute -top-0.5 -right-0.5">
                <div
                  className={`w-3 h-3 bg-gradient-to-br ${typeColor} backdrop-blur-sm rounded-full flex items-center justify-center border border-white/[0.08]`}
                >
                  <IconComponent className="w-1.5 h-1.5" />
                </div>
              </div>
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2 mb-1">
                <h3 className="font-mono text-white/80 text-xs truncate font-extralight">{grab.name}</h3>
                <div className="flex items-center gap-1.5 text-xs text-white/25 font-mono font-thin">
                  <span>{formatRelativeTime(new Date(grab.modified * 1000))}</span>
                  <span className="text-white/15">·</span>
                  <span>{formatFileSize(grab.size)}</span>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <Badge className="bg-white/[0.03] text-white/50 border-white/[0.06] text-xs px-1.5 py-0 font-mono font-thin h-4">
                  {grab.capture_type}
                </Badge>

                <Button
                  variant="ghost"
                  size="sm"
                  className="opacity-0 group-hover:opacity-100 text-white/30 hover:text-white/60 hover:bg-white/[0.03] transition-all duration-150 h-5 w-5 p-0"
                  onClick={(e) => {
                    e.stopPropagation();
                  }}
                >
                  <MoreHorizontal className="w-2.5 h-2.5" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div
        className="group relative bg-white/[0.015] hover:bg-white/[0.03] backdrop-blur-xl border border-white/[0.04] hover:border-white/[0.08] rounded-lg transition-all duration-150 cursor-pointer overflow-hidden p-3"
        onClick={() => setSelectedCapture(grab)}
      >
        <div className="relative mb-2">
          <div className="w-full h-24 rounded overflow-hidden">
            <ThumbnailImage capture={grab} />
          </div>
          <div className="absolute top-1 right-1">
            <Badge className="bg-black/15 backdrop-blur-xl text-white/70 border-white/[0.08] text-xs font-mono font-thin px-1.5 py-0 h-4">
              {grab.capture_type}
            </Badge>
          </div>
        </div>

        <div className="relative">
          <h3 className="font-mono text-white/80 text-xs mb-1.5 truncate font-extralight">{grab.name}</h3>
          <div className="flex items-center justify-between gap-1.5">
            <div className="flex items-center gap-1.5 text-xs text-white/25 font-mono font-thin">
              <span>{formatRelativeTime(new Date(grab.modified * 1000))}</span>
              <span className="text-white/15">·</span>
              <span>{formatFileSize(grab.size)}</span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              className="opacity-0 group-hover:opacity-100 text-white/30 hover:text-white/60 hover:bg-white/[0.03] transition-all duration-150 h-5 w-5 p-0"
              onClick={(e) => {
                e.stopPropagation();
              }}
            >
              <MoreHorizontal className="w-2.5 h-2.5" />
            </Button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-gray-950 to-black text-white font-mono">
      {/* Header */}
      <header className="sticky top-0 z-20 bg-black/15 backdrop-blur-2xl border-b border-white/[0.03]">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <h1 className="text-lg font-mono bg-gradient-to-r from-white to-white/50 bg-clip-text text-transparent tracking-tight font-extralight">
                grab
              </h1>
            </div>

            <div className="flex items-center gap-2">
              <div className="flex bg-white/[0.03] backdrop-blur-xl rounded p-0.5 border border-white/[0.04]">
                <Button
                  variant={viewMode === "grid" ? "secondary" : "ghost"}
                  size="sm"
                  onClick={() => setViewMode("grid")}
                  className="text-white/50 hover:text-white/80 h-6 px-2 data-[state=on]:bg-white/[0.06] data-[state=on]:text-white font-mono"
                >
                  <Grid className="w-3 h-3" />
                </Button>
                <Button
                  variant={viewMode === "list" ? "secondary" : "ghost"}
                  size="sm"
                  onClick={() => setViewMode("list")}
                  className="text-white/50 hover:text-white/80 h-6 px-2 data-[state=on]:bg-white/[0.06] data-[state=on]:text-white font-mono"
                >
                  <List className="w-3 h-3" />
                </Button>
              </div>
              
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowSettings(true)}
                className="text-white/50 hover:text-white/80 h-8 px-3 font-mono"
              >
                <SettingsIcon className="w-3 h-3" />
              </Button>
            </div>
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-3 h-3 text-white/25" />
            <Input
              placeholder="search grabs..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="h-8 pl-8 pr-3 text-xs font-mono font-thin"
            />
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar Filters */}
        <aside className="w-48 p-4 bg-white/[0.005] backdrop-blur-xl border-r border-white/[0.03]">
          <div className="space-y-6">
            <div>
              <h3 className="text-xs font-mono text-white/40 mb-3 flex items-center gap-1.5 uppercase tracking-wider font-thin">
                <Filter className="w-2.5 h-2.5" />
                type
              </h3>
              <div className="space-y-0.5">
                {[
                  { key: "all", label: "all", count: captures.length },
                  { key: "image", label: "image", count: captures.filter((g) => g.capture_type === "image").length },
                  { key: "text", label: "text", count: captures.filter((g) => g.capture_type === "text").length },
                  { key: "url", label: "url", count: captures.filter((g) => g.capture_type === "url").length },
                  { key: "note", label: "note", count: captures.filter((g) => g.capture_type === "note").length },
                ].map((filter) => (
                  <button
                    key={filter.key}
                    onClick={() => setTypeFilter(filter.key as GrabType | "all")}
                    className={`
                      w-full flex items-center justify-between px-2 py-1.5 rounded text-xs transition-all duration-150 font-mono font-thin
                      ${
                        typeFilter === filter.key
                          ? "bg-white/[0.04] text-white/80 border border-white/[0.06]"
                          : "text-white/40 hover:text-white/70 hover:bg-white/[0.015]"
                      }
                    `}
                  >
                    <span>{filter.label}</span>
                    <Badge className="bg-white/[0.03] text-white/30 text-xs font-mono font-thin border-0 px-1 h-3">
                      {filter.count}
                    </Badge>
                  </button>
                ))}
              </div>
            </div>

            <div>
              <h3 className="text-xs font-mono text-white/40 mb-3 flex items-center gap-1.5 uppercase tracking-wider font-thin">
                <Calendar className="w-2.5 h-2.5" />
                time
              </h3>
              <div className="space-y-0.5">
                {[
                  { key: "all", label: "all time" },
                  { key: "today", label: "today" },
                  { key: "week", label: "last 7d" },
                ].map((filter) => (
                  <button
                    key={filter.key}
                    onClick={() => setTimeFilter(filter.key as TimeFilter)}
                    className={`
                      w-full flex items-center px-2 py-1.5 rounded text-xs transition-all duration-150 font-mono font-thin
                      ${
                        timeFilter === filter.key
                          ? "bg-white/[0.04] text-white/80 border border-white/[0.06]"
                          : "text-white/40 hover:text-white/70 hover:bg-white/[0.015]"
                      }
                    `}
                  >
                    {filter.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-6">
          {loading && (
            <div className="flex items-center justify-center h-96">
              <div className="text-white/40 font-mono text-sm">loading captures...</div>
            </div>
          )}
          
          {error && (
            <div className="flex items-center justify-center h-96">
              <div className="text-center">
                <div className="text-red-400 text-sm mb-2 font-mono">error loading captures</div>
                <div className="text-white/40 text-xs font-mono mb-4">{error}</div>
                <Button onClick={loadCaptures} variant="secondary" size="sm">
                  try again
                </Button>
              </div>
            </div>
          )}
          
          {!loading && !error && filteredCaptures.length === 0 && <EmptyState />}
          
          {!loading && !error && filteredCaptures.length > 0 && (
            <>
              <div className="mb-6">
                <p className="text-xs text-white/30 font-mono font-thin">
                  {filteredCaptures.length} grab{filteredCaptures.length !== 1 ? "s" : ""} · most recent first
                </p>
              </div>

              <div
                className={
                  viewMode === "grid"
                    ? "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3"
                    : "space-y-1.5"
                }
              >
                {filteredCaptures.map((grab) => (
                  <GrabCard key={grab.name} grab={grab} />
                ))}
              </div>
            </>
          )}
        </main>
      </div>

      {/* Detail Modal */}
      {selectedCapture && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-2xl flex items-center justify-center p-6 z-50">
          <div className="bg-white/[0.03] backdrop-blur-2xl border border-white/[0.06] rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b border-white/[0.04]">
              <div className="flex items-center gap-3">
                <div
                  className={`w-6 h-6 rounded bg-gradient-to-br ${typeColors[selectedCapture.capture_type as GrabType] || typeColors.image} flex items-center justify-center`}
                >
                  {(() => {
                    const IconComponent = typeIcons[selectedCapture.capture_type as GrabType] || Monitor;
                    return <IconComponent className="w-3 h-3" />;
                  })()}
                </div>
                <h2 className="text-sm font-mono text-white/80 font-extralight">{selectedCapture.name}</h2>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedCapture(null)}
                className="text-white/30 hover:text-white/70 hover:bg-white/[0.03] h-6 w-6 p-0"
              >
                <X className="w-3 h-3" />
              </Button>
            </div>

            <div className="p-4 overflow-y-auto max-h-[calc(90vh-120px)]">
              {selectedCapture.capture_type === 'image' ? (
                <div className="space-y-4">
                  {imageLoading && (
                    <div className="flex items-center justify-center h-48 bg-white/[0.015] rounded border border-white/[0.03]">
                      <div className="text-white/40 font-mono text-xs">loading image...</div>
                    </div>
                  )}
                  
                  {imageError && (
                    <div className="flex flex-col items-center justify-center h-48 bg-white/[0.015] rounded border border-white/[0.03] text-red-400">
                      <div className="font-mono text-xs mb-2">{imageError}</div>
                      <Button onClick={loadImageData} variant="secondary" size="sm">
                        retry
                      </Button>
                    </div>
                  )}
                  
                  {imageData && (
                    <div className="space-y-3">
                      <div className="flex items-center justify-center space-x-2 p-2 border-b border-white/[0.04] bg-white/[0.01]">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setZoom(Math.max(0.25, zoom - 0.25))}
                          className="text-white/50 hover:text-white/80 h-6 px-2"
                        >
                          <ZoomOut className="w-3 h-3" />
                        </Button>
                        <span className="text-xs text-white/60 min-w-[60px] text-center font-mono">
                          {Math.round(zoom * 100)}%
                        </span>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setZoom(Math.min(3, zoom + 0.25))}
                          className="text-white/50 hover:text-white/80 h-6 px-2"
                        >
                          <ZoomIn className="w-3 h-3" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setRotation((rotation + 90) % 360)}
                          className="text-white/50 hover:text-white/80 h-6 px-2"
                        >
                          <RotateCw className="w-3 h-3" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => { setZoom(1); setRotation(0); }}
                          className="text-white/50 hover:text-white/80 h-6 px-2 font-mono text-xs"
                        >
                          reset
                        </Button>
                      </div>
                      
                      <div className="flex items-center justify-center bg-white/[0.005] rounded border border-white/[0.03] p-4 min-h-[300px]">
                        <img
                          src={imageData}
                          alt="Capture"
                          className="max-w-none transition-transform duration-200"
                          style={{
                            transform: `scale(${zoom}) rotate(${rotation}deg)`,
                            transformOrigin: 'center',
                          }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <div className="bg-white/[0.015] backdrop-blur-xl border border-white/[0.03] rounded p-3 mb-4">
                  <pre className="text-xs text-white/70 font-mono whitespace-pre-wrap leading-relaxed font-thin">
                    {selectedTextContent}
                  </pre>
                </div>
              )}

              <div className="flex items-center justify-between text-xs text-white/30 mb-4 font-mono font-thin">
                <span>{formatRelativeTime(new Date(selectedCapture.modified * 1000))}</span>
                <span>{formatFileSize(selectedCapture.size)}</span>
              </div>

              <div className="flex gap-2">
                <Button 
                  onClick={() => handleCopy(selectedCapture)}
                  className="flex-1 bg-white/[0.06] hover:bg-white/[0.1] backdrop-blur-xl text-white border-white/[0.06] font-mono font-thin text-xs h-8"
                >
                  <Copy className="w-3 h-3 mr-1.5" />
                  copy
                </Button>
                <Button
                  variant="ghost"
                  className="flex-1 text-white/50 hover:text-white/80 hover:bg-white/[0.03] font-mono font-thin text-xs h-8"
                >
                  <Download className="w-3 h-3 mr-1.5" />
                  download
                </Button>
                <Button
                  variant="ghost"
                  className="text-red-400/70 hover:text-red-300 hover:bg-red-500/[0.03] font-mono font-thin text-xs h-8 px-3"
                  onClick={() => deleteCapture(selectedCapture)}
                >
                  <Trash2 className="w-3 h-3" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Settings Modal - Keep existing Settings component */}
      {showSettings && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-2xl flex items-center justify-center p-6 z-50">
          <div className="bg-white/[0.03] backdrop-blur-2xl border border-white/[0.06] rounded-xl shadow-2xl max-w-md w-full">
            <div className="flex items-center justify-between p-4 border-b border-white/[0.04]">
              <h2 className="text-sm font-mono text-white/80 font-extralight">settings</h2>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowSettings(false)}
                className="text-white/30 hover:text-white/70 hover:bg-white/[0.03] h-6 w-6 p-0"
              >
                <X className="w-3 h-3" />
              </Button>
            </div>
            <div className="p-4">
              <p className="text-xs text-white/40 font-mono">Settings panel coming soon...</p>
            </div>
          </div>
        </div>
      )}

      {/* Clipboard Overlay Animation */}
      {clipboardOverlay.show && (
        <div className="fixed top-6 right-6 z-50 pointer-events-none">
          <div className="animate-slide-in">
            <div className="bg-white/[0.08] backdrop-blur-2xl border border-white/[0.12] rounded-xl shadow-2xl max-w-sm">
              {/* Header */}
              <div className="flex items-center gap-2 p-3 pb-2">
                <div className="w-2 h-2 bg-emerald-400/80 rounded-full animate-pulse"></div>
                <span className="text-xs font-mono text-white/60 uppercase tracking-wider">
                  {clipboardOverlay.type === 'url' ? 'url copied' : 
                   clipboardOverlay.type === 'code' ? 'code copied' : 
                   'text copied'}
                </span>
                <div className="ml-auto">
                  {clipboardOverlay.type === 'url' ? (
                    <Link className="w-3 h-3 text-purple-300/80" />
                  ) : clipboardOverlay.type === 'code' ? (
                    <FileText className="w-3 h-3 text-orange-300/80" />
                  ) : (
                    <Clipboard className="w-3 h-3 text-emerald-300/80" />
                  )}
                </div>
              </div>

              {/* Content Preview */}
              <div className="px-3 pb-3">
                <div className="bg-black/20 rounded-lg p-2 border border-white/[0.05]">
                  <p className="text-xs font-mono text-white/70 leading-relaxed line-clamp-3">
                    {clipboardOverlay.content}
                  </p>
                </div>
              </div>

              {/* Progress Bar */}
              <div className="h-1 bg-white/[0.05] rounded-b-xl overflow-hidden">
                <div className="h-full bg-gradient-to-r from-emerald-400/60 to-cyan-400/60 rounded-full animate-shrink"></div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;