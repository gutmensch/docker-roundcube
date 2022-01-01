<?php

$config = array();

$config['imap_conn_options'] =
$config['smtp_conn_options'] =
$config['managesieve_conn_options'] = [
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true,
    ],
];

// plugins added from Dockerfile
$config['plugins'] = array();
if(getenv('ROUNDCUBE_USER_FILE')) $config['plugins'][] = 'password';
