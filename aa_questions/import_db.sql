
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname VARCHAR NOT NULL,
    lname VARCHAR NOT NULL
);



CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    body VARCHAR NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_id INTEGER,
    reply_id INTEGER NOT NULL,
    body VARCHAR,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_id) REFERENCES replies(id),
    FOREIGN KEY (reply_id) REFERENCES users(id)
);


CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);



-- USERS INSERT
INSERT INTO 
    users (fname, lname)
VALUES
    ('Jeff', 'T'),
    ('Alex', 'V');

-- QUESTION INSERT
INSERT INTO
    questions (title, body, author_id)
VALUES 
    ('SQL Queries', 'How does this thing work?', (SELECT id FROM users WHERE lname = 'V')),
    ('Random','Why do humans yawn?', (SELECT id FROM users WHERE lname = 'T'));

-- QF INSERTS


INSERT INTO 
    question_follows (question_id, user_id) 
VALUES
    -- (1, 2),
    -- (2, 1) ;
-- question by V, followed by J
    (
    (SELECT id FROM questions WHERE author_id = (SELECT id FROM users WHERE lname = 'V')), 
    
    (SELECT id FROM users WHERE lname = 'T')
    ),
-- question by J followed by V
    ( 
    (SELECT id FROM questions WHERE author_id = (SELECT id FROM users WHERE lname = 'T')), 
    
    (SELECT id FROM users WHERE lname = 'V')
    );

-- REPLIES
INSERT INTO
    replies (question_id, parent_id, reply_id, body)
VALUES
    -- ONE REPLY Jeffrey replies to Alex's questions
    (  (SELECT id FROM questions WHERE reply_id = (SELECT id FROM users WHERE lname = 'V')),  -- question id 
      NULL, -- parent id 
        (SELECT id FROM users WHERE lname = 'T'),   -- author of reply id 
        'idk bro'                           -- body
    );



-- QLIKES
INSERT INTO 
    question_likes(user_id, question_id)
VALUES
-- ALEX LIKES JEFFREY's QUESTION
    ( 
         (SELECT id FROM users WHERE lname = 'V'),   -- user id
         (SELECT id FROM questions WHERE author_id = (SELECT id FROM users WHERE lname = 'T')) -- question id 
    );