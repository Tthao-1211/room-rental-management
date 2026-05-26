# Hệ Thống Quản Lý Thuê Phòng

Ứng dụng web quản lý thuê phòng xây dựng bằng ASP.NET MVC 5, cung cấp chức năng danh sách phòng, tìm kiếm, đặt phòng, hợp đồng, hóa đơn và theo dõi thanh toán.

**Phiên bản .NET mục tiêu:** .NET Framework 4.8.1

**IIS Express (mặc định):** https://localhost:44330/

**Thư viện chính:** Entity Framework 6.2.0, Bootstrap 5, jQuery

**Tệp SQL tạo dữ liệu mẫu:** `QuanLyThuePhongTro.sql`

**Connection string mặc định:** được cấu hình trong `Project_65133295/Web.config` (tên: `DbContext_65133295`).

**Lưu ý:** file cấu hình hiện trỏ tới instance `tthao\\SQLEXPRESS` và cơ sở dữ liệu `QuanLyThuePhongTroThanhThao`.

**Tính năng chính**
- Quản trị viên: quản lý phòng, duyệt/ quản lý đặt phòng, quản lý hợp đồng, tạo hóa đơn, quản lý người dùng, duyệt đánh giá, nhật ký hoạt động.
- Người dùng (chủ/phòng): quản lý phòng của mình, xem/ tạo hợp đồng, theo dõi hóa đơn và thanh toán.
- Khách: tìm kiếm phòng, xem chi tiết phòng, đăng ký/đăng nhập, gửi yêu cầu đặt phòng.

**Yêu cầu hệ thống**
- Windows, Visual Studio 2019/2022 hoặc tương đương

- .NET Framework 4.8.1
- SQL Server (LocalDB, SQL Express hoặc SQL Server) tương thích

**Cài đặt nhanh (development)**
1. Mở solution: `Project_65133295/Project_65133295.sln` bằng Visual Studio.
2. Khôi phục NuGet packages (Visual Studio sẽ tự động restore khi build). Nếu cần dùng CLI: `nuget restore Project_65133295.sln`.
3. Thiết lập cơ sở dữ liệu:
   - Mở `QuanLyThuePhongTro.sql` trong SQL Server Management Studio và chạy script để tạo cơ sở dữ liệu (nếu bạn muốn import dữ liệu mẫu).
   - Hoặc cập nhật connection string trong `Project_65133295/Web.config` tới server của bạn.
   - Ví dụ connection string trong `Web.config`:
     ```xml
     <add name="DbContext_65133295" connectionString="data source=tthao\\SQLEXPRESS;initial catalog=QuanLyThuePhongTroThanhThao;integrated security=True;trustservercertificate=True;MultipleActiveResultSets=True;App=EntityFramework" providerName="System.Data.SqlClient" />
     ```
4. Cấu hình SMTP gửi email (nếu cần): mở `Project_65133295/Web.config` và chỉnh `EmailHost`, `EmailPort`, `EmailUser`, `EmailPassword` trong `appSettings`.
5. Build solution (`Ctrl+Shift+B`). Đặt `Project_65133295` làm startup project và chạy (F5).

**Cấu trúc chính của dự án**
- `Areas/Admin` — Trang quản trị
- `Areas/User` — Chức năng người dùng
- `Controllers` — Controller chính (ví dụ `Guest_65133295Controller`)
- `Models` — Entity và ViewModel
- `Views` — Razor views
- `Content` / `Scripts` — CSS, JS (Bootstrap 5, jQuery)

**Ghi chú quan trọng**
- Mặc định project sử dụng SQL Server instance `tthao\\SQLEXPRESS` (kiểm tra và thay đổi nếu cần).
- SMTP trong `Web.config` hiện chứa giá trị mẫu — không lưu mật khẩu thật trong repo.