//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

/// Verbose markdown/LaTeX diagnostics for debugging render and preprocess issues.
public enum MarkdownDiagnosticsLogging {
  /// SAFETY: This flag is only modified during app bootstrap or debugging and is read-only
  /// during normal streaming operations. A benign data race on a boolean does not cause memory corruption.
  /// TODO: Replace with a thread-safe configuration mechanism or structured logs when available.
  nonisolated(unsafe) public static var isEnabled = false
}
