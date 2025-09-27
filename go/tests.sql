CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    age INT,
    country VARCHAR(100),
    phone_number VARCHAR(15),
    registration_date DATE
);