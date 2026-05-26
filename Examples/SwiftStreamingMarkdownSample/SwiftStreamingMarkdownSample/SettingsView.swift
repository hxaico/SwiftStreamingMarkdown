//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage(SampleSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true

  var body: some View {
    Form {
      Toggle("Streamed", isOn: $preferStreamedMarkdown)
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}
