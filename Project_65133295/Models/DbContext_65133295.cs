using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;
using System.Linq;

namespace Project_65133295.Models
{
    public partial class DbContext_65133295 : DbContext
    {
        public DbContext_65133295()
            : base("name=DbContext_65133295")
        {
        }

        public virtual DbSet<ActivityLogs> ActivityLogs { get; set; }
        
        public virtual DbSet<Bookings> Bookings { get; set; }
        public virtual DbSet<Contracts> Contracts { get; set; }
        public virtual DbSet<EmailVerificationTokens> EmailVerificationTokens { get; set; }
        public virtual DbSet<Fees> Fees { get; set; }
        public virtual DbSet<Notifications> Notifications { get; set; }
        public virtual DbSet<PasswordResetTokens> PasswordResetTokens { get; set; }
        public virtual DbSet<Payments> Payments { get; set; }
        public virtual DbSet<Reviews> Reviews { get; set; }
        public virtual DbSet<RoomImages> RoomImages { get; set; }
        public virtual DbSet<Room> Rooms { get; set; }
        public virtual DbSet<RoomStatuses> RoomStatuses { get; set; }
        public virtual DbSet<RoomUtilities> RoomUtilities { get; set; }
        public virtual DbSet<SystemSettings> SystemSettings { get; set; }
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<Utilities> Utilities { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            // Addresses table removed in new schema; related mappings removed.

            modelBuilder.Entity<Bookings>()
                .HasMany(e => e.Contracts)
                .WithRequired(e => e.Bookings)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<Contracts>()
                .HasMany(e => e.Payments)
                .WithRequired(e => e.Contracts)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<Reviews>()
                .Property(e => e.Rating)
                .HasPrecision(3, 2);

            modelBuilder.Entity<Room>()
                .Property(e => e.Area)
                .HasPrecision(10, 2);
            modelBuilder.Entity<Room>()
                .HasMany(e => e.Bookings)
                .WithRequired(e => e.Rooms)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<RoomStatuses>()
                .HasMany(e => e.Rooms)
                .WithRequired(e => e.RoomStatuses)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Bookings)
                .WithOptional(e => e.Users)
                .HasForeignKey(e => e.ApprovedBy);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Bookings1)
                .WithRequired(e => e.Users1)
                .HasForeignKey(e => e.UserID)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Notifications)
                .WithRequired(e => e.Users)
                .HasForeignKey(e => e.RecipientID)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Notifications1)
                .WithOptional(e => e.Users1)
                .HasForeignKey(e => e.SenderID);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Payments)
                .WithRequired(e => e.Users)
                .HasForeignKey(e => e.AdminID)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Payments1)
                .WithRequired(e => e.Users1)
                .HasForeignKey(e => e.UserID)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Reviews)
                .WithRequired(e => e.Users)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Rooms)
                .WithRequired(e => e.Users)
                .HasForeignKey(e => e.AdminID)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Rooms1)
                .WithOptional(e => e.Users1)
                .HasForeignKey(e => e.CurrentTenantID);

            modelBuilder.Entity<Utilities>()
                .HasMany(e => e.RoomUtilities)
                .WithRequired(e => e.Utilities)
                .WillCascadeOnDelete(false);
        }
    }
}
