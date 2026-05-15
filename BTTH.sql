-- Tạo cơ sở dữ liệu và sử dụng
CREATE DATABASE SocialNetworkDB;
USE SocialNetworkDB;

-- Bảng Users
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng Posts
CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Bảng Likes
CREATE TABLE Likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Bảng Comments
CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Bảng Friends
CREATE TABLE Friends (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status ENUM('pending','accepted','blocked') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Index cho Posts theo thời gian
CREATE INDEX idx_posts_created_at ON Posts(created_at);

-- Dữ liệu mẫu
INSERT INTO Users (username, password, email) VALUES
('alice', 'pass123', 'alice@example.com'),
('bob', 'pass456', 'bob@example.com'),
('charlie', 'pass789', 'charlie@example.com');

INSERT INTO Posts (user_id, content) VALUES
(1, 'Hello world! Đây là bài viết đầu tiên của Alice.'),
(2, 'Bob vừa tham gia mạng xã hội này.'),
(3, 'Charlie chia sẻ một bài viết thú vị.');

INSERT INTO Likes (post_id, user_id) VALUES
(1, 2),
(1, 3),
(2, 1);

INSERT INTO Comments (post_id, user_id, content) VALUES
(1, 2, 'Chào Alice!'),
(1, 3, 'Bài viết hay đó.'),
(2, 1, 'Welcome Bob!');

INSERT INTO Friends (user_id, friend_id, status) VALUES
(1, 2, 'accepted'),
(1, 3, 'accepted'),
(2, 3, 'pending');

-- ============================
-- VIEW & STORED PROCEDURE THEO ĐỀ
-- ============================

-- Chức năng 1: Hiển thị hồ sơ người dùng an toàn
CREATE VIEW view_user_info AS
SELECT user_id, username, email, created_at
FROM Users;

-- Chức năng 2: Báo cáo thống kê tương tác
CREATE VIEW view_post_statistics AS
SELECT p.post_id, u.username, p.content, p.created_at,
       COUNT(DISTINCT l.like_id) AS total_likes,
       COUNT(DISTINCT c.comment_id) AS total_comments
FROM Posts p
JOIN Users u ON p.user_id = u.user_id
LEFT JOIN Likes l ON p.post_id = l.post_id
LEFT JOIN Comments c ON p.post_id = c.post_id
WHERE p.is_deleted = FALSE
GROUP BY p.post_id, u.username, p.content, p.created_at;

-- Chức năng 3: Xử lý đăng ký tài khoản
DELIMITER //
CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(100),
    IN p_email VARCHAR(100)
)
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email đã được sử dụng';
    ELSE
        INSERT INTO Users(username, password, email)
        VALUES (p_username, p_password, p_email);
    END IF;
END //
DELIMITER ;

-- Chức năng 4: Đăng bài viết và lấy mã định danh
DELIMITER //
CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN
    INSERT INTO Posts(user_id, content) VALUES (p_user_id, p_content);
    SET p_new_post_id = LAST_INSERT_ID();
END //
DELIMITER ;

-- Chức năng 5: Danh sách bạn bè phân trang
DELIMITER //
CREATE PROCEDURE sp_get_friends(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT u.user_id, u.username, u.email, f.created_at
    FROM Friends f
    JOIN Users u ON f.friend_id = u.user_id
    WHERE f.user_id = p_user_id AND f.status = 'accepted'
    LIMIT p_limit OFFSET p_offset;
END //
DELIMITER ;
