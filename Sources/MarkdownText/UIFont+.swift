//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit

extension UIFont {
  /// Creates a UIFont with the specified name and already scaled size, disabling contextual alternates.
  static func withContextualAlternatesDisabled(name: String, size: CGFloat) -> UIFont? {
    let baseDescriptor = UIFontDescriptor(name: name, size: size)

    // Add feature settings to disable contextual alternates
    let modifiedDescriptor = baseDescriptor.addingAttributes([
      UIFontDescriptor.AttributeName.featureSettings: [
        [
          UIFontDescriptor.FeatureKey.featureIdentifier: kContextualAlternatesType,
          UIFontDescriptor.FeatureKey.typeIdentifier: kContextualAlternatesOffSelector
        ]
      ]
    ])

    return UIFont(descriptor: modifiedDescriptor, size: size)
  }
}
