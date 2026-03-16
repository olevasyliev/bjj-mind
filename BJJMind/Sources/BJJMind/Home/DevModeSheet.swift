#if DEBUG
import SwiftUI

struct DevModeSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Topic Progress") {
                    ForEach(["closed_guard", "guard_passing", "side_control_mount", "back_control"], id: \.self) { topic in
                        Button("Reset \(topic)") {
                            Task { await appState.devResetTopicProgress(topic) }
                        }
                    }
                }
                Section("Theory Cards") {
                    Button("Reset all theory cards seen") {
                        ["posture_defense", "guard_attacks", "sweeps", "guard_breaks",
                         "posture_in_guard", "kneeling_pass", "standing_pass", "open_guard_passing",
                         "side_control_defense", "side_control_attacks", "mount_transitions",
                         "mount_defense", "mount_attacks", "back_defense", "back_control_maintain",
                         "back_submissions", "back_combinations"].forEach { slug in
                            UserDefaults.standard.removeObject(forKey: "theory_seen_\(slug)")
                        }
                    }
                }
            }
            .navigationTitle("Dev Mode")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
