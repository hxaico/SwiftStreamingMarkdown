//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/// All typography styles used by this package.
public enum Typography: CaseIterable, Sendable {
  case extraLargeStrong
  case extraLargeStrongItalic
  case extraLarge
  case extraLargeItalic

  case largeStrong
  case largeStrongItalic
  case large
  case largeItalic

  case mediumStrong
  case mediumStrongItalic
  case medium
  case mediumItalic

  case baseStrong
  case baseStrongItalic
  case baseItalic
  case base

  case smallStrong
  case smallStrongItalic
  case small
  case smallItalic

  case extraSmallStrong
  case extraSmallStrongItalic
  case extraSmall
  case extraSmallItalic

  case citationDay
  case citationNight
  case code
  case tripleExtraSmallCustom450

  /// The UIFont instance of the typography.
  public var uiFont: UIFont {
    return switch self {
    case .citationDay: UIFonts.citationDay
    case .citationNight: UIFonts.citationNight
    case .tripleExtraSmallCustom450: UIFonts.tripleExtraSmallCustom450
    case .code: Self.systemMonospacedFont(size: 15.0, weight: .regular)

    case .extraLargeStrong: Self.systemFont(size: 28.0, weight: .semibold)
    case .extraLargeStrongItalic: Self.systemFont(size: 28.0, weight: .semibold, italic: true)
    case .extraLarge: Self.systemFont(size: 28.0, weight: .regular)
    case .extraLargeItalic: Self.systemFont(size: 28.0, weight: .regular, italic: true)

    case .largeStrong: Self.systemFont(size: 24.0, weight: .semibold)
    case .largeStrongItalic: Self.systemFont(size: 24.0, weight: .semibold, italic: true)
    case .large: Self.systemFont(size: 24.0, weight: .regular)
    case .largeItalic: Self.systemFont(size: 24.0, weight: .regular, italic: true)

    case .mediumStrong: Self.systemFont(size: 20.0, weight: .semibold)
    case .mediumStrongItalic: Self.systemFont(size: 20.0, weight: .semibold, italic: true)
    case .medium: Self.systemFont(size: 20.0, weight: .regular)
    case .mediumItalic: Self.systemFont(size: 20.0, weight: .regular, italic: true)

    case .baseStrong: Self.systemFont(size: 17.0, weight: .semibold)
    case .baseStrongItalic: Self.systemFont(size: 17.0, weight: .semibold, italic: true)
    case .baseItalic: Self.systemFont(size: 17.0, weight: .regular, italic: true)
    case .base: Self.systemFont(size: 17.0, weight: .regular)

    case .smallStrong: Self.systemFont(size: 15.0, weight: .semibold)
    case .smallStrongItalic: Self.systemFont(size: 15.0, weight: .semibold, italic: true)
    case .small: Self.systemFont(size: 15.0, weight: .regular)
    case .smallItalic: Self.systemFont(size: 15.0, weight: .regular, italic: true)

    case .extraSmallStrong: Self.systemFont(size: 14.0, weight: .semibold)
    case .extraSmallStrongItalic: Self.systemFont(size: 14.0, weight: .semibold, italic: true)
    case .extraSmall: Self.systemFont(size: 14.0, weight: .regular)
    case .extraSmallItalic: Self.systemFont(size: 14.0, weight: .regular, italic: true)
    }
  }

  private static func systemFont(size: CGFloat, weight: UIFont.Weight, italic: Bool = false) -> UIFont {
    let scaledSize = UIFontMetrics.default.scaledValue(for: size)
    let baseFont = UIFont.systemFont(ofSize: scaledSize, weight: weight)
    guard italic else {
      return baseFont
    }
    return baseFont.withItalicTrait()
  }

  private static func systemMonospacedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let scaledSize = UIFontMetrics.default.scaledValue(for: size)
    return UIFont.monospacedSystemFont(ofSize: scaledSize, weight: weight)
  }

  /// The SwiftUI `Font` instance of the typography.
  public var font: Font {
    return Font(uiFont)
  }

  /// Line height preferred by design system, may be different from the font's intrinsic line height.
  public var preferredLineHeight: CGFloat {
    return switch self {
    case .citationDay, .citationNight: 22.0
    case .code: 20.0
    case .tripleExtraSmallCustom450: 14.0

    case .extraLarge, .extraLargeStrong, .extraLargeItalic, .extraLargeStrongItalic: 32.0
    case .large, .largeStrong, .largeItalic, .largeStrongItalic: 32.0
    case .medium, .mediumStrong, .mediumItalic, .mediumStrongItalic: 26.0
    case .base, .baseStrong, .baseItalic, .baseStrongItalic: 26.0
    case .small, .smallStrong, .smallItalic, .smallStrongItalic: 20.0
    case .extraSmall, .extraSmallStrong, .extraSmallItalic, .extraSmallStrongItalic: 20.0
    }
  }

  public var preferredLetterSpacing: CGFloat {
    return switch self {
    case .code: -0.12
    case .extraLarge, .extraLargeStrong, .extraLargeItalic, .extraLargeStrongItalic: -0.28
    case .large, .largeStrong, .largeItalic, .largeStrongItalic: -0.24
    case .medium, .mediumStrong, .mediumItalic, .mediumStrongItalic: -0.2
    default: 0.0
    }
  }

  /// Returns the bold variant of the current typography.
  public var boldVariant: Typography {
    return switch self {
    case .extraLarge: .extraLargeStrong
    case .extraLargeItalic: .extraLargeStrongItalic

    case .large: .largeStrong
    case .largeItalic: .largeStrongItalic

    case .medium: .mediumStrong
    case .mediumItalic: .mediumStrongItalic

    case .base: .baseStrong
    case .baseItalic: .baseStrongItalic

    case .small: .smallStrong
    case .smallItalic: .smallStrongItalic

    case .extraSmall: .extraSmallStrong
    case .extraSmallItalic: .extraSmallStrongItalic

    case .extraLargeStrong, .extraLargeStrongItalic,
         .largeStrong, .largeStrongItalic,
         .mediumStrong, .mediumStrongItalic,
         .baseStrong, .baseStrongItalic,
         .smallStrong, .smallStrongItalic,
         .extraSmallStrong, .extraSmallStrongItalic,
         .citationDay, .citationNight, .code, .tripleExtraSmallCustom450: self
    }
  }

  /// Returns the italic variant of the current typography.
  public var italicVariant: Typography {
    return switch self {
    case .extraLarge: .extraLargeItalic
    case .extraLargeStrong: .extraLargeStrongItalic

    case .large: .largeItalic
    case .largeStrong: .largeStrongItalic

    case .medium: .mediumItalic
    case .mediumStrong: .mediumStrongItalic

    case .base: .baseItalic
    case .baseStrong: .baseStrongItalic

    case .small: .smallItalic
    case .smallStrong: .smallStrongItalic

    case .extraSmall: .extraSmallItalic
    case .extraSmallStrong: .extraSmallStrongItalic

    case .extraLargeItalic, .extraLargeStrongItalic,
         .largeItalic, .largeStrongItalic,
         .mediumItalic, .mediumStrongItalic,
         .baseItalic, .baseStrongItalic,
         .smallItalic, .smallStrongItalic,
         .extraSmallItalic, .extraSmallStrongItalic,
         .citationDay, .citationNight, .code, .tripleExtraSmallCustom450: self
    }
  }
}

private extension UIFont {
  func withItalicTrait() -> UIFont {
    let traits = fontDescriptor.symbolicTraits.union(.traitItalic)
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
      return self
    }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

extension View {

  /// Set both the font and the preferred line height if different from the font's line height.
  /// - Parameter font: The font
  /// - Returns: The modified view
  public func font(_ font: Typography) -> some View {
    self
      .font(font.font)
      .kerning(font.preferredLetterSpacing)
      .if(
        font.preferredLineHeight > font.uiFont.lineHeight,
        content: { $0.lineSpacing(font.preferredLineHeight - font.uiFont.lineHeight)})
  }
}
