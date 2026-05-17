import Foundation

/// Builds prompts for each generator. English instructions feed Apple
/// Foundation Models; the Arabic/Mixed prompts feed Claude.
nonisolated enum PromptBuilder {
    // MARK: English (on-device Foundation Models)

    static func englishInstructions(tone: Tone) -> String {
        """
        You are a professional presentation designer. You produce clear, \
        well-structured slide decks in English. The tone should be \
        \(tone.englishDescriptor). Keep bullets short (under 12 words), avoid \
        filler, and write genuinely useful speaker notes. Choose a sensible \
        layout per slide: use sectionDivider for the opening, titleContent for \
        most content, twoColumn when comparing, and quote sparingly.
        """
    }

    static func englishPrompt(source: String, slideCount: Int) -> String {
        """
        Create a \(slideCount)-slide presentation from the following input. \
        Return one strong title, an optional subtitle, and exactly \
        \(slideCount) slides.

        INPUT:
        \(source)
        """
    }

    // MARK: Arabic / Mixed (Claude)

    static func arabicSystemPrompt() -> String {
        """
        أنت مصمم عروض تقديمية محترف، تكتب باللغة العربية الفصحى الواضحة.
        المستخدم سيعطيك موضوعاً، ومنك تعدّ عرضاً تقديمياً.
        متطلبات:
        - عنوان رئيسي قوي وموجز للعرض
        - كل شريحة لها عنوان واضح ونقاط محددة (3-5 نقاط)
        - النقاط مختصرة (لا تتجاوز 12 كلمة لكل نقطة)
        - ملاحظات المتحدث تفصيلية ومفيدة
        - تجنّب الحشو والكلام الإنشائي
        - استخدم اللغة الفصحى، لا العامية
        أعد الإجابة بصيغة JSON صحيحة فقط، بدون أي شرح أو نص إضافي.
        """
    }

    static func mixedSystemPrompt() -> String {
        """
        You are a professional presentation designer fluent in Arabic and \
        English. Build a presentation that mixes both languages naturally: \
        use English for technical terms, brand names, and code; use Modern \
        Standard Arabic for explanation and connective text. Tag each slide's \
        dominant language. Return valid JSON only, no extra text.
        """
    }

    /// The JSON schema text appended to Claude prompts.
    static let jsonSchema = """
    {
      "title": "string",
      "subtitle": "string",
      "language": "english|arabic|mixed",
      "slides": [
        {
          "layout": "titleOnly|titleContent|twoColumn|quote|sectionDivider",
          "language": "english|arabic",
          "title": "string",
          "subtitle": "string (optional)",
          "bullets": ["string"],
          "body": "string (optional)",
          "speakerNotes": "string"
        }
      ]
    }
    """

    static func claudeUserPrompt(
        source: String,
        slideCount: Int,
        tone: Tone,
        arabic: Bool
    ) -> String {
        let toneLine = arabic
            ? "النبرة: \(tone.arabicDescriptor)"
            : "Tone: \(tone.englishDescriptor)"
        let countLine = arabic
            ? "عدد الشرائح: \(slideCount)"
            : "Number of slides: \(slideCount)"
        return """
        \(countLine)
        \(toneLine)

        \(arabic ? "الموضوع" : "INPUT"):
        \(source)

        \(arabic ? "أعد JSON بهذه البنية فقط" : "Return JSON in exactly this shape"):
        \(jsonSchema)
        """
    }
}
