String stripHtmlTags(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), '');
}

String stripHtml(String html, {bool stripEntities = true}) {
  var result = stripHtmlTags(html);
  if (stripEntities) {
    result = result.replaceAll(RegExp(r'&[^;]+;'), '');
  }
  return result.trim();
}
