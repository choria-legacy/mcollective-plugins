module MCollective
  class Aggregate
    class Nagios_states<Base
      # Before function is run processing
      def startup_hook
        @result[:value] = {}
        @result[:type] = :collection

        @status_map = ["OK", "WARNING", "CRITICAL", "UNKNOWN"]
        @status_map.each {|s| @result[:value][s] = 0}

        # set default aggregate_format if it is undefined
        @aggregate_format = "%10s : %s" unless @aggregate_format
      end

      # Determines the average of a set of numerical values
      def process_result(value, reply)
        if value
          status = @status_map[value]
          @result[:value][status] += 1
        else
          @result["UNKNOWN"] += 1
        end
      end
    end
  end
end
