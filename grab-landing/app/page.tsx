import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  Terminal,
  Zap,
  Copy,
  ImageIcon,
  MessageSquare,
  ArrowRight,
  Download,
  Github,
  Clock,
  Workflow,
} from "lucide-react"

export default function GrabLandingPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Navigation */}
      <nav className="border-b border-gray-800 bg-gray-950/50 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-blue-500 rounded-md flex items-center justify-center">
                <Terminal className="w-4 h-4 text-black" />
              </div>
              <span className="font-mono font-bold text-xl">Grab</span>
            </div>
            <div className="flex items-center gap-6">
              <a href="#features" className="text-gray-400 hover:text-white font-mono text-sm transition-colors">
                Features
              </a>
              <a href="#demo" className="text-gray-400 hover:text-white font-mono text-sm transition-colors">
                Demo
              </a>
              <Button size="sm" className="bg-white text-black hover:bg-gray-200 font-mono">
                Download
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-20 pb-16 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 bg-gray-900 border border-gray-800 rounded-full px-4 py-2 mb-8">
            <Zap className="w-4 h-4 text-yellow-400" />
            <span className="font-mono text-sm text-gray-300">Supercharge your LLM workflows</span>
          </div>

          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-mono font-bold mb-6 leading-tight">
            Context at your
            <br />
            <span className="bg-gradient-to-r from-green-400 via-blue-500 to-purple-600 bg-clip-text text-transparent">
              cursor
            </span>
          </h1>

          <p className="text-xl text-gray-400 mb-8 max-w-3xl mx-auto leading-relaxed">
            Grab instantly surfaces your last prompts, logs, and images right where you&apos;re working. No more context
            switching. No more lost clipboard history. Just pure workflow velocity.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
            <Button size="lg" className="bg-white text-black hover:bg-gray-200 font-mono px-8 py-3">
              <Download className="w-4 h-4 mr-2" />
              Download for macOS
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="border-gray-700 text-white hover:bg-gray-900 font-mono px-8 py-3 bg-transparent"
            >
              <Github className="w-4 h-4 mr-2" />
              View on GitHub
            </Button>
          </div>

          <div className="text-center">
            <p className="font-mono text-sm text-gray-500 mb-2">⌘+V to invoke anywhere</p>
            <div className="inline-flex items-center gap-1 text-xs text-gray-600 font-mono">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span>Native macOS app • Always available</span>
            </div>
          </div>
        </div>
      </section>

      {/* Demo Section */}
      <section id="demo" className="py-16 px-4 sm:px-6 lg:px-8 bg-gray-950/30">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-mono font-bold mb-4">See it in action</h2>
            <p className="text-gray-400 font-mono text-sm">Press ⌘+V anywhere to summon your context</p>
          </div>

          <div className="relative max-w-5xl mx-auto">
            <div className="absolute inset-0 bg-gradient-to-r from-green-400/20 via-blue-500/20 to-purple-600/20 blur-3xl"></div>
            <Card className="relative bg-gray-950 border-gray-800 shadow-2xl overflow-hidden">
              {/* Mock Terminal Header */}
              <div className="border-b border-gray-800 px-4 py-3 bg-gray-900">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-red-500"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                  <div className="w-3 h-3 rounded-full bg-green-500"></div>
                  <span className="ml-3 text-gray-400 font-mono text-sm">grab-nano-pastebin</span>
                </div>
              </div>

              {/* Mock Content Grid */}
              <div className="grid grid-cols-3 divide-x divide-gray-800 h-80">
                <div className="p-4">
                  <div className="flex items-center gap-2 mb-4">
                    <Terminal className="w-4 h-4 text-green-400" />
                    <span className="text-green-400 font-mono text-xs">logs</span>
                  </div>
                  <div className="space-y-2">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="bg-gray-900 border border-gray-800 rounded p-2">
                        <div className="text-xs font-mono text-gray-400 mb-1">#{i}</div>
                        <div className="text-xs font-mono text-gray-300 line-clamp-2">
                          {i === 1 && "ERROR: Database connection failed"}
                          {i === 2 && "INFO: Server started on port 3000"}
                          {i === 3 && "WARN: Deprecated API endpoint"}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="p-4">
                  <div className="flex items-center gap-2 mb-4">
                    <ImageIcon className="w-4 h-4 text-blue-400" />
                    <span className="text-blue-400 font-mono text-xs">images</span>
                  </div>
                  <div className="space-y-2">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="bg-gray-900 border border-gray-800 rounded p-2">
                        <div className="text-xs font-mono text-gray-400 mb-1">#{i}</div>
                        <div className="w-full h-12 bg-gray-800 rounded border border-gray-700 mb-1"></div>
                        <div className="text-xs font-mono text-gray-400 truncate">
                          {i === 1 && "Dashboard screenshot"}
                          {i === 2 && "UI mockup design"}
                          {i === 3 && "Error state capture"}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="p-4">
                  <div className="flex items-center gap-2 mb-4">
                    <MessageSquare className="w-4 h-4 text-purple-400" />
                    <span className="text-purple-400 font-mono text-xs">prompts</span>
                  </div>
                  <div className="space-y-2">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="bg-gray-900 border border-gray-800 rounded p-2">
                        <div className="text-xs font-mono text-gray-400 mb-1">#{i}</div>
                        <div className="text-xs font-mono text-gray-300 line-clamp-3">
                          {i === 1 && "Fix the authentication bug where users get logged out..."}
                          {i === 2 && "Create a responsive navigation component that works..."}
                          {i === 3 && "Optimize database queries in the user dashboard..."}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-16 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-mono font-bold mb-4">Built for modern workflows</h2>
            <p className="text-gray-400 text-lg max-w-2xl mx-auto">
              Every feature designed to eliminate friction in your AI-powered development process
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-green-500/10 rounded-lg flex items-center justify-center mb-4">
                <Zap className="w-6 h-6 text-green-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Instant Access</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Press ⌘+V anywhere on macOS to instantly access your clipboard history. No app switching, no delays.
              </p>
            </Card>

            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-blue-500/10 rounded-lg flex items-center justify-center mb-4">
                <Workflow className="w-6 h-6 text-blue-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Context Aware</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Automatically categorizes your clipboard into logs, images, and prompts. Find what you need instantly.
              </p>
            </Card>

            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-purple-500/10 rounded-lg flex items-center justify-center mb-4">
                <Copy className="w-6 h-6 text-purple-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Smart Previews</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Rich previews for code, images, and text. See exactly what you&apos;re copying before you paste.
              </p>
            </Card>

            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-yellow-500/10 rounded-lg flex items-center justify-center mb-4">
                <Clock className="w-6 h-6 text-yellow-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Timeline View</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                See when you copied each item with smart timestamps. Track your workflow chronologically.
              </p>
            </Card>

            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-red-500/10 rounded-lg flex items-center justify-center mb-4">
                <Terminal className="w-6 h-6 text-red-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Developer First</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Built by developers, for developers. Optimized for code, logs, and technical workflows.
              </p>
            </Card>

            <Card className="bg-gray-950 border-gray-800 p-6 hover:border-gray-700 transition-colors">
              <div className="w-12 h-12 bg-green-500/10 rounded-lg flex items-center justify-center mb-4">
                <ArrowRight className="w-6 h-6 text-green-400" />
              </div>
              <h3 className="font-mono font-bold text-lg mb-2">Native Performance</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Native macOS app with zero latency. Always running, never in your way.
              </p>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 px-4 sm:px-6 lg:px-8 bg-gradient-to-r from-gray-950 via-gray-900 to-gray-950">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl font-mono font-bold mb-4">Ready to accelerate your workflow?</h2>
          <p className="text-gray-400 text-lg mb-8 max-w-2xl mx-auto">
            Join developers who&apos;ve eliminated context switching from their AI workflows. Download Grab and experience
            the difference.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-8">
            <Button size="lg" className="bg-white text-black hover:bg-gray-200 font-mono px-8 py-4 text-lg">
              <Download className="w-5 h-5 mr-2" />
              Download for macOS
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="border-gray-700 text-white hover:bg-gray-900 font-mono px-8 py-4 text-lg bg-transparent"
            >
              <Github className="w-5 h-5 mr-2" />
              Star on GitHub
            </Button>
          </div>

          <div className="flex items-center justify-center gap-8 text-sm text-gray-500 font-mono">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Free & Open Source</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
              <span>macOS 12+</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
              <span>No Account Required</span>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-800 py-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="flex items-center gap-2 mb-4 md:mb-0">
              <div className="w-6 h-6 bg-gradient-to-br from-green-400 to-blue-500 rounded flex items-center justify-center">
                <Terminal className="w-3 h-3 text-black" />
              </div>
              <span className="font-mono font-bold">Grab</span>
              <span className="text-gray-600 font-mono text-sm ml-2">v1.0.0</span>
            </div>

            <div className="flex items-center gap-6 text-sm text-gray-500 font-mono">
              <a href="#" className="hover:text-white transition-colors">
                Privacy
              </a>
              <a href="#" className="hover:text-white transition-colors">
                Terms
              </a>
              <a href="#" className="hover:text-white transition-colors">
                Support
              </a>
              <a href="#" className="hover:text-white transition-colors">
                GitHub
              </a>
            </div>
          </div>

          <div className="mt-8 pt-8 border-t border-gray-800 text-center">
            <p className="text-gray-600 font-mono text-xs">Built for the future of AI-powered development workflows</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
