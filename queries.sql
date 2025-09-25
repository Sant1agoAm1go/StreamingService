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
    Channel_Name VARCHAR(255) NOT NULL UNIQUE,
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

ALTER SEQUENCE "User_User_ID_seq" RESTART WITH 1;
ALTER SEQUENCE "message_message_id_seq" RESTART WITH 1;
ALTER SEQUENCE "chat_chat_id_seq" RESTART WITH 1;
ALTER SEQUENCE "stream_stream_id_seq" RESTART WITH 1;
ALTER SEQUENCE "subscription_subscription_id_seq" RESTART WITH 1;
ALTER SEQUENCE "channel_channel_id_seq" RESTART WITH 1;
ALTER SEQUENCE "game_game_id_seq" RESTART WITH 1;


SELECT * FROM Stream_Game;
SELECT * FROM Message;
SELECT * FROM Chat;
SELECT * FROM Stream;
SELECT * FROM Subscription;
SELECT * FROM Channel;
SELECT * FROM Game;
SELECT * FROM "User";

-- Простые запросы

-- 1. Получение списка всех пользователей с датой регистрации.
SELECT Username, Registration_Date FROM "User";

-- 2. Получение всех каналов и их владельцев.
SELECT Channel_Name, Username AS Owner 
FROM Channel
JOIN "User" ON Channel."User_ID" = "User"."User_ID";

-- 3. Получение всех активных стримов с их количеством зрителей.
SELECT Stream_Title, Viewers 
FROM Stream
WHERE Status = 'Active';

-- 4. Получение всех подписок пользователя по имени.
SELECT Username, Channel_Name, Subscription_Date 
FROM Subscription
JOIN "User" ON Subscription."User_ID" = "User"."User_ID"
JOIN Channel ON Subscription.Channel_ID = Channel.Channel_ID
WHERE Username = 'michael58';

-- 5. Получение всех сообщений из конкретного чата, отсортированных по времени.
SELECT Message_Text, Timestamp, Username 
FROM Message
JOIN "User" ON Message."User_ID" = "User"."User_ID"
WHERE Chat_ID = 4
ORDER BY Timestamp;

-- Запросы с фильтрацией и агрегацией

-- 6. Количество подписчиков у каждого канала.
SELECT Channel_Name, COUNT(Subscription_ID) AS Subscriber_Count 
FROM Subscription
JOIN Channel ON Subscription.Channel_ID = Channel.Channel_ID
GROUP BY Channel_Name;

-- 7. Самые популярные игры по количеству стримов. 
SELECT Game_Name, COUNT(Stream_Game.Stream_ID) AS Stream_Count
FROM Game
JOIN Stream_Game ON Game.Game_ID = Stream_Game.Game_ID
GROUP BY Game_Name
ORDER BY Stream_Count DESC;

-- 8. Получение суммарного количества зрителей со всех стримов конкретного канала.
SELECT Channel_Name, SUM(Viewers) AS Total_Viewers 
FROM Stream
JOIN Channel ON Stream.Channel_ID = Channel.Channel_ID
WHERE Channel_Name = 'Morgan PLC'
GROUP BY Channel_Name;

-- 9. Количество сообщений в каждом чате.
SELECT Channel_Name, COUNT(Message_ID) AS Message_Count 
FROM Message
JOIN Chat ON Message.Chat_ID = Chat.Chat_ID
JOIN Channel ON Chat.Channel_ID = Channel.Channel_ID
GROUP BY Channel_Name;

-- 10. Средняя длина сообщений в чате.
SELECT Chat_ID, AVG(LENGTH(Message_Text)) AS Avg_Message_Length
FROM Message
GROUP BY Chat_ID;

-- Более сложные запросы с подзапросами и фильтрацией

-- 11. Получение пользователей, подписанных на конкретный канал. 
SELECT Username 
FROM "User"
WHERE "User_ID" IN (
    SELECT "User_ID"
    FROM Subscription
    WHERE Channel_ID = (SELECT Channel_ID FROM Channel WHERE Channel_Name = 'Holloway and Sons')
);

-- 12. Получение всех каналов с количеством подписчиков и количеством стримов.
SELECT Channel_Name, 
       COUNT(DISTINCT Subscription.Subscription_ID) AS Subscriber_Count, 
       COUNT(DISTINCT Stream.Stream_ID) AS Stream_Count
FROM Channel
LEFT JOIN Subscription ON Channel.Channel_ID = Subscription.Channel_ID
LEFT JOIN Stream ON Channel.Channel_ID = Stream.Channel_ID
GROUP BY Channel_Name
ORDER BY 
    Subscriber_Count DESC;

-- 13. Получение подписчиков, которые подписаны на более чем один канал. 
SELECT "User"."User_ID", Username, COUNT(Subscription_ID) AS Subscription_Count 
FROM "User"
JOIN Subscription ON "User"."User_ID" = Subscription."User_ID"
GROUP BY "User"."User_ID", Username
HAVING COUNT(Subscription_ID) > 1;

-- 14. Проверка подписок для обновления статуса на "Inactive"
SELECT *
FROM Subscription
WHERE Subscription_Date < (CURRENT_DATE - INTERVAL '6 months');

-- 15. Просмотр сообщений, которые старше одного года
SELECT *
FROM Message
WHERE Timestamp < (CURRENT_DATE - INTERVAL '6 months');

-- 16. Топ-10 каналов по количеству подписчиков
SELECT 
    Channel.Channel_Name,
    COUNT(Subscription.Subscription_ID) AS Subscriber_Count
FROM 
    Channel
LEFT JOIN 
    Subscription ON Channel.Channel_ID = Subscription.Channel_ID
GROUP BY 
    Channel.Channel_ID, Channel.Channel_Name
ORDER BY 
    Subscriber_Count DESC
LIMIT 10;








