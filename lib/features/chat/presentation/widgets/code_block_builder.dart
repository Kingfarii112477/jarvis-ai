import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Renders fenced ```lang code blocks with real syntax highlighting
/// (via `highlight.js`'s Dart port) and a copy button, instead of
/// flutter_markdown's default monochrome `<code>` styling.
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'code') return null;
    final isBlock = element.textContent.contains('\n');
    if (!isBlock) return null;

    final language = element.attributes['class']?.replaceFirst('language-', '') ?? 'plaintext';
    final code = element.textContent.trimRight();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Row(
              children: [
                Text(language, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                const Spacer(),
                InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: code)),
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                code,
                language: language,
                theme: atomOneDarkTheme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
