DROP DATABASE IF EXISTS taskermg_db;
CREATE DATABASE taskermg_db;
USE taskermg_db;

CREATE TABLE user (
    userID INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    creationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    salt VARCHAR(255) NOT NULL,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    firebaseToken TEXT
);

CREATE TABLE profileData (
  profileDataID INT AUTO_INCREMENT PRIMARY KEY,
  userID INT,
  profilePic VARCHAR(255),
  lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE project (
    projectID INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    deadline TIMESTAMP,
    proprietaryID INT,
    creationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (proprietaryID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE userProject (
    userProjectID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    projectID INT,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE
);

CREATE TABLE tasks (
    taskID INT AUTO_INCREMENT PRIMARY KEY,
    projectID INT,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    deadline TIMESTAMP,
    priority ENUM('Baja', 'Media', 'Alta') DEFAULT 'Media',
    status ENUM('Pendiente', 'En Proceso', 'Completada') DEFAULT 'Pendiente',
    creationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    createdUserID INT,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE,
    FOREIGN KEY (createdUserID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskAssignment (
    assignmentID INT AUTO_INCREMENT PRIMARY KEY,
    taskID INT,
    userID INT,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (taskID) REFERENCES tasks(taskID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskComment (
    taskCommentID INT AUTO_INCREMENT PRIMARY KEY,
    taskID INT,
    userID INT,
    comment TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (taskID) REFERENCES tasks(taskID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE attachment (
    attachmentID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    name VARCHAR(255) NOT NULL,
    type varchar(100) NOT NULL,
    size INT NOT NULL,
    fileUrl VARCHAR(255) NOT NULL,
    uploadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskAttachment (
    taskAttachmentID INT AUTO_INCREMENT PRIMARY KEY,
    attachmentID INT,
    taskCommentID INT,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (attachmentID) REFERENCES attachment(attachmentID) ON DELETE CASCADE,
    FOREIGN KEY (taskCommentID) REFERENCES taskComment(commentID) ON DELETE CASCADE
);


CREATE TABLE activityLog (
    activityID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    projectID INT,
    activityType VARCHAR(100) NOT NULL,
    activityDetails JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE
);

CREATE TABLE projectGoal (
    goalID INT AUTO_INCREMENT PRIMARY KEY,
    projectID INT,
    goalDescription TEXT NOT NULL,
    isCompleted BOOLEAN DEFAULT FALSE,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE
);

CREATE TABLE inviteRequests (
    inviteID INT AUTO_INCREMENT PRIMARY KEY,
    projectID INT,
    userID INT,
    status ENUM('Pendiente', 'Aceptada', 'Rechazada') DEFAULT 'Pendiente',
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);