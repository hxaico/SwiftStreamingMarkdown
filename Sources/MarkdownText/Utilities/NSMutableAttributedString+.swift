//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

extension NSMutableAttributedString {
  public func removingAllOccurrences(of target: String) -> NSMutableAttributedString {
    while true {
      let range = (self.string as NSString).range(of: target)

      if range.location == NSNotFound {
        break
      }

      self.deleteCharacters(in: range)
    }
    return self
  }

  func toSwiftUIAttributedString() -> AttributedString {
    var result = AttributedString(self)

    // Example: Handle custom attributes manually if needed
    self.enumerateAttributes(in: NSRange(location: 0, length: self.length)) { attributes, range, _ in
      // Check for specific UIKit attributes that need special handling
      if let uiFont = attributes[.font] as? UIFont {
        // Apply equivalent SwiftUI attribute
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].font = Font(uiFont)
        }
      }

      if let uiColor = attributes[.foregroundColor] as? UIColor {
        // Apply equivalent SwiftUI attribute
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].foregroundColor = Color(uiColor: uiColor)
        }
      }

      if let uiColor = attributes[.backgroundColor] as? UIColor {
        // Apply equivalent SwiftUI attribute
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].backgroundColor = Color(uiColor: uiColor)
        }
      }

      if let uiColor = attributes[.underlineColor] as? UIColor {
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].uiKit.underlineColor = uiColor
        }
      }
      if let uiColor = attributes[.strikethroughColor] as? UIColor {
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].uiKit.strikethroughColor = uiColor
        }
      }

      if let underlineStyle = (attributes[.underlineStyle] as? NSNumber)?.intValue {
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].underlineStyle = NSUnderlineStyle(rawValue: underlineStyle)
        }
      }
      if let strikeStyle = (attributes[.strikethroughStyle] as? NSNumber)?.intValue {
        if let swiftUIRange = Range(range, in: result) {
          result[swiftUIRange].strikethroughStyle = NSUnderlineStyle(rawValue: strikeStyle)
        }
      }
    }

    return result
  }
}
