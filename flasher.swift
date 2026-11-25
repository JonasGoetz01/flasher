// flasher — flashes an image full screen for a split second at random intervals.
//
// Usage:
//   flasher <image-or-folder> [--min SEC] [--max SEC] [--duration MS] [--foreground]
//   flasher --stop
//   flasher --uninstall
//
// By default it detaches itself and keeps running in the background.

import AppKit
import Foundation

let pidFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("flasher.pid")
let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "tif", "bmp", "webp"]

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

func usage() -> Never {
    fail("""
    usage: flasher <image-or-folder> [--min SEC] [--max SEC] [--duration MS] [--foreground]
           flasher --stop
           flasher --uninstall

      --min SEC       shortest pause between flashes (default 60)
      --max SEC       longest pause between flashes  (default 600)
      --duration MS   how long the image stays visible (default 150)
      --foreground    don't detach, run in this terminal (Ctrl-C to quit)
      --stop          stop the running background instance
      --uninstall     stop flasher and delete this binary
    """)
}

func runningPid() -> pid_t? {
    guard let s = try? String(contentsOfFile: pidFile, encoding: .utf8),
          let pid = pid_t(s.trimmingCharacters(in: .whitespacesAndNewlines)),
          kill(pid, 0) == 0 else { return nil }
    return pid
}

// MARK: - Argument parsing

var args = Array(CommandLine.arguments.dropFirst())
var minSec = 60.0, maxSec = 600.0, durationMs = 150.0
var foreground = false
var source: String?

func stop() {
    if let pid = runningPid() {
        kill(pid, SIGTERM)
        try? FileManager.default.removeItem(atPath: pidFile)
        print("flasher stopped (pid \(pid))")
    } else {
        print("flasher is not running")
    }
}

if args.contains("--stop") {
    stop()
    exit(0)
}

if args.contains("--uninstall") {
    stop()
    let exe = Bundle.main.executableURL?.resolvingSymlinksInPath().path ?? CommandLine.arguments[0]
    do {
        try FileManager.default.removeItem(atPath: exe)
        print("removed \(exe)")
    } catch {
        fail("could not remove \(exe): \(error.localizedDescription)")
    }
    exit(0)
}

var i = 0
while i < args.count {
    let a = args[i]
    func next() -> Double {
        i += 1
        guard i < args.count, let v = Double(args[i]) else { usage() }
        return v
    }
    switch a {
    case "--min": minSec = next()
    case "--max": maxSec = next()
    case "--duration": durationMs = next()
    case "--foreground", "--child": foreground = true
    case "-h", "--help": usage()
    default:
        if a.hasPrefix("-") || source != nil { usage() }
        source = a
    }
    i += 1
}

guard let src = source else { usage() }
if minSec < 0 || maxSec < minSec || durationMs <= 0 { fail("invalid timing values") }

// Collect image files
let srcURL = URL(fileURLWithPath: (src as NSString).expandingTildeInPath).standardizedFileURL
var isDir: ObjCBool = false
guard FileManager.default.fileExists(atPath: srcURL.path, isDirectory: &isDir) else { fail("not found: \(src)") }
let imageURLs: [URL] = isDir.boolValue
    ? ((try? FileManager.default.contentsOfDirectory(at: srcURL, includingPropertiesForKeys: nil)) ?? [])
        .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
    : [srcURL]
if imageURLs.isEmpty { fail("no images found in \(src)") }
for u in imageURLs where NSImage(contentsOf: u) == nil { fail("cannot load image: \(u.path)") }

// MARK: - Detach into background

if !foreground {
    if let pid = runningPid() { fail("flasher already running (pid \(pid)). Use --stop first.") }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
    p.arguments = [srcURL.path, "--min", "\(minSec)", "--max", "\(maxSec)",
                   "--duration", "\(durationMs)", "--child"]
    p.standardInput = FileHandle.nullDevice
    p.standardOutput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    do { try p.run() } catch { fail("failed to start: \(error)") }
    try? "\(p.processIdentifier)".write(toFile: pidFile, atomically: true, encoding: .utf8)
    print("flasher running in background (pid \(p.processIdentifier)). Stop with: flasher --stop")
    exit(0)
}

signal(SIGHUP, SIG_IGN) // survive the terminal closing

// MARK: - Flashing

final class Flasher {
    var windows: [NSWindow] = []

    func scheduleNext() {
        let delay = Double.random(in: minSec...maxSec)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            flash()
            scheduleNext()
        }
    }

    func flash() {
        guard let url = imageURLs.randomElement(), let image = NSImage(contentsOf: url) else { return }
        windows = NSScreen.screens.map { screen in
            let w = NSPanel(contentRect: screen.frame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
            w.level = .screenSaver
            w.backgroundColor = .black
            w.isOpaque = true
            w.hasShadow = false
            w.ignoresMouseEvents = true
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            let view = NSImageView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.image = image
            view.imageScaling = .scaleProportionallyUpOrDown
            w.contentView = view
            w.setFrame(screen.frame, display: true)
            w.orderFrontRegardless()
            return w
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + durationMs / 1000) { [self] in
            windows.forEach { $0.orderOut(nil) }
            windows = []
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, never steals focus
let flasher = Flasher()
flasher.scheduleNext()
app.run()
