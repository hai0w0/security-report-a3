-- MySQL dump 10.13  Distrib 5.5.32, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: Users
-- ------------------------------------------------------
-- Server version	5.5.32-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `credential`
--

DROP TABLE IF EXISTS `credential`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `credential` (
  `ID` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `Name` varchar(30) NOT NULL,
  `EID` varchar(20) DEFAULT NULL,
  `Salary` int(9) DEFAULT NULL,
  `birth` varchar(20) DEFAULT NULL,
  `SSN` varchar(20) DEFAULT NULL,
  `PhoneNumber` varchar(20) DEFAULT NULL,
  `Address` varchar(300) DEFAULT NULL,
  `Email` varchar(300) DEFAULT NULL,
  `NickName` varchar(300) DEFAULT NULL,
  `Password` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credential`
--

LOCK TABLES `credential` WRITE;
/*!40000 ALTER TABLE `credential` DISABLE KEYS */;
INSERT INTO `credential` VALUES (1,'Alice','10000',20000,'9/20','10211002','','','','','fdbe918bdae83000aa54747fc95fe0470fff4976'),(2,'Boby','20000',30000,'4/20','10213352','','','','','b78ed97677c161c1c82c142906674ad15242b2d4'),(3,'Ryan','30000',50000,'4/10','98993524','','','','','a3c50276cb120637cca669eb38fb9928b017e9ef'),(4,'Samy','40000',90000,'1/11','32193525','','','','','995b8b8c183f349b3cab0ae7fccd39133508d2af'),(5,'Ted','50000',110000,'11/3','32111111','','','','','99343bff28a7bb51cb6f22cb20a618701a2c2f58'),(6,'Admin','99999','400000','3/5','43254314','','','','','a5bdf35a1df4ea895905f6f6618e83951a6effc0');
/*!40000 ALTER TABLE `credential` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-10-25 10:57:28





-- start a new transaction
SET AUTOCOMMIT=0;
START TRANSACTION; 

--
-- Table structure of `workload`
--
DROP TABLE IF EXISTS tasks;

CREATE TABLE IF NOT EXISTS `tasks` (
  `TaskID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(5000) NOT NULL,
  `Hours` int(10) NOT NULL,
  `Amount` int(100) NOT NULL,
  `Description` TEXT NOT NULL,
  `Owner` int(6) UNSIGNED NOT NULL,
  `Type` TEXT NOT NULL,
  PRIMARY KEY (`TaskID`),
  FOREIGN KEY (`Owner`) REFERENCES `credential`(`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `tasks` (`Name`, `Hours`, `Amount`, `Description`,`Owner`,`Type`) VALUES
('On-site client requirement collection', '50', '10000', 'Collect client requirement', 1,'Collaboration'),
('Business Analysis', '50', '4000', 'Task Breakdown', 1,'Individual'),
('Demo App to client', '50', '2000', 'Onsite demonstration', 1,'Individual'),
('Design System Architecture1', '30', '5000', 'Design components and communication protocols', 1,'Collaboration'),
('Database Design', '30', '4000', 'Design database structures', 2,'Collaboration'),
('Setup Infrastructure and Dev Env', '20', '3000', 'Configure database and setup programing env', 6,'Individual'),
('Database Implementation', '20', '3000', 'Implement Databases', 3,'Collaboration'),
('Design System Architecture2', '20', '5000', 'Design components and communication protocols', 3,'Collaboration'),
('Front-end dev1', '40', '11000', 'Dev mobile front-end', 4,'Collaboration'),
('Front-end dev2', '40', '11000', 'Dev mobile front-end', 5,'Collaboration'),
('Back-end dev1', '30', '7000', 'Dev back-end', 5,'Collaboration'),
('Back-end dev2', '40', '10000', 'Dev back-end', 3,'Collaboration'),
('Front-end test', '10', '4000', 'Test front-end', 2,'Individual'),
('Back-end test', '20', '4000', 'Test back-end', 4,'Individual'),
('Maintainance', '5', '1000', 'Regular maintain', 6,'Individual');


--
-- Table structure of `preference`
--
DROP TABLE IF EXISTS preference;

CREATE TABLE IF NOT EXISTS `preference` (
  `PreferenceID` int(11) NOT NULL AUTO_INCREMENT,
  `favourite` varchar(5000) NOT NULL,
  `Owner` int(6) UNSIGNED NOT NULL,
  PRIMARY KEY (`PreferenceID`),
  FOREIGN KEY (`Owner`) REFERENCES `credential`(`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


INSERT INTO `preference` (`favourite`, `Owner`) VALUES
('Hours DESC', 1),
('Hours DESC', 2),
('Amount ASC', 3),
('Type ASC', 4),
('Amount DESC', 5),
('Name ASC', 6);


DELIMITER $$
--
-- function returns the userID of the user who has the max no. of declared tasks.
-- how to use: select userIdMaxTasks();

DROP FUNCTION IF EXISTS userIdMaxTasks $$

CREATE FUNCTION userIdMaxTasks() returns int(6) UNSIGNED
BEGIN
DECLARE result int(6) UNSIGNED;
DECLARE countCheck int(6) UNSIGNED;

select tasks.owner, count(tasks.owner) 
into result,countCheck
from tasks group by tasks.owner 
order by count(tasks.owner) desc
limit 1;
return result;
END$$

--
-- function creates a random user profile with random username and password
-- how to use: select generateRandomUser();

DROP FUNCTION IF EXISTS generateRandomUser $$

CREATE FUNCTION generateRandomUser() returns varchar(300)
BEGIN
DECLARE temprndName varchar(300);
DECLARE temppassword varchar(300);
DECLARE result int(6) UNSIGNED;

SET temprndName = lpad(conv(floor(rand()*pow(36,8)), 10, 36), 8, 0);
SET temppassword = lpad(conv(floor(rand()*pow(36,8)), 10, 36), 15, 0);
INSERT INTO `credential` (`Name`,`Password`) VALUES (temprndName,temppassword);
select ID into result from credential order by id desc limit 1;
INSERT INTO `preference` (`favourite`, `Owner`) VALUES ('Hours DESC', result);
return 'Created';
END$$

-- 
-- function returns the userId of a the newly created user.
-- how to use: select getNewestUserId();

DROP FUNCTION IF EXISTS getNewestUserId $$

CREATE FUNCTION getNewestUserId() returns int(6) UNSIGNED
BEGIN
DECLARE result int(6) UNSIGNED;
select ID into result from credential order by id desc limit 1;
return result;
END$$

--
-- store procedure copies all tasks from other users to a given userId
-- how to use: call copyTasksToUser(26);
DROP PROCEDURE IF EXISTS copyTasksToUser $$

CREATE PROCEDURE copyTasksToUser(in userID int(6) UNSIGNED)
BEGIN

DECLARE cursor_name varchar(5000);
DECLARE cursor_hours int(10);
DECLARE cursor_amount int(100);
DECLARE cursor_description TEXT;
DECLARE cursor_type TEXT;

DECLARE done TINYINT DEFAULT FALSE;

DECLARE cursor1 CURSOR FOR
SELECT t1.Name, t1.Hours,t1.Amount,t1.Description,t1.Type
FROM tasks t1
WHERE NOT t1.Owner = userID;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN cursor1;

read_loop: LOOP
  FETCH NEXT FROM cursor1 INTO cursor_name,cursor_hours,cursor_amount,cursor_description,cursor_type;
  IF done THEN
      LEAVE read_loop;
  ELSE
      INSERT INTO `tasks` (`Name`, `Hours`, `Amount`, `Description`,`Owner`,`Type`) VALUES
      (cursor_name, cursor_hours, cursor_amount, cursor_description,userID,cursor_type);

  END IF;

END LOOP;

CLOSE cursor1;

END$$


DELIMITER ;

-- commit changes   
COMMIT;
