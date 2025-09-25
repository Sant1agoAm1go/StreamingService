DROP TABLE IF EXISTS Stream_Game;
DROP TABLE IF EXISTS Message;
DROP TABLE IF EXISTS Chat;
DROP TABLE IF EXISTS Stream;
DROP TABLE IF EXISTS Subscription;
DROP TABLE IF EXISTS Channel;
DROP TABLE IF EXISTS Game;
DROP TABLE IF EXISTS "User";

CREATE TABLE "User" (
    "User_ID" SERIAL PRIMARY KEY,
    Username VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
	Login VARCHAR(255) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Registration_Date TIMESTAMP NOT NULL
);

CREATE TABLE Channel (
    Channel_ID SERIAL PRIMARY KEY,
    Channel_Name VARCHAR(255) NOT NULL,
    Channel_Description TEXT,
    "User_ID" INT NOT NULL UNIQUE REFERENCES "User"("User_ID") ON DELETE CASCADE
);

CREATE TABLE Game (
    Game_ID SERIAL PRIMARY KEY,
    Game_Name VARCHAR(255) NOT NULL,
    Genre VARCHAR(100)
);

CREATE TABLE Stream (
    Stream_ID SERIAL PRIMARY KEY,
    Channel_ID INT NOT NULL REFERENCES Channel(Channel_ID),
    Stream_Title VARCHAR(255) NOT NULL,
    Start_DateTime TIMESTAMP NOT NULL,
    End_DateTime TIMESTAMP,
    Status VARCHAR(20) CHECK (Status IN ('Active', 'Completed')),
    Viewers INT DEFAULT 0
);

CREATE TABLE Chat (
    Chat_ID SERIAL PRIMARY KEY,
    Channel_ID INT NOT NULL REFERENCES Channel(Channel_ID),
    Chat_Rules TEXT,
    Is_Private BOOLEAN DEFAULT FALSE
);

CREATE TABLE Message (
    Message_ID SERIAL PRIMARY KEY,
    Chat_ID INT NOT NULL REFERENCES Chat(Chat_ID),
    "User_ID" INT NOT NULL REFERENCES "User"("User_ID"),
    Message_Text TEXT NOT NULL,
    Timestamp TIMESTAMP NOT NULL
);

CREATE TABLE Subscription (
    Subscription_ID SERIAL PRIMARY KEY,
    "User_ID" INT NOT NULL REFERENCES "User"("User_ID"),
    Channel_ID INT NOT NULL REFERENCES Channel(Channel_ID),
    Subscription_Date TIMESTAMP NOT NULL,
    Subscription_Status VARCHAR(20) CHECK (Subscription_Status IN ('Active', 'Inactive')),
    Subscription_Level VARCHAR(50) CHECK (Subscription_Level IN ('Follower', 'Subscriber'))
);

CREATE TABLE Stream_Game (
    Stream_ID INT NOT NULL REFERENCES Stream(Stream_ID),
    Game_ID INT NOT NULL REFERENCES Game(Game_ID),
    Started_At TIMESTAMP NOT NULL,
    Ended_At TIMESTAMP,
    PRIMARY KEY (Stream_ID, Game_ID)
);

INSERT INTO "User" (Username, Email, Login, Password, Registration_Date)
SELECT 
    'user_' || i AS Username,
    'user' || i || '@example.com' AS Email,
    'login_' || i AS Login,
    md5('password' || i) AS Password, -- hashed for security
    NOW() - (interval '1 day' * (random() * 365)::int) AS Registration_Date
FROM generate_series(1, 1000000) AS s(i);

INSERT INTO Channel (Channel_Name, Channel_Description, "User_ID")
SELECT 
    'Channel_' || i AS Channel_Name,
    'Description for Channel ' || i AS Channel_Description,
    i AS "User_ID"
FROM generate_series(1, 1000000) AS s(i);

INSERT INTO Chat (Channel_ID, Chat_Rules, Is_Private)
SELECT 
    Channel_ID,
    'Chat rules for channel ' || Channel_ID AS Chat_Rules,
    CASE WHEN random() > 0.5 THEN TRUE ELSE FALSE END AS Is_Private
FROM Channel;

INSERT INTO Message (Chat_ID, "User_ID", Message_Text, Timestamp)
SELECT 
    (SELECT Chat_ID FROM Chat ORDER BY random() LIMIT 1) AS Chat_ID,
    (SELECT "User_ID" FROM "User" ORDER BY random() LIMIT 1) AS "User_ID",
    'Sample message text ' || i AS Message_Text,
    NOW() - (interval '1 minute' * (random() * 525600)::int) AS Timestamp
FROM generate_series(1, 1000000) AS s(i);

INSERT INTO Game (Game_Name, Genre)
SELECT 
    'Game_' || i AS Game_Name,
    CASE 
        WHEN i % 5 = 0 THEN 'Action'
        WHEN i % 5 = 1 THEN 'Adventure'
        WHEN i % 5 = 2 THEN 'Puzzle'
        WHEN i % 5 = 3 THEN 'RPG'
        ELSE 'Strategy'
    END AS Genre
FROM generate_series(1, 1000) AS s(i);

INSERT INTO Stream (Channel_ID, Stream_Title, Start_DateTime, End_DateTime, Status, Viewers)
SELECT 
    (random() * 1000000)::int AS Channel_ID,
    'Stream Title ' || i AS Stream_Title,
    NOW() - (interval '1 day' * (random() * 365)::int) AS Start_DateTime,
    CASE WHEN random() > 0.5 THEN NOW() - (interval '1 day' * (random() * 180)::int) ELSE NULL END AS End_DateTime,
    CASE WHEN random() > 0.5 THEN 'Active' ELSE 'Completed' END AS Status,
    (random() * 1000)::int AS Viewers
FROM generate_series(1, 100000) AS s(i);

INSERT INTO Subscription ("User_ID", Channel_ID, Subscription_Date, Subscription_Status, Subscription_Level)
SELECT 
    (SELECT "User_ID" FROM "User" ORDER BY random() LIMIT 1) AS "User_ID",
    (SELECT Channel_ID FROM Channel ORDER BY random() LIMIT 1) AS Channel_ID,
    NOW() - (interval '1 day' * (random() * 365)::int) AS Subscription_Date,
    CASE WHEN random() > 0.5 THEN 'Active' ELSE 'Inactive' END AS Subscription_Status,
    CASE WHEN random() > 0.5 THEN 'Follower' ELSE 'Subscriber' END AS Subscription_Level
FROM generate_series(1, 500000) AS s(i)
ON CONFLICT DO NOTHING;


INSERT INTO Stream_Game (Stream_ID, Game_ID, Started_At, Ended_At)
SELECT 
    s.Stream_ID,
    g.Game_ID,
    NOW() - (interval '1 day' * (random() * 365)::int) AS Started_At,
    CASE WHEN random() > 0.5 THEN NOW() - (interval '1 day' * (random() * 180)::int) ELSE NULL END AS Ended_At
FROM 
    (SELECT Stream_ID FROM Stream ORDER BY random() LIMIT 1000) AS s
CROSS JOIN 
    (SELECT Game_ID FROM Game ORDER BY random() LIMIT 100) AS g
ON CONFLICT (Stream_ID, Game_ID) DO NOTHING;

SELECT * FROM Stream_Game;
SELECT * FROM Message;
SELECT * FROM Chat;
SELECT * FROM Stream;
SELECT * FROM Subscription;
SELECT * FROM Channel;
SELECT * FROM Game;
SELECT * FROM "User";

