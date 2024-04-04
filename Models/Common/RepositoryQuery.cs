using Hotel.Models;
using Microsoft.EntityFrameworkCore.Query;
using System.Linq.Expressions;

namespace Hotel.Models
{
    public sealed class RepositoryQuery<TEntity> where TEntity : class
    {
        private readonly List<Expression<Func<TEntity, object>>>
            _includeProperties;

        private readonly Repository<TEntity> _repository;
        private Expression<Func<TEntity, bool>> _filter;
        private Func<IQueryable<TEntity>,
            IOrderedQueryable<TEntity>> _orderByQuerable;
        private int? _page;
        private int? _pageSize;
        private bool _trackingEnabled;

        private readonly List<IIncludableQueryable<TEntity, object>> _includedProperties;
        public RepositoryQuery(Repository<TEntity> repository)
        {
            _repository = repository;
            _trackingEnabled = false;
            _includeProperties =
                new List<Expression<Func<TEntity, object>>>();
            _includedProperties = new List<IIncludableQueryable<TEntity, object>>();
        }

        public RepositoryQuery<TEntity> Filter(
            Expression<Func<TEntity, bool>> filter)
        {
            _filter = filter;
            return this;
        }

        public RepositoryQuery<TEntity> AsTracking()
        {
            _trackingEnabled = true;
            return this;
        }

        public RepositoryQuery<TEntity> AsNoTracking()
        {
            _trackingEnabled = false;
            return this;
        }
        public RepositoryQuery<TEntity> OrderBy(
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderBy)
        {
            _orderByQuerable = orderBy;
            return this;
        }

        public RepositoryQuery<TEntity> Include(
            Expression<Func<TEntity, object>> expression)
        {
            _includeProperties.Add(expression);
            return this;
        }

        public RepositoryQuery<TEntity> Include(IIncludableQueryable<TEntity, object> include = null)
        {
            _includedProperties.Add(include);
            return this;
        }

        public IEnumerable<TEntity> GetPage(
            int page, int pageSize, out int totalCount)
        {
            _page = page;
            _pageSize = pageSize;
            totalCount = _repository.Get(_filter).Count();

            return _repository.Get(
                _filter,
                _trackingEnabled,
                _orderByQuerable, _includeProperties, _page, _pageSize);
        }

        public IEnumerable<TEntity> Get()
        {
            return _repository.Get(
                _filter,
                _trackingEnabled,
                _orderByQuerable, _includeProperties, _page, _pageSize);
        }

        public IQueryable<TEntity> GetQuerable()
        {
            return _repository.Get(
                _filter,
                _trackingEnabled,
                _orderByQuerable, _includeProperties, _page, _pageSize);
        }

        public IQueryable<TEntity> GetQuerable(Expression<Func<TEntity, bool>> filter = null,
            bool trackingEnabled = false,
            Func<IQueryable<TEntity>, IOrderedQueryable<TEntity>> orderByQuerable = null,
            List<Expression<Func<TEntity, object>>> includeProperties = null,
            int? page = null, int? pageSize = null)
        {
            return _repository.Get(
                filter,
                trackingEnabled,
                orderByQuerable, includeProperties, page, pageSize);
        }
    }
}