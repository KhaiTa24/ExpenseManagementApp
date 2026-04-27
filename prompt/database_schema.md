Database Schema \& Data Structure

SQLite Schema

Users

CREATE TABLE users (

&nbsp; id TEXT PRIMARY KEY,

&nbsp; email TEXT UNIQUE,

&nbsp; display\_name TEXT,

&nbsp; created\_at INTEGER

);



Categories

CREATE TABLE categories (

&nbsp; id TEXT PRIMARY KEY,

&nbsp; user\_id TEXT,

&nbsp; name TEXT NOT NULL,

&nbsp; icon TEXT,

&nbsp; color TEXT,

&nbsp; type TEXT CHECK(type IN ('income', 'expense')),

&nbsp; is\_default INTEGER DEFAULT 0,

&nbsp; created\_at INTEGER,

&nbsp; FOREIGN KEY (user\_id) REFERENCES users(id)

);



Transactions

CREATE TABLE transactions (

&nbsp; id TEXT PRIMARY KEY,

&nbsp; user\_id TEXT,

&nbsp; category\_id TEXT,

&nbsp; amount REAL NOT NULL,

&nbsp; type TEXT CHECK(type IN ('income', 'expense')),

&nbsp; description TEXT,

&nbsp; date INTEGER NOT NULL,

&nbsp; created\_at INTEGER,

&nbsp; updated\_at INTEGER,

&nbsp; FOREIGN KEY (user\_id) REFERENCES users(id),

&nbsp; FOREIGN KEY (category\_id) REFERENCES categories(id)

);



Budgets

CREATE TABLE budgets (

&nbsp; id TEXT PRIMARY KEY,

&nbsp; user\_id TEXT,

&nbsp; category\_id TEXT,

&nbsp; amount REAL NOT NULL,

&nbsp; period TEXT CHECK(period IN ('monthly', 'yearly')),

&nbsp; month INTEGER,

&nbsp; year INTEGER,

&nbsp; created\_at INTEGER,

&nbsp; FOREIGN KEY (user\_id) REFERENCES users(id),

&nbsp; FOREIGN KEY (category\_id) REFERENCES categories(id)

);



Settings

CREATE TABLE settings (

&nbsp; id TEXT PRIMARY KEY,

&nbsp; user\_id TEXT,

&nbsp; key TEXT NOT NULL,

&nbsp; value TEXT,

&nbsp; FOREIGN KEY (user\_id) REFERENCES users(id)

);



