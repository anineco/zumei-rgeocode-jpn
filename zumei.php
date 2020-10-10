<?php
require_once './init.php';
$cf = set_init();
$dsn = "mysql:dbname=$cf[database];host=$cf[host];charset=utf8mb4";
#$dsn = "mysql:dbname=$cf[database];unix_socket=$cf[socket];charset=utf8mb4";

$dbh = new PDO($dsn, $cf['user'], $cf['password']);
$type = !empty($_POST) ? INPUT_POST : INPUT_GET;
$lon = filter_input($type, 'lon');
$lat = filter_input($type, 'lat');

# MySQL8
$sql = <<<'EOS'
SET @pt=ST_GeomFromText(CONCAT('POINT(',?,' ',?,')'),4326,'axis-order=long-lat')
EOS;
# MySQL5/MariaDB10
#$sql = <<<'EOS'
#SET @pt=ST_GeomFromText(CONCAT('POINT(',?,' ',?,')'),4326)
#EOS;

$sth = $dbh->prepare($sql);
$sth->bindValue(1, $lon, PDO::PARAM_STR);
$sth->bindValue(2, $lat, PDO::PARAM_STR);
$sth->execute();
$sth = null;
$sql = <<<'EOS'
SELECT type,mapno,name,ST_AsGeoJSON(area,4) AS region
FROM zumei WHERE ST_Contains(area,@pt) ORDER BY type
EOS;
$sth = $dbh->prepare($sql);
$sth->execute();
$maps = array();
while ($row = $sth->fetch(PDO::FETCH_OBJ)) {
  $maps[] = array(
    'type' => $row->type,
    'mapno' => $row->mapno,
    'name' => $row->name,
    'region' => $row->region
  );
}
$sth = null;
$output = array( 'maps' => $maps );
header('Content-type: application/json');
echo json_encode($output, JSON_UNESCAPED_UNICODE), PHP_EOL;
$dbh = null;
