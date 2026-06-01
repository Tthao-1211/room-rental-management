namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class Reviews
    {
        [Key]
        public int ReviewID { get; set; }

        public int RoomID { get; set; }

        public int UserID { get; set; }

        public decimal Rating { get; set; }

        public string Comment { get; set; }

        [Required]
        [StringLength(20)]
        public string Status { get; set; } = "Approved";

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public virtual Room Rooms { get; set; }

        public virtual User Users { get; set; }
    }
}
