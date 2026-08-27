import SwiftUI

struct ContentView: View {
    @State private var photos = PhotoStore()
    @State private var invocation = ClipInvocation()

    var body: some View {
        CardScreen(viewOnly: AppRuntime.isClip)
            .environment(photos)
            .environment(invocation)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                invocation.consume(activity)
            }
            .onOpenURL { url in
                invocation.consume(url)
            }
            .task {
                invocation.consumeLaunchURL()
            }
    }
}

#Preview {
    ContentView()
}
