import SwiftUI

@main
struct CustomDragAndDropTestApp: App {
    var body: some Scene {
        WindowGroup {
            ReorderableForEachUser()
        }
    }
}
