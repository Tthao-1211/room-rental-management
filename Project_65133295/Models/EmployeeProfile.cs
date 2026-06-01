namespace Project_65133295.Models
{
    using System;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;

    [Table("EmployeeProfiles")]
    public partial class EmployeeProfile
    {
        [Key]
        public int ProfileID { get; set; }

        [Required]
        [ForeignKey("User")]
        [Index("IX_EmployeeProfiles_UserID", IsUnique = true)]
        public int UserID { get; set; }

        [Required]
        [ForeignKey("EmployeeGroup")]
        public int GroupID { get; set; }

        [StringLength(20)]
        [Index("IX_EmployeeProfiles_EmployeeCode", IsUnique = true)]
        public string EmployeeCode { get; set; }

        [StringLength(100)]
        public string Department { get; set; }

        [StringLength(100)]
        public string Position { get; set; }

        [Column(TypeName = "date")]
        public DateTime? HiredDate { get; set; }

        [StringLength(500)]
        public string Note { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public virtual User User { get; set; }
        public virtual EmployeeGroup EmployeeGroup { get; set; }
    }
}
