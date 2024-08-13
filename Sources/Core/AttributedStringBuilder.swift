//
//  Copyright © 2017-2023 Pavel Sharanda. All rights reserved.
//

import Foundation

public final class AttributedStringBuilder {
    public let string: String
    public private(set) var baseAttributes: AttributesProvider

    public struct AttributesRangeInfo {
        public let attributes: AttributesProvider
        public let range: Range<String.Index>
        public let level: Int

        public init(attributes: AttributesProvider, range: Range<String.Index>, level: Int) {
            self.attributes = attributes
            self.range = range
            self.level = level
        }
    }

    private var currentMaxLevel: Int = 0

    public private(set) var attributesRangeInfo: [AttributesRangeInfo]

    public init(string: String, attributesRangeInfo: [AttributesRangeInfo], baseAttributes: AttributesProvider) {
        self.string = string
        self.attributesRangeInfo = attributesRangeInfo
        self.baseAttributes = baseAttributes
    }

    public convenience init(string: String, baseAttributes: AttributesProvider = [NSAttributedString.Key: Any]()) {
        self.init(string: string, attributesRangeInfo: [], baseAttributes: baseAttributes)
    }

    public convenience init(attributedString: NSAttributedString, baseAttributes: AttributesProvider = [NSAttributedString.Key: Any]()) {
        let string = attributedString.string
        var info: [AttributesRangeInfo] = []

        attributedString.enumerateAttributes(in: NSMakeRange(0, attributedString.length), options: []) { attributes, range, _ in
            if let range = Range(range, in: string) {
                info.append(AttributesRangeInfo(attributes: attributes, range: range, level: -1))
            }
        }

        self.init(string: string, attributesRangeInfo: info, baseAttributes: baseAttributes)
    }

    public convenience init(
        htmlString: String,
        baseAttributes: AttributesProvider = [NSAttributedString.Key: Any](),
        tags: [String: TagTuning] = [:]
    ) {
        let (string, tagsInfo) = htmlString.detectTags(tags: tags)
        var info: [AttributesRangeInfo] = []

        var newLevel = 0
        tagsInfo.forEach { t in
            newLevel = max(t.level, newLevel)
            if let style = tags[t.tag.name.lowercased()] {
                info.append(AttributesRangeInfo(attributes: style.style(context: TagContext(tag: t.tag, outerTags: t.outerTags)), range: t.range, level: t.level))
            }
        }

        self.init(string: string, attributesRangeInfo: info, baseAttributes: baseAttributes)
        currentMaxLevel = newLevel
    }

    public var attributedString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: baseAttributes.attributes)

        let info = attributesRangeInfo.sorted {
            $0.level < $1.level
        }

        for i in info {
            let attributes = i.attributes
            if attributes.attributes.count > 0 {
                attributedString.addAttributes(attributes.attributes, range: NSRange(i.range, in: string))
            }
        }

        return attributedString
    }

    public func styleBase(_ attributes: AttributesProvider) -> Self {
        baseAttributes = attributes
        return self
    }

    public func styleHashtags(_ attributes: DetectionTuning) -> Self {
        return style(ranges: string.detectHashtags(),
                     attributes: attributes)
    }

    public func styleMentions(_ attributes: DetectionTuning) -> Self {
        return style(ranges: string.detectMentions(),
                     attributes: attributes)
    }

    public func style(regex: String, options: NSRegularExpression.Options = [], attributes: DetectionTuning) -> Self {
        return style(ranges: string.detect(regex: regex, options: options),
                     attributes: attributes)
    }

    public func style(textCheckingTypes: NSTextCheckingResult.CheckingType, attributes: DetectionTuning) -> Self {
        return style(ranges: string.detect(textCheckingTypes: textCheckingTypes),
                     attributes: attributes)
    }

    public func stylePhoneNumbers(_ attributes: DetectionTuning) -> Self {
        return style(ranges: string.detectPhoneNumbers(),
                     attributes: attributes)
    }

    public func styleLinks(_ attributes: DetectionTuning) -> Self {
        return style(ranges: string.detectLinks(),
                     attributes: attributes)
    }

    public func style(range: Range<String.Index>, attributes: DetectionTuning) -> Self {
        return style(ranges: [range], attributes: attributes)
    }

    public func style(ranges: [Range<String.Index>], attributes: DetectionTuning) -> Self {
        currentMaxLevel += 1
        let info = ranges.map { range in
            let detectionContext = DetectionContext(
                range: range,
                text: String(string[range]),
                existingAttributes: attributesRangeInfo.compactMap {
                    $0.range.clamped(to: range) == range ? $0.attributes : nil
                }
            )

            return AttributesRangeInfo(
                attributes: attributes.style(context: detectionContext),
                range: range,
                level: currentMaxLevel
            )
        }

        attributesRangeInfo.append(contentsOf: info)
        return self
    }
}

public protocol HTMLSpecialsProvider {
    func stringForHTMLSpecial(_ htmlSpecial: String) -> String?
}

public struct DefaultHTMLSpecialsProvider: HTMLSpecialsProvider {
    public func stringForHTMLSpecial(_ htmlSpecial: String) -> String? {
        return HTMLSpecials[htmlSpecial].map { String($0) }
    }

  private let HTMLSpecials: [String: Character] = [
    // Basic symbols
    "quot": "\u{22}",    // "
    "amp": "\u{26}",     // &
    "apos": "\u{27}",    // '
    "lt": "\u{3C}",      // <
    "gt": "\u{3E}",      // >
    "nbsp": "\u{A0}",    // Non-breaking space
    
    // Quotation marks
    "lsquo": "\u{2018}", // ‘ (left single quotation mark)
    "rsquo": "\u{2019}", // ’ (right single quotation mark)
    "ldquo": "\u{201C}", // “ (left double quotation mark)
    "rdquo": "\u{201D}", // ” (right double quotation mark)
    
    // Dashes and ellipses
    "ndash": "\u{2013}", // – (en dash)
    "mdash": "\u{2014}", // — (em dash)
    "hellip": "\u{2026}", // … (horizontal ellipsis)
    
    // Mathematical symbols
    "plusmn": "\u{00B1}", // ± (plus-minus sign)
    "times": "\u{00D7}",  // × (multiplication sign)
    "divide": "\u{00F7}", // ÷ (division sign)
    "frac14": "\u{00BC}", // ¼ (fraction one-quarter)
    "frac12": "\u{00BD}", // ½ (fraction one-half)
    "frac34": "\u{00BE}", // ¾ (fraction three-quarters)
    
    // Currency symbols
    "euro": "\u{20AC}",  // € (Euro sign)
    "pound": "\u{00A3}", // £ (Pound sign)
    "yen": "\u{00A5}",   // ¥ (Yen sign)
    "cent": "\u{00A2}",  // ¢ (Cent sign)
    "curren": "\u{00A4}", // ¤ (Currency sign)
    
    // Other symbols
    "copy": "\u{00A9}",  // © (Copyright sign)
    "reg": "\u{00AE}",   // ® (Registered trademark sign)
    "trade": "\u{2122}", // ™ (Trademark sign)
    "sect": "\u{00A7}",  // § (Section sign)
    "deg": "\u{00B0}",   // ° (Degree sign)
    "permil": "\u{2030}", // ‰ (Per mille sign)
    "bull": "\u{2022}",  // • (Bullet point)
    "middot": "\u{00B7}", // · (Middle dot)
    "para": "\u{00B6}",  // ¶ (Pilcrow sign, paragraph sign)
    "laquo": "\u{00AB}", // « (Left-pointing double angle quotation mark)
    "raquo": "\u{00BB}"  // » (Right-pointing double angle quotation mark)
  ]
}

public extension AttributedStringBuilder {
    static var htmlSpecialsProvider: HTMLSpecialsProvider = DefaultHTMLSpecialsProvider()
}
