using System.Web;

namespace Project_65133295.Helpers
{
    public static class RoleHelper
    {
        public static bool IsAdmin(HttpSessionStateBase session)
        {
            return string.Equals(session?["UserRole"]?.ToString()?.Trim(), "Admin", System.StringComparison.OrdinalIgnoreCase);
        }

        public static bool IsNhanVien(HttpSessionStateBase session)
        {
            return string.Equals(session?["UserRole"]?.ToString()?.Trim(), "NhanVien", System.StringComparison.OrdinalIgnoreCase);
        }

        public static bool IsKhach(HttpSessionStateBase session)
        {
            return string.Equals(session?["UserRole"]?.ToString()?.Trim(), "Khach", System.StringComparison.OrdinalIgnoreCase);
        }

        public static bool IsAdminOrNhanVien(HttpSessionStateBase session)
        {
            var r = session?["UserRole"]?.ToString()?.Trim();
            return string.Equals(r, "Admin", System.StringComparison.OrdinalIgnoreCase) || string.Equals(r, "NhanVien", System.StringComparison.OrdinalIgnoreCase);
        }
    }
}
