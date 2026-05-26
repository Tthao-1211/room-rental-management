namespace Project_65133295.Migrations
{
    using System.Data.Entity.Migrations;

    internal sealed class Configuration : DbMigrationsConfiguration<Project_65133295.Models.DbContext_65133295>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
            MigrationsDirectory = "Migrations";
            ContextKey = "Project_65133295.Models.DbContext_65133295";
        }

        protected override void Seed(Project_65133295.Models.DbContext_65133295 context)
        {
            // Seed data (if needed) can be added here.
            // Note: password hashing depends on project's hashing method; postpone seeding until hashing available.
        }
    }
}
