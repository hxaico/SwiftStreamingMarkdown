//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Equatable

/// Bundled copy and download actions for a table, taking the raw markdown string.
@Equatable
public struct TableActions {
  @EquatableIgnoredUnsafeClosure public let onCopy: (String) -> Void
  @EquatableIgnoredUnsafeClosure public let onDownload: (String) -> Void

  public init(onCopy: @escaping (String) -> Void, onDownload: @escaping (String) -> Void) {
    self.onCopy = onCopy
    self.onDownload = onDownload
  }
}
