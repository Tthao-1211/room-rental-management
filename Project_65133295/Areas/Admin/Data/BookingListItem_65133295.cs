namespace Project_65133295.Areas.Admin.Data
{
    public class BookingListItem_65133295
    {
        public int BookingID { get; set; }
        public string TenantFullName { get; set; }
        public string TenantPhone { get; set; }
        public string RoomNumber { get; set; }
        public string RoomTitle { get; set; }
        public System.DateTime CheckInDate { get; set; }
        public int? Duration { get; set; }
        public decimal? DepositAmount { get; set; }
        public string BookingStatus { get; set; }
    }
}