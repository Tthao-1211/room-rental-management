namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Users")]
    public partial class User
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public User()
        {
            ActivityLogs = new HashSet<ActivityLogs>();
            Bookings = new HashSet<Bookings>();
            Bookings1 = new HashSet<Bookings>();
            EmailVerificationTokens = new HashSet<EmailVerificationTokens>();
            Notifications = new HashSet<Notifications>();
            Notifications1 = new HashSet<Notifications>();
            PasswordResetTokens = new HashSet<PasswordResetTokens>();
            Payments = new HashSet<Payments>();
            Payments1 = new HashSet<Payments>();
            Reviews = new HashSet<Reviews>();
            Rooms = new HashSet<Room>();
            Rooms1 = new HashSet<Room>();
        }

        [Key]
        public int UserID { get; set; }

        [Required]
        [StringLength(50)]
        public string Username { get; set; }

        [Required]
        [StringLength(100)]
        public string Email { get; set; }

        [Required]
        [StringLength(255)]
        public string PasswordHash { get; set; }

        [StringLength(100)]
        public string FirstName { get; set; }

        [StringLength(100)]
        public string LastName { get; set; }

        [StringLength(20)]
        public string PhoneNumber { get; set; }

        [Range(0, 2, ErrorMessage = "Invalid role value")]
        public UserRole Role { get; set; }

        [StringLength(500)]
        public string Avatar { get; set; }

        [Column(TypeName = "date")]
        public DateTime? DateOfBirth { get; set; }

        [Column(TypeName = "nchar")]
        [StringLength(1)]
        public string Gender { get; set; }

        [StringLength(20)]
        public string IdentityNumber { get; set; }

        [StringLength(255)]
        public string Street { get; set; }

        [StringLength(100)]
        public string Ward { get; set; }

        [StringLength(100)]
        public string District { get; set; }

        [StringLength(100)]
        public string City { get; set; }

        public bool? IsActive { get; set; }

        public bool? IsEmailVerified { get; set; }

        public DateTime? CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        public DateTime? LastLoginAt { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<ActivityLogs> ActivityLogs { get; set; }

        

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Bookings> Bookings { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Bookings> Bookings1 { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<EmailVerificationTokens> EmailVerificationTokens { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Notifications> Notifications { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Notifications> Notifications1 { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<PasswordResetTokens> PasswordResetTokens { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Payments> Payments { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Payments> Payments1 { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Reviews> Reviews { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Room> Rooms { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Room> Rooms1 { get; set; }
    }
}
