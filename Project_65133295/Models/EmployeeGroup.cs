namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;

    [Table("EmployeeGroups")]
    public partial class EmployeeGroup
    {
        [Key]
        public int GroupID { get; set; }

        [Required]
        [StringLength(10)]
        [Index("IX_EmployeeGroups_GroupCode", IsUnique = true)]
        public string GroupCode { get; set; }

        [Required]
        [StringLength(100)]
        public string GroupName { get; set; }

        [StringLength(500)]
        public string Description { get; set; }

        public bool CanViewRoom { get; set; }
        public bool CanEditRoom { get; set; }
        public bool CanCreateBooking { get; set; }
        public bool CanApproveBooking { get; set; }
        public bool CanViewRoomDashboard { get; set; }

        public bool CanCreateContract { get; set; }
        public bool CanManageContract { get; set; }
        public bool CanCreatePayment { get; set; }
        public bool CanTrackPayment { get; set; }
        public bool CanViewRevenueDashboard { get; set; }

        public bool CanViewTenantProfile { get; set; }
        public bool CanManageReview { get; set; }
        public bool CanViewBookingHistory { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public virtual ICollection<EmployeeProfile> EmployeeProfiles { get; set; }
            = new HashSet<EmployeeProfile>();
    }
}
