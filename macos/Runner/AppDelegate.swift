import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = mainFlutterWindow {
            // Start in fullscreen mode
            if let screenFrame = window.screen?.visibleFrame {
                window.setFrame(screenFrame, display: true)
            }

            // Allow resizing and minimizing after launch
            window.isMovableByWindowBackground = true
            window.sharingType = .none
            window.styleMask.insert([.resizable, .miniaturizable])
        }

        super.applicationDidFinishLaunching(aNotification)
    }

    // Handle reopening the window when the app icon is clicked
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = mainFlutterWindow, !flag {
            window.makeKeyAndOrderFront(self) // Reopen the window
        }
        return true
    }

    // Quit the app when the main window is closed (for a single-window app)
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // This quits the app when the window is closed
    }
}
