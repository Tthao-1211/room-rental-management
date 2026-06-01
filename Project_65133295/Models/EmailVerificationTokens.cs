namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class EmailVerificationTokens
    {
        [Key]
        public int TokenID { get; set; }

        public int UserID { get; set; }

        [Required]
        [StringLength(255)]
        [Index("IX_EmailVerificationTokens_Token", IsUnique = true)]
        public string Token { get; set; }

        public DateTime ExpiresAt { get; set; }

        public bool IsUsed { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public virtual User Users { get; set; }
    }
}
