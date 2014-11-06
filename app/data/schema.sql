DROP DATABASE IF EXISTS social_app;
CREATE DATABASE social_app;

\c social_app

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  password TEXT NOT NULL,
  description TEXT,
  photo TEXT
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  content TEXT NOT NULL,
  author_id INTEGER REFERENCES users(id),
  date TEXT NOT NULL
);

CREATE TABLE friends (
  id SERIAL PRIMARY KEY,
  user_id_1 INTEGER REFERENCES users(id) NOT NULL,
  user_id_2 INTEGER REFERENCES users(id) NOT NULL,
  status INT
);

CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES posts(id),
  content TEXT NOT NULL, 
  author_id INTEGER REFERENCES users(id),
  date TEXT NOT NULL
);