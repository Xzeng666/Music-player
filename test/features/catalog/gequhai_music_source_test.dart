import 'package:flutter_test/flutter_test.dart';
import 'package:resonance_music/features/catalog/data/gequhai_music_source.dart';
import 'package:resonance_music/features/catalog/domain/song.dart';

void main() {
  test('解析搜索表格并保留顺序、歌名、歌手和详情页', () {
    const html = '''
      <table id="myTables"><tbody>
        <tr><td>1</td><td><a href="/play/333"> 稻香 </a></td><td>周杰伦</td></tr>
        <tr><td>2</td><td><a href="/play/5153065">稻香 (Live)</a></td><td>于文文</td></tr>
      </tbody></table>
    ''';

    final songs = GequhaiMusicSource().parseSearchHtml(html);

    expect(songs, hasLength(2));
    expect(songs.first.id, 'gequhai:333');
    expect(songs.first.title, '稻香');
    expect(songs.first.artist, '周杰伦');
    expect(songs.first.source, MusicSourceKind.gequhaiWeb);
    expect(songs.first.externalPageUrl, 'https://www.gequhai.com/play/333');
    expect(songs.first.isPlayable, isFalse);
    expect(songs.last.title, '稻香 (Live)');
  });

  test('跳过无效行和重复详情页', () {
    const html = '''
      <table id="myTables"><tbody>
        <tr><td>1</td><td><a href="/play/1">A</a></td><td>Singer</td></tr>
        <tr><td>2</td><td><a href="/play/1">A copy</a></td><td>Singer</td></tr>
        <tr><td>3</td><td>missing link</td><td>Singer</td></tr>
      </tbody></table>
    ''';

    final songs = GequhaiMusicSource().parseSearchHtml(html);
    expect(songs.map((song) => song.id), <String>['gequhai:1']);
  });
}
