<?php
$config['notes_basepath'] = '/var/www/db/'; // absolute base! path where your notes are stored
$config['notes_folder'] = '/files/Notes/'; // notes folder under basepath. in the end the folder is calculated by 'basepath' + 'username' + 'notes_folder'
$config['media_folder'] = '.media';  // folder to store embedded images or binary file like *.pdf
$config['default_format'] = 'md'; // default format, you can choose between 'html', 'md' or 'txt'
$config['yaml_support'] = true;  // set to true, if you want enable yaml support
$config['yaml_start'] = '---';  // the yaml header should starts as the first sign in a markdown note and is marked by default with '---'
$config['yaml_end'] = '---';  // the signs which marks the end of the yaml header
?>
