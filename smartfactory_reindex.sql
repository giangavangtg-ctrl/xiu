-- ========================================================
-- BƯỚC 0: TẠO MÔI TRƯỜNG GIẢ LẬP (Chạy phần này nếu chưa có CSDL)
-- ========================================================
CREATE DATABASE IF NOT EXISTS smartfactory_db;
USE smartfactory_db;

DROP TABLE IF EXISTS SensorLogs;
CREATE TABLE SensorLogs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT NOT NULL,
    recorded_at DATETIME NOT NULL,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    status VARCHAR(20)
);

-- Khởi tạo "Fat Index" gây thảm họa
CREATE INDEX idx_fat_covering ON SensorLogs(sensor_id, recorded_at, temperature, humidity, status);

-- Insert dữ liệu mẫu để test lệnh EXPLAIN
INSERT INTO SensorLogs (sensor_id, recorded_at, temperature, humidity, status) VALUES 
(105, '2026-06-21 10:00:00', 35.5, 60.2, 'NORMAL'),
(105, '2026-06-22 10:05:00', 38.0, 65.0, 'WARNING'),
(106, '2026-06-20 09:00:00', 25.0, 50.0, 'NORMAL');

-- ========================================================
-- BƯỚC 1 & BƯỚC 3: KIỂM TRA DUNG LƯỢNG VÀ TỐI ƯU HÓA (DỌN DẸP)
-- ========================================================
-- 1. Xem kích thước Index ban đầu
SHOW TABLE STATUS LIKE 'SensorLogs';

-- 2. Xóa Fat Index (Kẻ hủy diệt tốc độ Ghi)
ALTER TABLE SensorLogs DROP INDEX idx_fat_covering;

-- 3. Tạo Lean Index (Chỉ mục tinh gọn chỉ dùng để Lọc dữ liệu)
CREATE INDEX idx_lean_search ON SensorLogs(sensor_id, recorded_at);

-- 4. Xem kích thước Index sau khi tối ưu (Sẽ thấy Index_length giảm)
SHOW TABLE STATUS LIKE 'SensorLogs';

-- ========================================================
-- BƯỚC 4: VẬN HÀNH VÀ ĐỐI CHIẾU
-- ========================================================
-- Chạy lệnh EXPLAIN để chứng minh:
-- - type = 'range' hoặc 'ref' (Vẫn dùng Index rất tốt)
-- - key = 'idx_lean_search' (Nhận diện đúng Index mới)
-- - Extra không còn 'Using index' (Báo hiệu MySQL phải lookup vào bảng chính để lấy nhiệt độ, độ ẩm)
EXPLAIN SELECT temperature, humidity, status FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';