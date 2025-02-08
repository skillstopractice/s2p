module S2P
  class Search
    include ActiveModel::Validations

    class << self
      def setup(&conds)
        @before_callback = conds
      end

      def scope
        @before_callback.present? ? @before_callback[from] : from
      end

      def search_keys
        [:page, :sort_order, :order_by] + conditions.keys + (@additional_search_params || [])
      end

      def additional_search_params(*keys)
        @additional_search_params = keys
      end

      def create(params={})
        new(params).tap(&:save)
      end

      def searches(from)
        @from ||= from
      end

      def sortable_by(*names, table_name: self.from.table_name)
        names.each do |name|
          sortable_by!(name,
            asc: ->(s) { s.reorder("#{table_name}.#{name} asc")  },
            desc: ->(s) { s.reorder("#{table_name}.#{name} desc") }
          )
        end
      end

      def sortable_by_alias(sort_alias, sort_condition)
        sortable_by!(sort_alias,
          asc:  ->(s) { s.reorder("#{sort_condition} asc")  },
          desc: ->(s) { s.reorder("#{sort_condition} desc") }
        )
      end

      def sortable_by!(name, asc:, desc:)
        name = name.to_sym

        case asc
        when String
          sort_by_filters[name][:asc] = ->(s) { s.reorder(asc) }
        when Proc
          sort_by_filters[name][:asc] = asc
        end

        case desc
        when String
          sort_by_filters[name][:desc] = ->(s) { s.reorder(desc) }
        when Proc
          sort_by_filters[name][:desc] = desc
        end
      end

      # FIXME: Consider introducing a SortFilter object of some sort?
      def sort_by_filters
        @sort_by_filters ||= Hash.new { |h,k| h[k] = {} }
        @sort_by_filters[:id][:asc]  ||= ->(s) { s.reorder(id: :asc) }
        @sort_by_filters[:id][:desc] ||= ->(s) { s.reorder(id: :desc) }

        @sort_by_filters
      end

      def sort_by_default(key)
        @sort_by_default_key = key
      end

      def sort_by_default_key
        @sort_by_default_key || :id
      end

      def default_sort_order(params)
        sort_order_defaults.update(params).symbolize_keys!
      end

      def sort_order_defaults
        @sort_order_defaults ||=  Hash.new { |h,k| h[k] = :asc }
      end

      def cond(key, &scope)
        conditions[key] = scope
      end

      def conditions
        @conditions ||= {}
      end

      def cond_eq(*keys)
        keys.each do |key|
          cond_eq!(key, key)
        end
      end

      def cond_eq!(key, column)
        cond(key) { |s,v| s.where(column => v) }
      end

      def cond_start(*keys)
        keys.each do |key|
          cond_start!(key, "#{from.table_name}.#{key}")
        end
      end

      def cond_start!(key, column)
        cond(key) { |s,v| s.where("#{column} like ?", "#{v}%") }
      end

      def cond_like(*keys)
        keys.each do |key|
          cond_like!(key, "#{from.table_name}.#{key}")
        end
      end

      def cond_like!(key, column)
        cond(key) { |s,v| s.where("#{column} like ?", "%#{v}%") }
      end

      def cond_lt(*keys)
        keys.each do |key|
          cond(key) { |s,v| s.where("#{from.table_name}.#{key} < ?", v) }
        end
      end

      def cond_lte(*keys)
        keys.each do |key|
          cond_lte!(key, "#{from.table_name}.#{key}")
        end
      end

      def cond_lte!(key, column)
        cond(key) { |s,v| s.where("#{column} <= ?", v) }
      end

      def cond_gte(*keys)
        keys.each do |key|
          cond_gte!(key, "#{from.table_name}.#{key}")
        end
      end

      def cond_gte!(key, column)
        cond(key) { |s,v| s.where("#{column} >= ?", v) }
      end

      def cond_gt(*keys)
        keys.each do |key|
          cond(key) { |s,v| s.where("#{from.table_name}.#{key} > ?", v) }
        end
      end

      def cond_range(*ranges)
        ranges.each do |start_key, end_key, column|
          cond_range!(start_key, end_key, column)
        end
      end

      def cond_range!(start_key, end_key, column)
        cond_gte!(start_key, column)
        cond_lte!(end_key, column)
      end

      def cond_cont(*keys)
        keys.each do |key|
          cond(key) { |s,v| s.where("#{from.table_name}.#{key} like ?", "%#{v}%") }
        end
      end

      def cond_localized_date_range(*ranges)
        ranges.each do |range|
          cond_localized_date_range!(*range)
        end
      end

      # NOTE: You can use cond_range instead of this method when working with date columns
      # in the DB as they're zoneless. This method is only necessary when working with
      # datetime fields, because for those you will need to translate the beginning/end of the
      # range to the localized beginning/end of day times.
      def cond_localized_date_range!(start_key, end_key, column)
        cond(start_key) { |s,v| s.where("#{from.table_name}.#{column} >= ?", PetersenToolbox.to_local_time(Date.parse(v)).beginning_of_day) }
        cond(end_key) { |s,v| s.where("#{from.table_name}.#{column} <= ?", PetersenToolbox.to_local_time(Date.parse(v)).end_of_day) }
      end

      attr_reader :from
    end

    attr_reader :scopes, :results, :params, :conditions

    def initialize(params={})
      @params     = params.symbolize_keys
      @conditions = self.class.conditions.select { |k,v| @params[k].present? }

      @sort_by_key = @params.fetch(:order_by, self.class.sort_by_default_key).to_sym
      @sort_order  = @params.fetch(:sort_order, self.class.sort_order_defaults[@sort_by_key]).to_sym

      # FIXME: Should this be a validation instead?
      setup(**params) if respond_to?(:setup)
    end

    def save
      if valid?
        @results = @conditions.inject(self.class.scope) { |relation, (key, scope)|
          scope.call(relation, @params[key], @params)
        }

        @results = sorted(@results)
      end
    end

    def sorted(relation)
      self.class.sort_by_filters[@sort_by_key][@sort_order][relation]
    end

    def to_s
      @params.select { |k,v| v.present? }.map { |k,v| "<strong>#{k.to_s.humanize}</strong>: #{v}" }.join(" + ")
    end
  end
end
