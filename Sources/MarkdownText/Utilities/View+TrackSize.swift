//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

/// A modifier that measures the view's rendered size and reports changes
/// via a closure, using a background `GeometryReader`.
struct TrackSizeModifier: ViewModifier {

  let onChange: (CGSize) -> Void

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear
            .hidden()
            .onAppear {
              onChange(proxy.size)
            }
            .onChange(of: proxy.size) { newSize in
              onChange(newSize)
            }
        }
      )
  }
}

public extension View {

  /// Measures the view's rendered size and reports it via the `onChange` closure.
  ///
  /// The closure fires on appear and whenever the size changes.
  ///
  /// ```swift
  /// myView
  ///   .onSizeChange { size in
  ///     viewModel.measuredSize = size
  ///   }
  /// ```
  func onSizeChange(perform onChange: @escaping (CGSize) -> Void) -> some View {
    modifier(TrackSizeModifier(onChange: onChange))
  }

  /// Measures the view's rendered height and reports it via the `onChange` closure.
  ///
  /// The closure fires on appear and whenever the height changes.
  ///
  /// ```swift
  /// myView
  ///   .onHeightChange { height in
  ///     viewModel.measuredHeight = height
  ///   }
  /// ```
  func onHeightChange(perform onChange: @escaping (CGFloat) -> Void) -> some View {
    onSizeChange { size in onChange(size.height) }
  }

  /// Measures the view's rendered width and reports it via the `onChange` closure.
  ///
  /// The closure fires on appear and whenever the width changes.
  ///
  /// ```swift
  /// myView
  ///   .onWidthChange { width in
  ///     viewModel.measuredWidth = width
  ///   }
  /// ```
  func onWidthChange(perform onChange: @escaping (CGFloat) -> Void) -> some View {
    onSizeChange { size in onChange(size.width) }
  }
}
