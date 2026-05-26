//
//  Copyright © 2025 Microsoft. All rights reserved.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class CitationTests: XCTestCase {

  func testRemoveCitations() async {
    let input = """
    This is a [normal link](https://example.com) and this is a [citation](https://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1). More text.
    """
    let newString = await input.withoutCitationLinks()
    XCTAssertEqual(newString, "This is a [normal link](https://example.com) and this is a. More text.")
  }

  func testRemoveCitationsWithEncodedParentheses() async {
    // Test that citations with percent-encoded parentheses in the title are properly removed
    let input = """
    This is text with a [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](https://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Euronews%20%28English%29). More text.
    """
    let newString = await input.withoutCitationLinks()
    XCTAssertEqual(newString, "This is text with a. More text.")
  }

  func testRemoveCitationsWithEncodedSquareBrackets() async {
    // Test that citations with percent-encoded square brackets in the title are properly removed
    let input = """
    This is text with a [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](https://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Wikipedia%20%5Ben%5D). More text.
    """
    let newString = await input.withoutCitationLinks()
    XCTAssertEqual(newString, "This is text with a. More text.")
  }

  func testRemoveCitationsWithEncodedBackslash() async {
    // Test that citations with percent-encoded backslashes in the title are properly removed
    let input = """
    This is text with a [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](https://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Docs%5CTutorial). More text.
    """
    let newString = await input.withoutCitationLinks()
    XCTAssertEqual(newString, "This is text with a. More text.")
  }
}
