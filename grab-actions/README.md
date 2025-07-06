# Grab Actions

A modern desktop application for performing actions on your captured content (screenshots, text, links) from the Grab app.

## Features

- **View Captures**: Browse all your screenshots, text clips, and links
- **Search & Filter**: Find captures by type, date, or content
- **Action View**: Full-screen interface with zoom, rotation, and action controls
- **Export Options**: Copy to clipboard, download, or share captures
- **Tag Management**: View and organize captures by tags
- **Modern UI**: Clean, responsive interface built with React and Tailwind CSS

## Quick Start

1. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

2. **Or install manually**:
   ```bash
   # Install dependencies
   pnpm install  # or npm install
   
   # Start development
   pnpm tauri dev
   ```

## Prerequisites

- **Node.js** (v16 or higher)
- **Rust** (for Tauri)
- **pnpm** (recommended) or npm

### Installing Prerequisites

**Rust**:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**pnpm**:
```bash
npm install -g pnpm
```

## Available Commands

```bash
# Development
pnpm dev           # Start Vite dev server
pnpm tauri dev     # Start Tauri development with hot reload

# Building
pnpm build         # Build web assets
pnpm tauri build   # Build desktop app

# Code Quality
pnpm typecheck     # Run TypeScript checks
pnpm lint          # Run ESLint
```

## Project Structure

```
src/
├── components/
│   ├── ActionView.tsx       # Full-screen action interface
│   ├── LoadingSkeleton.tsx # Loading states
│   └── ...
├── hooks/
├── types/
├── utils/
└── App.tsx
```

## Tech Stack

- **Frontend**: React 18 + TypeScript
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **Desktop**: Tauri
- **Build**: Vite

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

MIT License - see LICENSE file for details