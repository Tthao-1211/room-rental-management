-- =====================================================================
-- HỆ THỐNG QUẢN LÝ THUÊ PHÒNG TRỌ - THANHTHAO STAY
-- Phiên bản: 2.0 – Thiết kế lại phân quyền nhân viên
-- =====================================================================

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLyThuePhongTroThanhThao')
    DROP DATABASE QuanLyThuePhongTroThanhThao;
GO

CREATE DATABASE QuanLyThuePhongTroThanhThao;
GO

USE QuanLyThuePhongTroThanhThao;
GO

-- =====================================================================
-- 1. BẢNG USERS
-- =====================================================================
CREATE TABLE Users (
    UserID          INT           PRIMARY KEY IDENTITY(1,1),
    Username        NVARCHAR(50)  UNIQUE NOT NULL,
    Email           NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash    NVARCHAR(255) NOT NULL,
    FirstName       NVARCHAR(100) NULL,
    LastName        NVARCHAR(100) NULL,
    PhoneNumber     NVARCHAR(20)  NULL,
    Role            TINYINT       NOT NULL DEFAULT 2,
    -- Role: 0 = Admin | 1 = NhanVien | 2 = KhachThue
    Avatar          NVARCHAR(500) NULL,
    DateOfBirth     DATE          NULL,
    Gender          NCHAR(1)      NULL,
    IdentityNumber  NVARCHAR(20)  NULL,
    Street          NVARCHAR(255) NULL,
    Ward            NVARCHAR(100) NULL,
    District        NVARCHAR(100) NULL,
    City            NVARCHAR(100) NULL,
    IsActive        BIT           NOT NULL DEFAULT 1,
    IsEmailVerified BIT           NOT NULL DEFAULT 0,
    CreatedAt       DATETIME      NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME      NOT NULL DEFAULT GETDATE(),
    LastLoginAt     DATETIME      NULL,
    CONSTRAINT CK_Users_Role   CHECK (Role   IN (0, 1, 2)),
    CONSTRAINT CK_Users_Gender CHECK (Gender IN ('M', 'F', 'O') OR Gender IS NULL)
);
GO

-- =====================================================================
-- 2. BẢNG EMPLOYEE_GROUPS  (Nhóm quyền nhân viên)
-- =====================================================================
CREATE TABLE EmployeeGroups (
    GroupID          INT           PRIMARY KEY IDENTITY(1,1),
    GroupCode        NVARCHAR(10)  UNIQUE NOT NULL,
    -- 'NVVH'   = Nhân viên Vận hành
    -- 'NVTC'   = Nhân viên Tài chính
    -- 'NVCSKH' = Nhân viên Chăm sóc khách hàng
    GroupName        NVARCHAR(100) NOT NULL,
    Description      NVARCHAR(500) NULL,

    -- ---- Quyền nhóm NVVH (Phòng & Đặt phòng) ----
    CanViewRoom           BIT NOT NULL DEFAULT 0,
    CanEditRoom           BIT NOT NULL DEFAULT 0,
    CanCreateBooking      BIT NOT NULL DEFAULT 0,
    CanApproveBooking     BIT NOT NULL DEFAULT 0,
    CanViewRoomDashboard  BIT NOT NULL DEFAULT 0,

    -- ---- Quyền nhóm NVTC (Hợp đồng & Hóa đơn) ----
    CanCreateContract       BIT NOT NULL DEFAULT 0,
    CanManageContract       BIT NOT NULL DEFAULT 0,
    CanCreatePayment        BIT NOT NULL DEFAULT 0,
    CanTrackPayment         BIT NOT NULL DEFAULT 0,
    CanViewRevenueDashboard BIT NOT NULL DEFAULT 0,

    -- ---- Quyền nhóm NVCSKH (Khách thuê & Đánh giá) ----
    CanViewTenantProfile  BIT NOT NULL DEFAULT 0,
    CanManageReview       BIT NOT NULL DEFAULT 0,
    CanViewBookingHistory BIT NOT NULL DEFAULT 0,

    IsActive  BIT      NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- =====================================================================
-- 3. BẢNG EMPLOYEE_PROFILES  (Hồ sơ nhân viên – nhóm quyền hiện tại)
-- =====================================================================
CREATE TABLE EmployeeProfiles (
    ProfileID    INT          PRIMARY KEY IDENTITY(1,1),
    UserID       INT          NOT NULL UNIQUE,   -- FK → Users (chỉ Role=1)
    GroupID      INT          NOT NULL,          -- FK → EmployeeGroups
    EmployeeCode NVARCHAR(20) UNIQUE NULL,
    Department   NVARCHAR(100) NULL,
    Position     NVARCHAR(100) NULL,
    HiredDate    DATE          NULL,
    Note         NVARCHAR(500) NULL,
    IsActive     BIT           NOT NULL DEFAULT 1,
    CreatedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    UpdatedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_EmpProfiles_User  FOREIGN KEY (UserID)  REFERENCES Users(UserID)          ON DELETE CASCADE,
    CONSTRAINT FK_EmpProfiles_Group FOREIGN KEY (GroupID) REFERENCES EmployeeGroups(GroupID)
);
GO

-- =====================================================================
-- 4. BẢNG ROOM_STATUSES
-- =====================================================================
CREATE TABLE RoomStatuses (
    StatusID    INT           PRIMARY KEY IDENTITY(1,1),
    StatusName  NVARCHAR(50)  UNIQUE NOT NULL,
    Description NVARCHAR(255) NULL
);
GO

-- =====================================================================
-- 5. BẢNG UTILITIES
-- =====================================================================
CREATE TABLE Utilities (
    UtilityID   INT           PRIMARY KEY IDENTITY(1,1),
    UtilityName NVARCHAR(100) UNIQUE NOT NULL,
    Description NVARCHAR(255) NULL,
    Icon        NVARCHAR(100) NULL
);
GO

-- =====================================================================
-- 6. BẢNG ROOMS
-- =====================================================================
CREATE TABLE Rooms (
    RoomID          INT            PRIMARY KEY IDENTITY(1,1),
    RoomNumber      NVARCHAR(50)   NOT NULL,
    AdminID         INT            NOT NULL,
    Title           NVARCHAR(200)  NOT NULL,
    Description     NVARCHAR(MAX)  NULL,
    Area            DECIMAL(10,2)  NULL,
    Price           DECIMAL(18,2)  NOT NULL,
    PriceUnit       NVARCHAR(20)   NOT NULL DEFAULT N'VND/tháng',
    MaxOccupancy    INT            NULL,
    StatusID        INT            NOT NULL,
    CurrentTenantID INT            NULL,
    CreatedAt       DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Rooms_Admin         FOREIGN KEY (AdminID)         REFERENCES Users(UserID),
    CONSTRAINT FK_Rooms_Status        FOREIGN KEY (StatusID)        REFERENCES RoomStatuses(StatusID),
    CONSTRAINT FK_Rooms_CurrentTenant FOREIGN KEY (CurrentTenantID) REFERENCES Users(UserID),
    CONSTRAINT CK_Rooms_Price         CHECK (Price > 0),
    CONSTRAINT CK_Rooms_Area          CHECK (Area IS NULL OR Area > 0)
);
GO

-- =====================================================================
-- 7. BẢNG ROOM_UTILITIES
-- =====================================================================
CREATE TABLE RoomUtilities (
    RoomUtilityID INT PRIMARY KEY IDENTITY(1,1),
    RoomID        INT NOT NULL,
    UtilityID     INT NOT NULL,
    CONSTRAINT FK_RoomUtilities_Room    FOREIGN KEY (RoomID)    REFERENCES Rooms(RoomID)     ON DELETE CASCADE,
    CONSTRAINT FK_RoomUtilities_Utility FOREIGN KEY (UtilityID) REFERENCES Utilities(UtilityID),
    CONSTRAINT UQ_RoomUtility           UNIQUE (RoomID, UtilityID)
);
GO

-- =====================================================================
-- 8. BẢNG ROOM_IMAGES
-- =====================================================================
CREATE TABLE RoomImages (
    ImageID      INT           PRIMARY KEY IDENTITY(1,1),
    RoomID       INT           NOT NULL,
    ImageUrl     NVARCHAR(500) NOT NULL,
    DisplayOrder INT           NOT NULL DEFAULT 1,
    IsMainImage  BIT           NOT NULL DEFAULT 0,
    UploadedAt   DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_RoomImages_Room FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID) ON DELETE CASCADE
);
GO

-- =====================================================================
-- 9. BẢNG BOOKINGS
-- =====================================================================
CREATE TABLE Bookings (
    BookingID     INT            PRIMARY KEY IDENTITY(1,1),
    RoomID        INT            NOT NULL,
    UserID        INT            NOT NULL,
    BookingStatus NVARCHAR(30)   NOT NULL DEFAULT 'Pending',
    CheckInDate   DATETIME       NOT NULL,
    CheckOutDate  DATETIME       NULL,
    Duration      INT            NULL,
    DepositAmount DECIMAL(18,2)  NULL,
    Notes         NVARCHAR(MAX)  NULL,
    ApprovedBy    INT            NULL,
    ApprovedAt    DATETIME       NULL,
    CreatedAt     DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt     DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Bookings_Room  FOREIGN KEY (RoomID)     REFERENCES Rooms(RoomID),
    CONSTRAINT FK_Bookings_User  FOREIGN KEY (UserID)     REFERENCES Users(UserID),
    CONSTRAINT FK_Bookings_Admin FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID),
    CONSTRAINT CK_Bookings_Status CHECK (BookingStatus IN ('Pending','Approved','Rejected','Cancelled'))
);
GO

-- =====================================================================
-- 10. BẢNG CONTRACTS
-- =====================================================================
CREATE TABLE Contracts (
    ContractID     INT            PRIMARY KEY IDENTITY(1,1),
    BookingID      INT            NOT NULL UNIQUE,
    ContractNumber NVARCHAR(50)   UNIQUE NOT NULL,
    StartDate      DATETIME       NOT NULL,
    EndDate        DATETIME       NOT NULL,
    RentalPrice    DECIMAL(18,2)  NOT NULL,
    DepositAmount  DECIMAL(18,2)  NULL,
    ContractTerms  NVARCHAR(MAX)  NULL,
    SignedDate     DATETIME       NULL,
    Status         NVARCHAR(30)   NOT NULL DEFAULT 'Active',
    CreatedAt      DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt      DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Contracts_Booking     FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID),
    CONSTRAINT CK_Contracts_RentalPrice CHECK (RentalPrice > 0),
    CONSTRAINT CK_Contracts_Status      CHECK (Status IN ('Active','Expired','Terminated'))
);
GO

-- =====================================================================
-- 11. BẢNG PAYMENTS
-- =====================================================================
CREATE TABLE Payments (
    PaymentID     INT            PRIMARY KEY IDENTITY(1,1),
    ContractID    INT            NOT NULL,
    UserID        INT            NOT NULL,
    AdminID       INT            NOT NULL,
    InvoiceNumber NVARCHAR(50)   UNIQUE NOT NULL,
    PaymentDate   DATE           NOT NULL,
    Amount        DECIMAL(18,2)  NOT NULL,
    PaymentStatus NVARCHAR(30)   NOT NULL DEFAULT 'Pending',
    PaymentMethod NVARCHAR(50)   NULL,
    DueDate       DATETIME       NULL,
    PaidDate      DATETIME       NULL,
    Notes         NVARCHAR(MAX)  NULL,
    CreatedAt     DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt     DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Payments_Contract FOREIGN KEY (ContractID) REFERENCES Contracts(ContractID),
    CONSTRAINT FK_Payments_User     FOREIGN KEY (UserID)     REFERENCES Users(UserID),
    CONSTRAINT FK_Payments_Admin    FOREIGN KEY (AdminID)    REFERENCES Users(UserID),
    CONSTRAINT CK_Payments_Amount   CHECK (Amount > 0),
    CONSTRAINT CK_Payments_Status   CHECK (PaymentStatus IN ('Pending','Paid','Overdue','Cancelled'))
);
GO

-- =====================================================================
-- 12. BẢNG FEES
-- =====================================================================
CREATE TABLE Fees (
    FeeID       INT            PRIMARY KEY IDENTITY(1,1),
    PaymentID   INT            NOT NULL,
    FeeName     NVARCHAR(100)  NOT NULL,
    FeeAmount   DECIMAL(18,2)  NOT NULL,
    Description NVARCHAR(255)  NULL,
    CONSTRAINT FK_Fees_Payment FOREIGN KEY (PaymentID) REFERENCES Payments(PaymentID) ON DELETE CASCADE,
    CONSTRAINT CK_Fees_Amount  CHECK (FeeAmount >= 0)
);
GO

-- =====================================================================
-- 13. BẢNG REVIEWS
-- =====================================================================
CREATE TABLE Reviews (
    ReviewID  INT            PRIMARY KEY IDENTITY(1,1),
    RoomID    INT            NOT NULL,
    UserID    INT            NOT NULL,
    Rating    DECIMAL(3,1)   NOT NULL,
    Comment   NVARCHAR(MAX)  NULL,
    Status    NVARCHAR(20)   NOT NULL DEFAULT 'Approved',
    CreatedAt DATETIME       NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Room   FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_User   FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT CK_Reviews_Rating CHECK (Rating >= 1.0 AND Rating <= 5.0),
    CONSTRAINT CK_Reviews_Status CHECK (Status IN ('Pending','Approved','Rejected'))
);
GO

-- =====================================================================
-- 14. BẢNG NOTIFICATIONS
-- =====================================================================
CREATE TABLE Notifications (
    NotificationID    INT            PRIMARY KEY IDENTITY(1,1),
    RecipientID       INT            NOT NULL,
    SenderID          INT            NULL,
    Title             NVARCHAR(200)  NOT NULL,
    Message           NVARCHAR(MAX)  NULL,
    Type              NVARCHAR(50)   NULL,
    RelatedEntityType NVARCHAR(50)   NULL,
    RelatedEntityID   INT            NULL,
    IsRead            BIT            NOT NULL DEFAULT 0,
    CreatedAt         DATETIME       NOT NULL DEFAULT GETDATE(),
    ReadAt            DATETIME       NULL,
    CONSTRAINT FK_Notifications_Recipient FOREIGN KEY (RecipientID) REFERENCES Users(UserID),
    CONSTRAINT FK_Notifications_Sender    FOREIGN KEY (SenderID)    REFERENCES Users(UserID)
);
GO

-- =====================================================================
-- 15. BẢNG ACTIVITY_LOGS
-- =====================================================================
CREATE TABLE ActivityLogs (
    LogID       INT            PRIMARY KEY IDENTITY(1,1),
    UserID      INT            NULL,
    ActionType  NVARCHAR(100)  NOT NULL,
    EntityType  NVARCHAR(50)   NULL,
    EntityID    INT            NULL,
    OldValues   NVARCHAR(MAX)  NULL,
    NewValues   NVARCHAR(MAX)  NULL,
    IPAddress   NVARCHAR(45)   NULL,
    Description NVARCHAR(MAX)  NULL,
    CreatedAt   DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ActivityLogs_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO

-- =====================================================================
-- 16. BẢNG SYSTEM_SETTINGS
-- =====================================================================
CREATE TABLE SystemSettings (
    SettingID    INT            PRIMARY KEY IDENTITY(1,1),
    SettingKey   NVARCHAR(100)  UNIQUE NOT NULL,
    SettingValue NVARCHAR(MAX)  NULL,
    Description  NVARCHAR(255)  NULL,
    UpdatedAt    DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

-- =====================================================================
-- 17. BẢNG PASSWORD_RESET_TOKENS
-- =====================================================================
CREATE TABLE PasswordResetTokens (
    TokenID   INT            PRIMARY KEY IDENTITY(1,1),
    UserID    INT            NOT NULL,
    Token     NVARCHAR(255)  UNIQUE NOT NULL,
    ExpiresAt DATETIME       NOT NULL,
    IsUsed    BIT            NOT NULL DEFAULT 0,
    CreatedAt DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_PasswordReset_User FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
GO

-- =====================================================================
-- 18. BẢNG EMAIL_VERIFICATION_TOKENS
-- =====================================================================
CREATE TABLE EmailVerificationTokens (
    TokenID   INT            PRIMARY KEY IDENTITY(1,1),
    UserID    INT            NOT NULL,
    Token     NVARCHAR(255)  UNIQUE NOT NULL,
    ExpiresAt DATETIME       NOT NULL,
    IsUsed    BIT            NOT NULL DEFAULT 0,
    CreatedAt DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_EmailVerification_User FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
GO


-- =====================================================================
-- =====================================================================
-- DỮ LIỆU SEED
-- =====================================================================
-- =====================================================================

-- --------------------------------------------------------------------
-- EmployeeGroups – 3 nhóm quyền cố định
-- --------------------------------------------------------------------
INSERT INTO EmployeeGroups
    (GroupCode, GroupName, Description,
     CanViewRoom, CanEditRoom, CanCreateBooking, CanApproveBooking, CanViewRoomDashboard,
     CanCreateContract, CanManageContract, CanCreatePayment, CanTrackPayment, CanViewRevenueDashboard,
     CanViewTenantProfile, CanManageReview, CanViewBookingHistory)
VALUES
(
    'NVVH', N'Nhân viên Vận hành',
    N'Xem & cập nhật phòng; tạo & xác nhận booking; xem Dashboard phòng trống/đầy',
    1, 1, 1, 1, 1,   -- quyền phòng & booking
    0, 0, 0, 0, 0,   -- không có quyền tài chính
    0, 0, 0          -- không có quyền CSKH
),
(
    'NVTC', N'Nhân viên Tài chính',
    N'Tạo & quản lý hợp đồng; lập & theo dõi thu tiền; xem Dashboard doanh thu',
    1, 0, 0, 0, 0,   -- chỉ xem phòng, không sửa/booking
    1, 1, 1, 1, 1,   -- toàn quyền tài chính
    0, 0, 0          -- không có quyền CSKH
),
(
    'NVCSKH', N'Nhân viên Chăm sóc khách hàng',
    N'Quản lý hồ sơ khách thuê; phê duyệt/ẩn đánh giá; xem lịch sử đặt phòng khách',
    1, 0, 0, 0, 0,   -- chỉ xem phòng
    0, 0, 0, 0, 0,   -- không có quyền tài chính
    1, 1, 1          -- toàn quyền CSKH
);
GO

-- --------------------------------------------------------------------
-- RoomStatuses
-- --------------------------------------------------------------------
INSERT INTO RoomStatuses (StatusName, Description) VALUES
(N'Available',   N'Phòng đang trống, sẵn sàng cho thuê'),
(N'Rented',      N'Phòng đang có người thuê'),
(N'Maintenance', N'Phòng đang bảo trì, tạm ngừng cho thuê'),
(N'Reserved',    N'Phòng đã được đặt, chờ xác nhận');
GO

-- --------------------------------------------------------------------
-- Utilities
-- --------------------------------------------------------------------
INSERT INTO Utilities (UtilityName, Description, Icon) VALUES
('WiFi',             N'Internet không dây tốc độ cao',    'wifi'),
(N'Điều hòa',        N'Máy lạnh điều hòa nhiệt độ',       'ac_unit'),
(N'Tủ lạnh',         N'Tủ lạnh mini',                     'kitchen'),
(N'Giường',          N'Giường đơn hoặc giường đôi',        'bed'),
(N'Bàn làm việc',    N'Bàn và ghế làm việc',              'desk'),
(N'Phòng tắm riêng', N'WC khép kín trong phòng',          'bathroom'),
(N'Bếp nấu',         N'Khu bếp nấu ăn',                   'local_fire_department'),
(N'Máy giặt',        N'Máy giặt riêng hoặc chung',        'local_laundry_service'),
('TV',               N'Tivi màn hình phẳng',               'tv'),
(N'Bảo mật 24/7',    N'Camera giám sát và bảo vệ 24/7',   'security');
GO

-- --------------------------------------------------------------------
-- Users – 3 tài khoản gốc (UserID 1,2,3)
-- PasswordHash = bcrypt("12345678")
-- --------------------------------------------------------------------
INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, PhoneNumber, Role,
                   DateOfBirth, Gender, IdentityNumber,
                   Street, Ward, District, City,
                   IsActive, IsEmailVerified, CreatedAt)
VALUES
('admin',
 'admin@admin.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Quản trị', N'Viên', '0900000001', 0,
 '1985-05-15', 'M', '079085001234',
 N'01 Lê Duẩn', N'Bến Nghé', N'Quận 1', N'TP.HCM',
 1, 1, '2024-01-01'),

('nhanvien',
 'nhanvien@nhanvien.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nhân', N'Viên', '0900000002', 1,
 '1995-08-20', 'F', '079095002345',
 N'12 Nguyễn Huệ', N'Bến Nghé', N'Quận 1', N'TP.HCM',
 1, 1, '2024-01-02'),

('khach',
 'khach@khach.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Khách', N'Thuê', '0900000003', 2,
 '2000-03-10', 'M', '079100003456',
 N'45 Trần Hưng Đạo', N'Tân Định', N'Quận 1', N'TP.HCM',
 1, 1, '2024-01-03');
GO

-- --------------------------------------------------------------------
-- Users – 7 nhân viên (UserID 4..10) : 3 NVVH + 2 NVTC + 2 NVCSKH
-- --------------------------------------------------------------------
INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, PhoneNumber, Role,
                   DateOfBirth, Gender, IdentityNumber,
                   Street, Ward, District, City,
                   IsActive, IsEmailVerified, CreatedAt)
VALUES
-- NVVH (3 người)
('nv_tran',    'tran.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần', N'Văn Bảo', '0901111111', 1, '1992-04-12', 'M', '079092004567',
 N'34 Pasteur', N'Phường 6', N'Quận 3', N'TP.HCM', 1, 1, '2024-01-05'),

('nv_le',      'le.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lê', N'Thị Cúc', '0901111112', 1, '1994-07-25', 'F', '079094005678',
 N'56 Cao Thắng', N'Phường 3', N'Quận 3', N'TP.HCM', 1, 1, '2024-01-06'),

('nv_pham',    'pham.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm', N'Văn Dũng', '0901111113', 1, '1990-11-03', 'M', '079090006789',
 N'78 Điện Biên Phủ', N'Đa Kao', N'Quận 1', N'TP.HCM', 1, 1, '2024-01-07'),

-- NVTC (2 người)
('nv_finance', 'finance.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Đinh', N'Thị Thanh', '0901111114', 1, '1991-06-18', 'F', '079091031234',
 N'14 Lê Thánh Tôn', N'Bến Nghé', N'Quận 1', N'TP.HCM', 1, 1, '2024-01-08'),

('nv_ketoan',  'ketoan.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Ngô', N'Minh Tuấn', '0901111115', 1, '1993-03-30', 'M', '079093032345',
 N'22 Hàm Nghi', N'Bến Nghé', N'Quận 1', N'TP.HCM', 1, 1, '2024-01-09'),

-- NVCSKH (2 người)
('nv_cskh',    'cskh.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Bùi', N'Văn Khoa', '0901111116', 1, '1993-09-25', 'M', '079093033456',
 N'26 Lý Tự Trọng', N'Bến Thành', N'Quận 1', N'TP.HCM', 1, 1, '2024-01-10'),

('nv_huyen',   'huyen.nv@staff.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lưu', N'Thị Huyền', '0901111117', 1, '1996-12-14', 'F', '079096034567',
 N'38 Nguyễn Du', N'Bến Nghé', N'Quận 1', N'TP.HCM', 1, 1, '2024-01-11');
GO

-- --------------------------------------------------------------------
-- Users – nhân viên tổng hợp nhanvien (UserID=2) cũng cần EmployeeProfile
-- Gán cho UserID=2 nhóm NVVH (trưởng nhóm vận hành)
-- --------------------------------------------------------------------

-- --------------------------------------------------------------------
-- Users – 24 khách thuê (UserID 11..34)
-- --------------------------------------------------------------------
INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, PhoneNumber, Role,
                   DateOfBirth, Gender, IdentityNumber,
                   Street, Ward, District, City,
                   IsActive, IsEmailVerified, CreatedAt)
VALUES
('khach_thanh', 'thanh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Văn Thành',  '0902222221', 2, '1998-02-14', 'M', '079098007890',
 N'12 Võ Văn Tần',          N'Phường 6',  N'Quận 3',     N'TP.HCM', 1, 1, '2024-02-01'),

('khach_linh',  'linh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần',   N'Thị Linh',   '0902222222', 2, '2001-06-30', 'F', '079101008901',
 N'89 Lê Lợi',              N'Bến Nghé',  N'Quận 1',     N'TP.HCM', 1, 1, '2024-02-03'),

('khach_hoa',   'hoa.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lê',     N'Thị Hoa',    '0902222223', 2, '1999-09-18', 'F', '079099009012',
 N'23 Hai Bà Trưng',        N'Tân Định',  N'Quận 1',     N'TP.HCM', 1, 1, '2024-02-05'),

('khach_minh',  'minh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm',   N'Văn Minh',   '0902222224', 2, '1997-12-05', 'M', '079097010123',
 N'45 Nam Kỳ Khởi Nghĩa',  N'Bến Thành', N'Quận 1',     N'TP.HCM', 1, 1, '2024-02-07'),

('khach_tuan',  'tuan.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Hoàng',  N'Tuấn',       '0902222225', 2, '2000-01-22', 'M', '079100011234',
 N'67 Nguyễn Trãi',         N'Phường 7',  N'Quận 5',     N'TP.HCM', 1, 1, '2024-02-09'),

('khach_huong', 'huong.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm',   N'Thị Hương',  '0902222226', 2, '1996-05-08', 'F', '079096012345',
 N'90 Trần Phú',             N'Phường 4',  N'Quận 5',     N'TP.HCM', 1, 1, '2024-02-11'),

('khach_dung',  'dung.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Văn Dũng',   '0902222227', 2, '1993-08-16', 'M', '079093013456',
 N'11 Hùng Vương',           N'Phường 1',  N'Quận 5',     N'TP.HCM', 1, 1, '2024-02-13'),

('khach_lan',   'lan.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần',   N'Thị Lan',    '0902222228', 2, '2002-03-27', 'F', '079102014567',
 N'33 An Dương Vương',      N'Phường 9',  N'Quận 5',     N'TP.HCM', 1, 1, '2024-02-15'),

('khach_hung',  'hung.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Văn Hùng',   '0902222229', 2, '1991-10-14', 'M', '079091015678',
 N'55 Lý Thường Kiệt',      N'Phường 7',  N'Quận 11',    N'TP.HCM', 1, 1, '2024-02-17'),

('khach_mai',   'mai.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lê',     N'Thị Mai',    '0902222230', 2, '2003-07-04', 'F', '079103016789',
 N'77 Lạc Long Quân',       N'Phường 5',  N'Quận 11',    N'TP.HCM', 1, 1, '2024-02-19'),

('khach_khanh', 'khanh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm',   N'Thị Khánh',  '0902222231', 2, '1998-11-19', 'F', '079098017890',
 N'99 Xô Viết Nghệ Tĩnh',  N'Phường 25', N'Bình Thạnh', N'TP.HCM', 1, 1, '2024-02-21'),

('khach_thy',   'thy.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Hoàng',  N'Thị Thủy',   '0902222232', 2, '2001-04-02', 'F', '079101018901',
 N'21 Bạch Đằng',           N'Phường 24', N'Bình Thạnh', N'TP.HCM', 1, 1, '2024-02-23'),

('khach_nhan',  'nhan.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần',   N'Văn Nhân',   '0902222233', 2, '1995-09-11', 'M', '079095019012',
 N'43 Phan Đăng Lưu',       N'Phường 5',  N'Phú Nhuận',  N'TP.HCM', 1, 1, '2024-02-25'),

('khach_phuong','phuong.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Thị Phương', '0902222234', 2, '1999-06-28', 'F', '079099020123',
 N'65 Huỳnh Văn Bánh',      N'Phường 11', N'Phú Nhuận',  N'TP.HCM', 1, 1, '2024-02-27'),

('khach_duc',   'duc.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lê',     N'Văn Đức',    '0902222235', 2, '1997-01-15', 'M', '079097021234',
 N'87 Nguyễn Văn Trỗi',    N'Phường 1',  N'Tân Bình',   N'TP.HCM', 1, 1, '2024-03-01'),

('khach_vy',    'vy.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm',   N'Thị Vy',     '0902222236', 2, '2002-10-07', 'F', '079102022345',
 N'09 Hoàng Văn Thụ',      N'Phường 4',  N'Tân Bình',   N'TP.HCM', 1, 1, '2024-03-03'),

('khach_binh',  'binh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Hoàng',  N'Văn Bình',   '0902222237', 2, '1994-03-23', 'M', '079094023456',
 N'31 Trường Chinh',        N'Phường 12', N'Tân Bình',   N'TP.HCM', 1, 1, '2024-03-05'),

('khach_an',    'an.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần',   N'Thị An',     '0902222238', 2, '2000-08-31', 'F', '079100024567',
 N'53 Võ Thị Sáu',          N'Phường 7',  N'Quận 3',     N'TP.HCM', 1, 1, '2024-03-07'),

('khach_son',   'son.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Văn Sơn',    '0902222239', 2, '1996-12-09', 'M', '079096025678',
 N'75 Nguyễn Thị Minh Khai',N'Phường 5', N'Quận 3',     N'TP.HCM', 1, 1, '2024-03-09'),

('khach_tram',  'tram.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Lê',     N'Thị Trâm',   '0902222240', 2, '2001-05-17', 'F', '079101026789',
 N'97 Lê Văn Sỹ',            N'Phường 14', N'Quận 3',     N'TP.HCM', 1, 1, '2024-03-11'),

('khach_tung',  'tung.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Phạm',   N'Văn Tùng',   '0902222241', 2, '1993-02-26', 'M', '079093027890',
 N'19 Phạm Ngọc Thạch',    N'Phường 6',  N'Quận 3',     N'TP.HCM', 1, 1, '2024-03-13'),

('khach_hanh',  'hanh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Hoàng',  N'Thị Hạnh',   '0902222242', 2, '1998-07-13', 'F', '079098028901',
 N'41 Cách Mạng Tháng 8',  N'Phường 8',  N'Quận 3',     N'TP.HCM', 1, 1, '2024-03-15'),

('khach_tien',  'tien.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Trần',   N'Văn Tiến',   '0902222243', 2, '2003-11-01', 'M', '079103029012',
 N'63 Đinh Tiên Hoàng',    N'Đa Kao',    N'Quận 1',     N'TP.HCM', 1, 1, '2024-03-17'),

('khach_quynh', 'quynh.khach@email.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 N'Nguyễn', N'Thị Quỳnh',  '0902222244', 2, '1997-04-20', 'F', '079097030123',
 N'85 Đinh Bộ Lĩnh',       N'Bến Thành', N'Quận 1',     N'TP.HCM', 1, 1, '2024-03-19');
GO

-- --------------------------------------------------------------------
-- EmployeeProfiles
-- UserID mapping sau khi INSERT:
--   2  = nhanvien  → NVVH (GroupID=1)
--   4  = nv_tran   → NVVH (GroupID=1)
--   5  = nv_le     → NVVH (GroupID=1)
--   6  = nv_pham   → NVVH (GroupID=1)  phụ trách phòng khu L-M
--   7  = nv_finance→ NVTC (GroupID=2)
--   8  = nv_ketoan → NVTC (GroupID=2)
--   9  = nv_cskh   → NVCSKH (GroupID=3)
--   10 = nv_huyen  → NVCSKH (GroupID=3)
-- --------------------------------------------------------------------
INSERT INTO EmployeeProfiles (UserID, GroupID, EmployeeCode, Department, Position, HiredDate, Note)
VALUES
(2,  1, 'NV-001', N'Vận hành',  N'Trưởng nhóm vận hành',     '2024-01-02', N'Phụ trách toàn bộ khu A-B-C-F-I-N'),
(4,  1, 'NV-002', N'Vận hành',  N'Nhân viên vận hành',        '2024-01-05', N'Phụ trách khu D-G-J-O'),
(5,  1, 'NV-003', N'Vận hành',  N'Nhân viên vận hành',        '2024-01-06', N'Phụ trách khu E-H-K-P'),
(6,  1, 'NV-004', N'Vận hành',  N'Nhân viên vận hành',        '2024-01-07', N'Phụ trách khu L-M'),
(7,  2, 'NV-005', N'Tài chính', N'Kế toán trưởng',            '2024-01-08', N'Quản lý hợp đồng và hóa đơn toàn hệ thống'),
(8,  2, 'NV-006', N'Tài chính', N'Nhân viên kế toán',         '2024-01-09', N'Theo dõi công nợ và nhắc thanh toán'),
(9,  3, 'NV-007', N'CSKH',      N'Chuyên viên khách hàng',    '2024-01-10', N'Xử lý khiếu nại và phê duyệt đánh giá'),
(10, 3, 'NV-008', N'CSKH',      N'Nhân viên chăm sóc KH',     '2024-01-11', N'Quản lý hồ sơ và lịch sử khách thuê');
GO

-- --------------------------------------------------------------------
-- Rooms – 31 phòng
-- AdminID dùng UserID của nhân viên vận hành (NVVH): 2,4,5,6
-- CurrentTenantID: UserID khách (bắt đầu từ 11)
-- --------------------------------------------------------------------
INSERT INTO Rooms (RoomNumber, AdminID, Title, Description, Area, Price, MaxOccupancy, StatusID, CurrentTenantID, CreatedAt)
VALUES
('A101', 2,  N'Phòng đẹp gần trường',               N'Phòng 25m², thoáng mát, cửa sổ lớn, gần trường ĐH',          25.0, 3500000, 2, 2, 11,   '2024-01-15'),
('A102', 2,  N'Phòng yên tĩnh giá rẻ',              N'Phòng 20m², yên tĩnh, phù hợp sinh viên',                     20.0, 2800000, 1, 1, NULL, '2024-01-15'),
('B201', 2,  N'Phòng hiện đại có bếp',               N'Phòng 30m², nội thất đầy đủ, bếp riêng, máy giặt',            30.0, 4500000, 3, 2, 12,   '2024-01-20'),
('B202', 2,  N'Phòng nhỏ gọn tiết kiệm',            N'Phòng 18m², đủ tiện nghi cơ bản, an ninh tốt',                18.0, 2500000, 1, 1, NULL, '2024-01-20'),
('C301', 2,  N'Phòng view sông thoáng đẹp',          N'Phòng 35m², ban công view sông, điều hòa, nước nóng',         35.0, 5500000, 4, 2, 13,   '2024-01-25'),
('C302', 4,  N'Phòng bình dân sạch sẽ',              N'Phòng 15m², sạch sẽ, giá rẻ phù hợp sinh viên',               15.0, 2000000, 1, 1, NULL, '2024-01-25'),
('D401', 4,  N'Phòng cao cấp full tiện ích',         N'Phòng 50m², sang trọng, đầy đủ nội thất, dịch vụ tốt',        50.0, 8000000, 5, 2, 14,   '2024-02-01'),
('D402', 4,  N'Phòng tiêu chuẩn trung tâm',          N'Phòng 25m², vị trí đắc địa, gần các tiện ích',                25.0, 3800000, 2, 1, NULL, '2024-02-01'),
('E501', 5,  N'Phòng gia đình rộng rãi',             N'Phòng 45m², thích hợp gia đình 4-6 người, bếp rộng',          45.0, 6500000, 6, 2, 15,   '2024-02-05'),
('E502', 5,  N'Phòng sinh viên gần ĐH',              N'Phòng 22m², gần các trường đại học, WiFi nhanh',               22.0, 2800000, 2, 1, NULL, '2024-02-05'),
('F601', 2,  N'Phòng gần bến xe tiện giao thông',    N'Phòng 26m², gần bến xe, điều hòa, chủ phòng dễ tính',         26.0, 3400000, 2, 2, 16,   '2024-02-10'),
('F602', 2,  N'Phòng cozy ấm cúng',                  N'Phòng 17m², nhỏ nhưng ấm cúng, chủ tử tế',                    17.0, 2200000, 1, 4, NULL, '2024-02-10'),
('G701', 4,  N'Phòng đầy đủ tiện ích',               N'Phòng 28m², có bếp, máy giặt, Internet cáp quang',            28.0, 3900000, 3, 2, 17,   '2024-02-15'),
('G702', 4,  N'Phòng rộng thoáng nắng',              N'Phòng 32m², hướng Đông, đón nắng sáng, thoáng mát',           32.0, 4200000, 3, 3, NULL, '2024-02-15'),
('H801', 5,  N'Phòng gần công viên xanh mát',        N'Phòng 29m², gần công viên, không khí trong lành',             29.0, 4000000, 2, 2, 18,   '2024-02-20'),
('H802', 5,  N'Phòng kinh tế cho sinh viên',         N'Phòng 16m², giá rẻ nhất khu vực, sạch sẽ',                    16.0, 1800000, 1, 1, NULL, '2024-02-20'),
('I901', 2,  N'Phòng sang nước nóng 24/7',           N'Phòng 48m², cao cấp, nước nóng 24/7, thang máy',              48.0, 7500000, 5, 3, NULL, '2024-02-25'),
('I902', 2,  N'Phòng tiện ích đầy đủ',               N'Phòng 24m², quản lý tốt, đủ dùng, an ninh camera',            24.0, 3600000, 2, 2, 19,   '2024-02-25'),
('J1001',4,  N'Phòng gần trung tâm dạo phố',         N'Phòng 21m², gần Bến Thành, tiện mua sắm và đi lại',           21.0, 3300000, 2, 2, 20,   '2024-03-01'),
('J1002',4,  N'Phòng bình yên đơn giản',             N'Phòng 19m², bình yên, đơn giản mà đầy đủ nhu cầu',            19.0, 2600000, 1, 4, NULL, '2024-03-01'),
('K1101',5,  N'Phòng mới sửa như mới',               N'Phòng 27m², vừa sửa chữa toàn bộ, nội thất mới 100%',         27.0, 3700000, 2, 2, 21,   '2024-03-05'),
('K1102',5,  N'Phòng ổn định cho thuê dài hạn',      N'Phòng 23m², ưu tiên thuê dài hạn, giá ổn định lâu dài',       23.0, 3100000, 2, 1, NULL, '2024-03-05'),
('L1201',6,  N'Phòng duplex 2 tầng',                 N'Phòng 40m² kiểu duplex, 2 tầng, rất thoáng và lạ',            40.0, 5800000, 4, 2, 22,   '2024-03-10'),
('L1202',6,  N'Phòng nhỏ xinh trang trí đẹp',        N'Phòng 18m², được trang trí xinh xắn, bắt mắt',                18.0, 2400000, 1, 1, NULL, '2024-03-10'),
('M1301',6,  N'Phòng view đường phố náo nhiệt',       N'Phòng 31m², view toàn bộ đường phố, ban công rộng',           31.0, 4300000, 3, 2, 23,   '2024-03-15'),
('M1302',6,  N'Phòng gần chợ tiện mua sắm',          N'Phòng 20m², gần chợ Bến Thành, tiện đi chợ hằng ngày',        20.0, 2700000, 1, 1, NULL, '2024-03-15'),
('N1401',2,  N'Phòng luxury đẳng cấp',               N'Phòng 55m², trang bị nội thất cao cấp, view đẹp, đủ thứ',     55.0, 8500000, 6, 4, NULL, '2024-03-20'),
('N1402',2,  N'Phòng standard giá hợp lý',           N'Phòng 25m², standard đầy đủ, giá hợp lý cho nhân viên',       25.0, 3500000, 2, 2, 24,   '2024-03-20'),
('O1501',4,  N'Phòng gia đình 6 người',              N'Phòng 42m², không gian rộng, thích hợp gia đình đông',         42.0, 6200000, 6, 2, 25,   '2024-03-25'),
('O1502',4,  N'Phòng 1 người nhân viên',             N'Phòng 15m², phù hợp nhân viên độc thân, giá tốt',             15.0, 2000000, 1, 1, NULL, '2024-03-25'),
('P1601',5,  N'Phòng an ninh tốt có camera',         N'Phòng 24m², an ninh 24/7, camera mọi góc, cổng từ',           24.0, 3300000, 2, 1, NULL, '2024-03-30');
GO

-- --------------------------------------------------------------------
-- RoomUtilities
-- --------------------------------------------------------------------
INSERT INTO RoomUtilities (RoomID, UtilityID) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),
(2,1),(2,2),(2,4),(2,10),
(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),
(4,1),(4,4),
(5,1),(5,2),(5,4),(5,5),(5,8),(5,9),(5,10),
(6,1),(6,4),
(7,1),(7,2),(7,3),(7,4),(7,5),(7,6),(7,7),(7,8),(7,9),(7,10),
(8,1),(8,2),(8,4),(8,5),(8,6),
(9,1),(9,2),(9,3),(9,4),(9,7),(9,8),(9,9),
(10,1),(10,4),(10,5),(10,10),
(11,1),(11,2),(11,4),(11,10),
(13,1),(13,2),(13,3),(13,4),(13,7),(13,8),
(17,1),(17,2),(17,3),(17,4),(17,5),(17,6),(17,8),(17,9),(17,10),
(21,1),(21,2),(21,4),(21,5),
(23,1),(23,2),(23,3),(23,4),(23,6),(23,9),
(27,1),(27,2),(27,3),(27,4),(27,5),(27,6),(27,7),(27,8),(27,9),(27,10);
GO

-- --------------------------------------------------------------------
-- RoomImages
-- --------------------------------------------------------------------
INSERT INTO RoomImages (RoomID, ImageUrl, DisplayOrder, IsMainImage) VALUES
(1,  '/images/rooms/a101_main.jpg',      1, 1),
(1,  '/images/rooms/a101_bathroom.jpg',  2, 0),
(1,  '/images/rooms/a101_window.jpg',    3, 0),
(2,  '/images/rooms/a102_main.jpg',      1, 1),
(3,  '/images/rooms/b201_main.jpg',      1, 1),
(3,  '/images/rooms/b201_kitchen.jpg',   2, 0),
(3,  '/images/rooms/b201_bedroom.jpg',   3, 0),
(4,  '/images/rooms/b202_main.jpg',      1, 1),
(5,  '/images/rooms/c301_main.jpg',      1, 1),
(5,  '/images/rooms/c301_view.jpg',      2, 0),
(5,  '/images/rooms/c301_balcony.jpg',   3, 0),
(7,  '/images/rooms/d401_main.jpg',      1, 1),
(7,  '/images/rooms/d401_living.jpg',    2, 0),
(7,  '/images/rooms/d401_bathroom.jpg',  3, 0),
(9,  '/images/rooms/e501_main.jpg',      1, 1),
(9,  '/images/rooms/e501_kitchen.jpg',   2, 0),
(11, '/images/rooms/f601_main.jpg',      1, 1),
(13, '/images/rooms/g701_main.jpg',      1, 1),
(13, '/images/rooms/g701_washer.jpg',    2, 0),
(17, '/images/rooms/i901_main.jpg',      1, 1),
(17, '/images/rooms/i901_view.jpg',      2, 0),
(21, '/images/rooms/k1101_main.jpg',     1, 1),
(23, '/images/rooms/l1201_floor1.jpg',   1, 1),
(23, '/images/rooms/l1201_floor2.jpg',   2, 0),
(27, '/images/rooms/n1401_main.jpg',     1, 1),
(27, '/images/rooms/n1401_living.jpg',   2, 0),
(27, '/images/rooms/n1401_master.jpg',   3, 0),
(28, '/images/rooms/n1402_main.jpg',     1, 1),
(29, '/images/rooms/o1501_main.jpg',     1, 1),
(30, '/images/rooms/p1601_main.jpg',     1, 1);
GO

-- --------------------------------------------------------------------
-- Bookings – 30 đơn đặt phòng
-- ApprovedBy: chỉ UserID của NVVH (2,4,5,6) vì họ có quyền duyệt booking
-- UserID khách: 11..34
-- --------------------------------------------------------------------
INSERT INTO Bookings (RoomID, UserID, BookingStatus, CheckInDate, CheckOutDate, Duration, DepositAmount, Notes, ApprovedBy, ApprovedAt, CreatedAt)
VALUES
(1,  11, 'Approved',  '2024-03-01', '2024-09-01', 6,  7000000,  N'Thanh toán trước 1 tháng',                  2, '2024-02-21', '2024-02-20'),
(3,  12, 'Approved',  '2024-03-15', '2025-03-15', 12, 9000000,  N'Hợp đồng 1 năm',                            2, '2024-03-02', '2024-03-01'),
(5,  13, 'Approved',  '2024-02-15', '2025-02-15', 12, 11000000, N'Gia đình 4 người',                           4, '2024-02-11', '2024-02-10'),
(7,  14, 'Approved',  '2024-02-01', '2026-02-01', 24, 16000000, N'Hợp đồng 2 năm, ưu tiên gia hạn',           4, '2024-01-29', '2024-01-28'),
(9,  15, 'Approved',  '2024-02-20', '2025-02-20', 12, 13000000, N'Gia đình 5 người, cần bếp lớn',              5, '2024-02-16', '2024-02-15'),
(11, 16, 'Approved',  '2024-03-01', '2024-09-01', 6,  6800000,  N'Gần chỗ làm, đi xe máy',                    2, '2024-02-26', '2024-02-25'),
(13, 17, 'Approved',  '2024-03-10', '2024-09-10', 6,  7800000,  N'Có nhu cầu dùng máy giặt',                  4, '2024-03-06', '2024-03-05'),
(15, 18, 'Approved',  '2024-03-20', '2024-09-20', 6,  8000000,  N'Cần phòng gần công viên để chạy bộ',        5, '2024-03-16', '2024-03-15'),
(18, 19, 'Approved',  '2024-04-01', '2024-10-01', 6,  7200000,  N'Nhân viên văn phòng, về muộn',               2, '2024-03-27', '2024-03-26'),
(19, 20, 'Approved',  '2024-04-05', '2024-10-05', 6,  6600000,  N'Thích ở gần trung tâm',                     4, '2024-04-01', '2024-03-31'),
(21, 21, 'Approved',  '2024-04-10', '2025-04-10', 12, 7400000,  N'Phòng mới sửa, hợp ý',                      5, '2024-04-06', '2024-04-05'),
(23, 22, 'Approved',  '2024-04-15', '2025-04-15', 12, 11600000, N'Thích kiểu duplex độc đáo',                  2, '2024-04-11', '2024-04-10'),
(25, 23, 'Approved',  '2024-05-01', '2024-11-01', 6,  8600000,  N'Thích view đường phố, ban công',             4, '2024-04-27', '2024-04-26'),
(28, 24, 'Approved',  '2024-05-05', '2025-05-05', 12, 7000000,  N'Hợp đồng 1 năm, giá hợp lý',                5, '2024-05-01', '2024-04-30'),
(29, 25, 'Approved',  '2024-05-10', '2025-05-10', 12, 12400000, N'Gia đình 6 người',                           2, '2024-05-06', '2024-05-05'),
(2,  26, 'Pending',   '2024-06-01', NULL,         6,  5600000,  N'Cần xác nhận sớm',                          NULL, NULL,       '2024-05-20'),
(4,  27, 'Pending',   '2024-06-05', NULL,         3,  5000000,  N'Thuê ngắn hạn thử 3 tháng',                 NULL, NULL,       '2024-05-21'),
(6,  28, 'Pending',   '2024-06-10', NULL,         6,  4000000,  N'Sinh viên, cần giá tốt',                    NULL, NULL,       '2024-05-22'),
(8,  29, 'Pending',   '2024-06-15', NULL,         12, 7600000,  N'Muốn hợp đồng 1 năm',                       NULL, NULL,       '2024-05-22'),
(10, 30, 'Pending',   '2024-06-20', NULL,         6,  5600000,  N'Sinh viên năm 3',                            NULL, NULL,       '2024-05-23'),
(12, 31, 'Rejected',  '2024-04-01', NULL,         6,  4400000,  N'Không phù hợp yêu cầu của chủ',             2, '2024-03-16', '2024-03-15'),
(14, 32, 'Rejected',  '2024-04-10', NULL,         3,  5400000,  N'Phòng đang bảo trì',                        4, '2024-03-26', '2024-03-25'),
(16, 33, 'Rejected',  '2024-04-20', NULL,         6,  3600000,  N'Vượt MaxOccupancy',                          5, '2024-04-06', '2024-04-05'),
(22, 34, 'Rejected',  '2024-05-01', NULL,         12, 6200000,  N'Khách chưa đủ thông tin CCCD',               2, '2024-04-16', '2024-04-15'),
(20, 32, 'Cancelled', '2024-04-15', NULL,         6,  5200000,  N'Khách tự hủy vì đổi kế hoạch',              NULL, NULL,       '2024-04-10'),
(24, 33, 'Cancelled', '2024-05-01', NULL,         3,  4800000,  N'Khách tìm được phòng phù hợp hơn',          NULL, NULL,       '2024-04-20'),
(26, 34, 'Cancelled', '2024-05-10', NULL,         6,  7000000,  N'Hủy do công việc thay đổi',                 NULL, NULL,       '2024-04-30'),
(30, 11, 'Cancelled', '2024-05-20', NULL,         12, 6600000,  N'Hủy vì tìm được nhà riêng',                 NULL, NULL,       '2024-05-10'),
(1,  12, 'Pending',   '2024-07-01', NULL,         6,  7000000,  N'Muốn ở lại phòng cũ sau khi hợp đồng hết', NULL, NULL,       '2024-05-23'),
(3,  26, 'Pending',   '2024-07-15', NULL,         12, 9000000,  N'Muốn thuê phòng B201 dài hạn',               NULL, NULL,      '2024-05-23');
GO

-- --------------------------------------------------------------------
-- Contracts – 15 hợp đồng ứng với 15 booking Approved
-- Được tạo bởi NVTC (UserID 7,8) qua AdminID trong Payments
-- --------------------------------------------------------------------
INSERT INTO Contracts (BookingID, ContractNumber, StartDate, EndDate, RentalPrice, DepositAmount, Status, SignedDate, CreatedAt)
VALUES
(1,  'CT-001-20240301', '2024-03-01', '2024-09-01', 3500000,  7000000,  'Active', '2024-02-22', '2024-02-21'),
(2,  'CT-002-20240315', '2024-03-15', '2025-03-15', 4500000,  9000000,  'Active', '2024-03-03', '2024-03-02'),
(3,  'CT-003-20240215', '2024-02-15', '2025-02-15', 5500000,  11000000, 'Active', '2024-02-12', '2024-02-11'),
(4,  'CT-004-20240201', '2024-02-01', '2026-02-01', 8000000,  16000000, 'Active', '2024-01-30', '2024-01-29'),
(5,  'CT-005-20240220', '2024-02-20', '2025-02-20', 6500000,  13000000, 'Active', '2024-02-17', '2024-02-16'),
(6,  'CT-006-20240301', '2024-03-01', '2024-09-01', 3400000,  6800000,  'Active', '2024-02-27', '2024-02-26'),
(7,  'CT-007-20240310', '2024-03-10', '2024-09-10', 3900000,  7800000,  'Active', '2024-03-07', '2024-03-06'),
(8,  'CT-008-20240320', '2024-03-20', '2024-09-20', 4000000,  8000000,  'Active', '2024-03-17', '2024-03-16'),
(9,  'CT-009-20240401', '2024-04-01', '2024-10-01', 3600000,  7200000,  'Active', '2024-03-28', '2024-03-27'),
(10, 'CT-010-20240405', '2024-04-05', '2024-10-05', 3300000,  6600000,  'Active', '2024-04-02', '2024-04-01'),
(11, 'CT-011-20240410', '2024-04-10', '2025-04-10', 3700000,  7400000,  'Active', '2024-04-07', '2024-04-06'),
(12, 'CT-012-20240415', '2024-04-15', '2025-04-15', 5800000,  11600000, 'Active', '2024-04-12', '2024-04-11'),
(13, 'CT-013-20240501', '2024-05-01', '2024-11-01', 4300000,  8600000,  'Active', '2024-04-28', '2024-04-27'),
(14, 'CT-014-20240505', '2024-05-05', '2025-05-05', 3500000,  7000000,  'Active', '2024-05-02', '2024-05-01'),
(15, 'CT-015-20240510', '2024-05-10', '2025-05-10', 6200000,  12400000, 'Active', '2024-05-07', '2024-05-06');
GO

-- --------------------------------------------------------------------
-- Payments – AdminID là NVTC (UserID 7,8) vì họ có quyền lập hóa đơn
-- --------------------------------------------------------------------
INSERT INTO Payments (ContractID, UserID, AdminID, InvoiceNumber, PaymentDate, Amount, PaymentStatus, PaymentMethod, DueDate, PaidDate, Notes, CreatedAt)
VALUES
(1,  11, 7, 'INV-001-202403', '2024-03-01', 3800000,  'Paid',    N'Chuyển khoản', '2024-03-05', '2024-03-04', N'Thanh toán đúng hạn',         '2024-02-25'),
(1,  11, 7, 'INV-001-202404', '2024-04-01', 3820000,  'Paid',    N'Chuyển khoản', '2024-04-05', '2024-04-03', N'Phí điện tăng nhẹ',           '2024-03-25'),
(1,  11, 7, 'INV-001-202405', '2024-05-01', 3800000,  'Paid',    N'Chuyển khoản', '2024-05-05', '2024-05-04', NULL,                            '2024-04-25'),
(2,  12, 7, 'INV-002-202403', '2024-03-15', 4900000,  'Paid',    N'Tiền mặt',     '2024-03-20', '2024-03-19', NULL,                            '2024-03-10'),
(2,  12, 7, 'INV-002-202404', '2024-04-15', 4950000,  'Paid',    N'Tiền mặt',     '2024-04-20', '2024-04-18', NULL,                            '2024-04-10'),
(2,  12, 7, 'INV-002-202405', '2024-05-15', 4900000,  'Pending', N'Tiền mặt',     '2024-05-20', NULL,         N'Chờ khách đến đóng',          '2024-05-10'),
(3,  13, 8, 'INV-003-202402', '2024-02-15', 5900000,  'Paid',    N'Online',        '2024-02-20', '2024-02-18', NULL,                            '2024-02-10'),
(3,  13, 8, 'INV-003-202403', '2024-03-15', 5950000,  'Paid',    N'Online',        '2024-03-20', '2024-03-17', NULL,                            '2024-03-10'),
(3,  13, 8, 'INV-003-202404', '2024-04-15', 5900000,  'Paid',    N'Online',        '2024-04-20', '2024-04-15', NULL,                            '2024-04-10'),
(3,  13, 8, 'INV-003-202405', '2024-05-15', 5900000,  'Pending', N'Online',        '2024-05-20', NULL,         NULL,                            '2024-05-10'),
(4,  14, 7, 'INV-004-202402', '2024-02-01', 8500000,  'Paid',    N'Chuyển khoản', '2024-02-05', '2024-02-05', NULL,                            '2024-01-25'),
(4,  14, 7, 'INV-004-202403', '2024-03-01', 8500000,  'Paid',    N'Chuyển khoản', '2024-03-05', '2024-03-04', NULL,                            '2024-02-25'),
(4,  14, 7, 'INV-004-202404', '2024-04-01', 8700000,  'Paid',    N'Chuyển khoản', '2024-04-05', '2024-04-03', N'Tăng phí gửi xe',             '2024-03-25'),
(4,  14, 7, 'INV-004-202405', '2024-05-01', 8500000,  'Pending', N'Chuyển khoản', '2024-05-05', NULL,         NULL,                            '2024-04-25'),
(5,  15, 8, 'INV-005-202402', '2024-02-20', 7000000,  'Paid',    N'Chuyển khoản', '2024-02-25', '2024-02-24', NULL,                            '2024-02-15'),
(5,  15, 8, 'INV-005-202403', '2024-03-20', 7100000,  'Paid',    N'Chuyển khoản', '2024-03-25', '2024-03-22', NULL,                            '2024-03-15'),
(5,  15, 8, 'INV-005-202404', '2024-04-20', 7000000,  'Paid',    N'Chuyển khoản', '2024-04-25', '2024-04-20', NULL,                            '2024-04-15'),
(6,  16, 7, 'INV-006-202403', '2024-03-01', 3700000,  'Paid',    N'Tiền mặt',     '2024-03-05', '2024-03-05', NULL,                            '2024-02-25'),
(6,  16, 7, 'INV-006-202404', '2024-04-01', 3700000,  'Overdue', N'Tiền mặt',     '2024-04-05', NULL,         N'Khách nói bận chưa đóng',     '2024-03-25'),
(7,  17, 8, 'INV-007-202403', '2024-03-10', 4200000,  'Paid',    N'Online',        '2024-03-15', '2024-03-13', NULL,                            '2024-03-05'),
(7,  17, 8, 'INV-007-202404', '2024-04-10', 4200000,  'Paid',    N'Online',        '2024-04-15', '2024-04-12', NULL,                            '2024-04-05'),
(8,  18, 7, 'INV-008-202403', '2024-03-20', 4300000,  'Paid',    N'Chuyển khoản', '2024-03-25', '2024-03-23', NULL,                            '2024-03-15'),
(8,  18, 7, 'INV-008-202404', '2024-04-20', 4350000,  'Paid',    N'Chuyển khoản', '2024-04-25', '2024-04-22', NULL,                            '2024-04-15'),
(9,  19, 8, 'INV-009-202404', '2024-04-01', 3900000,  'Paid',    N'Tiền mặt',     '2024-04-05', '2024-04-04', NULL,                            '2024-03-25'),
(9,  19, 8, 'INV-009-202405', '2024-05-01', 3900000,  'Pending', N'Tiền mặt',     '2024-05-05', NULL,         NULL,                            '2024-04-25'),
(10, 20, 7, 'INV-010-202404', '2024-04-05', 3600000,  'Paid',    N'Chuyển khoản', '2024-04-10', '2024-04-08', NULL,                            '2024-03-31'),
(11, 21, 8, 'INV-011-202404', '2024-04-10', 4000000,  'Paid',    N'Online',        '2024-04-15', '2024-04-14', NULL,                            '2024-04-05'),
(12, 22, 7, 'INV-012-202404', '2024-04-15', 6100000,  'Paid',    N'Chuyển khoản', '2024-04-20', '2024-04-19', NULL,                            '2024-04-10'),
(13, 23, 8, 'INV-013-202405', '2024-05-01', 4600000,  'Pending', N'Online',        '2024-05-05', NULL,         N'Hóa đơn đầu tiên',           '2024-04-26'),
(14, 24, 7, 'INV-014-202405', '2024-05-05', 3800000,  'Pending', N'Chuyển khoản', '2024-05-10', NULL,         NULL,                            '2024-05-01');
GO

-- --------------------------------------------------------------------
-- Fees
-- --------------------------------------------------------------------
INSERT INTO Fees (PaymentID, FeeName, FeeAmount, Description) VALUES
(1,  N'Điện',     150000, N'50 kWh x 3.000đ'),
(1,  N'Nước',      50000, N'5m³ x 10.000đ'),
(1,  N'Internet', 100000, N'Gói cố định tháng 3'),
(2,  N'Điện',     170000, N'57 kWh x 3.000đ'),
(2,  N'Nước',      50000, N'5m³ x 10.000đ'),
(4,  N'Điện',     250000, N'83 kWh x 3.000đ'),
(4,  N'Nước',      80000, N'8m³ x 10.000đ'),
(4,  N'Internet', 120000, N'Gói nhanh tháng 3'),
(5,  N'Điện',     280000, N'93 kWh x 3.000đ'),
(5,  N'Nước',      90000, N'9m³ x 10.000đ'),
(7,  N'Điện',     280000, N'93 kWh x 3.000đ'),
(7,  N'Nước',     120000, N'12m³ x 10.000đ'),
(8,  N'Điện',     300000, N'100 kWh x 3.000đ'),
(8,  N'Nước',     130000, N'13m³ x 10.000đ'),
(11, N'Điện',     350000, N'117 kWh x 3.000đ'),
(11, N'Nước',     100000, N'10m³ x 10.000đ'),
(11, N'Internet', 150000, N'Gói cao cấp'),
(11, N'Gửi xe',    50000, N'1 xe máy tháng 2'),
(12, N'Điện',     350000, N'117 kWh x 3.000đ'),
(12, N'Nước',     100000, N'10m³ x 10.000đ'),
(13, N'Điện',     550000, N'183 kWh x 3.000đ – hộ lớn'),
(13, N'Nước',     200000, N'20m³ x 10.000đ'),
(13, N'Internet', 150000, N'Gói cao cấp'),
(13, N'Gửi xe',   150000, N'3 xe tháng 4'),
(15, N'Điện',     400000, N'133 kWh x 3.000đ'),
(15, N'Nước',     100000, N'10m³ x 10.000đ'),
(16, N'Điện',     450000, N'150 kWh x 3.000đ'),
(16, N'Nước',     150000, N'15m³ x 10.000đ'),
(18, N'Điện',     180000, N'60 kWh x 3.000đ'),
(18, N'Nước',      70000, N'7m³ x 10.000đ'),
(19, N'Điện',     180000, N'60 kWh x 3.000đ'),
(20, N'Điện',     200000, N'67 kWh x 3.000đ'),
(20, N'Nước',      80000, N'8m³ x 10.000đ'),
(20, N'Internet', 120000, N'Gói chuẩn tháng 3'),
(21, N'Điện',     180000, N'60 kWh x 3.000đ');
GO

-- --------------------------------------------------------------------
-- Reviews – NVCSKH (UserID 9,10) có quyền duyệt/ẩn
-- --------------------------------------------------------------------
INSERT INTO Reviews (RoomID, UserID, Rating, Comment, Status, CreatedAt) VALUES
(1,  11, 4.5, N'Phòng sạch sẽ, thoáng mát, chủ phòng dễ tính, vị trí gần trường rất tiện',  'Approved', '2024-04-01'),
(3,  12, 4.0, N'Phòng rộng, bếp sạch, máy giặt hoạt động tốt. Hàng xóm khá ồn vào buổi tối','Approved', '2024-04-15'),
(5,  13, 5.0, N'Phòng view sông cực đẹp, điều hòa mạnh, nước nóng đầy đủ. Rất hài lòng!',   'Approved', '2024-03-20'),
(7,  14, 4.8, N'Phòng cao cấp xứng đáng giá tiền. Dịch vụ tuyệt vời, quản lý rất chu đáo',  'Approved', '2024-03-15'),
(9,  15, 4.2, N'Phòng rộng thoải mái cho gia đình, bếp sạch. Thỉnh thoảng mất nước nóng',   'Approved', '2024-04-10'),
(11, 16, 3.8, N'Gần bến xe rất tiện. Phòng hơi ồn vào ban ngày do gần đường lớn',           'Approved', '2024-04-05'),
(13, 17, 4.3, N'Máy giặt tiện lợi, wifi nhanh. Phòng thoáng, chủ nhà thân thiện',           'Approved', '2024-04-20'),
(15, 18, 4.7, N'Gần công viên, buổi sáng rất mát mẻ. Phòng sạch, yên tĩnh tuyệt vời',      'Approved', '2024-04-25'),
(18, 19, 4.1, N'Phòng đủ tiện nghi, quản lý tốt. Giá hơi cao so với khu vực',              'Approved', '2024-05-05'),
(19, 20, 3.9, N'Vị trí trung tâm rất tiện đi lại. Phòng nhỏ hơn ảnh một chút',             'Approved', '2024-05-10'),
(21, 21, 4.6, N'Phòng mới hoàn toàn, sơn mới, thiết bị mới. Rất ưng ý!',                   'Approved', '2024-05-15'),
(23, 22, 5.0, N'Duplex cực kỳ độc đáo, không gian 2 tầng rất thú vị. Sẽ ở lâu dài',        'Approved', '2024-05-20'),
(25, 23, 4.4, N'View đường phố ban đêm đẹp lắm. Ban công rộng, ngồi uống cà phê rất thích', 'Approved', '2024-05-22'),
(28, 24, 4.0, N'Phòng standard nhưng đủ dùng. Giá tốt so với vị trí trung tâm Q1',         'Approved', '2024-05-23'),
(1,  12, 4.3, N'Phòng đẹp, nhưng thỉnh thoảng wifi chậm vào giờ cao điểm buổi tối',         'Pending',  '2024-05-23'),
(3,  26, 3.5, N'Phòng tạm ổn, bếp hơi nhỏ với gia đình đông người',                         'Pending',  '2024-05-22'),
(5,  27, 2.0, N'Thất vọng với tiện ích, điều hòa hay hỏng, phản ánh chậm được xử lý',       'Rejected', '2024-05-20'),
(7,  28, 4.9, N'Phòng luxury thật sự đáng tiền. Mọi thứ đều hoàn hảo!',                     'Pending',  '2024-05-21'),
(9,  29, 4.2, N'Gia đình hài lòng, bếp rộng, máy giặt tiện. Chỉ hơi xa siêu thị',          'Approved', '2024-05-18'),
(11, 30, 3.7, N'Phòng ổn, chủ nhà dễ tính. Bãi giữ xe đôi khi hết chỗ',                   'Approved', '2024-05-15'),
(13, 31, 4.5, N'Máy giặt và wifi là điểm cộng lớn. Phòng sạch, vệ sinh tốt',               'Approved', '2024-05-12'),
(15, 32, 4.8, N'Công viên gần nhà là điểm tuyệt vời nhất. Không khí trong lành mỗi sáng',  'Approved', '2024-05-10'),
(18, 33, 3.5, N'Phòng sang nhưng thang máy hay hỏng. Cần khắc phục sớm',                   'Approved', '2024-05-08'),
(19, 34, 4.0, N'Trung tâm, đi đâu cũng tiện. Phòng hơi ồn do gần chợ',                    'Approved', '2024-05-05'),
(21, 32, 4.7, N'Phòng mới, sạch, chủ chu đáo. Rất ổn cho người trẻ đi làm',               'Approved', '2024-05-03'),
(23, 33, 4.9, N'Duplex đẳng cấp, mỗi tầng một không gian riêng. Sáng tạo và thoải mái',    'Approved', '2024-05-01'),
(25, 34, 4.3, N'Ban công view phố rất đẹp về đêm. Phòng thoáng, tiện đủ thứ',              'Approved', '2024-04-28'),
(28, 11, 4.1, N'Vị trí đắc địa Q1, phòng sạch, quản lý nhiệt tình. Giá xứng đáng',        'Approved', '2024-04-25'),
(29, 12, 4.5, N'Phòng gia đình rộng, bếp to, thoải mái cho 6 người. Rất hài lòng!',        'Approved', '2024-04-22'),
(30, 13, 4.6, N'An ninh cực tốt, cổng từ, camera đầy đủ. Cảm giác an toàn khi về muộn',   'Approved', '2024-04-20');
GO

-- --------------------------------------------------------------------
-- Notifications
-- SenderID phản ánh đúng vai trò:
--   NVVH  (2,4,5,6)  → gửi thông báo booking
--   NVTC  (7,8)      → gửi thông báo hóa đơn / hợp đồng
--   NVCSKH(9,10)     → gửi thông báo đánh giá
-- --------------------------------------------------------------------
INSERT INTO Notifications (RecipientID, SenderID, Title, Message, Type, RelatedEntityType, RelatedEntityID, IsRead, CreatedAt)
VALUES
(11, 2,    N'Đặt phòng được phê duyệt',       N'Booking phòng A101 của bạn đã được duyệt. Vui lòng đến ký hợp đồng.',          'Booking',  'Booking',  1,  1, '2024-02-21'),
(12, 2,    N'Đặt phòng được phê duyệt',       N'Booking phòng B201 của bạn đã được duyệt. Hợp đồng đã sẵn sàng.',              'Booking',  'Booking',  2,  1, '2024-03-02'),
(13, 4,    N'Đặt phòng được phê duyệt',       N'Booking phòng C301 của bạn đã được duyệt thành công.',                         'Booking',  'Booking',  3,  1, '2024-02-11'),
(14, 4,    N'Đặt phòng được phê duyệt',       N'Booking phòng D401 của bạn được duyệt. Hợp đồng 2 năm đã tạo.',                'Booking',  'Booking',  4,  1, '2024-01-29'),
(15, 5,    N'Đặt phòng được phê duyệt',       N'Booking phòng E501 của bạn đã được phê duyệt.',                                'Booking',  'Booking',  5,  0, '2024-02-16'),
(11, 7,    N'Hóa đơn tháng 3/2024',           N'Hóa đơn INV-001-202403 số tiền 3.800.000đ. Hạn thanh toán: 05/03/2024.',       'Payment',  'Payment',  1,  1, '2024-02-25'),
(11, 7,    N'Hóa đơn tháng 4/2024',           N'Hóa đơn INV-001-202404 số tiền 3.820.000đ. Hạn thanh toán: 05/04/2024.',       'Payment',  'Payment',  2,  1, '2024-03-25'),
(11, 7,    N'Hóa đơn tháng 5/2024',           N'Hóa đơn INV-001-202405 số tiền 3.800.000đ. Hạn thanh toán: 05/05/2024.',       'Payment',  'Payment',  3,  0, '2024-04-25'),
(12, 7,    N'Hóa đơn tháng 3/2024',           N'Hóa đơn INV-002-202403 số tiền 4.900.000đ. Hạn thanh toán: 20/03/2024.',       'Payment',  'Payment',  4,  1, '2024-03-10'),
(16, 7,    N'Hóa đơn tháng 4/2024 quá hạn',   N'Hóa đơn INV-006-202404 đã quá hạn. Vui lòng thanh toán ngay để tránh phạt.',  'Payment',  'Payment',  19, 0, '2024-04-10'),
(31, 9,    N'Đặt phòng bị từ chối',           N'Booking phòng A102 bị từ chối. Lý do: thông tin CCCD chưa đủ.',                'Booking',  'Booking',  21, 1, '2024-04-16'),
(32, 4,    N'Đặt phòng bị từ chối',           N'Booking phòng H801 bị từ chối. Phòng đang trong quá trình bảo trì.',           'Booking',  'Booking',  22, 1, '2024-03-16'),
(7,  NULL, N'Thông báo hệ thống',             N'Hệ thống sẽ bảo trì lúc 2:00-4:00 AM ngày 15/06/2024. Xin lỗi vì bất tiện.',  'System',   NULL,       NULL,0, '2024-06-10'),
(1,  NULL, N'Thông báo hệ thống',             N'Hệ thống sẽ bảo trì lúc 2:00-4:00 AM ngày 15/06/2024.',                       'System',   NULL,       NULL,0, '2024-06-10'),
(11, NULL, N'Nhắc nhở thanh toán',            N'Hóa đơn INV-001-202405 sắp đến hạn (05/05/2024). Vui lòng thanh toán sớm.',   'Payment',  'Payment',  3,  0, '2024-05-02'),
(12, 7,    N'Hóa đơn tháng 5/2024',           N'Hóa đơn INV-002-202405 số tiền 4.900.000đ. Hạn thanh toán: 20/05/2024.',       'Payment',  'Payment',  6,  0, '2024-05-10'),
(14, 7,    N'Hóa đơn tháng 5/2024',           N'Hóa đơn INV-004-202405 số tiền 8.500.000đ. Hạn thanh toán: 05/05/2024.',       'Payment',  'Payment',  14, 0, '2024-04-25'),
(19, 8,    N'Hợp đồng CT-009 đã tạo',         N'Hợp đồng CT-009-20240401 của bạn đã được tạo. Hiệu lực từ 01/04/2024.',        'Contract', 'Contract', 9,  1, '2024-03-27'),
(20, 7,    N'Hợp đồng CT-010 đã tạo',         N'Hợp đồng CT-010-20240405 của bạn đã được tạo.',                                'Contract', 'Contract', 10, 1, '2024-04-01'),
(21, 5,    N'Phòng cần bảo trì',              N'Phòng G702 sẽ bảo trì từ 15/02/2024. Liên hệ nhân viên nếu cần hỗ trợ.',      'Maintenance','Room',   14, 0, '2024-02-13'),
(26, 2,    N'Đặt phòng được phê duyệt',       N'Booking phòng B201 của bạn đã được duyệt.',                                    'Booking',  'Booking',  2,  0, '2024-05-23'),
(2,  1,    N'Đơn đặt phòng mới',              N'Có 5 booking mới đang chờ duyệt. Vui lòng xem xét sớm.',                      'Booking',  NULL,       NULL,0, '2024-05-23'),
(4,  1,    N'Đơn đặt phòng mới',              N'Có 3 booking mới cần bạn xét duyệt hôm nay.',                                  'Booking',  NULL,       NULL,0, '2024-05-23'),
(8,  1,    N'Báo cáo doanh thu tháng 5',      N'Doanh thu tháng 5/2024 đã được tổng hợp. Xem chi tiết trong báo cáo.',         'System',   NULL,       NULL,0, '2024-05-23'),
(13, 8,    N'Hóa đơn tháng 5/2024',           N'Hóa đơn INV-003-202405 số tiền 5.900.000đ. Hạn thanh toán: 20/05/2024.',       'Payment',  'Payment',  10, 0, '2024-05-10'),
(15, 8,    N'Hóa đơn tháng 5/2024',           N'Hóa đơn INV-005-202405 đang chờ xuất. Sẽ gửi trước 20/05/2024.',               'Payment',  NULL,       NULL,0, '2024-05-15'),
(23, 8,    N'Hóa đơn đầu tiên',              N'Hóa đơn INV-013-202405 đã tạo. Đây là tháng đầu tiên, hạn 05/05/2024.',        'Payment',  'Payment',  29, 1, '2024-04-26'),
(24, 7,    N'Hóa đơn đầu tiên',              N'Hóa đơn INV-014-202405 đã tạo. Hạn thanh toán: 10/05/2024.',                   'Payment',  'Payment',  30, 0, '2024-05-01'),
(17, 4,    N'Hợp đồng CT-007 đã tạo',         N'Hợp đồng phòng G701 đã được ký kết thành công.',                               'Contract', 'Contract', 7,  1, '2024-03-06'),
(22, 8,    N'Hợp đồng CT-012 đã tạo',         N'Hợp đồng phòng L1201 (duplex) đã được ký kết.',                               'Contract', 'Contract', 12, 1, '2024-04-11'),
(9,  1,    N'Phân quyền nhóm NVCSKH',         N'Bạn được giao nhóm quyền NVCSKH. Vui lòng xem lại các chức năng mới.',        'System',   NULL,       NULL,0, '2024-01-10'),
(10, 1,    N'Phân quyền nhóm NVCSKH',         N'Bạn được giao nhóm quyền NVCSKH. Vui lòng đăng nhập lại để cập nhật.',        'System',   NULL,       NULL,0, '2024-01-11');
GO

-- --------------------------------------------------------------------
-- ActivityLogs – phản ánh đúng vai trò từng nhân viên
-- --------------------------------------------------------------------
INSERT INTO ActivityLogs (UserID, ActionType, EntityType, EntityID, OldValues, NewValues, IPAddress, Description, CreatedAt)
VALUES
-- NVVH duyệt booking
(2,    'APPROVE', 'Booking', 1,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.100', N'[NVVH] nhanvien duyệt booking #1 – phòng A101',           '2024-02-21 09:00:00'),
(2,    'CREATE',  'Contract',1,    NULL,                     N'{"ContractNumber":"CT-001"}',      '192.168.1.100', N'[NVVH] Tạo hợp đồng CT-001 từ booking #1',                '2024-02-21 09:01:00'),
(4,    'APPROVE', 'Booking', 3,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.101', N'[NVVH] nv_tran duyệt booking #3 – phòng C301',            '2024-02-11 10:00:00'),
(4,    'APPROVE', 'Booking', 4,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.101', N'[NVVH] nv_tran duyệt booking #4 – phòng D401 2 năm',      '2024-01-29 09:30:00'),
(5,    'APPROVE', 'Booking', 5,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.102', N'[NVVH] nv_le duyệt booking #5 – phòng E501',              '2024-02-16 08:45:00'),
(6,    'UPDATE',  'Room',    23,   N'{"Price":5500000}',     N'{"Price":5800000}',               '192.168.1.103', N'[NVVH] nv_pham cập nhật giá phòng L1201 duplex',          '2024-03-09 14:00:00'),
(2,    'UPDATE',  'Room',    12,   N'{"StatusID":1}',        N'{"StatusID":4}',                  '192.168.1.100', N'[NVVH] nhanvien đặt phòng F602 sang Reserved',            '2024-05-22 14:00:00'),
(4,    'REJECT',  'Booking', 22,   N'{"Status":"Pending"}',  N'{"Status":"Rejected"}',           '192.168.1.101', N'[NVVH] nv_tran từ chối booking #22 – phòng bảo trì',      '2024-03-26 10:00:00'),
(5,    'REJECT',  'Booking', 23,   N'{"Status":"Pending"}',  N'{"Status":"Rejected"}',           '192.168.1.102', N'[NVVH] nv_le từ chối booking #23 – vượt MaxOccupancy',    '2024-04-06 10:00:00'),
-- NVTC tạo hợp đồng & hóa đơn
(7,    'CREATE',  'Contract',2,    NULL,                     N'{"ContractNumber":"CT-002"}',      '192.168.1.104', N'[NVTC] nv_finance tạo hợp đồng CT-002',                   '2024-03-02 10:00:00'),
(7,    'CREATE',  'Payment', 1,    NULL,                     N'{"Amount":3800000}',               '192.168.1.104', N'[NVTC] nv_finance lập hóa đơn INV-001-202403',            '2024-02-25 10:00:00'),
(7,    'UPDATE',  'Payment', 1,    N'{"Status":"Pending"}',  N'{"Status":"Paid"}',               '192.168.1.104', N'[NVTC] nv_finance xác nhận thanh toán tháng 3',           '2024-03-04 11:00:00'),
(8,    'CREATE',  'Contract',3,    NULL,                     N'{"ContractNumber":"CT-003"}',      '192.168.1.105', N'[NVTC] nv_ketoan tạo hợp đồng CT-003',                    '2024-02-11 10:30:00'),
(8,    'CREATE',  'Payment', 7,    NULL,                     N'{"Amount":5900000}',               '192.168.1.105', N'[NVTC] nv_ketoan lập hóa đơn INV-003-202402',             '2024-02-10 09:00:00'),
(7,    'UPDATE',  'Payment', 19,   N'{"Status":"Pending"}',  N'{"Status":"Overdue"}',            '192.168.1.104', N'[NVTC] nv_finance đánh dấu INV-006-202404 quá hạn',       '2024-04-06 00:01:00'),
(8,    'CREATE',  'Contract',5,    NULL,                     N'{"ContractNumber":"CT-005"}',      '192.168.1.105', N'[NVTC] nv_ketoan tạo hợp đồng CT-005 – gia đình lớn',    '2024-02-16 11:00:00'),
-- NVCSKH phê duyệt / ẩn đánh giá, xem hồ sơ KH
(9,    'APPROVE', 'Review',  1,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.106', N'[NVCSKH] nv_cskh duyệt đánh giá #1 phòng A101',           '2024-04-01 15:00:00'),
(9,    'APPROVE', 'Review',  3,    N'{"Status":"Pending"}',  N'{"Status":"Approved"}',           '192.168.1.106', N'[NVCSKH] nv_cskh duyệt đánh giá #3 phòng C301',           '2024-03-21 10:00:00'),
(10,   'REJECT',  'Review',  17,   N'{"Status":"Pending"}',  N'{"Status":"Rejected"}',           '192.168.1.107', N'[NVCSKH] nv_huyen từ chối đánh giá #17 – nội dung tiêu cực','2024-05-22 09:00:00'),
(9,    'VIEW',    'User',    11,   NULL,                     NULL,                               '192.168.1.106', N'[NVCSKH] nv_cskh xem hồ sơ khách khach_thanh',            '2024-05-15 10:00:00'),
(10,   'VIEW',    'Booking', NULL, NULL,                     NULL,                               '192.168.1.107', N'[NVCSKH] nv_huyen xem lịch sử booking của khách hàng',    '2024-05-20 14:00:00'),
-- Admin quản trị tổng thể
(1,    'LOGIN',   'User',    1,    NULL,                     NULL,                               '192.168.1.200', N'Admin đăng nhập hệ thống',                                '2024-05-23 08:00:00'),
(1,    'CREATE',  'User',    4,    NULL,                     N'{"Username":"nv_tran","Role":1}',  '192.168.1.200', N'Admin tạo tài khoản nhân viên nv_tran',                    '2024-01-05 09:00:00'),
(1,    'CREATE',  'User',    7,    NULL,                     N'{"Username":"nv_finance","Role":1}','192.168.1.200',N'Admin tạo tài khoản nhân viên nv_finance (NVTC)',          '2024-01-08 09:00:00'),
(1,    'CREATE',  'User',    9,    NULL,                     N'{"Username":"nv_cskh","Role":1}',  '192.168.1.200', N'Admin tạo tài khoản nhân viên nv_cskh (NVCSKH)',           '2024-01-10 09:00:00'),
(1,    'UPDATE',  'EmployeeProfile', 6, N'{"GroupID":1}',   N'{"GroupID":2}',                   '192.168.1.200', N'Admin chuyển nv_pham sang nhóm NVTC',                      '2024-03-01 10:00:00'),
(1,    'UPDATE',  'Room',    17,   N'{"StatusID":1}',        N'{"StatusID":3}',                  '192.168.1.200', N'Admin đổi phòng I901 sang Maintenance',                    '2024-02-20 11:00:00'),
(1,    'UPDATE',  'User',    31,   N'{"IsActive":1}',        N'{"IsActive":0}',                  '192.168.1.200', N'Admin tạm khóa tài khoản khach_tram do vi phạm',           '2024-05-20 10:00:00'),
-- Khách hàng thao tác
(11,   'LOGIN',   'User',    11,   NULL,                     NULL,                               '192.168.1.10',  N'Khách khach_thanh đăng nhập',                             '2024-02-20 08:00:00'),
(11,   'CREATE',  'Booking', 1,    NULL,                     N'{"RoomID":1,"Status":"Pending"}',  '192.168.1.10',  N'Khách tạo booking phòng A101',                            '2024-02-20 08:30:00'),
(11,   'UPDATE',  'Payment', 1,    N'{"Status":"Pending"}',  N'{"Status":"Paid"}',               '192.168.1.10',  N'Khách thanh toán hóa đơn tháng 3',                        '2024-03-04 10:00:00'),
(NULL, 'UPDATE',  'Payment', 19,   N'{"Status":"Pending"}',  N'{"Status":"Overdue"}',            '127.0.0.1',     N'Hệ thống tự động đánh dấu quá hạn INV-006-202404',        '2024-04-06 00:01:00');
GO

-- --------------------------------------------------------------------
-- SystemSettings
-- --------------------------------------------------------------------
INSERT INTO SystemSettings (SettingKey, SettingValue, Description) VALUES
('SYSTEM_NAME',                N'ThanhThao Stay',             N'Tên hệ thống hiển thị'),
('SYSTEM_URL',                 'https://thanhthaostay.vn',     N'URL website chính'),
('SYSTEM_EMAIL',               'contact@thanhthaostay.vn',     N'Email liên hệ chính'),
('EMAIL_SMTP_SERVER',          'smtp.gmail.com',               N'Server SMTP gửi email'),
('EMAIL_SMTP_PORT',            '587',                          N'Port SMTP'),
('EMAIL_FROM_ADDRESS',         'noreply@thanhthaostay.vn',     N'Địa chỉ gửi email thông báo'),
('MAX_UPLOAD_SIZE_MB',         '10',                           N'Kích thước file upload tối đa (MB)'),
('ALLOWED_IMAGE_TYPES',        'jpg,jpeg,png,webp',            N'Định dạng ảnh cho phép upload'),
('PASSWORD_MIN_LENGTH',        '8',                            N'Độ dài tối thiểu mật khẩu'),
('PASSWORD_RESET_EXPIRY_HOURS','24',                           N'Thời gian hết hạn token reset mật khẩu (giờ)'),
('EMAIL_VERIFY_EXPIRY_HOURS',  '24',                           N'Thời gian hết hạn token xác thực email (giờ)'),
('PAYMENT_DUE_DAY',            '5',                            N'Ngày hạn thanh toán mỗi tháng (ngày 5)'),
('PAYMENT_REMINDER_DAYS',      '3',                            N'Nhắc thanh toán trước bao nhiêu ngày'),
('PAYMENT_OVERDUE_DAYS',       '5',                            N'Số ngày trễ để đánh dấu Overdue'),
('ITEMS_PER_PAGE',             '12',                           N'Số phòng hiển thị mỗi trang tìm kiếm'),
('REVIEW_AUTO_APPROVE',        '0',                            N'Tự động duyệt đánh giá (0=tắt, 1=bật)'),
('BOOKING_AUTO_REJECT_DAYS',   '3',                            N'Tự động từ chối booking sau N ngày không xử lý'),
('CONTRACT_REMINDER_DAYS',     '30',                           N'Nhắc nhở trước khi hợp đồng hết hạn (ngày)'),
('MAINTENANCE_CONTACT',        '0901234567',                   N'Số điện thoại bảo trì khẩn cấp'),
('CURRENCY',                   'VND',                          N'Đơn vị tiền tệ mặc định'),
-- Cài đặt mới cho hệ thống phân quyền nhân viên
('EMP_GROUP_DEFAULT',          'NVVH',                         N'Nhóm quyền mặc định khi tạo nhân viên mới'),
('EMP_PERMISSION_MODE',        'GROUP',                        N'Chế độ phân quyền: GROUP = theo nhóm, CUSTOM = tuỳ chỉnh');
GO

-- =====================================================================
-- KIỂM TRA TỔNG QUAN
-- =====================================================================
SELECT 'Users',            COUNT(*) FROM Users                UNION ALL
SELECT 'EmployeeGroups',   COUNT(*) FROM EmployeeGroups       UNION ALL
SELECT 'EmployeeProfiles', COUNT(*) FROM EmployeeProfiles     UNION ALL
SELECT 'RoomStatuses',     COUNT(*) FROM RoomStatuses         UNION ALL
SELECT 'Utilities',        COUNT(*) FROM Utilities            UNION ALL
SELECT 'Rooms',            COUNT(*) FROM Rooms                UNION ALL
SELECT 'RoomUtilities',    COUNT(*) FROM RoomUtilities        UNION ALL
SELECT 'RoomImages',       COUNT(*) FROM RoomImages           UNION ALL
SELECT 'Bookings',         COUNT(*) FROM Bookings             UNION ALL
SELECT 'Contracts',        COUNT(*) FROM Contracts            UNION ALL
SELECT 'Payments',         COUNT(*) FROM Payments             UNION ALL
SELECT 'Fees',             COUNT(*) FROM Fees                 UNION ALL
SELECT 'Reviews',          COUNT(*) FROM Reviews              UNION ALL
SELECT 'Notifications',    COUNT(*) FROM Notifications        UNION ALL
SELECT 'ActivityLogs',     COUNT(*) FROM ActivityLogs         UNION ALL
SELECT 'SystemSettings',   COUNT(*) FROM SystemSettings;

-- Xem phân quyền nhân viên
SELECT
    u.UserID, u.Username,
    ep.EmployeeCode, ep.Position, ep.Department,
    eg.GroupCode, eg.GroupName,
    eg.CanViewRoom, eg.CanApproveBooking,
    eg.CanCreateContract, eg.CanTrackPayment,
    eg.CanManageReview, eg.CanViewBookingHistory
FROM Users u
JOIN EmployeeProfiles ep ON ep.UserID = u.UserID
JOIN EmployeeGroups   eg ON eg.GroupID = ep.GroupID
ORDER BY eg.GroupCode, u.UserID;
GO