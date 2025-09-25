import psycopg2
from faker import Faker
from datetime import timedelta
from psycopg2.extras import execute_values
import random

# Создаем объект Faker
fake = Faker()

# Подключение к базе данных
def connect():
    return psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="sql",
        host="localhost"
    )

# Функция для вставки данных в таблицу "User"
def insert_users(cur, count=200000):
    # Используем множества для отслеживания уникальных значений
    unique_logins = set()
    unique_emails = set()

    for _ in range(count):
        while True:
            login = fake.user_name()
            email = fake.email()
            if login not in unique_logins and email not in unique_emails:
                unique_logins.add(login)
                unique_emails.add(email)
                break  # Уникальные значения найдены, можно выйти из цикла

        username = fake.user_name()
        password = fake.password()
        registration_date = fake.date_time_this_year()

        cur.execute("""
            INSERT INTO "User" (Username, Email, Login, Password, Registration_Date)
            VALUES (%s, %s, %s, %s, %s)
        """, (username, email, login, password, registration_date))

# Функция для вставки данных в таблицу Channel
def insert_channels(cur):
    cur.execute('SELECT "User_ID" FROM "User"')
    user_ids = [row[0] for row in cur.fetchall()]
    random.shuffle(user_ids)

    # Извлечение всех существующих имен каналов
    cur.execute('SELECT Channel_Name FROM Channel')
    existing_channel_names = set(row[0] for row in cur.fetchall())

    for user_id in user_ids:
        while True:
            channel_name = fake.company()
            if channel_name not in existing_channel_names:
                existing_channel_names.add(channel_name)
                break  # Найдено уникальное имя канала

        channel_description = fake.text()

        cur.execute("""
            INSERT INTO Channel (Channel_Name, Channel_Description, "User_ID")
            VALUES (%s, %s, %s)
        """, (channel_name, channel_description, user_id))

# Функция для вставки данных в таблицу Chat
def insert_chats(cur):
    cur.execute('SELECT Channel_ID FROM Channel')
    channel_ids = [row[0] for row in cur.fetchall()]

    for channel_id in channel_ids:
        chat_rules = f"Rules for channel {channel_id}"
        is_private = random.choice([True, False])
        cur.execute("""
            INSERT INTO Chat (Channel_ID, Chat_Rules, Is_Private)
            VALUES (%s, %s, %s)
        """, (channel_id, chat_rules, is_private))

# Функция для вставки данных в таблицу Game
def insert_games(cur, count=100000):
    genres = ['Action', 'Adventure', 'Puzzle', 'RPG', 'Strategy']

    for _ in range(count):
        game_name = fake.word().capitalize() + ' ' + fake.word().capitalize()
        genre = random.choice(genres)
        cur.execute("""
            INSERT INTO Game (Game_Name, Genre)
            VALUES (%s, %s)
        """, (game_name, genre))

# Функция для вставки данных в таблицу Stream
def insert_streams(cur, count=100000):
    cur.execute('SELECT Channel_ID FROM Channel')
    channel_ids = [row[0] for row in cur.fetchall()]

    for _ in range(count):
        channel_id = random.choice(channel_ids)
        stream_title = fake.sentence(nb_words=4)
        start_time = fake.date_time_this_year()
        end_time = start_time + timedelta(hours=random.randint(1, 8))
        status = random.choice(['Active', 'Completed'])
        viewers = random.randint(0, 10000)
        cur.execute("""
            INSERT INTO Stream (Channel_ID, Stream_Title, Start_DateTime, End_DateTime, Status, Viewers)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (channel_id, stream_title, start_time, end_time, status, viewers))

# Функция для вставки данных в таблицу Message
def insert_messages(cur, count=200000):
    cur.execute('SELECT Chat_ID FROM Chat')
    chat_ids = [row[0] for row in cur.fetchall()]

    cur.execute('SELECT "User_ID" FROM "User"')
    user_ids = [row[0] for row in cur.fetchall()]

    for _ in range(count):
        chat_id = random.choice(chat_ids)
        user_id = random.choice(user_ids)
        message_text = fake.sentence()
        timestamp = fake.date_time_this_year()
        cur.execute("""
            INSERT INTO Message (Chat_ID, "User_ID", Message_Text, Timestamp)
            VALUES (%s, %s, %s, %s)
        """, (chat_id, user_id, message_text, timestamp))

# Функция для вставки данных в таблицу Subscription
def insert_subscriptions(cur, count=500000, min_followers=50, max_followers=10000):
    # Получаем списки пользователей и каналов
    cur.execute('SELECT "User_ID" FROM "User"')
    user_ids = [row[0] for row in cur.fetchall()]
    print(f"Fetched {len(user_ids)} users")

    cur.execute('SELECT Channel_ID FROM Channel')
    channel_ids = [row[0] for row in cur.fetchall()]
    print(f"Fetched {len(channel_ids)} channels")

    existing_subscriptions = set()
    subscriptions = []
    remaining_subscriptions = count

    # Шаг 1: добавляем случайное количество подписчиков для каждого канала (в диапазоне от min_followers до max_followers)
    for i, channel_id in enumerate(channel_ids, 1):
        # Определяем случайное количество подписчиков для текущего канала
        num_followers = random.randint(min_followers, min(max_followers, len(user_ids)))
        chosen_users = random.sample(user_ids, num_followers)

        for user_id in chosen_users:
            if (user_id, channel_id) not in existing_subscriptions:
                subscription_date = fake.date_time_this_year()
                subscription_status = random.choice(['Active', 'Inactive'])
                subscription_level = random.choice(['Follower', 'Subscriber'])

                subscriptions.append(
                    (user_id, channel_id, subscription_date, subscription_status, subscription_level)
                )
                existing_subscriptions.add((user_id, channel_id))
                remaining_subscriptions -= 1

                # Вставляем подписки пакетами по 1000 записей для ускорения
                if len(subscriptions) >= 1000:
                    execute_values(cur, """
                        INSERT INTO Subscription ("User_ID", Channel_ID, Subscription_Date, Subscription_Status, Subscription_Level)
                        VALUES %s
                    """, subscriptions)
                    subscriptions.clear()

        # Прерываем цикл, если достигли нужного количества подписок
        if remaining_subscriptions <= 0:
            print("Reached target subscription count.")
            break

    # Шаг 2: распределяем оставшиеся подписки случайным образом по всем каналам
    while remaining_subscriptions > 0:
        user_id = random.choice(user_ids)
        channel_id = random.choice(channel_ids)

        if (user_id, channel_id) not in existing_subscriptions:
            existing_subscriptions.add((user_id, channel_id))
            subscription_date = fake.date_time_this_year()
            subscription_status = random.choice(['Active', 'Inactive'])
            subscription_level = random.choice(['Follower', 'Subscriber'])

            subscriptions.append(
                (user_id, channel_id, subscription_date, subscription_status, subscription_level)
            )
            remaining_subscriptions -= 1

            # Вставка остатка подписок пакетами по 1000
            if len(subscriptions) >= 1000:
                execute_values(cur, """
                    INSERT INTO Subscription ("User_ID", Channel_ID, Subscription_Date, Subscription_Status, Subscription_Level)
                    VALUES %s
                """, subscriptions)
                subscriptions.clear()

    # Вставка оставшихся подписок, если их меньше 1000
    if subscriptions:
        execute_values(cur, """
            INSERT INTO Subscription ("User_ID", Channel_ID, Subscription_Date, Subscription_Status, Subscription_Level)
            VALUES %s
        """, subscriptions)

    print("All subscriptions inserted successfully!")

# Функция для вставки данных в таблицу Stream_Game
def insert_stream_games(cur, count=100000):
    # Получаем все возможные Stream_ID и Game_ID
    cur.execute('SELECT Stream_ID FROM Stream')
    stream_ids = [row[0] for row in cur.fetchall()]

    cur.execute('SELECT Game_ID FROM Game')
    game_ids = [row[0] for row in cur.fetchall()]

    # Множество для отслеживания уникальных комбинаций (Stream_ID, Game_ID)
    stream_games = set()

    for _ in range(count):
        while True:
            stream_id = random.choice(stream_ids)
            game_id = random.choice(game_ids)

            # Проверка на уникальность пары (stream_id, game_id)
            if (stream_id, game_id) not in stream_games:
                stream_games.add((stream_id, game_id))
                break  # Уникальная комбинация найдена, выходим из цикла

        # Генерация временных меток
        started_at = fake.date_time_this_year()
        ended_at = started_at + timedelta(hours=random.randint(1, 8))

        # Вставка данных
        cur.execute("""
            INSERT INTO Stream_Game (Stream_ID, Game_ID, Started_At, Ended_At)
            VALUES (%s, %s, %s, %s)
        """, (stream_id, game_id, started_at, ended_at))

# Главная функция для запуска всех вставок
def main():
    try:
        conn = connect()
        conn.autocommit = False
        cur = conn.cursor()

        print("Inserting users...")
        insert_users(cur)

        print("Inserting channels...")
        insert_channels(cur)

        print("Inserting chats...")
        insert_chats(cur)

        print("Inserting games...")
        insert_games(cur)

        print("Inserting streams...")
        insert_streams(cur)

        print("Inserting messages...")
        insert_messages(cur)

        print("Inserting subscriptions...")
        insert_subscriptions(cur)

        print("Inserting stream-game relationships...")
        insert_stream_games(cur)

        # Подтверждаем транзакцию
        conn.commit()
        print("Data inserted successfully!")

    except Exception as e:
        print(f"An error occurred: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()
