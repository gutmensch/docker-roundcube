<?php

$config = array();

$config['db_dsnw'] = 'sqlite:////var/www/db/sqlite.db';

$config['imap_conn_options'] =
$config['smtp_conn_options'] =
$config['managesieve_conn_options'] = [
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true,
    ],
];

$config['smtp_server'] = 'mail';
$config['smtp_port'] = 587;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';

// session lifetime in minutes
$config['session_lifetime'] = 20160;

$config['default_host'] = array(
  'mail' => 'Default Server',
);
$config['default_port'] = 143;

$config['username_domain'] = array(
  'mail' => 'schumann.link',
);

$config['plugins'] = array('carddav', 'managesieve');
if(getenv('ROUNDCUBE_USER_FILE')) $config['plugins'][] = 'password';
