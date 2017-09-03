<?php
require_once('core/db-config.php');

$maxplayers = 100;
?>

<html>
<head>
  <title>SimpleStats - Leaderboard</title>
  <link rel="stylesheet" href="dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="dist/css/bootstrap-theme.min.css">
  <link rel="stylesheet" href="dist/css/css.css">
</head>
<body>
<div class="container">
  <h1>SimpleStats - Leaderboard</h1>
  <div class="form-group pull-right">
      <input type="text" class="search form-control" placeholder="What you looking for?">
  </div>
  <span class="counter pull-right"></span>
  <table class="table table-hover table-bordered results">
    <thead>
      <tr>
        <th class="col-md-3 col-xs-3">SteamID</th>
        <th class="col-md-3 col-xs-3">Player Name</th>
        <th>Kills</th>
		<th>Deaths</th>
		<th>Shots</th>
		<th>Hits</th>
		<th>Headshots</th>
		<th>Assists</th>
		<th class="col-md-3 col-xs-3">Last Connection</th>
      </tr>
      <tr class="warning no-result">
        <td colspan="4"><i class="fa fa-warning"></i> No result</td>
      </tr>
    </thead>
    <tbody>
      <?php
      $sth = $db->prepare('SELECT * FROM `players` ORDER by kills DESC LIMIT ' . $maxplayers);
      $sth->execute();

      while ($row = $sth->fetch(PDO::FETCH_ASSOC))
      {
        echo '<tr>';
        echo '<td> <a href="http://steamcommunity.com/profiles/' . $row['steamid'] . '">' . $row['steamid'] . '</a></td>';
        echo '<td>' . $row['name'] . '</td>';
        echo '<td>' . $row['kills'] . '</td>';
		echo '<td>' . $row['deaths'] . '</td>';
		echo '<td>' . $row['shots'] . '</td>';
		echo '<td>' . $row['hits'] . '</td>';
		echo '<td>' . $row['headshots'] . '</td>';
		echo '<td>' . $row['assists'] . '</td>';
		echo '<td>' . date('y-d-m , H:i:s', $row['lastconn']); '</td>';
        echo '</tr>';
      }
       ?>
    </tbody>
  </table>
</div>
<script src="dist/js/jquery.min.js"></script>
<script src="dist/js/bootstrap.min.js"></script>
<script src="dist/js/js.js"></script>
</body>
</html>
