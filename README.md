# zumei-rgeocode-jpn
Setup reverse geocoding API using MySQL to search a map name of Japan topographic map by latitude and longitude.

## はじめに
国土地理院HPの[20万分1地勢図の新旧緯度・経度対照表(索引図)](https://www.gsi.go.jp/MAP/NEWOLDBL/200000/index200000.html)、[5万分の1，2.5万分の1地形図の新旧緯度・経度対照表(索引図)](https://www.gsi.go.jp/MAP/NEWOLDBL/25000-50000/index25000-50000.html)から図郭の情報を抽出し、MySQLのGIS機能を利用して、緯度・経度から図名を求める逆ジオコーディングAPIを自前で構築する手順を示す。

表示例：https://anineco.github.io/zumei-rgeocode-jpn/example.html

左上の[⌖]ボタンを押すと中央十字線の緯度、経度を読み取り、逆ジオコーディングを実行して、20万図名、5万図名、2.5万図名をポップアップ表示する。また、2.5万図名の範囲を赤く薄塗りして示す。

## 逆ジオコーディングAPI（試験公開）
```
https://map.jpn.org/share/zumei.php?lat=緯度&lon=経度
```
表示例：https://map.jpn.org/share/zumei.php?lat=36.405277&lon=139.330562

緯度、経度は世界測地系（WGS84）で、度単位の10進数で与える。結果はJSON形式で返され、次のkey-valueからなる。
* type: 1=20万図、2=5万図、3=2.5万図
* mapno: 地図の番号
* name: 図名
* region: 図の範囲（GeoJSONの'{"type":"Polygon",…}'要素）

図名の先頭に★が付くものは、世界測地系の緯度経度を表示した地形図が刊行されているもの、※は以前に刊行されていたが,現在は廃止されたものを示す。

## データベースの作成

### STEP 1. 入力データ（SQL）の入手
作成済のデータ（[zumei-rgeocode-jpn_200920.zip](https://map.jpn.org/share/zumei-rgeocode-jpn_200920.zip)）も公開しているので、これを用いても良い。ダウンロードして適当なディレクトリで解凍すると、
* map200000.sql
* map50000.sql
* map25000.sql

が得られる。

### STEP 2. 入力データ（SQL）の作成
STEP 1.で作成済データを入手した場合は、次のSTEP 3.に進む。

入力データ（SQL）は、次のコマンドで作成する。
```
$ ./get_zumei.pl
$ ./csv2sql.pl < map200000.csv > map200000.sql
$ ./csv2sql.pl < map50000.csv > map50000.sql
$ ./csv2sql.pl < map25000.csv > map25000.sql
```
get_zumei.pl を実行すると国土地理院HPからデータを抽出して map200000.csv、map50000.csv、map25000.csv が出力される。

### STEP 3. テーブルの作成

次の SQLコマンドでテーブルを作成する。
```
CREATE TABLE `zumei` (
  `type` tinyint NOT NULL COMMENT '種別',
  `mapno` varchar(255) NOT NULL COMMENT '地図番号',
  `name` varchar(255) NOT NULL COMMENT '図名',
  `area` polygon NOT NULL /*!80003 SRID 4326 */ COMMENT '範囲',
  SPATIAL KEY `area` (`area`)
);
```
なお、MySQL8の場合は、areaフィールドにSRID 4326を設定している（ https://dev.mysql.com/doc/refman/8.0/en/spatial-type-overview.html ）。

### STEP 4. 入力データ（SQL）のインポート
map200000.sql、map50000.sql、map25000.sql のうち、必要なものをSTEP 3.で作成したテーブルにインポートする。phpMyAdmin を用いる場合は、SQLファイルをドラッグ&ドロップでインポートする機能が便利である。

### STEP 5. テスト
```
SET @lon=140.084619;
SET @lat=36.104638;
SET @pt=ST_GeomFromText(CONCAT('POINT(',@lon,' ',@lat,')'),4326);
SELECT type,mapno,name FROM zumei WHERE ST_Contains(area,@pt) ORDER BY type;
```
SQLファイルを全てインポートした場合は、次の結果が得られる。
```
1 47         ★水戸
2 水戸16号    ★土浦
3 水戸16号-3  ★上郷
```
注：MySQL8では、POINT中の@lonと@latの順番が入れ替わる（ https://dev.mysql.com/doc/refman/8.0/en/gis-wkt-functions.html#function_st-geomfromtext ）。 

## API用PHPの設置
init.phpにデータベースへアクセスするための情報を記入し、zumei.phpと共にWebサーバに設置する。

### 参考URL
* [逆ジオコーディングAPIを自前で構築](https://github.com/anineco/easy-rgeocode-jpn)
* [MySQLでGISデータを扱う](https://qiita.com/onunu/items/59ef2c050b35773ced0d)
