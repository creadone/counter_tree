module CounterTree
  class Counter
    include MessagePack::Serializable

    getter table : Hash(UInt64, UInt64)
    getter total : UInt64

    def initialize
      @table = Hash(UInt64, UInt64).new
      @total = 0_u64
    end

    def increment : UInt64
      insert(key = timestamp, value : UInt64 = 1)
    end

    def decrement : UInt64
      remove(key = timestamp, value : UInt64 = 1)
    end

    def insert(key : UInt64, value : UInt64) : UInt64
      if @table.has_key?(key)
        @table[key] += value
      else
        @table[key] = value
      end
      increment_total(value)
      value
    end

    def remove(key : UInt64, value : UInt64) : UInt64
      if @table.has_key?(key)
        if @table[key] >= value
          @table[key] -= value
        else
          @table[key] = 0_u64
        end
      end
      decrement_total(value)
      value
    end

    def find(time_from : UInt64, time_to : UInt64) : Hash(UInt64, UInt64)
      @table.select do |key, _|
        key >= time_from && key <= time_to
      end
    end

    def delete(time_from : UInt64, time_to : UInt64) : Bool
      @table.each do |key, _val|
        if key >= time_from && key <= time_to
          @table.delete(key)
        end
      end
      true
    end

    def sum : UInt64
      @total
    end

    def sum(time_from : UInt64, time_to : UInt64) : UInt64
      find(time_from, time_to).values.sum
    end

    def reset : Bool
      @table = {} of UInt64 => UInt64
      @total = 0_u64
      true
    end

    private def increment_total(value : UInt64) : UInt64
      @total = @total + value
    end

    private def decrement_total(value : UInt64) : UInt64
      if @total <= value
        @total = 0_u64
      else
        @total = @total - value
      end
    end

    private def timestamp : UInt64
      Time.local.to_s("%Y%m%d").to_u64
    end

  end
end