//
//  Copyright © 2017-2023 Pavel Sharanda. All rights reserved.
//

import Foundation

public extension String {
    func style(tags: [String: TagTuning]) -> AttributedStringBuilder {
        return AttributedStringBuilder(htmlString: self, tags: tags)
    }

    func styleBase(_ attributes: AttributesProvider) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self, baseAttributes: attributes)
    }

    func styleHashtags(_ attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).styleHashtags(attributes)
    }

    func styleMentions(_ attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).styleMentions(attributes)
    }

    func style(regex: String, options: NSRegularExpression.Options = [], attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).style(regex: regex, options: options, attributes: attributes)
    }

    func style(textCheckingTypes: NSTextCheckingResult.CheckingType, attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).style(textCheckingTypes: textCheckingTypes, attributes: attributes)
    }

    func stylePhoneNumbers(_ attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).stylePhoneNumbers(attributes)
    }

    func styleLinks(_ attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).styleLinks(attributes)
    }

    func style(range: Range<String.Index>, attributes: DetectionTuning) -> AttributedStringBuilder {
        return AttributedStringBuilder(string: self).style(range: range, attributes: attributes)
    }
}

// MARK: - Helper Methods

@available(iOS 13.0, macOS 10.15, *)
public extension String {
  /// Check if a given string contains HTML
  var containsHTML: Bool {
    let pattern = #"(<script(\s|\S)*?</script>)|(<style(\s|\S)*?</style>)|(<!--(\s|\S)*?-->)|(<!DOCTYPE(\s|\S)*?>)|(<\/?(\\s*html\s*>|html\s+.*>|body\s*>|body\s+.*>|meta\s*>|title\s*>|head\s*>|script\s*>|script\s\S*>|header>|footer>|nav\s*>|a\s*>|a\shref\s*=\s*.*>|p\s*>|hr\s*>|div\s*>|div\s+.*>|h1>|h2>|h3>|h4>|h5>|h6>|br>|br\/>|span>|b>|li>|ul>|u>|ol>|strong>|i>))"#
    
    let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    let range = NSRange(location: 0, length: self.utf16.count)
    
    return regex?.firstMatch(in: self, options: [], range: range) != nil
  }
  
  /// Convert given HTML string to NSAttributedString
  /// - Parameter fontSizeToUse: base text font size
  func toAttributedStringFromHTML(usingFontSize fontSizeToUse: CGFloat) -> NSAttributedString {
    let links = TagTuner {
#if os(iOS)
      Attrs().foregroundColor(.link).font(.systemFont(ofSize: fontSizeToUse)).link($0.tag.attributes["href"] ?? "")
#else
      Attrs().foregroundColor(.linkColor).font(.systemFont(ofSize: fontSizeToUse)).link($0.tag.attributes["href"] ?? "")
#endif
    }
    
    let htmlTextAttrib = self
      .style(tags: [
        "a":links,
        "b":Attrs().font(.boldSystemFont(ofSize: fontSizeToUse)),
        "u":Attrs().underlineStyle(.single)
      ])
      .styleBase(Attrs().font(.systemFont(ofSize: fontSizeToUse)))
      .attributedString
    
    return htmlTextAttrib
  }
}

@available(macOS 10.15, iOS 13.0, *)
public extension NSString {
  /// Check if a given string contains HTML
  @objc var doesContainHTML: Bool {
    return (self as String).containsHTML
  }
  
  /// Convert given HTML string to NSAttributedString
  /// - Parameter fontSizeToUse: base text font size
  @objc func convertToAttributedStringFromHTML(usingFontSize fontSizeToUse: CGFloat) -> NSAttributedString {
    // Convert NSString to String and call the String method
    return (self as String).toAttributedStringFromHTML(usingFontSize: fontSizeToUse)
  }
}
