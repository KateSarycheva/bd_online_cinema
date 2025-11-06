CREATE DATABASE bd_online_cinema;

SELECT current_database();

SELECT CURRENT_USER;

-- 1.Основная схема для базовых сущностей
CREATE SCHEMA base;

SELECT CURRENT_SCHEMA;

-- 2.Для финансовых данных (изоляция, безопасность)
CREATE SCHEMA payment;

-- 3.Для аналитики и отчетности (тяжелые запросы)
CREATE SCHEMA analytics;

-- 4.Для пользовательского контента (рецензии, комментарии)
CREATE SCHEMA content;

-- Для таблиц
CREATE TABLESPACE tablespace_data LOCATION 'E:\postgres_data';

-- Для индексов  
CREATE TABLESPACE tablespace_index LOCATION 'D:\postgres_index';

--------------------------------------------------------------------------------------------------------

-- 1. пользователи
CREATE TABLE base."user" (
    user_id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(50) NOT NULL
);

-- Ускоряет авторизацию по логину/паролю
CREATE INDEX idx_user_login_password ON base."user"(login, password);
-- Ускоряет поиск по логину
CREATE INDEX idx_user_login ON base."user"(login);

-- 2. фильмы
CREATE TABLE base.movie (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    description TEXT,
    year INTEGER,
    country VARCHAR(50),
    rating NUMERIC
);

CREATE INDEX idx_movie_title ON base.movie(title);
CREATE INDEX idx_movie_country ON base.movie(country);
CREATE INDEX idx_movie_year ON base.movie(year);
CREATE INDEX idx_movie_rating ON base.movie(rating);

-- Составные индексы для популярных комбинаций
CREATE INDEX idx_movie_year_rating ON base.movie(year, rating);
CREATE INDEX idx_movie_country_year ON base.movie(country, year);

-- 3. персоны (актеры/режиссеры)
CREATE TABLE base.person (
    person_id SERIAL PRIMARY KEY,
    full_name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL
);

-- Ускоряет поиск персон по имени
CREATE INDEX idx_person_full_name ON base.person(full_name);

-- Ускоряет фильтрацию по роли
CREATE INDEX idx_person_role ON base.person(role);

-- 4. жанры
CREATE TABLE base.genre (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE INDEX idx_genre_name ON base.genre(name);

-- 5. рецензии
CREATE TABLE content.review (
    review_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES base."user"(user_id),
    movie_id INTEGER REFERENCES base.movie(movie_id),
    review_text TEXT NOT NULL
);

-- Ускоряет получение рецензий пользователя
CREATE INDEX idx_review_user_id ON content.review(user_id);

-- Ускоряет получение рецензий на фильм
CREATE INDEX idx_review_movie_id ON content.review(movie_id);

-- Ускоряет поиск рецензий по пользователю и фильму
CREATE INDEX idx_review_user_movie ON content.review(user_id, movie_id);

-- 6. истории просмотров
CREATE TABLE analytics.view_history (
    view_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES base."user"(user_id),
    movie_id INTEGER REFERENCES base.movie(movie_id)
);

-- Ускоряет получение истории просмотров пользователя
CREATE INDEX idx_view_history_user_id ON analytics.view_history(user_id);

-- Ускоряет аналитику по популярности фильмов
CREATE INDEX idx_view_history_movie_id ON analytics.view_history(movie_id);

-- 7. избранное
CREATE TABLE content.favorites (
    user_id INTEGER REFERENCES base."user"(user_id),
    movie_id INTEGER REFERENCES base.movie(movie_id),
    PRIMARY KEY (user_id, movie_id)
);

CREATE INDEX idx_favorites_user_id ON content.favorites(user_id);
CREATE INDEX idx_favorites_movie_id ON content.favorites(movie_id);

-- 8. Связующая таблица фильмы-жанры
CREATE TABLE base.movie_genre (
    movie_id INTEGER REFERENCES base.movie(movie_id),
    genre_id INTEGER REFERENCES base.genre(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

-- Ускоряет поиск фильмов по жанру
CREATE INDEX idx_movie_genre_genre_id ON base.movie_genre(genre_id);
-- Ускоряет получение жанров фильма
CREATE INDEX idx_movie_genre_movie_id ON base.movie_genre(movie_id);

-- 9. Связующая таблица фильмы-персоны
CREATE TABLE base.movie_person (
    movie_id INTEGER REFERENCES base.movie(movie_id),
    person_id INTEGER REFERENCES base.person(person_id),
    PRIMARY KEY (movie_id, person_id)
);

-- Ускоряет поиск фильмов по персоне
CREATE INDEX idx_movie_person_person_id ON base.movie_person(person_id);

-- Ускоряет получение персон фильма
CREATE INDEX idx_movie_person_movie_id ON base.movie_person(movie_id);

-------------------------------------------------------------------------------------------------------------

-- 10. таблица тарифных планов
CREATE TABLE "subscription".subscription_plan (
    plan_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC,
    duration_days INTEGER
);

-- Ускоряет поиск тарифов по цене
CREATE INDEX idx_plan_price ON subscription.subscription_plan(price);
-- Ускоряет поиск тарифов по продолжительности
CREATE INDEX idx_plan_duration_days ON subscription.subscription_plan(duration_days);

-- 11. таблица подписок пользователей
CREATE TABLE "subscription".user_subscription (
    subscription_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES base."user"(user_id),
    plan_id INTEGER NOT NULL REFERENCES "subscription".subscription_plan(plan_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL
);

-- Ускоряет проверку активных подписок пользователя
CREATE INDEX idx_user_subscription_user_id ON subscription.user_subscription(user_id);

-- Ускоряет поиск подписок по статусу
CREATE INDEX idx_user_subscription_status ON subscription.user_subscription(status);

CREATE INDEX idx_user_subscription_dates ON subscription.user_subscription(start_date, end_date);
CREATE INDEX idx_user_subscription_end_date ON subscription.user_subscription(end_date);

-- 13. таблица комментариев к рецензиям
CREATE TABLE content.review_comment (
    comment_id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES content.review(review_id),
    parent_comment_id INTEGER REFERENCES content.review_comment(comment_id),
    user_id INTEGER REFERENCES base."user"(user_id),
    comment_text TEXT NOT NULL
);

-- Ускоряет получение комментариев к рецензии
CREATE INDEX idx_review_comment_review_id ON content.review_comment(review_id);

CREATE INDEX idx_review_comment_parent_id ON content.review_comment(parent_comment_id);

-- Ускоряет получение комментариев пользователя
CREATE INDEX idx_review_comment_user_id ON content.review_comment(user_id);

CREATE INDEX idx_review_comment_review_parent ON content.review_comment(review_id, parent_comment_id);

--------------------------------------------------------------------------------------------------------

-- Схема (base)
COMMENT ON SCHEMA base IS 'Основные сущности системы: пользователи, фильмы, персоны, жанры';

-- Таблица: "user"
COMMENT ON TABLE base."user" IS 'Пользователи онлайн-кинотеатра';
COMMENT ON COLUMN base."user".user_id IS 'Уникальный идентификатор пользователя';
COMMENT ON COLUMN base."user".login IS 'Уникальный логин для входа в систему';
COMMENT ON COLUMN base."user".password IS 'Пароль пользователя';

-- Таблица: movie
COMMENT ON TABLE base.movie IS 'Фильмы и сериалы в каталоге онлайн-кинотеатра';
COMMENT ON COLUMN base.movie.movie_id IS 'Уникальный идентификатор фильма';
COMMENT ON COLUMN base.movie.title IS 'Название фильма';
COMMENT ON COLUMN base.movie.description IS 'Описание фильма';
COMMENT ON COLUMN base.movie.year IS 'Год выпуска фильма';
COMMENT ON COLUMN base.movie.country IS 'Страна производства фильма';
COMMENT ON COLUMN base.movie.rating IS 'Рейтинг фильма';

-- Таблица: person
COMMENT ON TABLE base.person IS 'Персоны киноиндустрии: актеры, режиссеры, сценаристы и др.';
COMMENT ON COLUMN base.person.person_id IS 'Уникальный идентификатор персоны';
COMMENT ON COLUMN base.person.full_name IS 'Полное имя персоны';
COMMENT ON COLUMN base.person.role IS 'Роль в кинопроизводстве: actor, director, writer';

-- Таблица: genre
COMMENT ON TABLE base.genre IS 'Жанры фильмов и сериалов';
COMMENT ON COLUMN base.genre.genre_id IS 'Уникальный идентификатор жанра';
COMMENT ON COLUMN base.genre.name IS 'Название жанра: драма, комедия, боевик и др.';


-- Таблица: movie_genre
COMMENT ON TABLE base.movie_genre IS 'Связующая таблица между фильмами и жанрами';
COMMENT ON COLUMN base.movie_genre.movie_id IS 'Внешний ключ к фильму (часть первичного ключа)';
COMMENT ON COLUMN base.movie_genre.genre_id IS 'Внешний ключ к жанру (часть первичного ключа)';

-- Таблица: movie_person
COMMENT ON TABLE base.movie_person IS 'Связующая таблица между фильмами и персонами';
COMMENT ON COLUMN base.movie_person.movie_id IS 'Внешний ключ к фильму (часть первичного ключа)';
COMMENT ON COLUMN base.movie_person.person_id IS 'Внешний ключ к персоне (часть первичного ключа)';

--------------------------------------------------------------------------------------------------------

-- Схема (content)
COMMENT ON SCHEMA content IS 'Пользовательский контент: рецензии, комментарии, избранное';

-- Таблица: favorites
COMMENT ON TABLE content.favorites IS 'Избранные фильмы, сериалы пользователей';
COMMENT ON COLUMN content.favorites.user_id IS 'Внешний ключ к пользователю (часть первичного ключа)';
COMMENT ON COLUMN content.favorites.movie_id IS 'Внешний ключ к фильму (часть первичного ключа)';

-- Таблица: review
COMMENT ON TABLE content.review IS 'Пользовательские рецензии на фильмы/сериалы';
COMMENT ON COLUMN content.review.review_id IS 'Уникальный идентификатор рецензии';
COMMENT ON COLUMN content.review.user_id IS 'Внешний ключ к пользователю, автору рецензии';
COMMENT ON COLUMN content.review.movie_id IS 'Внешний ключ к фильму, на который написана рецензия';
COMMENT ON COLUMN content.review.review_text IS 'Текст рецензии';

-- Таблица: review_comment
COMMENT ON TABLE content.review_comment IS 'Комментарии (ответы) к пользовательским рецензиям';
COMMENT ON COLUMN content.review_comment.comment_id IS 'Уникальный идентификатор комментария';
COMMENT ON COLUMN content.review_comment.review_id IS 'Внешний ключ к рецензии, к которой относится комментарий';
COMMENT ON COLUMN content.review_comment.parent_comment_id IS 'Внешний ключ к родительскому комментарию';
COMMENT ON COLUMN content.review_comment.user_id IS 'Внешний ключ к пользователю, автору комментария';
COMMENT ON COLUMN content.review_comment.comment_text IS 'Текст комментария';

--------------------------------------------------------------------------------------------------------

-- Схема (analytics)
COMMENT ON SCHEMA analytics IS 'Аналитические данные и история просмотров';

-- Таблица: view_history
COMMENT ON TABLE analytics.view_history IS 'История просмотров пользователей для аналитики и рекомендаций';
COMMENT ON COLUMN analytics.view_history.view_id IS 'Уникальный идентификатор просмотра';
COMMENT ON COLUMN analytics.view_history.user_id IS 'Внешний ключ к пользователю, который смотрел фильм';
COMMENT ON COLUMN analytics.view_history.movie_id IS 'Внешний ключ к просмотренному фильму';

--------------------------------------------------------------------------------------------------------

--Схема (subscription)
COMMENT ON SCHEMA subscription IS 'Тарифные планы и подписки';

-- Таблица: subscription_plan
COMMENT ON TABLE subscription.subscription_plan IS 'Тарифные планы подписок с различными условиями';
COMMENT ON COLUMN subscription.subscription_plan.plan_id IS 'Уникальный идентификатор тарифного плана';
COMMENT ON COLUMN subscription.subscription_plan.name IS 'Название тарифного плана: Базовый, Премиум, Семейный и др.';
COMMENT ON COLUMN subscription.subscription_plan.price IS 'Стоимость подписки';
COMMENT ON COLUMN subscription.subscription_plan.duration_days IS 'Продолжительность подписки';

-- Таблица: user_subscription
COMMENT ON TABLE subscription.user_subscription IS 'Активные и архивные подписки пользователей';
COMMENT ON COLUMN subscription.user_subscription.subscription_id IS 'Уникальный идентификатор подписки';
COMMENT ON COLUMN subscription.user_subscription.user_id IS 'Внешний ключ к пользователю-владельцу подписки';
COMMENT ON COLUMN subscription.user_subscription.plan_id IS 'Внешний ключ к тарифному плану подписки';
COMMENT ON COLUMN subscription.user_subscription.start_date IS 'Дата начала действия подписки';
COMMENT ON COLUMN subscription.user_subscription.end_date IS 'Дата окончания действия подписки';
COMMENT ON COLUMN subscription.user_subscription.status IS 'Статус подписки: active-активна, expired-истекла, cancelled-отменена';

-----------------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------------------

-- Заполнение таблицы пользователей с хешированными паролями
INSERT INTO base."user" (login, password)
SELECT 
    'user_' || seq || '_' || substr(md5(random()::text), 1, 8) as login,
    -- Хеш: md5(логин + соль + случайная строка)
    md5(
        'user_' || seq || 
        '_salt_' || 
        substr(md5(random()::text), 1, 12)
    ) as password
FROM generate_series(1, 1500) as seq;

-- Заполнение таблицы жанров
INSERT INTO base.genre (name)
VALUES 
    ('драма'), ('комедия'), ('боевик'), ('триллер'), ('фантастика'),
    ('фэнтези'), ('ужасы'), ('мелодрама'), ('детектив'), ('приключения'),
    ('аниме'), ('документальный'), ('биография'), ('исторический'), ('мультфильм'),
    ('семейный'), ('мюзикл'), ('спорт');

-- Заполнение таблицы персон
INSERT INTO base.person (full_name, role)
SELECT 
    CASE 
        WHEN seq % 4 = 0 THEN 'Актер ' || seq || ' ' || substr(md5(random()::text), 1, 6)
        WHEN seq % 4 = 1 THEN 'Режиссер ' || seq || ' ' || substr(md5(random()::text), 1, 6)
        WHEN seq % 4 = 2 THEN 'Продюсер ' || seq || ' ' || substr(md5(random()::text), 1, 6)
        ELSE 'Сценарист ' || seq || ' ' || substr(md5(random()::text), 1, 6)
    END as full_name,
    CASE 
        WHEN seq % 4 = 0 THEN 'actor'
        WHEN seq % 4 = 1 THEN 'director'
        WHEN seq % 4 = 2 THEN 'producer'
        ELSE 'writer'
    END as role
FROM generate_series(1, 1000) as seq;

-- Заполнение таблицы фильмов
INSERT INTO base.movie (title, description, year, country, rating)
SELECT 
    'Фильм ' || seq || ': ' || 
    CASE (seq % 20)
        WHEN 0 THEN 'Путешествие во времени'
        WHEN 1 THEN 'Тайна океана'
        WHEN 2 THEN 'Город мечты'
        WHEN 3 THEN 'Последний рубеж'
        WHEN 4 THEN 'Эхо прошлого'
        WHEN 5 THEN 'Неизвестная вселенная'
        WHEN 6 THEN 'Скрытая угроза'
        WHEN 7 THEN 'Путь воина'
        WHEN 8 THEN 'Забытые истории'
        WHEN 9 THEN 'Новые горизонты'
        WHEN 10 THEN 'Темные секреты'
        WHEN 11 THEN 'Свет надежды'
        WHEN 12 THEN 'Конец эпохи'
        WHEN 13 THEN 'Начало пути'
        WHEN 14 THEN 'Потерянный рай'
        WHEN 15 THEN 'Герои нашего времени'
        WHEN 16 THEN 'Тени прошлого'
        WHEN 17 THEN 'Буря страстей'
        WHEN 18 THEN 'Молчание ветра'
        ELSE 'Последний шанс'
    END as title,
    'Описание фильма ' || seq || '. ' ||
    'Это захватывающая история о приключениях, любви и преодолении трудностей. ' ||
    'Главные герои сталкиваются с неожиданными вызовами и должны найти силы для их преодоления.' as description,
    (1920 + (seq % 106)) as year,
    CASE (seq % 10)
        WHEN 0 THEN 'США'
        WHEN 1 THEN 'Россия'
        WHEN 2 THEN 'Великобритания'
        WHEN 3 THEN 'Франция'
        WHEN 4 THEN 'Германия'
        WHEN 5 THEN 'Япония'
        WHEN 6 THEN 'Южная Корея'
        WHEN 7 THEN 'Канада'
        WHEN 8 THEN 'Австралия'
        WHEN 9 THEN 'Испания'
    END as country,
    round((2 + random() * 7.9)::numeric, 1) as rating
FROM generate_series(1, 1200) as seq;

-- Заполнение связей фильмы-жанры
INSERT INTO base.movie_genre (movie_id, genre_id)
SELECT 
    m.movie_id,
    g.genre_id
FROM base.movie m
CROSS JOIN LATERAL (
    SELECT genre_id 
    FROM base.genre 
    ORDER BY random() 
    LIMIT (1 + (random() * 1)::int)
) g
WHERE m.movie_id <= 800
LIMIT 1200
ON CONFLICT DO NOTHING;

-- Заполнение связей фильмы-персоны
INSERT INTO base.movie_person (movie_id, person_id)
SELECT 
    m.movie_id,
    p.person_id
FROM base.movie m
CROSS JOIN LATERAL (
    SELECT person_id 
    FROM base.person 
    WHERE role IN ('actor', 'director')
    ORDER BY random() 
    LIMIT (1 + (random() * 1)::int)
) p
WHERE m.movie_id <= 600
LIMIT 1100
ON CONFLICT DO NOTHING;

-- Заполнение тарифных планов
INSERT INTO subscription.subscription_plan (name, price, duration_days)
VALUES 
    ('Базовый', 299, 30),
    ('Стандартный', 499, 30),
    ('Премиум', 799, 30),
    ('Семейный', 999, 30),
    ('Годовой Базовый', 2990, 365),
    ('Годовой Премиум', 7990, 365),
    ('Бесплатный', 0, 7);

-- Заполнение подписок пользователей
INSERT INTO subscription.user_subscription (user_id, plan_id, start_date, end_date, status)
SELECT 
    u.user_id,
    (SELECT plan_id FROM subscription.subscription_plan ORDER BY random() LIMIT 1) as plan_id,
    CURRENT_DATE - (random() * 365)::int as start_date,
    CURRENT_DATE + (random() * 365)::int as end_date,
    CASE 
        WHEN random() > 0.7 THEN 'expired'
        WHEN random() > 0.9 THEN 'cancelled'
        ELSE 'active'
    END as status
FROM base."user" u
LIMIT 1500;

-- Заполнение истории просмотров
INSERT INTO analytics.view_history (user_id, movie_id)
SELECT 
    u.user_id,
    m.movie_id
FROM base."user" u
CROSS JOIN LATERAL (
    SELECT movie_id 
    FROM base.movie 
    ORDER BY random() 
    LIMIT (1 + (random() * 2)::int)
) m
WHERE random() > 0.1
LIMIT 1800;

-- Заполнение избранного
INSERT INTO content.favorites (user_id, movie_id)
SELECT 
    u.user_id,
    m.movie_id
FROM base."user" u
CROSS JOIN LATERAL (
    SELECT movie_id 
    FROM base.movie 
    ORDER BY random() 
    LIMIT (1 + (random() * 1)::int)
) m
WHERE random() > 0.2
LIMIT 1500;

-- Заполнение рецензий
INSERT INTO content.review (user_id, movie_id, review_text)
SELECT 
    u.user_id,
    m.movie_id,
    'Рецензия пользователя ' || u.login || ' на фильм "' || m.title || '". ' ||
    CASE 
        WHEN random() > 0.7 THEN 'Отличный фильм! Рекомендую к просмотру. '
        WHEN random() > 0.4 THEN 'Неплохой фильм, но есть недостатки. '
        ELSE 'Разочарован. Ожидал большего. '
    END as review_text
FROM base."user" u
CROSS JOIN LATERAL (
    SELECT movie_id, title 
    FROM base.movie 
    ORDER BY random() 
    LIMIT (1 + (random() * 1)::int)
) m
WHERE u.user_id % 2 = 0
LIMIT 1500;

-- Заполнение комментариев к рецензиям
INSERT INTO content.review_comment (review_id, parent_comment_id, user_id, comment_text)
SELECT 
    r.review_id,
    CASE 
        WHEN random() > 0.7 THEN NULL
        ELSE (SELECT comment_id FROM content.review_comment WHERE review_id = r.review_id ORDER BY random() LIMIT 1)
    END as parent_comment_id,
    u.user_id,
    'Комментарий пользователя ' || u.login || '. ' ||
    CASE 
        WHEN random() > 0.6 THEN 'Полностью согласен с автором! '
        ELSE 'Интересная точка зрения. '
    END as comment_text
FROM content.review r
CROSS JOIN base."user" u
WHERE random() > 0.8
LIMIT 1500;

-- Проверка количества записей в таблицах с классификацией
SELECT 
    table_name,
    table_type,
    record_count
FROM (
    SELECT 'base.user' as table_name, 'Измерение' as table_type, COUNT(*) as record_count FROM base."user"
    UNION ALL SELECT 'base.movie', 'Измерение', COUNT(*) FROM base.movie
    UNION ALL SELECT 'base.person', 'Измерение', COUNT(*) FROM base.person
    UNION ALL SELECT 'base.genre', 'Измерение', COUNT(*) FROM base.genre
    UNION ALL SELECT 'base.movie_genre', 'Связующая', COUNT(*) FROM base.movie_genre
    UNION ALL SELECT 'base.movie_person', 'Связующая', COUNT(*) FROM base.movie_person
    UNION ALL SELECT 'subscription.subscription_plan', 'Измерение', COUNT(*) FROM subscription.subscription_plan
    UNION ALL SELECT 'subscription.user_subscription', 'Факт', COUNT(*) FROM subscription.user_subscription
    UNION ALL SELECT 'analytics.view_history', 'Факт', COUNT(*) FROM analytics.view_history
    UNION ALL SELECT 'content.favorites', 'Связующая', COUNT(*) FROM content.favorites
    UNION ALL SELECT 'content.review', 'Факт', COUNT(*) FROM content.review
    UNION ALL SELECT 'content.review_comment', 'Факт', COUNT(*) FROM content.review_comment
) AS counts
ORDER BY 
    CASE table_type
        WHEN 'Факт' THEN 1
        WHEN 'Измерение' THEN 2
        WHEN 'Связующая' THEN 3
    END,
    table_name;



