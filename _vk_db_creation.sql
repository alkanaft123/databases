DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамиль', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	phone BIGINT UNSIGNED UNIQUE, 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'юзеры';

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100)
	
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE -- (значение по умолчанию)
    ON DELETE RESTRICT; -- (значение по умолчанию)

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL, -- изменили на составной ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'unfriended', 'declined'),
    -- `status` TINYINT(1) UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, -- можно будет даже не упоминать это поле при обновлении
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)-- ,
    -- CHECK (initiator_user_id <> target_user_id)
);
-- чтобы пользователь сам себе не отправил запрос в друзья
ALTER TABLE friend_requests 
ADD CHECK(initiator_user_id <> target_user_id);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	
	INDEX communities_name_idx(name), -- индексу можно давать свое имя (communities_name_idx)
	foreign key (admin_user_id) references users(id)
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL,
    name VARCHAR(255), -- записей мало, поэтому в индексе нет необходимости
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    -- file blob,    	
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  

/* намеренно забыли, чтобы позднее увидеть их отсутствие в ER-диаграмме
    , FOREIGN KEY (user_id) REFERENCES users(id)
    , FOREIGN KEY (media_id) REFERENCES media(id)
*/
);

DROP TABLE IF EXISTS `photo_albums`;
CREATE TABLE `photo_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
  	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos` (
	id SERIAL,
	`album_id` BIGINT unsigned NULL,
	`media_id` BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk 
FOREIGN KEY (media_id) REFERENCES vk.media(id);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk_1 
FOREIGN KEY (user_id) REFERENCES vk.users(id);

ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_1 
FOREIGN KEY (photo_id) REFERENCES media(id);

/* МОЙ КОД
*/

DROP TABLE IF EXISTS `friends`;
CREATE TABLE `friends` (
    `user_id` BIGINT unsigned NOT NULL,
    `friend_id` BIGINT unsigned NOT NULL,
    become_friend_at DATETIME DEFAULT NOW(),

    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (friend_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS `countries`;
CREATE TABLE `countries` (
    id SERIAL,
    `name` varchar(255)  NOT NULL,
    
    INDEX countries_name_idx(name)
);

DROP TABLE IF EXISTS `cities`;
CREATE TABLE `cities` (
    id SERIAL,
    `name` varchar(255)  NOT NULL,
    `country_id` BIGINT unsigned NOT NULL,
  
    INDEX city_name_idx(name),
    FOREIGN KEY (country_id) REFERENCES countries(id)
);

ALTER TABLE vk.profiles CHANGE COLUMN hometown hometown_id BIGINT unsigned NOT NULL;
ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_2 
FOREIGN KEY (hometown_id) REFERENCES cities(id);


/* ДЗ 4
*/

ALTER TABLE vk.profiles ADD COLUMN is_active TINYINT NULL DEFAULT 0;

INSERT IGNORE INTO vk.`users` VALUES ('1','Javonte','Jakubowski','trey62@example.net','38515893c796660bb1307410f6aed138988b97d1','89676723604'),
('2','Aurelia','Ratke','rrolfson@example.org','84f259f5415b6f0cd20c6d4aff1a4868ac3ff0ae','89339101296'),
('3','Jacey','Fritsch','stone96@example.com','b9fd1bbdc3f7caccb0923003ea81acdab2b59610','89802518644'),
('4','Aurelia','Jerde','jonathon.feil@example.com','06292d6942f52879745960fcf6b1f1074875e53a','89397268208'),
('5','Axel','Lynch','ckuhic@example.org','e3e4d5c8e9c84cd665be208849c4e066ae2f8849','89585747656'),
('6','Karlee','Kunde','syost@example.org','46b15aca372c290f92cc7bd49a842b2cede3e1f8','89125986482'),
('7','Ryann','Prosacco','malvina.toy@example.net','856f6b5f9c993da0c5048e83570de7dccf6c188a','89334895548'),
('8','Ona','Schumm','adelia91@example.com','6cba3682da29e775f84f14c16d6fc511248a5b7d','89838377175'),
('9','Kennith','Gaylord','alphonso71@example.com','62ed6ae488aa4374d644cd571e3ae7d95959ce3d','89777246849'),
('10','Alexandre','Rowe','esipes@example.net','06e3c0a3e879a95c24452691d4f323f62756e367','89230775666');

INSERT IGNORE INTO vk.`friend_requests` VALUES ('1', '10', 'approved', '1970-08-21 06:40:37', '2003-12-29 23:20:55'),
('1', '2', 'requested', '1987-10-10 07:33:23', '1983-01-18 01:56:05'),
('1', '3', 'approved', '2015-02-07 01:53:07', '2015-09-14 16:17:12'),
('4', '1', 'approved', '1983-04-08 15:57:26', '1976-12-28 23:54:58'),
('5', '2', 'unfriended', '1976-03-03 18:22:00', '1996-12-03 11:29:04'),
('6', '3', 'unfriended', '2008-12-06 17:07:59', '2015-11-01 08:03:23'),
('7', '1', 'requested', '1989-10-26 06:20:23', '2001-08-05 16:01:03'),
('8', '6', 'unfriended', '1987-12-30 01:50:03', '2001-07-09 07:39:50'),
('9', '7', 'requested', '2003-12-27 22:52:09', '1998-04-18 04:41:46'),
('10', '5', 'declined', '1970-05-08 00:32:15', '2007-03-22 21:08:16');

INSERT IGNORE INTO vk.`countries` VALUES ('1', 'RF'),
('2', 'USA'),
('3', 'GB'),
('4', 'FR'),
('5', 'EN'),
('6', 'GR'),
('7', 'UK'),
('8', 'DN'),
('9', 'SW'),
('10', 'NOR');

INSERT IGNORE INTO vk.`cities` VALUES ('1', 'MOSCOW', '1'),
('2', 'NEWYORK', '2'),
('3', 'LONDON', '7'),
('4', 'VOLGOGRAD', '1'),
('5', 'CHELYABA', '1'),
('6', 'VORONEZH', '1'),
('7', 'SARATOV', '1'),
('8', 'PSKOV', '1'),
('9', 'PERM', '1'),
('10', 'IVANOVO', '1');

INSERT IGNORE INTO vk.`communities` VALUES ('1', 'BIKES', '1'),
('2', 'GAMES', '2'),
('3', 'MUSIC', '7'),
('4', 'TOLKIEN', '3'),
('5', 'CYBERPUNK', '4'),
('6', 'VINYL', '5'),
('7', 'SNAKES', '6'),
('8', 'FILMS', '7'),
('9', 'HORRORS', '8'),
('10', 'SERIALS', '9');

INSERT IGNORE INTO vk.`friends` VALUES ('1', '2', '2007-03-22 21:08:16'),
('2', '2', '2007-03-22 21:08:16'),
('3',  '2', '2007-03-22 21:08:16'),
('4', '5', '2007-03-22 21:08:16'),
('5',  '6', '2007-03-22 21:08:16'),
('6', '2', '2007-03-22 21:08:16'),
('7', '1', '2007-03-22 21:08:16'),
('8', '3', '2007-03-22 21:08:16'),
('9', '3', '2007-03-22 21:08:16'),
('10', '1', '2007-03-22 21:08:16');

INSERT IGNORE INTO vk.`media_types` VALUES ('1', 'type1', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('2', 'type2', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('3', 'type3', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('4', 'type4', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('5', 'type5', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('6', 'type6', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('7', 'type7', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('8', 'type8', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('9', 'type9', '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('10', 'type10', '2007-03-22 21:08:16', '2007-03-22 21:08:16');

INSERT IGNORE INTO vk.`media` VALUES ('1', '1', '1', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('2', '2', '2', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('3', '3', '3', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('4', '4', '4', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('5', '5', '5', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('6', '6', '6', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('7', '7', '7', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('8', '8', '8', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('9', '9', '9', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16'),
('10', '10', '10', 'text1', 'text1', '1', NULL, '2007-03-22 21:08:16', '2007-03-22 21:08:16');

INSERT IGNORE INTO vk.`profiles` VALUES ('1', 'f', '2007-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('2', 'm', '2012-03-22', '1', '2017-03-22 21:08:16', '1', '1'),
('3', 'f', '2012-03-22', '1', '2017-03-22 21:08:16', '1', '1'),
('4', 'm', '1987-03-22', '1', '2017-03-22 21:08:16', '1', '1'),
('5', 'f', '1987-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('6', 'm', '1987-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('7', 'm', '2007-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('8', 'm', '2007-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('9', 'm', '2007-03-22', '1', '2007-03-22 21:08:16', '1', '1'),
('10', 'm', '2007-03-22', '1', '2007-03-22 21:08:16', '1', '1');

INSERT INTO messages values
('1','1','2','Voluptatem ut quaerat quia. Pariatur esse amet ratione qui quia. In necessitatibus reprehenderit et. Nam accusantium aut qui quae nesciunt non.','1995-08-28 22:44:29'),
('2','2','1','Sint dolores et debitis est ducimus. Aut et quia beatae minus. Ipsa rerum totam modi sunt sed. Voluptas atque eum et odio ea molestias ipsam architecto.',now()),
('3','3','1','Sed mollitia quo sequi nisi est tenetur at rerum. Sed quibusdam illo ea facilis nemo sequi. Et tempora repudiandae saepe quo.','1993-09-14 19:45:58'),
('4','1','3','Quod dicta omnis placeat id et officiis et. Beatae enim aut aliquid neque occaecati odit. Facere eum distinctio assumenda omnis est delectus magnam.','1985-11-25 16:56:25'),
('5','1','5','Voluptas omnis enim quia porro debitis facilis eaque ut. Id inventore non corrupti doloremque consequuntur. Molestiae molestiae deleniti exercitationem sunt qui ea accusamus deserunt.','1999-09-19 04:35:46'),
('6','3','2','Voluptatem ut quaerat quia. Pariatur esse amet ratione qui quia. In necessitatibus reprehenderit et. Nam accusantium aut qui quae nesciunt non.','1995-08-28 22:44:29'),
('7','2','1','Sint dolores et debitis est ducimus. Aut et quia beatae minus. Ipsa rerum totam modi sunt sed. Voluptas atque eum et odio ea molestias ipsam architecto.',now()),
('8','2','1','Sed mollitia quo sequi nisi est tenetur at rerum. Sed quibusdam illo ea facilis nemo sequi. Et tempora repudiandae saepe quo.','1993-09-14 19:45:58'),
('9','2','3','Quod dicta omnis placeat id et officiis et. Beatae enim aut aliquid neque occaecati odit. Facere eum distinctio assumenda omnis est delectus magnam.','1985-11-25 16:56:25'),
('10','2','5','Voluptas omnis enim quia porro debitis facilis eaque ut. Id inventore non corrupti doloremque consequuntur. Molestiae molestiae deleniti exercitationem sunt qui ea accusamus deserunt.','2022-09-19 04:35:46');

INSERT IGNORE INTO vk.`likes` VALUES ('1', '1', '1', '2007-03-22 21:08:16'),
('2', '1', '2', '2007-03-22 21:08:16'),
('3', '1', '3', '2007-03-22 21:08:16'),
('4', '1', '4', '2007-03-22 21:08:16'),
('5', '1', '5', '2007-03-22 21:08:16'),
('6', '2', '1', '2007-03-22 21:08:16'),
('7', '2', '2', '2007-03-22 21:08:16'),
('8', '3', '1', '2007-03-22 21:08:16'),
('9', '3', '2', '2007-03-22 21:08:16'),
('10', '3', '3', '2007-03-22 21:08:16');


/* да достаточно думаю
*/

