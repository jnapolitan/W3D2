DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;


CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(250) NOT NULL,
  lname VARCHAR(250) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(250) NOT NULL,
  body VARCHAR(250) NOT NULL,
  user_id INTEGER NOT NULL,
  
  FOREIGN KEY(user_id) REFERENCES users (id)
);

CREATE TABLE question_follows (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  
  FOREIGN KEY(user_id) REFERENCES users (id),
  FOREIGN KEY(question_id) REFERENCES questions (id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body VARCHAR(250) NOT NULL,
  
  FOREIGN KEY(user_id) REFERENCES users (id),
  FOREIGN KEY(question_id) REFERENCES questions (id),
  FOREIGN KEY(parent_id) REFERENCES replies (id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  
  FOREIGN KEY(user_id) REFERENCES users (id),
  FOREIGN KEY(question_id) REFERENCES questions (id)
);

INSERT INTO 
  users (fname, lname)
VALUES 
  ('Julian', 'Napolitan'),
  ('Nikki', 'Hui'),
  ('Bob', 'Sam');
  
INSERT INTO 
  questions (title, body, user_id)
VALUES 
  ('What am I doing here?', 'See above', (SELECT id FROM users WHERE fname = 'Julian')),
  ('What are you doing here?', 'See above', (SELECT id FROM users WHERE fname = 'Nikki')),
  ('Where is everybody?', 'See above', (SELECT id FROM users WHERE fname = 'Bob'));

INSERT INTO 
  replies (question_id, parent_id, user_id, body)
VALUES 
  ((SELECT id FROM questions WHERE title = 'What am I doing here?'), NULL, (SELECT id FROM users WHERE fname = 'Bob'), 'I don''t know');

INSERT INTO 
  replies (question_id, parent_id, user_id, body)
VALUES 
  ((SELECT id FROM questions WHERE title = 'What am I doing here?'), (SELECT id FROM replies WHERE body = 'I don''t know'), (SELECT id FROM users WHERE fname = 'Nikki'), 'Classic Bob');

INSERT INTO 
  question_likes (user_id, question_id)
VALUES 
  ((SELECT id FROM users WHERE fname = 'Bob'), (SELECT id FROM questions WHERE title = 'What am I doing here?'));
  
INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Bob'), (SELECT id FROM questions WHERE title = 'What am I doing here?')),
  ((SELECT id FROM users WHERE fname = 'Nikki'), (SELECT id FROM questions WHERE title = 'What am I doing here?'));
  
  


