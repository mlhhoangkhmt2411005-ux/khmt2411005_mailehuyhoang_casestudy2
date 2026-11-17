# CASE STUDY 2 - DỰ ÁN QUẢN LÝ VÀ GIAO CÔNG VIỆC NHÓM

## 👤 Thông tin cá nhân
- **Họ và tên:** Mai Lê Huy Hoàng
- **Mã số sinh viên (MSSV):** KHMT2411005
- **Môn học:** Case Study 2 - Mobile App & Web API

---

## 📌 Nội dung thực hiện (Phần A & Phần B)

### A. Quản lý tài khoản & Xác thực
1. **Đăng ký / Đăng nhập**: Xác thực qua Email & Mật khẩu với băm mật khẩu `bcryptjs` và cấp mã token JWT (`auth/register`, `auth/login`).
2. **Quản lý Hồ sơ**: Xem & cập nhật họ tên, đổi mật khẩu (`auth/me`, `auth/change-password`).
3. **Bảo mật**: Xác thực Middleware Bearer Token cho toàn bộ API bảo mật.

### B. Quản lý công việc (Task Management)
1. **Danh sách công việc (`TaskListScreen`)**:
   - Hiển thị công việc tạo mới, được giao và chia sẻ.
   - Tìm kiếm công việc theo tên (`q`).
   - Lọc công việc theo trạng thái: Chưa thực hiện (`todo`), Đang thực hiện (`in_progress`), Đã hoàn thành (`completed`).
   - Lọc công việc theo mức độ ưu tiên: Thấp (`low`), Trung bình (`medium`), Cao (`high`).
   - Sắp xếp công việc theo: Hạn hoàn thành (`dueDate`), Mức độ ưu tiên (`priority`), Ngày tạo (`createdAt`).
2. **Chi tiết công việc (`TaskDetailScreen`)**:
   - Xem thông tin tên, mô tả, ngày bắt đầu, hạn hoàn thành, người tạo.
   - Cập nhật nhanh trạng thái trực tiếp bằng thanh lựa chọn.
   - Nút Chỉnh sửa & Xóa công việc.
3. **Thêm & Chỉnh sửa công việc (`TaskFormScreen`)**:
   - Nhập tên công việc, mô tả chi tiết, chọn ngày bắt đầu & hạn hoàn thành qua DatePicker.
   - Chọn mức độ ưu tiên & trạng thái.
   - Kiểm tra ràng buộc hợp lệ: Tên không trống, hạn hoàn thành không trước ngày bắt đầu.
4. **Cập nhật trạng thái nhanh**:
   - Chuyển đổi trạng thái trực tiếp trên thẻ công việc (Card) và chi tiết công việc.

---

## 🚀 Hướng dẫn khởi chạy dự án

### 1. Khởi chạy Backend API (Node.js / Express / MongoDB)
```bash
cd api
npm install
npm run dev
# Máy chủ REST API sẽ chạy tại: http://localhost:3000/api
```

### 2. Khởi chạy App Frontend (Flutter)
```bash
flutter pub get
flutter run
```
*Ghi chú:*
- Khi chạy trên Android Emulator, ứng dụng tự động kết nối qua `http://10.0.2.2:3000/api`.
- Khi chạy Web hoặc Desktop, ứng dụng tự động kết nối `http://localhost:3000/api`.
