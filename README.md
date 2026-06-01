# Rental Room Management System

ASP.NET MVC 5 application for managing rental rooms, bookings, contracts, invoices, reviews, notifications, and employee permissions.

## Tech Stack

- ASP.NET MVC 5
- Entity Framework 6
- .NET Framework 4.8.1
- SQL Server
- Bootstrap, jQuery

## Main Roles

- `Admin`: full access to the admin area
- `NhanVien`: staff access controlled by `EmployeeGroups` permissions
- `Khach`: customer/tenant access for personal dashboard and booking features

## Database

The updated schema is in `db_new.sql`.

Key additions:

- `EmployeeGroups`
- `EmployeeProfiles`
- staff permission flags:
  - `CanViewRoom`
  - `CanEditRoom`
  - `CanCreateBooking`
  - `CanApproveBooking`
  - `CanViewRoomDashboard`
  - `CanCreateContract`
  - `CanManageContract`
  - `CanCreatePayment`
  - `CanTrackPayment`
  - `CanViewRevenueDashboard`
  - `CanViewTenantProfile`
  - `CanManageReview`
  - `CanViewBookingHistory`

## Admin Area Behavior

- Admin users can access all admin pages.
- Staff users are routed and authorized by permission group.
- The admin sidebar only shows menu items allowed by the current staff group.
- Direct URL access is also blocked in the controller, not only hidden in the UI.

## Important Files

- `Project_65133295/Controllers/Guest_65133295Controller.cs`
- `Project_65133295/Areas/Admin/Controllers/Admin_65133295Controller.cs`
- `Project_65133295/Areas/Admin/Views/Shared/_LayoutAdmin.cshtml`
- `Project_65133295/Models/DbContext_65133295.cs`
- `Project_65133295/Models/Users.cs`
- `db_new.sql`

## Run

1. Open `Project_65133295/Project_65133295.sln` in Visual Studio.
2. Restore NuGet packages if needed.
3. Update the connection string in `Project_65133295/Web.config` if your SQL Server differs.
4. Build and run the project.

## Notes

- The login flow redirects staff to the first page they are allowed to access.
- Admin user management supports staff visibility, employee group details, and create user flow.
- The admin area now checks permissions at both UI and controller level.
