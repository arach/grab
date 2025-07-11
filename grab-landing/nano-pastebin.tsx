import { useState } from "react"
import { Copy, Terminal, ImageIcon, MessageSquare, Clock, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"

interface PastebinItem {
  id: string
  content: string
  timestamp: Date
  type: "log" | "image" | "prompt"
  preview?: string
}

const mockData: PastebinItem[] = [
  {
    id: "1",
    type: "log",
    content:
      "ERROR: Failed to connect to database\n  at Connection.connect (/app/db.js:42:15)\n  at async Server.start (/app/server.js:28:5)",
    timestamp: new Date(Date.now() - 1000 * 60 * 2),
  },
  {
    id: "2",
    type: "log",
    content:
      "INFO: Server started on port 3000\nINFO: Database connected successfully\nINFO: Ready to accept connections",
    timestamp: new Date(Date.now() - 1000 * 60 * 15),
  },
  {
    id: "3",
    type: "log",
    content:
      "WARN: Deprecated API endpoint /api/v1/users\nWARN: Please migrate to /api/v2/users\nWARN: Support ends in 30 days",
    timestamp: new Date(Date.now() - 1000 * 60 * 45),
  },
  {
    id: "4",
    type: "image",
    content: "/placeholder.svg?height=200&width=300",
    preview: "Screenshot of dashboard error",
    timestamp: new Date(Date.now() - 1000 * 60 * 5),
  },
  {
    id: "5",
    type: "image",
    content: "/placeholder.svg?height=150&width=250",
    preview: "UI mockup for login page",
    timestamp: new Date(Date.now() - 1000 * 60 * 20),
  },
  {
    id: "6",
    type: "image",
    content: "/placeholder.svg?height=180&width=320",
    preview: "Database schema diagram",
    timestamp: new Date(Date.now() - 1000 * 60 * 35),
  },
  {
    id: "7",
    type: "prompt",
    content:
      "Fix the authentication bug where users are getting logged out after 5 minutes. The session should last 24 hours by default.",
    timestamp: new Date(Date.now() - 1000 * 60 * 3),
  },
  {
    id: "8",
    type: "prompt",
    content:
      "Create a responsive navigation component that works on mobile and desktop. Use the existing design system colors.",
    timestamp: new Date(Date.now() - 1000 * 60 * 18),
  },
  {
    id: "9",
    type: "prompt",
    content: "Optimize the database queries in the user dashboard. Currently taking 2-3 seconds to load.",
    timestamp: new Date(Date.now() - 1000 * 60 * 40),
  },
]

export default function NanoPastebin() {
  const [copiedId, setCopiedId] = useState<string | null>(null)

  const handleCopy = async (content: string, id: string) => {
    await navigator.clipboard.writeText(content)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  const formatTime = (date: Date) => {
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const minutes = Math.floor(diff / (1000 * 60))

    if (minutes < 1) return "now"
    if (minutes < 60) return `${minutes}m`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}h`
    return `${Math.floor(hours / 24)}d`
  }

  const getIcon = (type: string) => {
    switch (type) {
      case "log":
        return <Terminal className="w-3 h-3 text-slate-50" />
      case "image":
        return <ImageIcon className="w-3 h-3 text-slate-100" />
      case "prompt":
        return <MessageSquare className="w-3 h-3 text-slate-200" />
      default:
        return <Terminal className="w-3 h-3" />
    }
  }

  const logs = mockData.filter((item) => item.type === "log").slice(0, 3)
  const images = mockData.filter((item) => item.type === "image").slice(0, 3)
  const prompts = mockData.filter((item) => item.type === "prompt").slice(0, 3)

  return (
    <div className="fixed inset-0 bg-black/20 backdrop-blur-sm flex items-center justify-center p-4">
      <Card className="bg-gray-950 border-gray-800 shadow-2xl max-w-6xl w-full max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="border-b border-gray-800 px-4 py-3">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-500"></div>
            <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
            <div className="w-3 h-3 rounded-full bg-green-500"></div>
            <span className="ml-3 text-gray-400 font-mono text-sm">nano-pastebin</span>
            <div className="ml-auto flex items-center gap-1 text-xs text-gray-500 font-mono">
              <Clock className="w-3 h-3" />
              <span>⌘+V to invoke</span>
            </div>
          </div>
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-3 divide-x divide-gray-800 h-[500px]">
          {/* Logs Column */}
          <div className="p-4 space-y-3 overflow-y-auto py-4">
            <div className="flex gap-2 mb-4 items-start mt-0 font-mono leading-3 font-extralight text-sm">
              <Terminal className="w-4 h-4 text-green-400" />
              <span className="text-green-400 font-mono font-light text-xs">logs</span>
              <span className="text-gray-600 font-mono text-xs">({logs.length})</span>
            </div>

            {logs.map((item, index) => (
              <div key={item.id} className="group relative">
                <div className="bg-gray-900 border border-gray-800 rounded-md p-3 hover:border-gray-700 transition-colors">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getIcon(item.type)}
                      <span className="text-gray-500 font-mono text-xs">#{index + 1}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-600 font-mono text-xs">{formatTime(item.timestamp)}</span>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={() => handleCopy(item.content, item.id)}
                      >
                        {copiedId === item.id ? (
                          <Check className="w-3 h-3 text-green-400" />
                        ) : (
                          <Copy className="w-3 h-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                  <pre className="text-xs font-mono text-gray-300 whitespace-pre-wrap line-clamp-4 leading-relaxed">
                    {item.content}
                  </pre>
                </div>
              </div>
            ))}
          </div>

          {/* Images Column */}
          <div className="p-4 space-y-3 overflow-y-auto">
            <div className="flex gap-2 mb-4 items-start mt-3 font-mono font-thin leading-3">
              <ImageIcon className="w-4 h-4 text-blue-400" />
              <span className="text-blue-400 font-mono font-light text-xs">images</span>
              <span className="text-gray-600 font-mono text-xs">({images.length})</span>
            </div>

            {images.map((item, index) => (
              <div key={item.id} className="group relative">
                <div className="bg-gray-900 border border-gray-800 rounded-md p-3 hover:border-gray-700 transition-colors">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getIcon(item.type)}
                      <span className="text-gray-500 font-mono text-xs">#{index + 1}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-600 font-mono text-xs">{formatTime(item.timestamp)}</span>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={() => handleCopy(item.content, item.id)}
                      >
                        {copiedId === item.id ? (
                          <Check className="w-3 h-3 text-green-400" />
                        ) : (
                          <Copy className="w-3 h-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <img
                      src={item.content || "/placeholder.svg"}
                      alt={item.preview || "Clipboard image"}
                      className="w-full h-20 object-cover rounded border border-gray-700"
                    />
                    {item.preview && <p className="text-xs font-mono text-gray-400 truncate">{item.preview}</p>}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Prompts Column */}
          <div className="p-4 space-y-3 overflow-y-auto py-4">
            <div className="flex items-center gap-2 mb-4">
              <MessageSquare className="w-4 h-4 text-purple-400" />
              <span className="text-purple-400 font-mono font-light text-xs">prompts</span>
              <span className="text-gray-600 font-mono text-xs">({prompts.length})</span>
            </div>

            {prompts.map((item, index) => (
              <div key={item.id} className="group relative">
                <div className="bg-gray-900 border border-gray-800 rounded-md p-3 hover:border-gray-700 transition-colors">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getIcon(item.type)}
                      <span className="text-gray-500 font-mono text-xs">#{index + 1}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-600 font-mono text-xs">{formatTime(item.timestamp)}</span>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={() => handleCopy(item.content, item.id)}
                      >
                        {copiedId === item.id ? (
                          <Check className="w-3 h-3 text-green-400" />
                        ) : (
                          <Copy className="w-3 h-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                  <p className="text-xs font-mono text-gray-300 line-clamp-4 leading-relaxed">{item.content}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Footer */}
        <div className="border-t border-gray-800 px-4 py-2">
          <div className="flex items-center justify-between text-xs font-mono text-gray-500">
            <span>ESC to close</span>
            <span>⌘+C to copy • ⌘+V to paste</span>
          </div>
        </div>
      </Card>
    </div>
  )
}
