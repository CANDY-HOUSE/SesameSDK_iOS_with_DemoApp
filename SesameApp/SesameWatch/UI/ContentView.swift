import SwiftUI

/// Device list and the selected device's page, swiped between as in the native Watch app.
struct ContentView: View {
    @EnvironmentObject private var devices: WatchDevices
    @State private var page = 1

    var body: some View {
        if devices.list.isEmpty {
            Text("Open Sesame on your iPhone to sync your devices")
                .font(.headline)
                .multilineTextAlignment(.center)
        } else {
            TabView(selection: $page) {
                DeviceListView { id in
                    devices.select(id)
                    page = 1
                }
                .tag(0)
                if let item = devices.list.first(where: { $0.id == devices.selectedId }) {
                    DeviceView(item: item)
                        .id(item.id)
                        .tag(1)
                }
            }
            .tabViewStyle(.page)
        }
    }
}

struct DeviceListView: View {
    @EnvironmentObject private var devices: WatchDevices
    let onSelect: (String) -> Void

    var body: some View {
        List(devices.list) { item in
            Button {
                onSelect(item.id)
            } label: {
                HStack {
                    Image("Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.sesameLightGray, lineWidth: item.id == devices.selectedId ? 2 : 0))
                    Text(item.name)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(height: 70)
        }
    }
}
