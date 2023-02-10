require "benchmark"

module Primus
  module CoreExtensions
    module StringMonkeyPatch
      class << self
        def apply_patch
          const = find_const

          if const
            const.prepend(self)
          end
        end

        private

        def find_const
          Kernel.const_get("::String")
        rescue NameError
        end
      end

      def gp_sum
        Primus.sum(self).sum
      end

      def to_gp(strategy = :letter)
        Primus.parse(self, strategy)
      end

      def prime?
        gp_sum.prime?
      end
    end
  end
end
