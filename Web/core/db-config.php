<?php

$servername = "localhost";
$username = "root";
$password = "";
$table = "simplestats";
$db = new PDO("mysql:host=$servername;dbname=$table", $username, $password, array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'"));
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

?>
