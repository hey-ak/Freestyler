import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    
    var body: some View {
        Form {
            Section(header: Text("Metronome")) {
                Toggle("Enable Metronome", isOn: $settings.metronomeOn)
            }
            Section(header: Text("Countdown Length")) {
                Picker("Countdown", selection: $settings.countdownLength) {
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 