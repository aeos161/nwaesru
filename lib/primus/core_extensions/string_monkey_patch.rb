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
        Primus.sum(self)
      end

      def to_gp(strategy = :letter)
        Primus.parse(self, strategy)
      end
    end
  end
end
