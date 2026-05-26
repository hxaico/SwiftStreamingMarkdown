//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import UIKit

extension URL {
  /// Whether this URL uses a copilot action scheme (`copilot-action://` or `ca://`), case-insensitive.
  ///
  /// Copilot action links trigger in-app actions rather than opening external URLs.
  var isCopilotActionLink: Bool {
    guard let scheme = scheme?.lowercased() else { return false }
    return scheme == "copilot-action" || scheme == "ca"
  }
}

/// The type of inline attachment, used to render different visual styles
enum AttachmentType: String, Codable {
  case citation
}

struct InlineAttachmentData: Codable {
  let type: AttachmentType
  let title: String
  let accessibilityLabel: String
  let url: URL

  /// Initialize from a citation link destination
  init?(
    linkDestination: String,
    fixURLDoubleEncoded: Bool = false
  ) {
    let url: URL?
    if fixURLDoubleEncoded {
      url = URL.fromMixedEncodingString(linkDestination)
    } else {
      url = URL(string: linkDestination)
    }

    guard let url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let title = components.queryItems?.first(
            where: { $0.name == InlineCitationConstants.citationTitleParam }
          )?.value,
          let accessibilityLabel = components.queryItems?.first(
            where: { $0.name == InlineCitationConstants.citationFullTitleParam }
          )?.value
    else {
      return nil
    }

    self.type = .citation
    self.url = url
    self.title = title
    self.accessibilityLabel = accessibilityLabel
  }
}
