CREATE TABLE user (
    userID INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    creationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE project (
    projectID INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    deadline DATE,
    proprietaryID INT,
    creationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (proprietaryID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE userProject (
    userProjectID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    projectID INT,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE
);

CREATE TABLE task (
    taskID INT AUTO_INCREMENT PRIMARY KEY,
    projectID INT,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    deadline DATE,
    priority ENUM('Baja', 'Media', 'Alta') DEFAULT 'Media',
    status ENUM('Pendiente', 'En Proceso', 'Completada') DEFAULT 'Pendiente',
    creationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    createdUserID INT,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE,
    FOREIGN KEY (createdUserID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskAssignment (
    assignmentID INT AUTO_INCREMENT PRIMARY KEY,
    taskID INT,
    userID INT,
    FOREIGN KEY (taskID) REFERENCES task(taskID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE messageChat (
    messageID INT AUTO_INCREMENT PRIMARY KEY,
    projectID INT,
    userID INT,
    content TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (projectID) REFERENCES project(projectID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskComment (
    commentID INT AUTO_INCREMENT PRIMARY KEY,
    taskID INT,
    userID INT,
    comment TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (taskID) REFERENCES task(taskID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE attachment (
    attachmentID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    filePath VARCHAR(255) NOT NULL,
    uploadDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    lastUpdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES user(userID) ON DELETE CASCADE
);

CREATE TABLE taskAttachment (
    taskAttachmentID INT AUTO_INCREMENT PRIMARY KEY,
    attachmentID INT,
    taskID INT,
    FOREIGN KEY (attachmentID) REFERENCES attachment(attachmentID) ON DELETE CASCADE,
    FOREIGN KEY (taskID) REFERENCES task(taskID) ON DELETE CASCADE
);

CREATE TABLE messageAttachment (
    messageAttachmentID INT AUTO_INCREMENT PRIMARY KEY,
    attachmentID INT,
    messageID INT,
    FOREIGN KEY (attachmentID) REFERENCES attachment(attachmentID) ON DELETE CASCADE,
    FOREIGN KEY (messageID) REFERENCES messageChat(messageID) ON DELETE CASCADE
);

CREATE TABLE activityLog (
    activityID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    projectID INT,
    activityType VARCHAR(100) NOT NULL,
    activityDetails JSON,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
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


//crear proyecto de  prueba
INSERT INTO user (username, name, email, password) VALUES ('admin', 'Administrador', 'test@test.com', '$2y$10$3')
INSERT INTO project (name, description, proprietaryID, deadline) VALUES ('Proyecto de Prueba', 'Este es un proyecto de prueba', 1, '2024-12-31')