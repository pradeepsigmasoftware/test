using Hotel.data;
using Hotel.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using System.Linq.Expressions;

namespace Hotel.Models
{
    public class Repository<TEntity> : IRepository<TEntity> where TEntity : class
    {
        internal UPSTDCHoteldbContext Context;
        internal DbSet<TEntity> DbSet;
        private readonly IConfiguration configuration;

        public Repository(UPSTDCHoteldbContext context, IConfiguration configuration)
        {
            Context = context;
            DbSet = context.Set<TEntity>();
            this.configuration = configuration;
        }
        public async Task<List<TEntity>> GetAllAsync() => await DbSet.ToListAsync();

        public async Task<TEntity> GetAsync(int id) => await DbSet.FindAsync(id);

        public async Task UpdateAsync(TEntity entity)
        {
            if (entity == null)
            {
                throw new ArgumentNullException("entity");
            }
            DbSet.Update(entity);
            await Context.SaveChangesAsync();
        }
        public virtual RepositoryQuery<TEntity> Query()
        {
            var repositoryGetFluentHelper =
                new RepositoryQuery<TEntity>(this);

            return repositoryGetFluentHelper;
        }

        public virtual TEntity FindById(object SectionId)
        {
            return DbSet.Find(SectionId);
        }
        public virtual void Insert(TEntity entity)
        {
            try
            {
                DbSet.Add(entity);
                Context.SaveChanges();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task InsertAsync(TEntity entity)
        {
            if (entity == null)
            {
                throw new ArgumentNullException("entity");
            }
            DbSet.Add(entity);
            await Context.SaveChangesAsync();
        }

        public virtual void InsertList(List<TEntity> entities)
        {
            try
            {
                foreach (var entity in entities)
                {
                    DbSet.Add(entity);
                }

                Context.SaveChanges();
            }
            catch (Exception ex)
            { 
            }
        }



        public virtual void Update(TEntity entity)
        {
            try
            {
                // Detach any existing entity with the same key
                var existingEntity = DbSet.Local.SingleOrDefault(e => Context.Entry(e).Entity == entity);
                if (existingEntity != null)
                {
                    Context.Entry(existingEntity).State = EntityState.Detached;
                }

                // Attach and update the entity
                DbSet.Attach(entity);
                Context.Entry(entity).State = EntityState.Modified;
                Context.SaveChanges();
            }
            catch (DbUpdateException ex)
            {
                // Handle and log the exception
                //Log.Error($"Error updating entity of type {typeof(TEntity)}", ex);
                throw;
            }
            catch (Exception ex)
            {
                // Handle and log other exceptions
                //Log.Error($"Error updating entity of type {typeof(TEntity)}", ex);
                throw;
            }
        }




        public virtual void UpdateWithoutAttach(TEntity entity)
        {
            try
            {
                Context.Entry(entity).State = EntityState.Modified;
                Context.SaveChanges();
            }
            catch (Exception ex) //(DbEntityValidationException ex)
            {
                //StringBuilder sb = new StringBuilder();

                //foreach (var failure in ex.EntityValidationErrors)
                //{
                //    sb.AppendFormat("{0} failed validation\n", failure.Entry.Entity.GetType());
                //    foreach (var error in failure.ValidationErrors)
                //    {
                //        sb.AppendFormat("- {0} : {1}", error.PropertyName, error.ErrorMessage);
                //        sb.AppendLine();
                //    }
                //}

                //throw new DbEntityValidationException(
                //    "Entity Validation Failed - errors follow:\n" +
                //    sb.ToString(), ex
                //);
            }
        }
        //public virtual void Delete(object id)
        //{
        //    var entity = DbSet.Find(id);
        //    Delete(entity);
        //}


        public virtual void InsertCollection(List<TEntity> entityCollection)
        {
            entityCollection.ForEach(e =>
            {
                DbSet.Add(e);
            });
            Context.SaveChanges();
        }
        public virtual void Delete(TEntity entity)
        {

            DbSet.Attach(entity);
            DbSet.Remove(entity);
            Context.SaveChanges();
        }
        public async Task Delete(object id)
        {
            try
            {
                var entity = DbSet.Find(id);
                DbSet.Remove(entity);
                await Context.SaveChangesAsync();
            }
            catch (Exception ex)
            {

            }
        }

        public virtual void DeleteCollection(List<TEntity> entityCollection)
        {
            entityCollection.ForEach(e =>
            {
                Context.Entry(e).State = EntityState.Deleted;
            });
            Context.SaveChanges();
        }
        public virtual void Delete(List<TEntity> entity)
        {

            DbSet.RemoveRange(entity);
            Context.SaveChanges();
        }
        public UPSTDCHoteldbContext GetContext()
        {
            return Context;
        }

        public void SaveChanges()
        {
            Context.SaveChanges();
        }

        public IEnumerable<TEntity> Get<TResult>(Expression<Func<TEntity, bool>> filter = null,
                                            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy = null,
                                            Func<IQueryable<TEntity>, IIncludableQueryable<TEntity, object>> include = null,
                                            bool trackingEnabled = false
                                          ) where TResult : class
        {
            IQueryable<TEntity> query = DbSet;

            if (include != null)
            {
                query = include(query);
            }

            if (filter != null)
            {
                query = query.Where(filter);
            }

            if (orderBy != null)
            {
                query = orderBy(query);
            }

            return (trackingEnabled ? query : query.AsNoTracking()).AsEnumerable();
        }

        internal IQueryable<TEntity> Get(
           Expression<Func<TEntity, bool>> filter = null,
           bool trackingEnabled = false,
           Func<IQueryable<TEntity>,
               IOrderedQueryable<TEntity>> orderBy = null,
           List<Expression<Func<TEntity, object>>>
               includeProperties = null,
           int? page = null,
           int? pageSize = null)
        {
            IQueryable<TEntity> query = DbSet;

            if (includeProperties != null)
                includeProperties.ForEach(i => { query = query.Include(i); });

            if (filter != null)
                query = query.Where(filter);

            if (orderBy != null)
                query = orderBy(query);

            if (page != null && pageSize != null)
                query = query
                    .Skip((page.Value - 1) * pageSize.Value)
                    .Take(pageSize.Value);

            return (trackingEnabled ? query : query.AsNoTracking());
        }




        public void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
