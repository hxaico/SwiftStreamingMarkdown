//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit

public struct TextContextMenuItem {
  public let subtitle: String?
  public let handler: (String) -> Void
  public let onAppear: (() -> Void)?
  private let titleProvider: () -> String
  private let imageProvider: () -> UIImage?

  var resolvedTitle: String {
    titleProvider()
  }

  var resolvedImage: UIImage? {
    imageProvider()
  }

  public init(
    title: String,
    subtitle: String? = nil,
    image: UIImage? = nil,
    handler: @escaping (String) -> Void,
    onAppear: (() -> Void)? = nil
  ) {
    self.titleProvider = { title }
    self.imageProvider = { image }
    self.subtitle = subtitle
    self.handler = handler
    self.onAppear = onAppear
  }

  public init(
    titleProvider: @escaping () -> String,
    imageProvider: @escaping () -> UIImage?,
    handler: @escaping (String) -> Void
  ) {
    self.titleProvider = titleProvider
    self.imageProvider = imageProvider
    self.subtitle = nil
    self.handler = handler
    self.onAppear = nil
  }
}

public struct TextContextMenuGroup {
  public let title: String?
  public let image: UIImage?
  public let displayInline: Bool
  public let items: [TextContextMenuItem]

  public init(
    title: String?,
    image: UIImage?,
    displayInline: Bool,
    items: [TextContextMenuItem]
  ) {
    self.title = title
    self.image = image
    self.displayInline = displayInline
    self.items = items
  }
}

/// Configuration for the edit menu that appears on text selection.
public struct TextContextMenu {
  public let menuGroups: [TextContextMenuGroup]

  public init(menuGroups: [TextContextMenuGroup]) {
    self.menuGroups = menuGroups
  }

  public func buildUIMenu(textView: UITextView, selectedRange: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu {
    var customMenu: [UIMenu] = []

    let clampedRange = NSIntersectionRange(selectedRange, NSRange(location: 0, length: textView.attributedText.length))
    let selectedText = textView.attributedText.attributedSubstring(from: clampedRange).string
    for group in menuGroups {
      var groupActions: [UIAction] = []
      for item in group.items {
        let uiAction = UIAction(
          title: item.resolvedTitle,
          subtitle: item.subtitle,
          image: item.resolvedImage?.withRenderingMode(.alwaysTemplate),
        ) { _ in
          item.handler(selectedText)
        }
        groupActions.append(uiAction)
        item.onAppear?()
      }
      let submenu = UIMenu(
        title: group.title ?? "",
        image: group.image?.withRenderingMode(.alwaysTemplate),
        options: group.displayInline ? .displayInline : [],
        children: groupActions
      )
      customMenu.append(submenu)
    }

    // Combine: system suggested actions first, then custom actions
    let filteredSuggestedActions = suggestedActions.filter { menuItem in
      if let menuItem = menuItem as? UIMenu {
        return menuItem.identifier == .standardEdit
      }
      return false
    }
    return UIMenu(children: filteredSuggestedActions + customMenu)
  }
}
