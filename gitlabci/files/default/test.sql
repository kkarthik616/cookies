DROP DATABASE IF EXISTS gitlab_ci_production;
GRANT USAGE ON *.* TO 'gitlab_ci'@'localhost';
DROP USER 'gitlab_ci'@'localhost';
CREATE DATABASE IF NOT EXISTS `gitlab_ci_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
CREATE USER 'gitlab_ci'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlab_ci_production`.* TO 'gitlab_ci'@'localhost'; 


