using Hotel.data;
using Microsoft.EntityFrameworkCore.Query;
using System.Linq.Expressions;

namespace Hotel.Models
{
    public interface IRepository<TEntity> where TEntity : class
    {
        TEntity FindById(object id);

        void Insert(TEntity entity);

        void InsertList(List<TEntity> entity);

        void InsertCollection(List<TEntity> entityCollection);

        void DeleteCollection(List<TEntity> entityCollection);
        void Update(TEntity entity);

        void Delete(TEntity entity);
        public UPSTDCHoteldbContext GetContext();
        public void SaveChanges();
        RepositoryQuery<TEntity> Query();
        IEnumerable<TEntity> Get<TResult>(Expression<Func<TEntity, bool>> filter = null,
                                          Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy = null,
                                         Func<IQueryable<TEntity>, IIncludableQueryable<TEntity, object>> include = null,
                                          bool trackingEnabled = false) where TResult : class;


        public void Dispose();
    }
}
