create database misp;
grant usage on *.* to misp@localhost identified by 'misp';
grant all privileges on misp.* to misp@localhost;
flush privileges;
