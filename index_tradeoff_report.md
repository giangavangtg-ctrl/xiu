# Báo cáo Chẩn đoán và Thiết kế Giải pháp Index - SmartFactory

## 1. Chẩn đoán vấn đề (Fat Index)
Hệ thống IoT ghi nhận dữ liệu liên tục với tần suất khổng lồ. Việc lập trình viên cũ tạo Covering Index (`idx_fat_covering`) chứa toàn bộ 5 cột đã biến Index này thành một "bản sao" thứ hai của bảng dữ liệu. Mỗi lần có dữ liệu cảm biến gửi về (INSERT), MySQL phải cập nhật cấu trúc cây B-Tree cho những dữ liệu liên tục thay đổi (như nhiệt độ, độ ẩm). Điều này gây ra "Write Penalty" (Hình phạt ghi) cực lớn, làm thắt cổ chai I/O ổ đĩa, tiêu tốn RAM và làm cạn kiệt dung lượng lưu trữ một cách vô nghĩa.

## 2. Giải pháp Cân bằng (Lean Index)
Kiến trúc Index mới (`idx_lean_search`) được thu gọn chỉ còn 2 cột: `sensor_id` và `recorded_at`. Đây là 2 cột phục vụ trực tiếp cho mệnh đề `WHERE` để định vị dữ liệu.

**Sự đánh đổi:**
- **Nhược điểm (Read):** Lệnh SELECT bị chậm đi một phần nghìn giây. Lý do là hệ thống mất đi Covering Index (không còn dòng chữ *Using index* trong Extra). MySQL tìm được con trỏ trên Index, sau đó bắt buộc phải "nhảy" vào bảng gốc (Clustered Index/Data Pages) để bốc các cột `temperature`, `humidity`, `status` ra ngoài.
- **Ưu điểm (Write & Storage):** Tốc độ INSERT tăng vọt vì B-Tree giờ đây rất nhẹ. Dung lượng Index giảm hơn 70%, giải phóng bộ nhớ Buffer Pool cho các tác vụ quan trọng khác. Sự đánh đổi này là hoàn toàn chính xác và mang tính sống còn đối với một hệ thống IoT.