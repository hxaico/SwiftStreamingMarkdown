//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

struct ThematicBreakView: View {

  var body: some View {
    Divider()
      .foregroundColor(Color.Theme.Stroke.Default.Default300)
      .frame(height: 4)
      .padding([.top, .bottom], 8)
      .transition(.opacity)
  }
}
