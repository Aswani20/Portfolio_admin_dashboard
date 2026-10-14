import 'dart:convert';

import '../models/portfolio_models.dart';

/// Static website payload, explicitly excludes drafts and local revision tokens.
String exportWebsiteArticles(List<Article> articles) =>
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'articles': [
        for (final article in articles.where((a) => a.isPublished))
          {
            'id': article.id,
            'title': article.title,
            'summary': article.summary,
            'body': article.body,
            'publishedOn': article.publishedOn,
          },
      ],
    });
