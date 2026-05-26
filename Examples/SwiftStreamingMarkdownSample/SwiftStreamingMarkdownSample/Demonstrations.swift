//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

enum Demonstration: String, CaseIterable, Identifiable, Hashable {
  case multiParagraph = "Multi-paragraph"
  case tables = "Tables"
  case math = "Math"

  var id: String { rawValue }

  var subtitle: String {
    switch self {
    case .multiParagraph:
      "Excerpts from famous novels"
    case .tables:
      "Top 10 populous cities and basic info"
    case .math:
      "Top 10 most popular math equations"
    }
  }

  var fixtureFileName: String {
    switch self {
    case .multiParagraph: "multi-paragraph"
    case .tables: "tables"
    case .math: "math"
    }
  }
}
