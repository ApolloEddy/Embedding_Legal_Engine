
import 'package:legal_engine_shared/legal_engine_shared.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  print('=== 开始验证法律条文解析器 ===');
  
  final parser = LawArticleParser();
  // 只读取刑法目录，减少时间
  final lawDir = p.join(Directory.current.parent.path, 'Law', '刑法');
  print('正在解析目录: $lawDir');
  
  try {
    final articles = await parser.parseDirectory(lawDir);
    print('解析完成，共找到 ${articles.length} 条法律条文');
    
    // 查找第三百四十一条
    final targetArticle = '第三百四十一条';
    final matches = articles.filterByArticleNumber(targetArticle);
    
    if (matches.isEmpty) {
      print('❌ 错误: 未找到 $targetArticle');
      exit(1);
    } 
    
    print('✅ 成功: 找到 ${matches.length} 个 $targetArticle 相关的款项');
    
    for (var article in matches) {
      print('\n-------------------');
      print('条号: ${article.articleNumber}');
      print('款号: 第 ${article.clauseIndex} 款');
      if (article.crimeName != null) {
        print('提取罪名: ${article.crimeName}');
      }
      print('内容预览: ${article.content.substring(0, article.content.length > 50 ? 50 : article.content.length)}...');
    }
    
    // 验证是否包含我们需要的三个罪名（通过内容或款号）
    // 1. 危害珍贵、濒危野生动物罪 (通常是第一款)
    // 2. 非法狩猎罪 (通常是第二款)
    // 3. 非法猎捕陆生野生动物 (通常是第三款)
    
    if (matches.length >= 3) {
      print('\n✅ 验证通过: 包含至少3款，符合预期结构');
    } else {
      print('\n⚠️ 警告: 款项数量 (${matches.length}) 可能不足，请检查 markdown 格式');
    }

  } catch (e, stack) {
    print('❌ 更严重的错误: $e');
    print(stack);
    exit(1);
  }
}
